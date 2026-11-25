-- More than one character on an account. The saved data is the account's, so each character
-- must get its own sessions, its own running session and its own history, also where two
-- characters share a first name (the Forever client: no realm name, and a surname).
--
-- The saved data starts as a version before 1.0.0 left it: every session filed under the
-- first name alone, one running session for the whole account, the gear choice in the
-- settings.
local T = {}

local EEL, COD = 13422, 6362
local HOUR = 3600
local HEAD = 1

local MAIN = { name = "Mara", surname = "Tidewell", guid = "Player-4101-00A1B2C3", level = 38 }
local ALT = { name = "Mara", surname = "Brook", guid = "Player-4102-00D4E5F6", level = 12 }
local NEW = { name = "Pell", surname = "Harrow", guid = "Player-4101-00A7B8C9", level = 24 }

local function Count(list, text)
    local n = 0
    for _, line in ipairs(list) do
        if tostring(line):find(text, 1, true) then n = n + 1 end
    end
    return n
end

-- A link as the game writes it, with the level of whoever looted it
local function Link(id, name, level)
    return ("|cnIQ1:|Hitem:%d::::::::%d:1486:::::::::|h[%s]|h|r"):format(id, level, name)
end

local function Old(id, zone, started, level)
    return {
        id = id, char = "Mara", zone = zone, started = started, ended = started + 600,
        last = started + 600, active = 600, casts = 10, catches = 8, misses = 2, unknown = 0,
        value = 800,
        items = { [EEL] = { id = EEL, count = 8, name = "Stonescale Eel", link = Link(EEL, "Stonescale Eel", level) } },
    }
end

function T.before()
    Stub.realm = ""
    Stub.player = ALT
    -- Stub.guidLate = n: the game doesn't say who is playing the next n times it is asked
    -- (as when the addon loads before the character is known)
    function UnitGUID()
        if (Stub.guidLate or 0) > 0 then
            Stub.guidLate = Stub.guidLate - 1
            return nil
        end
        return Stub.player.guid
    end
    function UnitLevel() return Stub.player.level end
    local now = time()
    KeepnetDB = {
        sessions = {
            Old(1, "Desolace", now - 30 * HOUR, 37),
            Old(2, "Tanaris", now - 20 * HOUR, 38),
            Old(3, "Tanaris", now - 10 * 60, 38),
        },
        nextId = 4,
        currentId = 3,
        settings = { gearChoice = { [HEAD] = false } },
        usedAt = { [4594] = now - 60 },
    }
end

local function Play(who)
    Stub.player = who
    return Stub.reload()
end

local function Cast(ns, zone, catch)
    local Sessions, Core = ns.Sessions, ns.Core
    local now = time()
    Sessions.CastStarted(now, zone, Core.Character())
    if catch then
        Sessions.CastEnded(now + 15, "catch", { { id = COD, count = 1, name = "Raw Rockscale Cod" } },
            zone, Core.Character())
    end
    ns.Fire("SESSION")
    return Sessions.Current()
end

-- When the live panel was last put at this x from its saved place (0: never). The stand-in
-- game's frames don't move, so this reads the order the panel was placed in.
local function PlacedAt(x)
    local last = 0
    for index, point in ipairs(KeepnetPanel.__placed or {}) do
        if point[2] == UIParent and point[4] == x then last = index end
    end
    return last
end

local function Names(ns)
    local names = {}
    for _, character in ipairs(ns.UI.Characters()) do names[#names + 1] = character.name end
    return table.concat(names, ", ")
end

function T.run(ns)
    -- ------------------------------------------- the alt logs in first, after the update
    Stub.login()
    local Sessions, Core, UI = ns.Sessions, ns.Core, ns.UI
    eq(Core.Character(), ALT.guid, "a character is known by its GUID, not by a name two can share")
    eq(Core.CharacterName(ALT.guid), "Mara Brook", "and shown by its full name")
    eq(ns.db.currentId, nil, "the account's one running session is gone from the saved data")
    eq(#Sessions.List(nil, ALT.guid), 0,
        "sessions fished at level 38 are not a level 12 character's, whatever the shared first name")
    eq(Sessions.Current(), nil, "so the alt has no running session: the live panel starts empty")
    eq(#Sessions.List(nil, "Mara"), 3, "the old sessions wait for the character they fit")
    eq(Count(Stub.chat, "first time on"), 0, "the first character seen is not announced")
    eq(ns.db.usedAt, nil, "the account-wide item marks are dropped")
    eq(ns.db.settings.gearChoice, nil, "the gear choice is no longer a setting of the account")
    eq(ns.char.gearChoice[HEAD], false, "it went to the first character seen")
    check(ns.char == ns.db.chars[ALT.guid], "a character's own data is saved under its key")

    Stub.equip(Stub.POLE)
    eq(KeepnetPanel.casts:GetText(), "Casts: 0", "the live panel shows nothing of another character's session")
    local altSession = Cast(ns, "Durotar", true)
    eq(altSession.char, ALT.guid, "a cast starts a session of the character who cast")
    eq(altSession.id, 4, "a new one")

    -- The alt sets things its own way: a lure, the sound, what is hidden, where the panel is
    eq(ns.db.owner, ALT.guid, "the saved settings are marked as this character's")
    check(ns.settings == ns.db.settings, "and are the settings in use")
    ns.settings.lureMode, ns.settings.lureItem = "specific", 6529
    ns.settings.masterVolume = 0.4
    ns.settings.hideParts.chat = true
    ns.db.panel = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 111, y = 222 }
    ns.db.panelSize = { width = 300, rows = 5 }
    eq(KeepnetPanel.casts:GetText(), "Casts: 1", "and the live panel follows it")
    eq(Sessions.Get(3).casts, 10, "the other character's session is untouched")

    UI.Show("history")
    eq(#ns.HistoryTab.list.data, 1, "History lists the character's own sessions")
    eq(Names(ns), "Mara Brook, Mara",
        "the list of characters: the one played first, then whoever else has sessions")
    UI.Show("zones")
    local fished = 0
    for _, row in ipairs(ns.ZonesTab.zones.data) do
        if row.sessions > 0 then fished = fished + 1 end
    end
    eq(fished, 1, "the Zones tab counts only this character's sessions")
    eq(ns.ZonesTab.zones.data[1].zone, "Durotar", "in the zone it fished")

    -- ----------------------------------------------- the main logs in: the old data is its
    ns = Play(MAIN)
    Sessions, Core, UI = ns.Sessions, ns.Core, ns.UI
    eq(Core.Character(), MAIN.guid, "another character, another key")
    eq(#Sessions.List(nil, MAIN.guid), 3, "the sessions from before fit this character and are taken over")
    eq(#Sessions.List(nil, "Mara"), 0, "none left under the old label")
    eq(Count(Stub.chat, "first time on"), 0, "a character that takes over its old sessions is not new")
    check(Sessions.Current() ~= nil and Sessions.Current().id == 3,
        "its running session is the one it had, not the alt's")
    check(Sessions.IsCurrent(Sessions.Get(3)) and not Sessions.IsCurrent(Sessions.Get(4)),
        "only the played character's session counts as running")
    eq(next(ns.char.gearChoice), nil, "the other character's gear choice is not this one's")

    -- Settings: a character seen for the first time starts with a copy of the last one's
    eq(ns.db.owner, MAIN.guid, "the saved settings are now this character's")
    eq(ns.settings.lureMode, "specific", "first time on a character: it starts with the last one's settings")
    eq(ns.db.panel.x, 111, "and its place for the panel")
    local parked = ns.db.chars[ALT.guid].kit
    check(parked ~= nil and parked.settings.lureItem == 6529, "the other character's settings are put away under its key")
    -- and from here on they are its own
    ns.settings.lureMode, ns.settings.lureItem = "off", nil
    ns.settings.masterVolume = 0.9
    ns.settings.sessionGap = 45
    ns.settings.hideParts.chat = false
    ns.settings.key = "G"
    ns.Fire("SETTINGS")
    ns.db.panel.x = 333
    ns.db.panelSize = nil
    eq(parked.settings.lureMode, "specific", "changing them leaves the other character's alone")
    eq(parked.settings.hideParts.chat, true, "down to the lists inside")
    eq(parked.panel.x, 111, "and its panel where it was")

    Stub.equip(Stub.POLE)
    eq(KeepnetPanel.casts:GetText(), "Casts: 10", "the live panel shows this character's session")
    local carried = Cast(ns, "Tanaris", true)
    eq(carried.id, 3, "a cast within the session gap carries the character's own session on")
    eq(Sessions.Get(4).casts, 1, "the alt's session got none of it")

    -- The lists: own by default, another character's or everyone's on request
    UI.Show("history")
    local history = ns.HistoryTab.list
    eq(#history.data, 3, "History: the main's three sessions")
    eq(ns.HistoryTab.who.value, MAIN.guid, "the list of characters stands on the one played")
    eq(Names(ns), "Mara Tidewell, Mara Brook", "both characters can be chosen")
    eq(#Sessions.FindCatches("cod", UI.Viewed()), 1, "the search looks through the same sessions")

    UI.View(ALT.guid)
    eq(#history.data, 1, "the other character chosen: its one session")
    eq(history.data[1].session.id, 4, "the alt's")
    eq(history.data[1].live, false, "which is not running: that character is not being played")
    eq(ns.HistoryTab.who.value, ALT.guid, "the list says whose they are")
    eq(Sessions.Current().id, 3, "the running session is still the played character's")
    eq(KeepnetPanel.casts:GetText(), "Casts: 11", "and the live panel has not moved")
    UI.Show("zones")
    eq(ns.ZonesTab.zones.data[1].zone, "Durotar", "the Zones tab follows the same choice")
    eq(ns.ZonesTab.who.value, ALT.guid, "and its list says so")
    -- A cast while looking at another character's history still goes to the played one
    eq(Cast(ns, "Tanaris").id, 3, "a cast meanwhile is the played character's")
    eq(Sessions.Get(4).casts, 1, "not the viewed one's")

    UI.View(false)
    UI.Show("history")
    eq(#history.data, 4, "all characters: every session")
    eq(ns.HistoryTab.who.label:GetText(), "All characters", "labelled so")
    UI.View(MAIN.guid)
    eq(#history.data, 3, "and back to the played character")

    -- The sample sessions carry no real name, in the list either
    SlashCmdList.KEEPNET("demo")
    eq(Names(ns), ns.Demo.CHARACTER, "sample sessions on: only the sample character can be chosen")
    eq(Sessions.Current().char, ns.Demo.CHARACTER, "and the running session is the sample one")
    SlashCmdList.KEEPNET("demo")
    eq(Sessions.Current().id, 3, "sample sessions off: the character's own running session is back")

    -- ------------------------------------------------------------- a character never seen
    local before = #Stub.chat
    ns = Play(NEW)
    Sessions, Core, UI = ns.Sessions, ns.Core, ns.UI
    eq(Count(Stub.chat, "first time on Pell Harrow"), 1, "a new character is noticed and told once")
    eq(Sessions.Current(), nil, "it starts with no session")
    eq(#Sessions.List(nil, Core.Character()), 0, "and no history")
    eq(Names(ns), "Pell Harrow, Mara Brook, Mara Tidewell",
        "every character seen on the account can be chosen, the played one first")
    UI.Show("history")
    eq(#ns.HistoryTab.list.data, 0, "its History is empty")
    eq(ns.settings.sessionGap, 45, "it starts with the settings of the character played last")
    eq(ns.settings.key, "G", "the key among them")
    check(ns.db.chars[MAIN.guid].kit ~= nil, "whose own are put away")
    ns = Play(NEW)
    eq(Count(Stub.chat, "first time on Pell Harrow"), 1, "not told again at the next login")

    -- ------------------------------------- back on the alt after a break: a new session
    Stub.advance(2 * HOUR)
    ns = Play(ALT)
    Sessions = ns.Sessions
    eq(ns.char.gearChoice[HEAD], false, "the alt's own gear choice is still its own")

    -- Everything the alt set is back, and nothing of the others'
    eq(ns.settings.lureMode, "specific", "back on the alt: its own lure choice")
    eq(ns.settings.lureItem, 6529, "the lure it chose")
    eq(ns.settings.masterVolume, 0.4, "its own sound")
    eq(ns.settings.hideParts.chat, true, "its own choice of what to hide")
    eq(ns.settings.sessionGap, 30, "its own session gap")
    eq(ns.settings.key, "F", "its own key")
    eq(ns.db.panel.x, 111, "its own place for the panel")
    eq(ns.db.panelSize.rows, 5, "and size")
    eq(ns.db.chars[ALT.guid].kit, nil, "nothing of it is left put away: the saved settings are its own")
    check(ns.settings == ns.db.settings, "the settings in use are the saved ones")
    check(Stub.binding("F") ~= nil and Stub.binding("G") == nil, "the key bound is this character's, not the last one's")
    check(PlacedAt(111) > 0, "the live panel is put where this character left it")
    eq(PlacedAt(333), 0, "never where the other keeps it")
    eq(Sessions.Current().id, 4, "its last session is the one the panel shows until it casts")
    local fresh = Cast(ns, "Durotar")
    check(fresh.id ~= 4 and fresh.char == ALT.guid, "after the session gap a cast starts a new session of its own")
    eq(#Sessions.List(nil, ALT.guid), 2, "two sessions for the alt")
    eq(#Sessions.List(nil, MAIN.guid), 3, "three for the main, as they were")
    eq(#Sessions.List(), 5, "five in the saved data")

    -- ------------------------- the game says who is playing only after the addon has loaded
    -- The screens are built on the last character's settings, then put right at login
    Stub.guidLate = 1
    ns = Play(MAIN)
    eq(Stub.guidLate, 0, "(the game was asked once before it answered)")
    eq(ns.Core.Character(), MAIN.guid, "known at login all the same")
    eq(ns.settings.lureMode, "off", "the main's settings, though the addon loaded on the alt's")
    eq(ns.settings.sessionGap, 45, "all of them")
    eq(ns.db.panelSize, nil, "its panel at the size it started with")
    check(Stub.binding("G") ~= nil and Stub.binding("F") == nil, "the key is bound again as the main's")
    check(PlacedAt(333) > PlacedAt(111), "and the live panel is moved to where the main keeps it")
    eq(ns.Sessions.Current().id, 3, "with the main's running session")
    eq(ns.db.chars[ALT.guid].kit.settings.lureItem, 6529, "the alt's are put away again, as they were")

    UnitGUID, UnitLevel = nil, nil
    Stub.guidLate = nil
end

return T
