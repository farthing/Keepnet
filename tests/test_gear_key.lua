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

    -- In combat the hands can still be changed: the weapon comes back at once, and the
    -- clothing when combat ends
    Stub.press(GEAR_KEY)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], LUCKY_HAT, "fishing, with the hat on")
    Stub.enterCombat()
    Stub.chat = {}
    Stub.press(GEAR_KEY)
    Stub.advance(2)
    eq(Stub.mainHand, DAGGER, "attacked while fishing: the key puts the weapon back in combat")
    eq(Stub.equipped[17], SHIELD, "and the other hand's")
    eq(Stub.equipped[HEAD], LUCKY_HAT, "the hat stays on until combat ends")
    check(Said("Your clothing changes when combat ends"), "and the player is told so")
    Stub.leaveCombat()
    Stub.advance(1)
    eq(Stub.equipped[HEAD], PLAIN_HELM, "combat over: the player's own hat is back")
    -- And the other way, the pole on in combat
    Stub.enterCombat()
    Stub.press(GEAR_KEY)
    Stub.advance(1.5)
    check(Stub.mainHand ~= DAGGER, "in combat the key puts the pole on as well")
    eq(Stub.equipped[HEAD], PLAIN_HELM, "the fishing hat waits")
    Stub.leaveCombat()
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], LUCKY_HAT, "and goes on when combat ends")
    Stub.press(GEAR_KEY)
    Stub.advance(2)
    eq(Stub.mainHand, DAGGER, "off again")

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

    -- ------------------------------------------------------------- recording a key
    -- The Settings tab has a button for each key: click, then press the key or the keys
    ns.UI.Show("settings")
    ns.UI.Refresh()
    local button = ns.SettingsKeys.gear
    local function Down(key) button:GetScript("OnKeyDown")(button, key) end
    local function Up(key) button:GetScript("OnKeyUp")(button, key) end
    local function Click(which) button:GetScript("OnClick")(button, which or "LeftButton") end
    eq(button.label:GetText(), "none", "no gear key: the button says so")

    -- Ctrl and F, the game saying nothing about what is held: the keys themselves are followed
    Click()
    eq(button.label:GetText(), "Press the key or keys (Esc cancels)", "clicked: it asks for the keys")
    Down("LCTRL")
    eq(button.label:GetText(), "CTRL-...", "Ctrl held: it shows on the button, and nothing is taken yet")
    eq(settings.gearKey, nil, "a held key by itself is not a key")
    Down("F")
    eq(settings.gearKey, "CTRL-F", "then F: Ctrl and F is the key")
    eq(button.label:GetText(), "CTRL-F", "shown on the button")
    eq(Gear.Key(), "CTRL-F", "and bound")
    Up("F")
    Up("LCTRL")
    eq(settings.gearKey, "CTRL-F", "letting go changes nothing")

    -- Three and four keys, in the order the game writes them whatever order they went down in
    Click()
    Down("RSHIFT")
    Down("LALT")
    eq(button.label:GetText(), "ALT-SHIFT-...", "two held")
    Down("LCTRL")
    eq(button.label:GetText(), "ALT-CTRL-SHIFT-...", "three held")
    Down("G")
    eq(settings.gearKey, "ALT-CTRL-SHIFT-G", "four keys make one combination")
    Up("G")
    Up("LCTRL")
    Up("LALT")
    Up("RSHIFT")

    -- A held key let go again before the last key is not part of it
    Click()
    Down("LSHIFT")
    Up("LSHIFT")
    eq(button.label:GetText(), "Press the key or keys (Esc cancels)", "let go: back to asking")
    Down("H")
    eq(settings.gearKey, "H", "a key pressed alone is that key alone")

    -- The game saying what is held is enough too (a key held before the click)
    Stub.heldKeys = { CTRL = true }
    Click()
    eq(button.label:GetText(), "CTRL-...", "Ctrl held since before the click: seen")
    Down("J")
    eq(settings.gearKey, "CTRL-J", "and counted")
    Stub.heldKeys = nil

    -- A game that keeps what is held to itself breaks nothing
    Stub.heldKeysHidden = true
    Click()
    Down("LALT")
    Down("K")
    eq(settings.gearKey, "ALT-K", "the game keeps it to itself: the keys seen still count")
    Stub.heldKeysHidden = nil
    Up("LALT")

    -- A side button of the mouse, with a key held
    Click()
    Down("LCTRL")
    Click("Button4")
    eq(settings.gearKey, "CTRL-BUTTON4", "a side button of the mouse with Ctrl held")
    Up("LCTRL")

    -- Escape cancels; a right click clears
    Click()
    Down("ESCAPE")
    eq(settings.gearKey, "CTRL-BUTTON4", "Escape leaves the key as it was")
    eq(button.label:GetText(), "CTRL-BUTTON4", "and shows it again")
    Click("RightButton")
    eq(settings.gearKey, nil, "a right click sets no key")
    eq(button.label:GetText(), "none", "and the button says so")

    -- The fishing key's own key is refused, but that key with another held is a key of its own
    Click()
    Down(settings.key)
    eq(settings.gearKey, nil, "the fishing key itself is refused")
    Click()
    Down("LCTRL")
    Down(settings.key)
    Up("LCTRL")
    eq(settings.gearKey, "CTRL-" .. settings.key, "the fishing key with Ctrl held is another key")
    eq(Gear.Key(), "CTRL-" .. settings.key, "and is bound")
    -- The fishing key's button takes combinations the same way
    local fishing = ns.SettingsKeys.fishing
    fishing:GetScript("OnClick")(fishing, "LeftButton")
    fishing:GetScript("OnKeyDown")(fishing, "LSHIFT")
    fishing:GetScript("OnKeyDown")(fishing, "F")
    eq(settings.key, "SHIFT-F", "the fishing key can be a combination too")
    fishing:GetScript("OnKeyUp")(fishing, "LSHIFT")
    fishing:GetScript("OnClick")(fishing, "LeftButton")
    fishing:GetScript("OnKeyDown")(fishing, "F")
    eq(settings.key, "F", "and a single key again")
    settings.gearKey = nil
    ns.Fire("SETTINGS")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
