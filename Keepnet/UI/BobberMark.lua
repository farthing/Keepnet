-- Keepnet: a mark over your fishing bobber while the line is out, so it is easy to find on the
-- water: a ring in the look's accent colour round a middle that fades from green through yellow
-- to red as the line's time runs out, and an arrow pointing down at the bobber, bobbing gently.
--
-- How it finds the bobber: there is no way for an addon to learn where an object is on the
-- screen. So while the line is out the game is asked (SoftTarget.lua) to make the bobber its
-- soft interact target and to give that target a nameplate; Keepnet then pins a frame of its
-- own to that nameplate, and the game moves it with the bobber every frame. Blizzard's own
-- nameplate parts are never touched (that would taint them). The target is the bobber when its
-- GUID is a game object with the Fishing Bobber's ID; on this client the GUID can be hidden
-- (a "secret" value), which is checked before it is read.
--
-- The idea of a mark over the bobber on this client is Mastercraft's (Shadowblade). Anchoring
-- an addon's own frame to the soft-interact game object's nameplate is the method CorpseBeacon
-- (kriffin, MIT), Rubber Ducky and OneCast use; the game resetting the icon setting at entering
-- the world was noted by Lueur. Written from scratch; see CREDITS.md.
local _, ns = ...
local Util, Fishing, W = ns.Util, ns.Fishing, ns.Widgets

local BobberMark = {}
ns.BobberMark = BobberMark

local BOBBER = 35591          -- the Fishing Bobber's game object ID
local MEDIA = "Interface\\AddOns\\Keepnet\\Media\\"
local SIZE = 44               -- the ring, before the player's size setting
local RISE = 20               -- above the nameplate's top, clear of the game's own small icon
local BOB, BOB_SECONDS = 4, 1.4
local CHECK_SECONDS = 0.25    -- how often to look again while the line is out

-- { name, the least it must be, what to set } (see SoftTarget.lua)
-- SoftTargetInteract 3: the interact target is picked for mouse and keyboard as well as gamepad.
-- Arc 2 and range 30: the bobber counts wherever it lands within cast range.
-- SoftTargetIconGameObject 1: game objects can be soft targets with an icon (and a nameplate).
-- SoftTargetNameplateInteract 1: the soft interact target always gets its nameplate.
local CVARS = {
    { "SoftTargetInteract", 2, "3" },
    { "SoftTargetInteractArc", 2, "2" },
    { "SoftTargetInteractRange", 30, "30" },
    { "SoftTargetIconGameObject", 1, "1" },
    { "SoftTargetNameplateInteract", 1, "1" },
}

-- ---------------------------------------------------------------------------------------------
-- The mark
-- ---------------------------------------------------------------------------------------------
-- Under the world frame, so it stays when Keepnet (or the player) hides the game's interface
local mark = CreateFrame("Frame", nil, WorldFrame)
mark:SetSize(SIZE, SIZE + 18)
mark:SetFrameStrata("HIGH")
mark:EnableMouse(false)
mark:Hide()
BobberMark.frame = mark -- (for the tests)

-- What bobs: everything but the anchor
local body = CreateFrame("Frame", nil, mark)
body:SetSize(SIZE, SIZE + 18)
body:SetPoint("BOTTOM", mark, "BOTTOM", 0, 0)

-- The middle: a disc whose colour runs from green to yellow to red as the line's time runs out
-- (the owner's colours and times). (1.1.9 had Keepnet's net and fish on it; the owner
-- preferred the colour alone.)
local disc = body:CreateTexture(nil, "BACKGROUND")
disc:SetTexture(MEDIA .. "BobberDisc")
disc:SetSize(SIZE, SIZE)
disc:SetPoint("TOP", body, "TOP", 0, 0)

local ring = body:CreateTexture(nil, "ARTWORK")
ring:SetTexture(MEDIA .. "BobberRing")
ring:SetSize(SIZE, SIZE)
ring:SetPoint("TOP", body, "TOP", 0, 0)

local arrow = body:CreateTexture(nil, "ARTWORK")
arrow:SetTexture(MEDIA .. "BobberArrow")
arrow:SetSize(SIZE * 0.5, SIZE * 0.5)
arrow:SetPoint("BOTTOM", body, "BOTTOM", 0, 0)
BobberMark.parts = { disc = disc, ring = ring, arrow = arrow } -- (for the tests)

-- The mark's colours. Each set has the circle, the arrow, and the middle's three: the line
-- going out, half way, nearly done. "normal" is the owner's (2026-11-27: "green for the first
-- 10 seconds, yellow for when it gets to 20, red when it hits 29.9", the arrow green); the
-- colour blind sets follow docs/research/colour-blind.md. ring = nil means the look's accent.
-- The arrow is a darker green than the middle's first colour, or the two would be one at the
-- start. In the colour blind sets the circle and the arrow are white: a near black arrow is
-- lost on deep water (contrast about 2:1), and the two differ by shape anyway.
local WHITE = { 1.00, 1.00, 1.00 }
local PALETTES = {
    { key = "normal", name = "Off (green, yellow, red)", ring = nil,
      arrow = { 0.00, 0.63, 0.24 },
      stops = { { 0.20, 0.78, 0.25 }, { 1.00, 0.82, 0.10 }, { 0.90, 0.16, 0.12 } } },
    -- Okabe-Ito sky blue, yellow and vermillion: along the blue-yellow axis red-weak eyes keep
    { key = "protanopia", name = "Protanopia (red weak)", ring = WHITE, arrow = WHITE,
      stops = { { 0.34, 0.71, 0.91 }, { 0.94, 0.89, 0.26 }, { 0.84, 0.37, 0.00 } } },
    -- The same, with a darker vermillion: yellow against vermillion is the weakest pair for
    -- green-weak eyes
    { key = "deuteranopia", name = "Deuteranopia (green weak)", ring = WHITE, arrow = WHITE,
      stops = { { 0.34, 0.71, 0.91 }, { 0.94, 0.89, 0.26 }, { 0.67, 0.24, 0.00 } } },
    -- Cyan, pink and red: along the red-cyan axis blue-weak eyes keep, never blue against yellow
    { key = "tritanopia", name = "Tritanopia (blue weak)", ring = WHITE, arrow = WHITE,
      stops = { { 0.31, 0.82, 0.82 }, { 1.00, 0.63, 0.78 }, { 0.86, 0.08, 0.08 } } },
    -- Brightness alone: light, mid and dark grey
    { key = "mono", name = "Monochrome (by brightness)", ring = WHITE, arrow = WHITE,
      stops = { { 0.78, 0.78, 0.78 }, { 0.50, 0.50, 0.50 }, { 0.22, 0.22, 0.22 } } },
}
-- (A last choice, "game", follows the game's own colour blind setting; see Palette below)
local STOP_SECONDS = { 10, 20, 29.9 }
local DISC_ALPHA = 0.85

function BobberMark.PaletteChoices()
    local choices = {}
    for _, p in ipairs(PALETTES) do choices[#choices + 1] = { value = p.key, text = p.name } end
    choices[#choices + 1] = { value = "game", text = "As the game's colour blind mode" }
    return choices
end

local function ByKey(key)
    for _, p in ipairs(PALETTES) do
        if p.key == key then return p end
    end
    return PALETTES[1]
end

-- The game's own colour blind mode (Options, Accessibility), when it has one: which filter
-- (0 none, 1 protanopia, 2 deuteranopia, 3 tritanopia)
local GAME_FILTERS = { [1] = "protanopia", [2] = "deuteranopia", [3] = "tritanopia" }
local function GamePalette()
    local filter = tonumber(Util.GetCVar("colorblindSimulator") or "")
    return GAME_FILTERS[filter or 0] or "normal"
end

-- The set in use
function BobberMark.Palette()
    local key = (ns.settings and ns.settings.bobberPalette) or "normal"
    if key == "game" then key = GamePalette() end
    return ByKey(key)
end

-- The colours in use: { ring, arrow, stops = { three } }, the player's own picks first
function BobberMark.Colours()
    local p, settings = BobberMark.Palette(), ns.settings or {}
    local accent = W.COLORS.accent
    return {
        ring = settings.bobberRingColor or p.ring or { accent[1], accent[2], accent[3] },
        arrow = settings.bobberArrowColor or p.arrow,
        stops = p.stops,
    }
end

-- The middle's colour after `seconds` of line: the first colour up to 10 s, fading to the
-- second at 20 s and to the third at 29.9 s
function BobberMark.Colour(seconds)
    seconds = seconds or 0
    local stops = BobberMark.Palette().stops
    if seconds <= STOP_SECONDS[1] then return stops[1][1], stops[1][2], stops[1][3] end
    for i = 2, #STOP_SECONDS do
        if seconds < STOP_SECONDS[i] then
            local f = (seconds - STOP_SECONDS[i - 1]) / (STOP_SECONDS[i] - STOP_SECONDS[i - 1])
            local a, b = stops[i - 1], stops[i]
            return a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f
        end
    end
    local last = stops[#stops]
    return last[1], last[2], last[3]
end

-- How long the line now out has been in the water
local function LineSeconds()
    local from = Fishing.Line()
    if not from then return 0 end
    return math.max(0, GetTime() - from)
end

-- The pulse: from 20 s (when the second colour is reached) the mark swells and its middle
-- brightens, gently at first and fully by 29.9 s, so the end of the line shows by more than
-- colour (the Game Accessibility Guidelines' advice; the owner, 2026-11-27: "do the pulse").
-- 1.5 swells a second, well under the three flashes a second that WCAG 2.3.1 warns about.
local PULSE_FROM, PULSE_HZ, PULSE_GROW = 20, 1.5, 0.18

-- How much bigger the mark is, and how much brighter its middle, after `seconds` of line
-- (1 and 0 when it isn't pulsing)
function BobberMark.Pulse(seconds)
    seconds = seconds or 0
    if not (ns.settings and ns.settings.bobberPulse) or seconds < PULSE_FROM then return 1, 0 end
    local ramp = math.min(1, (seconds - PULSE_FROM) / (STOP_SECONDS[3] - PULSE_FROM))
    local wave = 0.5 - 0.5 * math.cos((seconds - PULSE_FROM) * PULSE_HZ * 2 * math.pi) -- 0 to 1
    local strength = (0.4 + 0.6 * ramp) * wave
    return 1 + PULSE_GROW * strength, strength
end

local function Colour()
    local seconds = LineSeconds()
    local r, g, b = BobberMark.Colour(seconds)
    local grow, bright = BobberMark.Pulse(seconds)
    disc:SetVertexColor(r, g, b, DISC_ALPHA + (1 - DISC_ALPHA) * bright)
    -- (it swells from its foot: the arrow's tip stays at the bobber)
    body:SetScale(grow)
end

local function Tint()
    local colours = BobberMark.Colours()
    ring:SetVertexColor(colours.ring[1], colours.ring[2], colours.ring[3], 1)
    arrow:SetVertexColor(colours.arrow[1], colours.arrow[2], colours.arrow[3], 1)
end

local function ApplyScale()
    -- Under the world frame the mark doesn't take the interface's own scale (as the live panel)
    local world = WorldFrame:GetEffectiveScale() or 1
    local outer = (UIParent:GetEffectiveScale() or 1) / (world ~= 0 and world or 1)
    mark:SetScale(outer * ((ns.settings and ns.settings.bobberMarkSize) or 1))
end

local phase = 0
mark:SetScript("OnUpdate", function(_, elapsed)
    phase = (phase + (elapsed or 0)) % BOB_SECONDS
    body:ClearAllPoints()
    body:SetPoint("BOTTOM", mark, "BOTTOM", 0, BOB * math.sin(phase / BOB_SECONDS * 2 * math.pi))
    Colour()
end)

-- ---------------------------------------------------------------------------------------------
-- Finding the bobber
-- ---------------------------------------------------------------------------------------------
-- Is the game's soft interact target the bobber? (A game object GUID reads
-- "GameObject-0-server-instance-zone-ID-spawn"; the spawn part is scrambled on this client.)
function BobberMark.IsBobberTarget()
    if not UnitGUID then return false end
    local ok, guid = pcall(UnitGUID, "softinteract")
    if not ok or guid == nil or Util.Hidden(guid) or type(guid) ~= "string" then return false end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    return kind == "GameObject" and tonumber(id) == BOBBER
end

-- The nameplate the game gives the soft interact target, if it has one
function BobberMark.Plate()
    if not C_NamePlate then return nil end
    if C_NamePlate.GetNamePlateForUnit then
        local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, "softinteract")
        if ok and plate and not Util.Hidden(plate) then return plate end
    end
    -- Otherwise the plate whose unit is the soft interact target
    if C_NamePlate.GetNamePlates and UnitIsUnit then
        local ok, plates = pcall(C_NamePlate.GetNamePlates)
        if ok and type(plates) == "table" then
            for _, plate in ipairs(plates) do
                local token = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
                if type(token) == "string" and not Util.Hidden(token) then
                    local same
                    ok, same = pcall(UnitIsUnit, token, "softinteract")
                    if ok and not Util.Hidden(same) and same then return plate end
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------------------------
-- Showing it
-- ---------------------------------------------------------------------------------------------
local pinned -- the nameplate the mark hangs from
local ticker

local function Wanted()
    local settings = ns.settings
    return settings and settings.bobberMark and ns.fishing and not ns.inCombat and Fishing.LineOut() or false
end

local function HideMark()
    mark:Hide()
    pinned = nil
end

-- Looks for the bobber's nameplate and hangs the mark from it
local function Refresh()
    if not Wanted() then return HideMark() end
    local plate = BobberMark.IsBobberTarget() and BobberMark.Plate()
    if not plate then return HideMark() end
    if plate ~= pinned then
        mark:ClearAllPoints()
        -- The game may refuse an anchor to a plate it keeps to itself
        if not pcall(mark.SetPoint, mark, "BOTTOM", plate, "TOP", 0, RISE) then return HideMark() end
        pinned = plate
    end
    if not mark:IsShown() then
        ApplyScale()
        Colour()
        mark:Show()
    end
end
BobberMark.Refresh = Refresh

function BobberMark.Update()
    if not ns.db then return end
    if Wanted() then
        if not InCombatLockdown() then ns.SoftTarget.Want("mark", CVARS) end
        if not ticker then ticker = C_Timer.NewTicker(CHECK_SECONDS, Refresh) end
        ApplyScale()
        Refresh()
    else
        if ticker then ticker:Cancel() end
        ticker = nil
        HideMark()
        -- (combat start still allows it for an instant: COMBAT is fired then)
        if not InCombatLockdown() then ns.SoftTarget.Release("mark") end
    end
end

-- Shown or not, as it is now (for the tests)
function BobberMark.Shown()
    return mark:IsShown() and true or false
end

-- /kn bobber: every step from the setting to the mark on screen, for when it doesn't show
local function Say(value)
    if value == nil then return "none" end
    if Util.Hidden(value) then return "hidden by the game" end
    return tostring(value)
end

function BobberMark.Report()
    local settings = ns.settings or {}
    local lines = {}
    local function Add(text) lines[#lines + 1] = text end
    Add(("setting: %s, size %d%%"):format(settings.bobberMark and "on" or "off",
        math.floor((settings.bobberMarkSize or 1) * 100 + 0.5)))
    Add(("pole on: %s, in combat: %s, line out: %s, so wanted: %s, looking every %.2f s: %s"):format(
        tostring(ns.fishing), tostring(ns.inCombat), tostring(Fishing.LineOut()), tostring(Wanted()),
        CHECK_SECONDS, tostring(ticker ~= nil)))
    local values = {}
    for _, entry in ipairs(CVARS) do values[#values + 1] = entry[1]:gsub("SoftTarget", "") .. "=" .. Say(Util.GetCVar(entry[1])) end
    Add("game settings: " .. table.concat(values, " "))
    local guid
    if UnitGUID then
        local ok, value = pcall(UnitGUID, "softinteract")
        guid = ok and value or ("error: " .. tostring(value))
    end
    Add(("soft interact target: %s, is the bobber: %s"):format(Say(guid), tostring(BobberMark.IsBobberTarget())))
    local direct
    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, "softinteract")
        direct = ok and plate or nil
        Add(("its nameplate (asked for directly): %s"):format(ok and Say(plate) or ("error: " .. tostring(plate))))
    else
        Add("its nameplate: this client has no C_NamePlate.GetNamePlateForUnit")
    end
    local count = 0
    if C_NamePlate and C_NamePlate.GetNamePlates then
        local ok, plates = pcall(C_NamePlate.GetNamePlates)
        if ok and type(plates) == "table" then count = #plates end
    end
    local found = BobberMark.Plate()
    Add(("nameplates in sight: %d, the one found: %s%s"):format(count, Say(found),
        found and found ~= direct and " (from the list)" or ""))
    if found and found.GetCenter then
        local ok, x, y = pcall(found.GetCenter, found)
        Add(("  where it is: %s"):format(ok and (Say(x) .. ", " .. Say(y)) or ("error: " .. tostring(x))))
        local okShown, shown = pcall(found.IsVisible, found)
        Add(("  visible: %s"):format(okShown and Say(shown) or "unknown"))
    end
    Add(("mark: shown %s, hangs from %s, scale %.2f"):format(tostring(mark:IsShown()),
        pinned and "that plate" or "nothing", mark:GetScale() or 0))
    if mark:IsShown() then
        local ok, x, y = pcall(mark.GetCenter, mark)
        Add(("  where it is: %s"):format(ok and (Say(x) .. ", " .. Say(y)) or ("error: " .. tostring(x))))
    end
    if Util.IsAddOnLoaded("EllesmereUINameplates") then
        Add("EllesmereUI Nameplates is loaded: it replaces the game's nameplates")
    end
    Util.Print("Bobber mark:")
    for _, line in ipairs(lines) do DEFAULT_CHAT_FRAME:AddMessage("  " .. line) end
end

-- The game's own news about the soft target and nameplates
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_SOFT_INTERACT_CHANGED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do
    pcall(events.RegisterEvent, events, event) -- (an event this client doesn't know is skipped)
end
events:SetScript("OnEvent", function() Refresh() end)

Tint()
ns.On("THEME", Tint)
ns.On("SETTINGS", Tint) -- (the circle, arrow and colour blind choices)
ns.On("LINE", BobberMark.Update)
ns.On("MODE", BobberMark.Update)
ns.On("COMBAT", BobberMark.Update)
ns.On("SETTINGS", BobberMark.Update)
-- A logout in combat can't touch the settings; the saved copy puts them back at next login
ns.On("LOGOUT", function()
    HideMark()
    if not InCombatLockdown() then ns.SoftTarget.Release("mark") end
end)
