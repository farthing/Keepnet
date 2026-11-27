-- The mark over the bobber while the line is out (UI\BobberMark.lua). The game is asked to make
-- the bobber its soft interact target and to give that a nameplate; the mark hangs from the
-- plate. The game's own parts are played here by the test: the soft target's GUID, the plate
-- C_NamePlate hands out, and the events that say the target changed.
local T = {}

local KEY = "F"
local EEL = 13422
local BOBBER = "GameObject-0-4170-0-12-35591-0000AA0B2C"
local CRATE = "GameObject-0-4170-0-12-180691-0000AA0B2D"
local SHEEP = "Creature-0-4170-0-12-1933-0000AA0B2E"

function T.before()
    -- What the game knows about the soft interact target
    Stub.soft = { guid = nil, plate = nil, token = nil, listOnly = false }
    function UnitGUID(unit)
        if unit == "softinteract" then return Stub.soft.guid end
        return nil
    end
    function UnitIsUnit(a, b)
        if b == "softinteract" then return Stub.soft.token ~= nil and a == Stub.soft.token end
        return a == b
    end
    C_NamePlate = {}
    function C_NamePlate.GetNamePlateForUnit(unit)
        if unit ~= "softinteract" or Stub.soft.listOnly then return nil end
        return Stub.soft.guid and Stub.soft.plate or nil
    end
    function C_NamePlate.GetNamePlates()
        return { Stub.soft.plate }
    end
end

-- Something becomes the soft interact target, with a plate of its own
local function Target(guid, listOnly)
    local plate = CreateFrame("Frame", nil, WorldFrame)
    plate.namePlateUnitToken = "nameplate3"
    Stub.soft.guid, Stub.soft.plate, Stub.soft.token, Stub.soft.listOnly = guid, plate, "nameplate3", listOnly or false
    Stub.fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
    Stub.fire("PLAYER_SOFT_INTERACT_CHANGED", nil, guid)
    return plate
end

local function NoTarget()
    Stub.soft.guid, Stub.soft.plate, Stub.soft.token = nil, nil, nil
    Stub.fire("NAME_PLATE_UNIT_REMOVED", "nameplate3")
    Stub.fire("PLAYER_SOFT_INTERACT_CHANGED", BOBBER, nil)
end

function T.run(ns)
    Stub.bags = {}
    Stub.login()
    local settings = ns.settings
    settings.lureMode, settings.gear = "off", false
    Stub.equip(Stub.POLE)
    local Mark = ns.BobberMark
    local mark = Mark.frame
    local cvars = Stub.cvars

    eq(settings.bobberMark, true, "the mark is on by default")
    eq(settings.bobberMarkSize, 1, "at its own size")
    check(not mark:IsShown(), "nothing shows with no line out")
    eq(mark:GetParent(), WorldFrame, "it lives under the world frame, so hiding the interface leaves it")
    eq(mark:GetAlpha(), 0.9, "the whole mark a little see-through (10 %)")
    eq(cvars.SoftTargetIconGameObject, "0", "the game's settings are the player's own before a cast")

    -- The line goes out: the game is asked to give the bobber a nameplate
    eq(Stub.press(KEY), "cast", "the line goes out")
    eq(cvars.SoftTargetIconGameObject, "1", "game objects get the soft target icon")
    eq(cvars.SoftTargetNameplateInteract, "1", "and the soft interact target its nameplate")
    eq(cvars.SoftTargetInteract, "3", "the soft interact target is picked with mouse and keyboard")
    eq(cvars.SoftTargetInteractRange, "30", "out to cast range")
    eq(ns.db.interactBackup.SoftTargetIconGameObject, "0", "the player's own value is saved first")
    check(not mark:IsShown(), "the bobber isn't the target yet: no mark")

    -- The bobber lands and becomes the target
    local plate = Target(BOBBER)
    check(mark:IsShown(), "the bobber is the target: the mark shows")

    -- /kn bobber tells every step
    local before = #Stub.chat
    SlashCmdList.KEEPNET("bobber")
    local said = table.concat(Stub.chat, "\n", before + 1)
    check(said:find("setting: on", 1, true), "/kn bobber: the setting")
    check(said:find("line out: true", 1, true), "the line")
    check(said:find("35591", 1, true) and said:find("is the bobber: true", 1, true), "the target, and that it is the bobber")
    check(said:find("IconGameObject=1", 1, true), "the game's settings")
    check(said:find("mark: shown true, hangs from that plate", 1, true), "and the mark")

    local placed = mark.__placed[#mark.__placed]
    eq(placed[1], "BOTTOM", "it hangs by its foot")
    eq(placed[2], plate, "from the bobber's nameplate")
    eq(placed[3], "TOP", "above the plate")
    check(placed[5] > 0, "clear of the game's own small icon")
    local accent = ns.Widgets.COLORS.accent
    local ring = Mark.parts.ring.__vertex
    check(ring and ring[1] == accent[1] and ring[2] == accent[2] and ring[3] == accent[3], "the ring takes the accent colour")
    eq(Mark.parts.icon, nil, "the middle is the colour alone (no icon on it)")
    check(math.abs(mark.__scale - (Stub.uiScale or 1)) < 1e-9, "at its own size: the interface's scale, as the live panel")

    -- It bobs: a quarter of the way through, it is at the top of its bob
    mark:GetScript("OnUpdate")(mark, 0.35)
    local body = Mark.parts.ring.__parent
    local at = body.__placed[#body.__placed]
    check(math.abs(at[5] - 4) < 0.01, "the mark bobs up and down")

    -- The middle's colour runs with the line's time: green to 10 s, fading to yellow at 20 s,
    -- then to red at 29.9 s (the owner's times)
    settings.bobberPulse = false -- (the colour on its own first; the pulse is below)
    local function MiddleAfter(seconds)
        Stub.advance(seconds)
        mark:GetScript("OnUpdate")(mark, 0)
        return Mark.parts.disc.__vertex
    end
    local function Is(c, r, g, b)
        return math.abs(c[1] - r) < 0.01 and math.abs(c[2] - g) < 0.01 and math.abs(c[3] - b) < 0.01
    end
    check(Is(MiddleAfter(0), 0.20, 0.78, 0.25), "green as the line goes out")
    check(Is(MiddleAfter(9.9), 0.20, 0.78, 0.25), "still green just before 10 seconds")
    check(Is(MiddleAfter(5.1), 0.60, 0.80, 0.175), "half way to yellow at 15 seconds")
    check(Is(MiddleAfter(5), 1.00, 0.82, 0.10), "yellow at 20")
    check(Is(MiddleAfter(4.95), 0.95, 0.49, 0.11), "half way to red at 24.95")
    check(Is(MiddleAfter(4.95), 0.90, 0.16, 0.12), "red at 29.9")
    check(Is(MiddleAfter(5), 0.90, 0.16, 0.12), "and red after that")
    eq(Mark.parts.disc.__vertex[4], 0.85, "nearly solid, over the water")

    -- The pulse (on by default): from 20 s the mark swells and its middle brightens, gently at
    -- first and fully by 29.9 s, 1.5 times a second
    settings.bobberPulse = true
    local function Near(a, b) return math.abs(a - b) < 0.001 end
    check(Near(Mark.Pulse(15), 1), "no pulse before 20 seconds")
    check(Near(Mark.Pulse(20), 1), "it starts from its own size")
    local early = Mark.Pulse(20 + 1 / 3)
    check(early > 1.05 and early < 1.1, "the first swell is gentle")
    check(Near(Mark.Pulse(20 + 15 / 1.5 + 1 / 3), 1.18), "at the end it swells by 18 %")
    check(Near(Mark.Pulse(20 + 16 / 1.5), 1), "and back to its size a third of a second later: 1.5 a second")
    local most = 1
    for i = 0, 300 do most = math.max(most, (Mark.Pulse(20 + i * 0.05))) end
    check(most <= 1.1801, "never more than 18 % bigger")
    local _, bright = Mark.Pulse(20 + 15 / 1.5 + 1 / 3)
    check(Near(bright, 1), "and its middle fully solid at the top of a swell")
    -- On the mark itself: the body swells (from its foot, so the arrow stays at the bobber)
    mark:GetScript("OnUpdate")(mark, 0)
    local grow = Mark.parts.ring.__parent.__scale
    check(grow and Near(grow, (Mark.Pulse(Stub.now - ns.Fishing.Line()))), "the mark takes the pulse's size")
    settings.bobberPulse = false
    mark:GetScript("OnUpdate")(mark, 0)
    eq(Mark.parts.ring.__parent.__scale, 1, "switched off: no pulse")
    eq(Mark.parts.disc.__vertex[4], 0.85, "and the middle as it was")
    settings.bobberPulse = true

    -- The game picks something else: a crate, a sheep, nothing, a hidden value
    Target(CRATE)
    check(not mark:IsShown(), "a crate as the target: no mark")
    Target(BOBBER)
    check(mark:IsShown(), "back on the bobber")
    Target(SHEEP)
    check(not mark:IsShown(), "a creature as the target: no mark")
    Target(BOBBER)
    NoTarget()
    check(not mark:IsShown(), "no target at all: no mark")
    Target(Stub.SECRET)
    check(not mark:IsShown(), "the game hides the target's GUID: no mark, and no error")

    -- The plate is only found in the list of plates (by its unit)
    Target(BOBBER, true)
    check(mark:IsShown(), "the plate found by its unit in the list of plates")
    eq(mark.__placed[#mark.__placed][2], Stub.soft.plate, "and the mark hangs from it")

    -- The ticker looks again while the line is out, without any event
    Stub.soft.guid = CRATE
    Stub.advance(0.3)
    check(not mark:IsShown(), "the target changed without an event: found on the next look")
    Stub.soft.guid = BOBBER
    Stub.advance(0.3)
    check(mark:IsShown(), "and the bobber again")

    -- The line comes in: the mark goes and the game's settings come back
    Stub.reel({ { id = EEL, count = 1 } })
    check(not mark:IsShown(), "the line is in: no mark")
    eq(cvars.SoftTargetIconGameObject, "0", "the player's icon setting is back")
    eq(cvars.SoftTargetNameplateInteract, "0", "and the nameplate setting")
    eq(cvars.SoftTargetInteract, "0", "and the interact setting")
    eq(ns.db.interactBackup, nil, "nothing left to put back")

    -- Its size
    settings.bobberMarkSize = 1.5
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast with a bigger mark")
    Target(BOBBER)
    check(math.abs(mark.__scale - 1.5 * (Stub.uiScale or 1)) < 1e-9, "the mark is half as big again")
    Stub.reel(nil)
    Stub.advance(1.1)
    settings.bobberMarkSize = 1

    -- Combat: everything goes at once and comes back after
    eq(Stub.press(KEY), "cast", "a cast before a fight")
    Target(BOBBER)
    check(mark:IsShown(), "marked")
    Stub.enterCombat()
    check(not mark:IsShown(), "combat: no mark")
    eq(cvars.SoftTargetIconGameObject, "0", "and the settings are back before the lock")
    Stub.leaveCombat()
    Stub.reel(nil)
    Stub.advance(1.1)
    eq(ns.db.interactBackup, nil, "nothing left over after the fight")

    -- Switched off: the key still reels in, but nothing asks for nameplates
    settings.bobberMark = false
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast with the mark switched off")
    Target(BOBBER)
    check(not mark:IsShown(), "no mark")
    eq(cvars.SoftTargetIconGameObject, "0", "the icon setting is left alone")
    eq(cvars.SoftTargetInteract, "3", "the key's own interact setting is still raised")
    -- Turned on with the line out: the mark comes at once
    settings.bobberMark = true
    ns.Fire("SETTINGS")
    check(mark:IsShown(), "turned on with the line out: marked at once")
    settings.bobberMark = false
    ns.Fire("SETTINGS")
    check(not mark:IsShown(), "and turned off again: gone")
    eq(cvars.SoftTargetIconGameObject, "0", "with the icon setting put back while the key keeps its own")
    eq(cvars.SoftTargetInteract, "3", "the key's interact setting is still raised")
    Stub.reel(nil)
    Stub.advance(1.1)
    eq(cvars.SoftTargetInteract, "0", "line in: all back")
    settings.bobberMark = true
    ns.Fire("SETTINGS")

    -- With no fishing key the mark still works (it asks for the interact target itself)
    settings.key = nil
    ns.Fire("SETTINGS")
    Stub.castFishing()
    Target(BOBBER)
    check(mark:IsShown(), "no fishing key: still marked")
    eq(cvars.SoftTargetInteract, "3", "the mark raised the interact setting itself")
    Stub.reel(nil)
    Stub.advance(1.1)
    eq(ns.db.interactBackup, nil, "and put it back")
    settings.key = KEY
    ns.Fire("SETTINGS")

    -- A reload with the line out: settings back at logout, raised again when the line is seen
    eq(Stub.press(KEY), "cast", "a cast before a reload")
    Target(BOBBER)
    ns = Stub.reload()
    eq(cvars.SoftTargetIconGameObject, "1", "after the reload the line is still out: raised again")
    Target(BOBBER)
    check(ns.BobberMark.Shown(), "and the bobber marked again")
    Stub.reel(nil)
    Stub.advance(1.1)
    eq(cvars.SoftTargetIconGameObject, "0", "line in: back")

    -- Keepnet hides the whole interface: the game takes the nameplates with it, so Keepnet
    -- brings the in-world part back on its own and the mark keeps its plate
    local s = ns.settings
    s.hideMode, s.hideAuto = "all", true
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast that hides the interface")
    eq(ns.HideUI.IsActive(), true, "the interface is hidden")
    eq(Stub.inWorldUI, true, "but the nameplates are back on their own, for the bobber's")
    Target(BOBBER)
    check(ns.BobberMark.Shown(), "the bobber is marked with the interface hidden")
    ns.HideUI.Show()
    Stub.reel(nil)
    Stub.advance(1.1)
    -- With the mark off the nameplates go with the interface, as before
    s.bobberMark = false
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast that hides the interface, mark off")
    eq(Stub.inWorldUI, false, "mark off: the nameplates are hidden with the interface, as before")
    ns.HideUI.Show()
    eq(Stub.inWorldUI, true, "and back with it")
    Stub.reel(nil)
    Stub.advance(1.1)
    s.bobberMark, s.hideMode = true, "off"
    ns.Fire("SETTINGS")

    -- Its colours: the circle in the accent, the arrow green (the owner's default)
    local Mark2 = ns.BobberMark
    local function Is(c, r, g, b)
        return c and math.abs(c[1] - r) < 0.01 and math.abs(c[2] - g) < 0.01 and math.abs(c[3] - b) < 0.01
    end
    local accent2 = ns.Widgets.COLORS.accent
    check(Is(Mark2.parts.ring.__vertex, accent2[1], accent2[2], accent2[3]), "the circle in the accent colour")
    check(Is(Mark2.parts.arrow.__vertex, 0.00, 0.63, 0.24), "the arrow green (a darker green than the middle's first)")

    -- The player's own colours, each on its own
    s.bobberRingColor = { 1, 0, 1 }
    ns.Fire("SETTINGS")
    check(Is(Mark2.parts.ring.__vertex, 1, 0, 1), "a circle colour of the player's own")
    check(Is(Mark2.parts.arrow.__vertex, 0.00, 0.63, 0.24), "the arrow left as it was")
    s.bobberArrowColor = { 0, 1, 1 }
    ns.Fire("SETTINGS")
    check(Is(Mark2.parts.arrow.__vertex, 0, 1, 1), "an arrow colour of the player's own")
    s.bobberRingColor, s.bobberArrowColor = nil, nil
    ns.Fire("SETTINGS")
    check(Is(Mark2.parts.arrow.__vertex, 0.00, 0.63, 0.24), "back to the defaults")

    -- Colour blind colours: the circle, the arrow and the middle's three all change
    local normal = { Mark2.Colour(0) }
    for _, choice in ipairs(Mark2.PaletteChoices()) do
        if choice.value ~= "normal" and choice.value ~= "game" then
            s.bobberPalette = choice.value
            ns.Fire("SETTINGS")
            local start = { Mark2.Colour(0) }
            local mid = { Mark2.Colour(20) }
            local finish = { Mark2.Colour(29.9) }
            check(not Is(start, normal[1], normal[2], normal[3]), choice.text .. ": its own first colour")
            check(not Is(start, mid[1], mid[2], mid[3]) and not Is(mid, finish[1], finish[2], finish[3]),
                choice.text .. ": three different colours")
            local colours = Mark2.Colours()
            check(Is(Mark2.parts.arrow.__vertex, colours.arrow[1], colours.arrow[2], colours.arrow[3]),
                choice.text .. ": the arrow in its colour")
        end
    end
    -- The player's own pick still wins over a colour blind set
    s.bobberPalette, s.bobberArrowColor = "deuteranopia", { 0, 1, 1 }
    ns.Fire("SETTINGS")
    check(Is(Mark2.parts.arrow.__vertex, 0, 1, 1), "a picked arrow colour stays with colour blind colours")
    s.bobberArrowColor = nil
    -- As the game's own colour blind mode
    s.bobberPalette = "game"
    Stub.cvars.colorblindSimulator = "2"
    ns.Fire("SETTINGS")
    eq(Mark2.Palette().key, "deuteranopia", "the game's deuteranopia filter: the deuteranopia colours")
    Stub.cvars.colorblindSimulator = "0"
    eq(Mark2.Palette().key, "normal", "the game's filter off: the usual colours")
    Stub.cvars.colorblindSimulator = nil
    eq(Mark2.Palette().key, "normal", "a game with no such setting: the usual colours")
    s.bobberPalette = "normal"
    ns.Fire("SETTINGS")

    -- The Settings tab offers it all (the live panel's options went to Appearance)
    ns.UI.Show("settings")
    ns.UI.Refresh()
    local controls = ns.SettingsBobber
    check(controls ~= nil, "the Settings tab has the bobber mark")
    eq(controls.check:GetChecked(), true, "switched on")
    eq(controls.size.value:GetText(), "100%", "at its own size")
    eq(controls.pulse:GetChecked(), true, "the pulse is on")
    check(Is(controls.arrow.color.__color, 0.00, 0.63, 0.24), "the arrow's swatch shows green")
    check(Is(controls.stops[3].__color, 0.90, 0.16, 0.12), "the third colour shown is red")
    eq(#Mark2.PaletteChoices(), 6, "off, four colour blind sets, and as the game's")
    -- A right click on a swatch puts the colour back to the default
    s.bobberArrowColor = { 0, 1, 1 }
    controls.arrow:GetScript("OnClick")(controls.arrow, "RightButton")
    eq(s.bobberArrowColor, nil, "a right click: the arrow back to its default")
    ns.UI.Show("appearance")
    ns.UI.Refresh()

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
