-- Keepnet: telling the player that a newer Keepnet is out.
--
-- An addon cannot reach the internet, so a copy of Keepnet can only learn of a newer version
-- from another player's copy. Every copy says which version it is, in hidden addon messages
-- that no chat window shows:
--   - on a chat channel of Keepnet's own (CHANNEL), which reaches every Keepnet player on
--     the realm. Fishing is done alone, so guild and group would reach almost nobody;
--   - to the guild and to the party or raid as well, which costs nothing and still works
--     when the channel can't be joined.
--
-- The rules, all of them there to keep it quiet and hard to fool:
--   - A copy announces its version once after logging in (and once to a group it joins).
--     When it hears an older version it answers after a random wait, and stays silent when
--     ENOUGH other copies have answered in the meantime.
--   - A newer version is believed only when WITNESSES different players have announced it:
--     one forged or broken message cannot raise the notice. What each player announced is
--     remembered for a few days, so the two need not be online at the same time.
--   - Only a plain "1.2.3" within small bounds is taken for a version.
--   - A development copy (the one tools\install.ps1 puts in the game: a line in its TOC
--     says so) listens like any other and never announces, so nobody is told about a
--     version that can't be downloaded yet.
--   - The player can turn it all off in Settings; Keepnet then leaves the channel.
--   - Nothing is sent, and nothing that arrives is read, while the game holds chat back or
--     hides its values (inside instances and encounters).
--
-- What is heard is the account's, not a character's: db.updates = { heard = { [player] =
-- { version, at } } }.
--
-- The realm-wide channel is how Mastercraft talks on this client, and the announce / answer
-- / stay silent pattern is Forever Dungeon Journal's. How a channel is joined, kept out of
-- sight and sent on here (which calls, in which order, what they answer) was read from
-- Mastercraft, MapUtils and LayerSwap. Written from scratch, nothing copied: see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Updates = {}
ns.Updates = Updates

local PREFIX = "Keepnet"        -- the addon-message prefix (16 characters at most)
local CHANNEL = "KeepersNet"    -- the channel's name
Updates.PREFIX, Updates.CHANNEL = PREFIX, CHANNEL

local WITNESSES = 2             -- different players who must have announced a newer version
local ENOUGH = 2                -- answers by others after which a copy keeps its own to itself
local REMEMBER = 7 * 86400      -- how long one player's announcement counts, in seconds
local SETTLE = 10               -- seconds after entering the world before anything is done
local RETRY = 5                 -- then look again this often until the channel is in and told
local JOIN_PATIENCE = 120       -- join anyway when the game's own channels never showed up
local GIVE_UP = 180             -- stop looking after this long (no room for another channel)
local SEND_GAP = 10             -- at most one message per route in this many seconds
local ANSWER_MIN, ANSWER_MAX = 1, 5
local TELL_SECONDS = 20         -- how long the line stays on the live panel
local MAX_PART = 99             -- no part of a version is larger than this

-- ---------------------------------------------------------------------------------------------
-- Versions
-- ---------------------------------------------------------------------------------------------
-- { major, minor, patch } from "1.2.3"; nil for anything else
function Updates.Parse(text)
    if type(text) ~= "string" or #text > 8 then return nil end
    local major, minor, patch = text:match("^(%d+)%.(%d+)%.(%d+)$")
    major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
    if not major or major > MAX_PART or minor > MAX_PART or patch > MAX_PART then return nil end
    return { major, minor, patch }
end

-- Below 0 when a is the older of two version texts, above 0 when it is the newer; nil when
-- either isn't a version
function Updates.Compare(a, b)
    local first, second = Updates.Parse(a), Updates.Parse(b)
    if not first or not second then return nil end
    for part = 1, 3 do
        if first[part] ~= second[part] then return first[part] - second[part] end
    end
    return 0
end

-- A newer version worth believing in is at most one big step ahead of this one
local function Plausible(version)
    local theirs, mine = Updates.Parse(version), Updates.Parse(ns.VERSION)
    return theirs ~= nil and mine ~= nil and theirs[1] <= mine[1] + 1
end

-- ---------------------------------------------------------------------------------------------
-- What was heard
-- ---------------------------------------------------------------------------------------------
local function Heard()
    local db = ns.db
    db.updates = db.updates or {}
    db.updates.heard = db.updates.heard or {}
    return db.updates.heard
end

-- Forgets what is too old to count, and what is no longer newer than this copy
local function Prune()
    local heard, now = Heard(), time()
    for player, entry in pairs(heard) do
        local newer = type(entry) == "table" and Updates.Compare(entry.version, ns.VERSION)
        if not newer or newer <= 0 or now - (entry.at or 0) > REMEMBER then
            heard[player] = nil
        end
    end
end

-- The newest version that enough different players have announced, or nil
function Updates.Newest()
    if not ns.db then return nil end
    Prune()
    local versions = {}
    for _, entry in pairs(Heard()) do versions[#versions + 1] = entry.version end
    table.sort(versions, function(a, b) return Updates.Compare(a, b) > 0 end)
    -- The second highest is the highest that two players vouch for: whoever announced a
    -- newer one than that also vouches for it
    return versions[WITNESSES]
end

-- Whether this copy is a development build (see the top of the file)
local isDev
function Updates.IsDev()
    if isDev == nil then
        local read = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        local ok, build = pcall(function() return read and read(ns.ADDON, "X-Keepnet-Build") end)
        isDev = ok and build == "dev" or false
    end
    return isDev
end

function Updates.On()
    return ns.settings ~= nil and ns.settings.updates ~= false
end

-- ---------------------------------------------------------------------------------------------
-- Telling the player
-- ---------------------------------------------------------------------------------------------
local toldChat, toldPanel -- the version each was told about, this session

function Updates.Line(version)
    return ("Keepnet %s is out (you have %s). Update it with the CurseForge app."):format(version, ns.VERSION)
end

local function Tell()
    if not Updates.On() then return end
    local version = Updates.Newest()
    if not version then return end
    if toldChat ~= version then
        toldChat = version
        Util.Print(Updates.Line(version))
    end
    -- Chat is out of sight while the interface is hidden: the live panel says it too, the
    -- first time it is up
    if toldPanel ~= version and ns.fishing and ns.LivePanel then
        toldPanel = version
        -- The panel's line is narrow: the short form
        ns.LivePanel.Notice(("Keepnet %s is out (you have %s)"):format(version, ns.VERSION), TELL_SECONDS, true)
    end
    if ns.UI then ns.UI.Refresh() end
end

-- The line under the switch in Settings
function Updates.Describe()
    if not Updates.On() then
        return "Off: Keepnet asks nobody and tells nobody which version it is."
    end
    local version = Updates.Newest()
    if version then
        return "|cff" .. ns.Widgets.AccentHex() .. Updates.Line(version) .. "|r"
    end
    local how = "Keepnet copies tell each other their version over a hidden chat channel (" .. CHANNEL
        .. "), your guild and your group. Nothing shows in chat."
    if Updates.IsDev() then
        how = how .. " This is a development copy: it listens and never announces."
    end
    return how
end

-- ---------------------------------------------------------------------------------------------
-- The channel
-- ---------------------------------------------------------------------------------------------
-- Nothing about chat may be done in combat or while the game holds chat back
local function Locked()
    if InCombatLockdown and InCombatLockdown() then return true end
    local lockdown = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    if lockdown then
        local ok, held = pcall(lockdown)
        if not ok or Util.Hidden(held) or held then return true end
    end
    return false
end

-- The channel's number, which can change: looked up before every use. nil when not in it.
local function ChannelNumber()
    if not GetChannelName then return nil end
    local ok, number = pcall(GetChannelName, CHANNEL)
    if ok and type(number) == "number" and not Util.Hidden(number) and number > 0 then return number end
    return nil
end

-- The player never sees the channel: it is taken off every chat window. Done more than once
-- after joining, because the game puts a new channel on the first window by itself.
local function HideFromChat()
    for window = 1, NUM_CHAT_WINDOWS or 10 do
        if RemoveChatWindowChannel then pcall(RemoveChatWindowChannel, window, CHANNEL) end
        local frame = _G["ChatFrame" .. window]
        if frame and ChatFrame_RemoveChannel then pcall(ChatFrame_RemoveChannel, frame, CHANNEL) end
    end
end

-- And nothing about it is printed: not "Joined Channel", not who came and went, not a line
-- somebody typed into it. The channel's own name is the ninth thing such a message carries.
local function IsOurs(name)
    return type(name) == "string" and not Util.Hidden(name) and name:lower() == CHANNEL:lower()
end
local function Silence(_, _, ...)
    return IsOurs((select(9, ...)))
end
do
    local add = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
    if add then
        for _, event in ipairs({ "CHAT_MSG_CHANNEL_NOTICE", "CHAT_MSG_CHANNEL_NOTICE_USER", "CHAT_MSG_CHANNEL" }) do
            pcall(add, event, Silence)
        end
    end
end

-- Whether the game's own channels (General, Trade) are in. Joining before them would take
-- a low number and push theirs up.
local function GameChannelsIn()
    if GetChannelList then
        local ok, first = pcall(GetChannelList)
        return ok and first ~= nil
    end
    return true
end

local worldAt -- GetTime() when the world was last entered

local function Join()
    if not Updates.On() or ChannelNumber() or Locked() or not JoinTemporaryChannel then return end
    if not GameChannelsIn() and worldAt and GetTime() - worldAt < JOIN_PATIENCE then return end
    -- A temporary channel: the game forgets it at logout, so nothing of it is left behind
    -- when Keepnet is removed
    pcall(JoinTemporaryChannel, CHANNEL)
    HideFromChat()
    C_Timer.After(1, HideFromChat)
    C_Timer.After(5, HideFromChat)
end

-- Does something only right after the player's own click on the switch in Settings: at any
-- other time the notice is either on, or was off before the channel could be joined
local function Leave()
    if ChannelNumber() and LeaveChannelByName and not Locked() then pcall(LeaveChannelByName, CHANNEL) end
end

-- ---------------------------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------------------------
-- A mark of this copy's own for this session, so its own messages are known when they come
-- back (the sender's name comes in a form that differs between clients)
local token = ("%04x%04x"):format(math.random(0, 0xffff), math.random(0, 0xffff))

local lastSent = {} -- route -> GetTime() of the last message

-- The chat type and target for a route, or nil when the route isn't open now
local function Target(route)
    if route == "CHANNEL" then
        local number = ChannelNumber()
        if number then return "CHANNEL", number end
    elseif route == "GUILD" then
        if IsInGuild and IsInGuild() then return "GUILD" end
    elseif route == "GROUP" then
        if IsInRaid and IsInRaid() then return "RAID" end
        if IsInGroup and IsInGroup() then return "PARTY" end
    end
end

-- Says which version this is, on one route. Returns whether a message went out.
local function Announce(route)
    if not Updates.On() or Updates.IsDev() or Locked() then return false end
    if lastSent[route] and GetTime() - lastSent[route] < SEND_GAP then return false end
    local send = C_ChatInfo and C_ChatInfo.SendAddonMessage
    local kind, target = Target(route)
    if not send or not kind then return false end
    lastSent[route] = GetTime()
    local ok, result = pcall(send, PREFIX, ("V1 %s %s"):format(ns.VERSION, token), kind, target)
    -- A number on this client, 0 for sent (a channel still coming in answers 7: the next
    -- look tries again); true or nothing on older ones
    return ok and (result == true or result == 0 or result == nil)
end
Updates.Announce = Announce

-- ---------------------------------------------------------------------------------------------
-- Hearing
-- ---------------------------------------------------------------------------------------------
-- An answer that is waiting for its moment: route -> { others = { [player] = true }, count }
local answering = {}

local function Answer(route)
    if answering[route] then return end
    local waiting = { others = {}, count = 0 }
    answering[route] = waiting
    local function Speak()
        if answering[route] ~= waiting then return end
        -- Enough others said it first: one more would only be noise
        if waiting.count >= ENOUGH then
            answering[route] = nil
            return
        end
        -- This copy spoke there a moment ago: the answer waits its turn
        local wait = lastSent[route] and (SEND_GAP - (GetTime() - lastSent[route])) or 0
        if wait > 0 then
            C_Timer.After(wait + 0.1, Speak)
            return
        end
        answering[route] = nil
        Announce(route)
    end
    C_Timer.After(ANSWER_MIN + math.random() * (ANSWER_MAX - ANSWER_MIN), Speak)
end

local ROUTES = { CHANNEL = "CHANNEL", GUILD = "GUILD", PARTY = "GROUP", RAID = "GROUP" }

local function OnMessage(prefix, text, kind, sender)
    if not ns.db or not Updates.On() then return end
    -- Inside an instance the game hides what arrives; a hidden value must not be looked at
    if Util.Hidden(prefix) or Util.Hidden(text) or Util.Hidden(kind) or Util.Hidden(sender) then return end
    if prefix ~= PREFIX or type(text) ~= "string" or #text > 32 then return end
    local route = ROUTES[kind]
    if not route or type(sender) ~= "string" or sender == "" then return end
    local version, mark = text:match("^V1 (%S+) (%x+)$")
    if not version or mark == token then return end -- not ours to read, or our own coming back
    local difference = Updates.Compare(version, ns.VERSION)
    if not difference then return end

    if difference >= 0 then
        -- Somebody at least as new as this copy has spoken: it counts as an answer to any
        -- older copy this one was about to answer
        local waiting = answering[route]
        if waiting and not waiting.others[sender] then
            waiting.others[sender] = true
            waiting.count = waiting.count + 1
        end
    end
    if difference > 0 then
        if not Plausible(version) then return end
        local heard = Heard()
        local known = heard[sender]
        -- A player's newest claim is the one kept
        if not known or (Updates.Compare(version, known.version) or 0) >= 0 then
            heard[sender] = { version = version, at = time() }
        end
        Tell()
    elseif difference < 0 then
        Answer(route)
    end
end
Updates.OnMessage = OnMessage

-- ---------------------------------------------------------------------------------------------
-- When
-- ---------------------------------------------------------------------------------------------
local announced = {} -- route -> true once this copy has said its version there this session
local inGroup = false
local lookUntil = 0  -- GetTime() until which the channel is looked for
local scheduled = false
local Routine

local function Later(seconds)
    if scheduled then return end
    scheduled = true
    C_Timer.After(seconds, function()
        scheduled = false
        Routine()
    end)
end

-- Joins the channel when it is time, says the version wherever it hasn't been said yet, and
-- tells the player what is known. Safe to call at any moment, as often as wanted.
function Routine()
    if not ns.db then return end
    if not Updates.On() then
        Leave()
        return
    end
    if not worldAt then return end
    local settling = SETTLE - (GetTime() - worldAt)
    if settling > 0 then
        Later(settling)
        return
    end
    Join()
    for _, route in ipairs({ "CHANNEL", "GUILD", "GROUP" }) do
        if not announced[route] and Target(route) and Announce(route) then
            announced[route] = true
        end
    end
    Tell()
    -- The game's own channels may not be in yet, and ours takes a moment to come in
    local done = ChannelNumber() and (announced.CHANNEL or Updates.IsDev())
    if not done and GetTime() < lookUntil then Later(RETRY) end
end

local events = CreateFrame("Frame")
local function Register(event) pcall(events.RegisterEvent, events, event) end
Register("CHAT_MSG_ADDON")
Register("GROUP_ROSTER_UPDATE")
Register("CHAT_MSG_CHANNEL_NOTICE")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnMessage(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- A group joined is a new audience: once per group
        local now = Target("GROUP") ~= nil
        if now and not inGroup then announced.GROUP = nil end
        inGroup = now
        Routine()
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        -- Our channel came in (or its number moved): out of sight again, and say the version
        if IsOurs((select(9, ...))) then
            C_Timer.After(0.5, HideFromChat)
            Later(1)
        end
    end
end)

ns.On("INIT", function()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
    end
    Prune()
end)

ns.On("WORLD", function()
    worldAt = GetTime()
    lookUntil = worldAt + GIVE_UP
    Later(SETTLE)
end)

ns.On("COMBAT", function(inCombat)
    if not inCombat then Routine() end
end)

ns.On("MODE", function(on)
    if on then Tell() end
end)

ns.On("SETTINGS", Routine)
