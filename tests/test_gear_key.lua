-- The gear key: a key of its own, apart from the fishing key, that puts the fishing pole on
-- (which brings the fishing clothing with it) and, pressed again, puts back what the character
-- held before (which takes the clothing off again).
local T = {}

local FISH_KEY = "F"
local GEAR_KEY = "CTRL-G"
local STRONG_POLE = 6365
local DAGGER, SHIELD = 2092, 2362
local PLAIN_HELM, LUCKY_HAT = 10000, 19972
local HEAD = 1

local function Said(text)
    for _, line in ipairs(Stub.chat) do
        if tostring(line):find(text, 1, true) then return true end
    end
    return false
end

function T.before()
    Stub.items[DAGGER] = { "Worn Dagger", 1, 7, 2, 15, 0 }
    Stub.items[SHIELD] = { "Worn Wooden Shield", 1, 1, 4, 6, 0 }
end

function T.run(ns)
    local Gear = ns.Gear
    Stub.bags = { [Stub.POLE] = 1, [STRONG_POLE] = 1, [LUCKY_HAT] = 1 }
    Stub.mainHand = DAGGER
    Stub.equipped = { [17] = SHIELD, [HEAD] = PLAIN_HELM }
    Stub.login()
    local settings = ns.settings
    settings.lureMode = "off"
    eq(ns.fishing, false, "no pole on to begin with")
    eq(settings.gearKey, nil, "and no gear key set")
    eq(Gear.Key(), nil, "so none is bound")

    -- Setting the key binds it at once, pole or no pole
    settings.gearKey = GEAR_KEY
    ns.Fire("SETTINGS")
    eq(Gear.Key(), GEAR_KEY, "the key that is set is bound")
    eq(Stub.binding(GEAR_KEY).button, "KeepnetGearButton", "to a button of its own")
    eq(Stub.binding(FISH_KEY), nil, "the fishing key is still only for when a pole is on")

    -- First press: the pole goes on, and the clothing follows
    Stub.press(GEAR_KEY)
    Stub.advance(1.5)
    eq(Stub.mainHand, STRONG_POLE, "the pole that raises Fishing most goes into the main hand")
    eq(ns.fishing, true, "which turns fishing mode on")
    eq(Stub.equipped[17], nil, "a pole takes both hands")
    eq(Stub.bags[DAGGER], 1, "the weapon is in the bags")
    eq(Stub.bags[SHIELD], 1, "and so is what the other hand held")
    eq(Stub.equipped[HEAD], LUCKY_HAT, "the fishing hat is put on with it")
    check(ns.char.hands and tostring(ns.char.hands.main):find("item:" .. DAGGER, 1, true), "what the main hand held is written down")
    check(tostring(ns.char.hands.off):find("item:" .. SHIELD, 1, true), "and the other hand")
    check(Said("Fishing pole on: Strong Fishing Pole"), "the player is told")
    check(Stub.binding(FISH_KEY) ~= nil, "the fishing key works now")
    eq(Stub.binding(GEAR_KEY).button, "KeepnetGearButton", "and the gear key is still its own")

    -- The press's own release is not a second press
    eq(Stub.mainHand, STRONG_POLE, "one press, one change")

    -- Second press: everything back
    Stub.press(GEAR_KEY)
    Stub.advance(2)
    eq(Stub.mainHand, DAGGER, "pressed again: the weapon is back in the main hand")
    eq(Stub.equipped[17], SHIELD, "and the other hand's a moment later")
    eq(ns.fishing, false, "fishing mode is off")
    eq(Stub.equipped[HEAD], PLAIN_HELM, "and the player's own hat is back on")
    eq(Stub.bags[STRONG_POLE], 1, "the pole is in the bags again")
    eq(ns.char.hands, nil, "nothing is left written down")
    check(Said("Back in your hands: Worn Dagger, Worn Wooden Shield"), "the player is told")
    eq(Stub.binding(FISH_KEY), nil, "the fishing key is let go")

    -- The pole last fished with is the one reached for, whatever its bonus
    eq(ns.char.pole, STRONG_POLE, "the pole fished with is remembered")
    ns.char.pole = Stub.POLE
    Stub.press(GEAR_KEY)
    Stub.advance(1.5)
    eq(Stub.mainHand, Stub.POLE, "the pole last fished with is preferred")
    Stub.press(GEAR_KEY)
    Stub.advance(2)
    eq(Stub.mainHand, DAGGER, "and off again")

    -- In combat nothing changes
    Stub.enterCombat()
    Stub.chat = {}
    Stub.press(GEAR_KEY)
    Stub.advance(1)
    eq(Stub.mainHand, DAGGER, "in combat the key changes nothing")
    check(Said("press the gear key again afterwards"), "and says to press again afterwards")
    Stub.leaveCombat()
    Stub.advance(1)

    -- A pole put on by hand: nothing is written down to go back to
    Stub.bags[Stub.POLE] = Stub.bags[Stub.POLE] - 1
    Stub.bags[DAGGER] = (Stub.bags[DAGGER] or 0) + 1
    Stub.equip(Stub.POLE)
    eq(ns.fishing, true, "a pole put on by hand")
    Stub.chat = {}
    Stub.press(GEAR_KEY)
    Stub.advance(1)
    eq(Stub.mainHand, Stub.POLE, "the key leaves it on")
    check(Said("doesn't know what you held before"), "and says why")
    -- The player takes it off by hand
    Stub.bags[DAGGER] = Stub.bags[DAGGER] - 1
    Stub.bags[Stub.POLE] = (Stub.bags[Stub.POLE] or 0) + 1
    Stub.equip(DAGGER)
    eq(ns.fishing, false, "taken off by hand")

    -- A weapon changed by hand while the pole was on: the note is dropped with the pole
    Stub.press(GEAR_KEY)
    Stub.advance(1.5)
    check(ns.char.hands ~= nil, "the key put the pole on again")
    local pole = Stub.mainHand
    Stub.bags[pole] = (Stub.bags[pole] or 0) + 1
    Stub.bags[DAGGER] = Stub.bags[DAGGER] - 1
    Stub.equip(DAGGER)
    eq(ns.char.hands, nil, "a weapon put on by hand: what was written down is dropped")
    Stub.equipped[17] = SHIELD
    Stub.bags[SHIELD] = 0

    -- No pole in the bags
    local poles = { [Stub.POLE] = Stub.bags[Stub.POLE], [STRONG_POLE] = Stub.bags[STRONG_POLE] }
    Stub.bags[Stub.POLE], Stub.bags[STRONG_POLE] = nil, nil
    Stub.chat = {}
    Stub.advance(1)
    Stub.press(GEAR_KEY)
    Stub.advance(1)
    eq(Stub.mainHand, DAGGER, "with no pole in the bags nothing changes")
    check(Said("no fishing pole in your bags"), "and the player is told")
    Stub.bags[Stub.POLE], Stub.bags[STRONG_POLE] = poles[Stub.POLE], poles[STRONG_POLE]

    -- The two keys can't be one: the fishing key is the fishing key
    settings.gearKey = settings.key
    ns.Fire("SETTINGS")
    eq(Gear.Key(), nil, "the fishing key set as the gear key: the gear key is not bound")
    settings.gearKey = "BUTTON4"
    ns.Fire("SETTINGS")
    eq(Gear.Key(), "BUTTON4", "another key: bound, and the old one let go")
    eq(Stub.binding(GEAR_KEY), nil, "the old key is free again")
    -- No key
    settings.gearKey = nil
    ns.Fire("SETTINGS")
    eq(Gear.Key(), nil, "no key set: none bound")
    eq(Stub.binding("BUTTON4"), nil, "and the last one is let go")

    -- The Settings tab has a button for it
    ns.UI.Show("settings")
    ns.UI.Refresh()

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
