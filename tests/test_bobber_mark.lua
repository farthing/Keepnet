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
    eq(Mark.parts.disc.__vertex[1], 0, "its middle is dark, to stand out on bright water")
    check(math.abs(mark.__scale - (Stub.uiScale or 1)) < 1e-9, "at its own size: the interface's scale, as the live panel")

    -- It bobs: a quarter of the way through, it is at the top of its bob
    mark:GetScript("OnUpdate")(mark, 0.35)
    local body = Mark.parts.ring.__parent
    local at = body.__placed[#body.__placed]
    check(math.abs(at[5] - 4) < 0.01, "the mark bobs up and down")

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

    -- The Appearance tab offers it
    ns.UI.Show("appearance")
    ns.UI.Refresh()
    local controls = ns.AppearanceBobber
    check(controls ~= nil, "the Appearance tab has the bobber mark")
    eq(controls.check:GetChecked(), true, "switched on")
    eq(controls.size.value:GetText(), "100%", "at its own size")

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
