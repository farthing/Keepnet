-- Keepnet: saved data, game events, fishing mode and the slash commands.
--
-- Fishing mode is on while a fishing pole is in the main hand. Everything else listens for it:
--   "INIT"      saved data is ready
--   "WORLD"     entered the world (login, /reload, loading screen)
--   "MODE"      fishing mode turned on or off (true/false)
--   "COMBAT"    combat started or ended (true/false)
--   "LOGOUT"    logging out or reloading
--   "SETTINGS"  a setting changed
--   "SESSION"   the session data changed
--   "TICK"      every few seconds while fishing, after the session was re-priced
--   "CATCH"     loot, session: something was caught, counted and priced
local ADDON, ns = ...
local Util, Sessions, Prices = ns.Util, ns.Sessions, ns.Prices

local Core = {}
ns.Core = Core

local DEFAULTS = {
    key = "F",            -- the one key: casts when the line is in, reels in when it's out
    lureMode = "auto",    -- "off", "auto" (strongest usable lure in the bags) or "specific"
    lureItem = nil,       -- the item ID for "specific"
    lureFallback = false, -- "specific" has run out: use the best lure in the bags instead
    sound = true,         -- fishing sound profile while the pole is on
    masterVolume = 1,     -- master volume of that profile, 0.1 to 1
    sessionGap = 30,      -- minutes without a cast before a new session starts
    zoneSplit = true,     -- a different zone starts a new session
    auctionCut = false,   -- take the auction house's 5 % off auction prices
    priceSource = "auto", -- which auction addon prices come from (see Prices.SOURCES), or "vendor"
    panelLocked = false,  -- the live panel can't be dragged or sized
    panelCatches = true,  -- the live panel lists what was caught this session
    panelKit = true,      -- the live panel shows the lure, food and fishing gear in use
    todayPrices = false,  -- History shows finished sessions at today's prices
    gear = true,          -- wear fishing gear from the bags while the pole is on
    foodMode = "off",     -- fishing food: "off", "auto" (best in the bags) or "specific"
    foodItem = nil,       -- the item ID for "specific"
    rareQuality = 2,      -- alert for a catch of at least this quality (2 green, 3 blue, 4 purple; 0 off)
    rareGold = 0,         -- alert for a catch worth at least this much gold each (0 off)
    rareSound = true,     -- play a sound with the alert
    theme = "keepnet",    -- the look (see W.THEMES)
    schemes = nil,        -- the colours chosen for each family of looks: { keepnet = "slate", ... }
    accentMode = "theme", -- the accent colour: "theme" (the colours' own), "class" or "custom"
    font = "overpass",    -- the font of Keepnet's own looks: "overpass", "game", or "shared:" and
                          -- the name another addon shares one under (see W.FONTS, W.FontChoices)
    accentColor = nil,    -- { r, g, b } for "custom"
    windowOpacity = 0.94, -- how solid the window's background is, 0.2 to 1
    panelOpacity = 0.94,  -- the same for the live panel
    glassWindow = 0.65,   -- the Glass look: how dense the window's tint is
    glassPanel = 0.65,    -- and the live panel's
    panelScale = 1,       -- the live panel's size, 0.7 to 1.5
    borders = true,       -- thin borders round panels and buttons
    hideMode = "off",     -- hide the game's interface while fishing: "off", "all" or "parts"
    hideAuto = true,      -- hide on a cast, bring back on moving (else only by the button)
    updates = true,       -- hear from other players' copies when a newer Keepnet is out (Updates.lua)
}

-- The sound for each kind of rare catch: green, blue, purple (and better), and "worth gold"
local DEFAULT_SOUNDS = { list = "kit:31578", q2 = "kit:31578", q3 = "kit:31578", q4 = "kit:31578", gold = "kit:31578" }

local REPRICE_SECONDS = 5
local MAIN_HAND_SLOT = 16
local WEAPON_CLASS, FISHING_POLE_SUBCLASS = 2, 20

ns.fishing = nil   -- nil until the equipment has been looked at once
ns.inCombat = false

-- ---------------------------------------------------------------------------------------------
-- Who and where
-- ---------------------------------------------------------------------------------------------
function Core.Zone()
    local zone = GetRealZoneText and GetRealZoneText()
    if Util.Hidden(zone) or not zone or zone == "" then return "Unknown" end
    return zone
end

-- The named part of the zone the character stands in, or nil
function Core.SubZone()
    local subzone = GetSubZoneText and GetSubZoneText()
    if Util.Hidden(subzone) or not subzone or subzone == "" then return nil end
    return subzone
end

-- ---------------------------------------------------------------------------------------------
-- Which character this is
-- ---------------------------------------------------------------------------------------------
-- An account's saved data is shared by all of its characters, so everything that belongs to
-- one of them is filed under that character's key: its sessions (session.char), its running
-- session, what Keepnet has to remember about it (ns.char: the gear it swapped, the choice
-- of gear per slot, when an item was last used), and everything the player sets: every
-- setting and the live panel's place and size (see "A character's own settings" below).
--
-- The key is the character's GUID: on this client a name does not tell two characters
-- apart. A Forever realm has no name (GetRealmName gives ""), and the second thing UnitName
-- returns is the character's surname, not a realm, so one account can hold a "Mara
-- Tidewell" and a "Mara Brook". How this client names characters was read from
-- ForeverCore and Mastercraft; see CREDITS.md. Until 1.0.0 the key was the first name with
-- the realm, which made those two one character.
local identity -- this character's key, once the game has said who it is

-- The name, the surname where the client has them, and the realm where it has a name
local function ReadName()
    local name, second = UnitName("player")
    if type(name) ~= "string" or Util.Hidden(name) or name == "" or name == UNKNOWNOBJECT then return nil end
    local realm = GetRealmName and GetRealmName() or ""
    if type(realm) ~= "string" or Util.Hidden(realm) then realm = "" end
    if type(second) ~= "string" or Util.Hidden(second) or second == "" or second == realm
        or second == realm:gsub("[%s%-]", "") then
        second = nil
    end
    return name, second, realm
end

-- What versions before 1.0.0 filed this character's sessions under
local function OldLabel(name, realm)
    if realm ~= "" then return name .. "-" .. realm end
    return name
end

-- The key every session of the character at the keys is filed under
function Core.Character()
    -- While the sample sessions show, so does a sample name: pictures of them carry no real one
    if ns.Demo and ns.Demo.IsOn() then return ns.Demo.CHARACTER end
    if identity then return identity end
    local name, _, realm = ReadName()
    return name and OldLabel(name, realm) or "?"
end

-- A character's name for the screen, from its key: "Mara Tidewell". A key that was never
-- seen logging in (sessions from before 1.0.0 that nobody has taken over, the sample
-- sessions) is a name already.
function Core.CharacterName(character)
    local known = ns.db and ns.db.chars and ns.db.chars[character]
    if known and known.name then return known.name end
    return Util.ShortName(character)
end

-- ---------------------------------------------------------------------------------------------
-- A character's own settings
-- ---------------------------------------------------------------------------------------------
-- Every character has its own settings (the key, lures, food, sound, alerts, appearance, what
-- is hidden, prices: all of them) and its own place and size for the live panel.
--
-- KeepnetDB.settings, .panel and .panelSize are always those of one character, the one named
-- in KeepnetDB.owner: whoever played last. Everybody else's are parked in
-- KeepnetDB.chars[key].kit. When another character logs in, the owner's are parked, and that
-- character's are loaded into the same settings table (so ns.settings is one table for the
-- whole session, whoever is playing). A character seen for the first time has nothing
-- parked and keeps what is there: it starts with a copy of the settings of the character
-- played last, and from then on its changes are its own. An account with one character
-- never swaps anything.
local ready = false -- "INIT" has gone out: frames may exist that show the settings

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Copy(inner) end
    return copy
end

-- A setting that isn't there gets its default
local function Fill(settings)
    for key, value in pairs(DEFAULTS) do
        if settings[key] == nil then settings[key] = value end
    end
    -- Other items the key uses when their buff is missing (a coin, a toy ...): item IDs
    settings.extraItems = settings.extraItems or {}
    -- What "parts" hides: the ticked parts, and frames picked with the mouse, by name
    settings.hideParts = settings.hideParts or
        { actionbars = true, unitframes = true, buffs = true, minimap = true, chat = false, tracker = true }
    settings.hideFrames = settings.hideFrames or {}
    -- Names of the player's own sound files (see Alerts.lua)
    settings.customSounds = settings.customSounds or {}
    -- Which kinds of listed fishing rarities are announced (see Rares.lua)
    settings.rareList = settings.rareList or {}
    for _, kind in ipairs(ns.Rares.KINDS) do
        if settings.rareList[kind.key] == nil then settings.rareList[kind.key] = kind.on end
    end
    settings.rareSounds = settings.rareSounds or {}
    for key, value in pairs(DEFAULT_SOUNDS) do
        if settings.rareSounds[key] == nil then settings.rareSounds[key] = value end
    end
end

-- Makes the saved settings and panel those of this character. Returns whether they changed.
local function TakeSettings(db, key, own)
    local owner = db.owner
    db.owner = key
    if owner == key then return false end
    -- Whoever played last: theirs are put away under their own key
    if owner and db.chars[owner] then
        db.chars[owner].kit = { settings = Copy(db.settings), panel = Copy(db.panel), panelSize = Copy(db.panelSize) }
    end
    local kit = own.kit
    if not kit then return false end -- first time here: it starts with what is there
    own.kit = nil
    for name in pairs(db.settings) do db.settings[name] = nil end
    for name, value in pairs(kit.settings or {}) do db.settings[name] = value end
    Fill(db.settings)
    db.panel, db.panelSize = kit.panel, kit.panelSize
    return true
end

-- Finds out who is playing and gets that character's own data ready. Called when the addon
-- loads, at login and at every loading screen until the game has answered.
function Core.Identify()
    if identity or not ns.db then return end
    local name, surname, realm = ReadName()
    if not name then return end
    local full = surname and (name .. " " .. surname) or name
    local guid = UnitGUID and UnitGUID("player")
    local key
    if type(guid) == "string" and not Util.Hidden(guid) and guid:match("^Player%-") then
        key = guid
    elseif UnitGUID then
        return -- the game knows GUIDs and hasn't given this one yet: ask again later
    else
        key = OldLabel(full, realm)
    end
    identity = key

    local db = ns.db
    db.chars = db.chars or {}
    local others = next(db.chars) ~= nil
    local own = db.chars[key]
    local new = own == nil
    if new then
        own = {}
        db.chars[key] = own
    end
    own.name = full
    own.realm = realm ~= "" and realm or nil
    own.seen = time()
    ns.char = own

    -- Sessions from before characters had keys: this character's, if the label fits
    local level = UnitLevel and UnitLevel("player")
    if type(level) ~= "number" or Util.Hidden(level) or level <= 0 then level = nil end
    local taken = Sessions.Adopt(OldLabel(name, realm), key, level)
    -- The choice of gear per slot was one for the account. It names items, so it goes to
    -- the first character seen and the others start on automatic.
    if db.settings.gearChoice then
        if not own.gearChoice and next(db.settings.gearChoice) then own.gearChoice = db.settings.gearChoice end
        db.settings.gearChoice = nil
    end
    own.gearChoice = own.gearChoice or {}
    db.usedAt = nil -- kept per character now; the old marks would be anyone's

    local changed = TakeSettings(db, key, own)

    if not (ns.Demo and ns.Demo.IsOn()) then Sessions.SetCharacter(key) end
    if new and others and taken == 0 then
        Util.Print(("first time on %s. It has its own sessions and history, and starts with the "
            .. "settings of the character you played last; from here on its settings are its own.")
            :format(full))
    end
    ns.Fire("CHARACTER")
    -- The game said who is playing only after the screens were built on the last
    -- character's settings: show this character's. (A theme of another kind asks for a
    -- reload, as changing to one always does.)
    if changed and ready then
        if ns.Widgets and ns.Widgets.ApplyTheme then ns.Widgets.ApplyTheme() end
        ns.Fire("SETTINGS")
    end
    ns.Fire("SESSION")
end

-- A fishing pole is a weapon of the fishing pole kind in the main hand.
-- Same check FishyWashy (by veiset) uses; see CREDITS.md.
function Core.HasPole()
    local itemID = GetInventoryItemID("player", MAIN_HAND_SLOT)
    if not itemID or Util.Hidden(itemID) then return false end
    local _, _, _, _, _, classID, subclassID = Util.ItemInfoInstant(itemID)
    return classID == WEAPON_CLASS and subclassID == FISHING_POLE_SUBCLASS
end

-- ---------------------------------------------------------------------------------------------
-- Gold
-- ---------------------------------------------------------------------------------------------
-- Items are stored when caught; the facts that decide the price (quality, vendor price, binds
-- when picked up) are filled in as soon as the game knows the item.
function Core.Enrich(item)
    if item.known or not item.id then return end
    local name, link, quality, _, _, _, _, _, _, icon, sell, _, _, bindType = Util.ItemInfo(item.link or item.id)
    if not name then return end
    item.name = item.name or name
    item.link = item.link or link
    item.icon = item.icon or icon
    item.quality = quality or item.quality
    item.sell = sell
    -- 1 binds when picked up, 4 is a quest item: neither can be auctioned
    item.bind = (bindType == 1 or bindType == 4) or nil
    item.known = true
end

local function EnrichAll(session)
    for _, item in pairs(session.items) do
        Core.Enrich(item)
    end
    for _, item in pairs(session.opened or {}) do
        Core.Enrich(item)
    end
end

-- The item rows of a session at today's prices, the total and how many items have no price
function Core.Rows(session)
    EnrichAll(session)
    return Prices.Rows(session, ns.settings)
end

-- A session's gold and the number of items without a price. The current session is always
-- live; a finished one keeps the value it had unless "today's prices" is ticked.
function Core.Value(session)
    if Sessions.IsCurrent(session) or ns.settings.todayPrices or session.value == nil then
        local _, total, unpriced = Core.Rows(session)
        return total, unpriced
    end
    return session.value, session.unpriced or 0
end

-- Stores the current session's value as it stands now
function Core.Reprice()
    local session = Sessions.Current()
    if not session then return end
    local _, total, unpriced = Core.Rows(session)
    Sessions.SetValue(session, total, unpriced)
end

-- Changes a session after the fact (something it caught was opened) and brings its gold up
-- to date. The running session is simply priced again. A finished one keeps the value it
-- had, moved by what the change is worth at today's prices.
local function Amend(session, change)
    local live = Sessions.IsCurrent(session)
    local before
    if not live and session.value ~= nil then
        EnrichAll(session)
        before = Prices.SessionValue(session, ns.settings)
    end
    change()
    if live then
        Core.Reprice()
    elseif before then
        EnrichAll(session)
        local after, unpriced = Prices.SessionValue(session, ns.settings)
        Sessions.SetValue(session, math.max(0, session.value + after - before), unpriced)
    end
    ns.Fire("SESSION")
end

-- A catch that is opened afterwards (a trunk, a chest, a clam, a bloated fish; seen by the
-- second half of Fishing.lua) belongs to the session it was caught in. That session, or nil
-- when no session of this character holds such a catch unopened.
function Core.CaughtIn(itemID)
    if ns.Demo and ns.Demo.IsOn() then return nil end -- the sample sessions are not the player's
    return Sessions.CaughtIn(itemID, Core.Character())
end

-- Something came out of it: the items and coins join that session
function Core.Opened(session, loot, money)
    Amend(session, function() Sessions.AddOpened(session, loot, money) end)
end

-- It is empty and gone from the bags
function Core.OpenedGone(session, itemID)
    Amend(session, function() Sessions.MarkOpened(session, itemID, 1) end)
end

function Core.NewSession()
    Core.Reprice()
    Sessions.StartNew()
    ns.Fire("SESSION")
end

-- ---------------------------------------------------------------------------------------------
-- Fishing mode
-- ---------------------------------------------------------------------------------------------
local ticker

local function SetMode(on)
    if ns.fishing == on then return end
    ns.fishing = on
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    if on then
        ticker = C_Timer.NewTicker(REPRICE_SECONDS, function()
            Core.Reprice()
            ns.Fire("TICK")
        end)
    else
        Core.Reprice()
    end
    ns.Fire("MODE", on)
end

local offCheck

-- Called whenever the equipment may have changed. Turning off waits a moment: during a loading
-- screen the main hand can look empty for an instant, and the sound settings shouldn't flap.
function Core.UpdateMode()
    if Core.HasPole() then
        offCheck = nil
        SetMode(true)
    elseif ns.fishing == nil then
        SetMode(false)
    elseif ns.fishing and not offCheck then
        local token = {}
        offCheck = token
        C_Timer.After(0.3, function()
            if offCheck ~= token then return end
            offCheck = nil
            if not Core.HasPole() then SetMode(false) end
        end)
    end
end

-- ---------------------------------------------------------------------------------------------
-- Casts feed the sessions
-- ---------------------------------------------------------------------------------------------
ns.On("CAST_START", function()
    Sessions.CastStarted(time(), Core.Zone(), Core.Character())
    ns.Fire("SESSION")
end)

ns.On("CAST_END", function(result, loot)
    local session = Sessions.CastEnded(time(), result, loot, Core.Zone(), Core.Character())
    if session and result == "catch" then
        Core.Reprice()
        ns.Fire("CATCH", loot, session)
    end
    ns.Fire("SESSION")
end)

-- ---------------------------------------------------------------------------------------------
-- Start-up and events
-- ---------------------------------------------------------------------------------------------
local function Init()
    KeepnetDB = KeepnetDB or {}
    local db = KeepnetDB
    db.version = db.version or 1
    db.settings = db.settings or {}
    Fill(db.settings)
    ns.db = db
    ns.settings = db.settings
    -- This character's own data (see Core.Identify). Until the game says who is playing it
    -- is a table that is not saved, so nothing of one character is filed under another.
    ns.char = { gearChoice = {} }
    Sessions.Init(db, db.settings)
    -- Before "INIT": when the game already says who is playing, everything that starts up
    -- on "INIT" finds this character's settings in place
    Core.Identify()
    ns.Fire("INIT")
    ready = true
end

-- Other fishing addons bind the same key and change the same game settings
local CONFLICTS = { "FishyWashy", "ForeverFishing" }

local function WarnConflicts()
    local found = {}
    for _, name in ipairs(CONFLICTS) do
        if Util.IsAddOnLoaded(name) then found[#found + 1] = name end
    end
    if #found > 0 then
        Util.Print(("%s is also enabled. It binds the fishing key and changes the same sound and "
            .. "interact settings, so the two will fight. Disable it in the addon list while you "
            .. "use Keepnet."):format(table.concat(found, " and ")))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LOGOUT")
-- Fires once the equipment is known again after a loading screen
events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ns.ADDON then Init() end
        return
    end
    if not ns.db then return end
    if event == "PLAYER_LOGIN" then
        Core.Identify()
        WarnConflicts()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Core.Identify()
        ns.inCombat = InCombatLockdown() and true or false
        ns.Fire("WORLD")
        -- The main hand can look empty right after a loading screen, so look once it has settled
        C_Timer.After(1, Core.UpdateMode)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Sent just before the combat lock, so keys and protected settings can still be put back
        ns.inCombat = true
        ns.Fire("COMBAT", true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.inCombat = false
        ns.Fire("COMBAT", false)
        Core.UpdateMode()
    elseif event == "PLAYER_LOGOUT" then
        Core.Reprice()
        ns.Fire("LOGOUT")
    else
        Core.UpdateMode()
    end
end)

-- ---------------------------------------------------------------------------------------------
-- Slash commands and the addon menu on the minimap
-- ---------------------------------------------------------------------------------------------
SLASH_KEEPNET1 = "/keepnet"
SLASH_KEEPNET2 = "/kn"
SlashCmdList["KEEPNET"] = function(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    if command == "new" then
        Core.NewSession()
        Util.Print("New session: it starts with your next cast.")
    elseif command == "panel" then
        if ns.LivePanel then ns.LivePanel.Toggle() end
    elseif command == "ui" then
        if ns.HideUI then ns.HideUI.Toggle() end
    elseif command == "demo" then
        if ns.Demo then ns.Demo.Toggle() end
    elseif command == "reset" then
        if ns.LivePanel then ns.LivePanel.ResetPosition() end
    elseif command == "help" then
        Util.Print("/kn opens the window. /kn new starts a new session. /kn panel shows or "
            .. "hides the live panel. /kn reset puts the panel back in the middle at the size it "
            .. "started with. /kn ui hides "
            .. "the game's interface or brings it back. /kn demo shows sample sessions, for trying "
            .. "the screens out, and /kn demo again brings your own back.")
    elseif ns.UI then
        ns.UI.Toggle()
    end
end

-- Named in the TOC file as AddonCompartmentFunc
function Keepnet_OnAddonCompartmentClick()
    if ns.UI then ns.UI.Toggle() end
end
