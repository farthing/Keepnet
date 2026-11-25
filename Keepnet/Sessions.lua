-- Keepnet: fishing sessions. Pure logic on the saved data, no frames and no game calls, so it
-- is tested outside the game (tests\test_logic.lua).
--
-- A session belongs to one character and one zone. It starts on a cast and is replaced by a new
-- one when the last activity is older than the session gap, the zone differs, or the player
-- asks for a new session.
--
-- Every character has its own running session and its own history: session.char is the
-- character's key (Core.Character()), db.current holds each character's running session, and
-- the lists further down take a character to list only that one's sessions. "The character"
-- with no name given is the one playing (Sessions.SetCharacter, or whoever cast last).
local _, ns = ...

local Sessions = {}
ns.Sessions = Sessions

-- A gap between two casts counts as fishing time only up to this many seconds, so a break
-- doesn't drag the gold per hour down. A full cast is about 20 seconds.
Sessions.ACTIVE_GAP = 120
-- No per-hour figure before this much fishing time: the first catch would read as a fortune.
Sessions.MIN_RATE_TIME = 60

local db       -- the saved data: { sessions = { ... }, nextId, current = { [character] = id } }
local settings -- read live: sessionGap (minutes), zoneSplit
local playing  -- the character at the keys

function Sessions.Init(store, options)
    db = store
    settings = options or {}
    db.sessions = db.sessions or {}
    db.nextId = db.nextId or 1
    db.current = db.current or {}
    -- Before 1.0.0 the whole account had one running session
    if db.currentId then
        for _, session in ipairs(db.sessions) do
            if session.id == db.currentId and session.char then
                db.current[session.char] = db.current[session.char] or session.id
            end
        end
        db.currentId = nil
    end
end

-- Who is playing: the running session, and everything that says "this character", is theirs
function Sessions.SetCharacter(character)
    playing = character
end

function Sessions.Character()
    return playing
end

local function Find(id)
    if not id then return nil end
    for i, session in ipairs(db.sessions) do
        if session.id == id then return session, i end
    end
end

function Sessions.Get(id)
    return (Find(id))
end

-- The session the character at the keys is fishing now, or nil
function Sessions.Current()
    if not playing then return nil end
    local session = Find(db.current[playing])
    if not session then db.current[playing] = nil end
    return session
end

function Sessions.IsCurrent(session)
    return session ~= nil and playing ~= nil and session.id == db.current[playing]
end

-- Adds the time since the last activity to the fishing time, unless it was a break
local function Touch(session, now)
    local gap = now - (session.last or now)
    if gap > 0 and gap <= Sessions.ACTIVE_GAP then
        session.active = session.active + gap
    end
    session.last = now
    session.ended = now
end

-- Ends the current session. One with no casts is not kept.
function Sessions.CloseCurrent()
    if not playing then return end
    local session, index = Find(db.current[playing])
    db.current[playing] = nil
    if session and session.casts <= 0 then
        table.remove(db.sessions, index)
    end
end

-- The player's New session button: the next cast starts a fresh one
function Sessions.StartNew()
    Sessions.CloseCurrent()
end

function Sessions.NeedsNew(session, now, zone, character)
    if not session then return true end
    if now - (session.last or session.started) > (settings.sessionGap or 30) * 60 then return true end
    if session.char ~= character then return true end
    if settings.zoneSplit ~= false and session.zone ~= zone then return true end
    return false
end

local function Ensure(now, zone, character)
    -- Whoever casts is the one playing. Another character's running session is left as it
    -- is: it carries on when that character is back within the session gap.
    playing = character or playing
    local session = Sessions.Current()
    if Sessions.NeedsNew(session, now, zone, character) then
        Sessions.CloseCurrent()
        session = {
            id = db.nextId,
            char = character,
            zone = zone,
            started = now,
            ended = now,
            last = now,
            active = 0,
            casts = 0,
            catches = 0,
            misses = 0,
            unknown = 0,
            items = {},
        }
        db.nextId = db.nextId + 1
        db.sessions[#db.sessions + 1] = session
        db.current[playing] = session.id
    end
    return session
end

-- A cast went out. Returns the session it belongs to.
function Sessions.CastStarted(now, zone, character)
    local session = Ensure(now, zone, character)
    Touch(session, now)
    session.casts = session.casts + 1
    return session
end

-- The Fishing skill went up by this many points: counted for the running session, when it is
-- this character's. Returns that session, or nil when there is none to count it for.
function Sessions.SkillGained(points, character)
    local session = Sessions.Current()
    if not session or session.char ~= character or not points or points <= 0 then return nil end
    session.skillUps = (session.skillUps or 0) + points
    return session
end

-- A cast ended. result is "catch" (loot is a list of { id, link, name, icon, quality, count }
-- or { hidden = true } for a catch the game wouldn't show), "miss" (the line came in empty) or
-- "recast" (thrown again before it could catch anything, so it never counted as a cast).
function Sessions.CastEnded(now, result, loot, zone, character)
    if result == "catch" then
        local session = Ensure(now, zone, character)
        Touch(session, now)
        session.catches = session.catches + 1
        -- A catch always has a cast, even when the cast itself wasn't seen (a /reload mid-cast)
        if session.casts < session.catches + session.misses then
            session.casts = session.catches + session.misses
        end
        for _, drop in ipairs(loot or {}) do
            if drop.hidden or not drop.id then
                session.unknown = session.unknown + 1
            else
                local item = session.items[drop.id]
                if not item then
                    item = { id = drop.id, count = 0 }
                    session.items[drop.id] = item
                end
                item.count = item.count + (drop.count or 1)
                item.link = drop.link or item.link
                item.name = drop.name or item.name
                item.icon = drop.icon or item.icon
                if drop.quality then item.quality = drop.quality end
            end
        end
        return session
    end

    local session = Sessions.Current()
    if not session then return nil end
    if result == "miss" then
        Touch(session, now)
        session.misses = session.misses + 1
        if session.casts < session.catches + session.misses then
            session.casts = session.catches + session.misses
        end
    elseif result == "recast" then
        if session.casts > session.catches + session.misses then
            session.casts = session.casts - 1
        end
    end
    return session
end

-- ---------------------------------------------------------------------------------------------
-- Catches that get opened: a trunk, a chest, a clam, a bloated fish. What comes out of one
-- belongs to the session it was caught in, and is kept apart from the catch itself
-- (session.opened, session.money), so the catch list and "where was it caught" stay what was
-- on the hook.
-- ---------------------------------------------------------------------------------------------
-- How many of an item the session caught and has not seen opened
local function Unopened(session, itemID)
    local item = session.items and session.items[itemID]
    if not item then return 0 end
    return item.count - (item.opened or 0)
end

-- The session a catch being opened belongs to: the running one when it still holds one that
-- wasn't opened, otherwise the character's newest session that does. nil when no session
-- has one left: it wasn't fished, or not while Keepnet was counting.
function Sessions.CaughtIn(itemID, character)
    local current = Sessions.Current()
    if current and current.char == character and Unopened(current, itemID) > 0 then return current end
    for i = #db.sessions, 1, -1 do
        local session = db.sessions[i]
        if session.char == character and Unopened(session, itemID) > 0 then return session end
    end
end

-- Every item the character caught that some session still holds unopened: { [itemID] = true }
function Sessions.UnopenedItems(character)
    local ids = {}
    for _, session in ipairs(db.sessions) do
        if session.char == character then
            for id in pairs(session.items or {}) do
                if Unopened(session, id) > 0 then ids[id] = true end
            end
        end
    end
    return ids
end

-- What came out of an opened catch: loot as for a catch ({ id, link, name, icon, quality,
-- count }), and coins in copper
function Sessions.AddOpened(session, loot, money)
    for _, drop in ipairs(loot or {}) do
        if drop.id and not drop.hidden then
            session.opened = session.opened or {}
            local item = session.opened[drop.id]
            if not item then
                item = { id = drop.id, count = 0 }
                session.opened[drop.id] = item
            end
            item.count = item.count + (drop.count or 1)
            item.link = drop.link or item.link
            item.name = drop.name or item.name
            item.icon = drop.icon or item.icon
            if drop.quality then item.quality = drop.quality end
        end
    end
    if money and money > 0 then
        session.money = (session.money or 0) + money
    end
end

-- One of the session's catches was opened and is gone from the bags: it can't be sold any
-- more, so it stops counting at its own price
function Sessions.MarkOpened(session, itemID, count)
    local item = session.items and session.items[itemID]
    if not item then return end
    item.opened = math.min(item.count, (item.opened or 0) + (count or 1))
end

-- What was caught in a session, most first, for the live panel:
-- { { name, link, icon, quality, count, percent } }, where percent is the item's share of
-- everything caught in the session. Catches the game wouldn't show are a row of their own
-- ({ unknown = true, ... }).
function Sessions.CatchList(session)
    local rows, total = {}, 0
    for _, item in pairs(session.items or {}) do
        rows[#rows + 1] = {
            id = item.id,
            name = item.name or (type(item.link) == "string" and item.link:match("%[(.-)%]")) or ("item " .. tostring(item.id)),
            link = item.link,
            icon = item.icon,
            quality = item.quality,
            count = item.count,
        }
        total = total + item.count
    end
    if (session.unknown or 0) > 0 then
        rows[#rows + 1] = { unknown = true, name = "Not shown by the game", count = session.unknown }
        total = total + session.unknown
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name:lower() < b.name:lower()
    end)
    for _, row in ipairs(rows) do
        row.percent = total > 0 and row.count * 100 / total or 0
    end
    return rows, total
end

-- Where a fish or item was caught, best zone first. query is part of a name, in any case.
-- One row for each matching item in each zone it was caught in:
--   { zone, id, name, link, icon, quality,
--     count     how many were caught there, over every session in that zone
--     total     everything caught in that zone
--     percent   the item's share of everything caught there
--     sessions  how many sessions there caught it; zoneSessions  how many sessions there in all }
-- Sorted by share, highest first; equal shares go to the zone with more caught, since a share
-- of a handful of catches says little. With a character, only that character's sessions.
function Sessions.FindCatches(query, character)
    query = type(query) == "string" and query:lower():match("^%s*(.-)%s*$") or ""
    if query == "" then return {} end
    local zones = {}
    for _, session in ipairs(Sessions.List(nil, character)) do
        local zone = zones[session.zone]
        if not zone then
            zone = { total = 0, sessions = 0, items = {} }
            zones[session.zone] = zone
        end
        zone.sessions = zone.sessions + 1
        zone.total = zone.total + (session.unknown or 0)
        for id, item in pairs(session.items or {}) do
            zone.total = zone.total + item.count
            local entry = zone.items[id]
            if not entry then
                entry = { id = id, count = 0, sessions = 0 }
                zone.items[id] = entry
            end
            entry.count = entry.count + item.count
            entry.sessions = entry.sessions + 1
            entry.name = entry.name or item.name or (type(item.link) == "string" and item.link:match("%[(.-)%]"))
            entry.link = entry.link or item.link
            entry.icon = entry.icon or item.icon
            entry.quality = entry.quality or item.quality
        end
    end
    local rows = {}
    for zoneName, zone in pairs(zones) do
        for _, entry in pairs(zone.items) do
            local name = entry.name or ("item " .. tostring(entry.id))
            if name:lower():find(query, 1, true) then
                rows[#rows + 1] = {
                    zone = zoneName, id = entry.id, name = name, link = entry.link, icon = entry.icon,
                    quality = entry.quality, count = entry.count, total = zone.total,
                    percent = zone.total > 0 and entry.count * 100 / zone.total or 0,
                    sessions = entry.sessions, zoneSessions = zone.sessions,
                }
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.percent ~= b.percent then return a.percent > b.percent end
        if a.total ~= b.total then return a.total > b.total end
        if a.zone ~= b.zone then return a.zone < b.zone end
        return a.name < b.name
    end)
    return rows
end

-- The value as it stood, kept so a finished session keeps the gold it was worth at the time
function Sessions.SetValue(session, value, unpriced)
    session.value = value
    session.unpriced = unpriced
end

function Sessions.Delete(id)
    local _, index = Find(id)
    if not index then return false end
    table.remove(db.sessions, index)
    for character, current in pairs(db.current) do
        if current == id then db.current[character] = nil end
    end
    return true
end

-- Every session, or only those of one zone and/or one character, newest first
function Sessions.List(zone, character)
    local list = {}
    for i = #db.sessions, 1, -1 do
        local session = db.sessions[i]
        if (not zone or session.zone == zone) and (not character or session.char == character) then
            list[#list + 1] = session
        end
    end
    return list
end

-- The characters that have sessions, the one who fished last first
function Sessions.Characters()
    local seen, list = {}, {}
    for i = #db.sessions, 1, -1 do
        local character = db.sessions[i].char
        if character and not seen[character] then
            seen[character] = true
            list[#list + 1] = character
        end
    end
    return list
end

-- The level the character had when the session was fished, read from the links of what was
-- caught (a link carries the level of whoever looted it); nil when no link says
function Sessions.Level(session)
    local level
    for _, item in pairs(session.items or {}) do
        local found = type(item.link) == "string"
            and tonumber(item.link:match("item:%d+:[^:|]*:[^:|]*:[^:|]*:[^:|]*:[^:|]*:[^:|]*:[^:|]*:(%d+)"))
        if found and found > 0 and (not level or found > level) then level = found end
    end
    return level
end

-- Sessions saved before characters had keys of their own carry only the label of that time
-- (the name, with the realm where there is one). The character that label fits takes them
-- over the first time it logs in. On a client where two characters of an account can share
-- that label, the level settles it where it can: a session fished at a higher level than
-- the character has now was somebody else's, and is left for them. Returns how many were
-- taken.
function Sessions.Adopt(label, key, level)
    if not label or not key or label == key then return 0 end
    local taken, kept = 0, false
    for _, session in ipairs(db.sessions) do
        if session.char == label then
            local fished = level and Sessions.Level(session)
            if fished and fished > level then
                kept = true
            else
                session.char = key
                taken = taken + 1
                if db.current[label] == session.id then
                    db.current[key] = db.current[key] or session.id
                    db.current[label] = nil
                end
            end
        end
    end
    if not kept then db.current[label] = nil end
    return taken
end

-- The zone names that have sessions (of one character, when given), A to Z
function Sessions.ZoneNames(character)
    local seen, names = {}, {}
    for _, session in ipairs(db.sessions) do
        if not seen[session.zone] and (not character or session.char == character) then
            seen[session.zone] = true
            names[#names + 1] = session.zone
        end
    end
    table.sort(names)
    return names
end

-- Gold per hour of fishing time, or nil when there isn't enough time to say
function Sessions.PerHour(value, active)
    if not value or not active or active < Sessions.MIN_RATE_TIME then return nil end
    return value * 3600 / active
end

-- One row per zone: { zone, sessions, active, casts, catches, value, perHour }.
-- valueOf(session) returns the session's gold in copper; without it the gold is left at 0
-- (the Zones tab only wants the zones and their session counts). With a character, only
-- that character's sessions count.
function Sessions.Zones(valueOf, character)
    local byZone, rows = {}, {}
    for _, session in ipairs(Sessions.List(nil, character)) do
        local row = byZone[session.zone]
        if not row then
            row = { zone = session.zone, sessions = 0, active = 0, casts = 0, catches = 0, value = 0 }
            byZone[session.zone] = row
            rows[#rows + 1] = row
        end
        row.sessions = row.sessions + 1
        row.active = row.active + session.active
        row.casts = row.casts + session.casts
        row.catches = row.catches + session.catches
        row.value = row.value + ((valueOf and valueOf(session)) or 0)
    end
    for _, row in ipairs(rows) do
        row.perHour = Sessions.PerHour(row.value, row.active)
    end
    return rows
end
