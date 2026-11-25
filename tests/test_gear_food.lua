-- Fishing gear put on and taken off with the pole, food and buff items through the key, a toy,
-- a worn lure hat, the skill reading and the rare-catch alert.
local T = {}

local KEY = "F"
local HEAD, FEET, HANDS = 1, 8, 10

local function Count(list, text)
    local n = 0
    for _, line in ipairs(list) do
        if tostring(line):find(text, 1, true) then n = n + 1 end
    end
    return n
end

function T.run(ns)
    local Gear, Buffs, Lures, Skill = ns.Gear, ns.Buffs, ns.Lures, ns.Skill

    -- Wearing a plain helm and plain gloves, no boots. In the bags: a fishing hat, fishing
    -- boots, gloves with a fishing enchant, and a better hat the character can't wear yet.
    Stub.equipped = { [HEAD] = 10000, [HANDS] = 10001 }
    Stub.bags = { [19972] = 1, [19969] = 1, [15405] = 1, [99001] = 1 }
    Stub.auction = { [13422] = 41800, [13756] = 900 }
    Stub.login()
    ns.settings.lureMode = "off"

    -- -------------------------------------------------------------------------- skill
    local rank, max, bonus = Skill.Get()
    eq(rank, 187, "fishing skill")
    eq(max, 225, "skill cap")
    eq(bonus, 105, "temporary bonus")

    -- ------------------------------------------------------------------ gear goes on
    eq(#Gear.Plan(), 3, "three items in the bags beat what is worn")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], 19972, "the fishing hat is on (not the one that needs more skill)")
    eq(Stub.equipped[FEET], 19969, "the fishing boots are on")
    eq(Stub.equipped[HANDS], 15405, "the gloves with the fishing enchant are on")
    eq(Stub.bags[10000], 1, "the plain helm is in the bags")
    check(ns.char.gearSwap[HEAD].was:find("item:10000", 1, true), "what the hat replaced is saved")
    eq(ns.char.gearSwap[FEET].was, false, "the feet were bare")
    eq(Count(Stub.chat, "Fishing gear on"), 1, "says what it put on, once")
    eq(#Gear.Plan(), 0, "nothing left to put on")
    eq(#Gear.Wearing(), 3, "three pieces of fishing gear worn")
    local gearLine = KeepnetPanel.kit.gearText:GetText()
    check(gearLine:find("Lucky Fishing Hat", 1, true) and gearLine:find("+12", 1, true),
        "the live panel names the gear put on and its total bonus")

    -- A reload with the gear on: what it replaced is still known
    ns = Stub.reload()
    Gear, Buffs, Lures, Skill = ns.Gear, ns.Buffs, ns.Lures, ns.Skill
    ns.settings.lureMode = "off"
    check(ns.char.gearSwap and ns.char.gearSwap[HEAD] ~= nil, "after a reload the swap is still remembered")
    eq(Stub.equipped[HEAD], 19972, "after a reload the hat is still on")

    -- ----------------------------------------------------------------------- food
    Stub.bags[4594], Stub.bags[5476] = 2, 3
    Stub.fire("BAG_UPDATE_DELAYED")
    eq(Stub.press(KEY), "cast", "food off: the key just casts")
    Stub.reel(nil)
    Stub.advance(2)
    ns.settings.foodMode = "auto"
    eq(Buffs.BestFood(), 4594, "auto picks the strongest fishing food")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5) -- the panel's once-a-second redraw
    check(KeepnetPanel.kit.foodText:GetText():find("Rockscale Cod", 1, true), "the live panel names the food the key will eat")
    eq(Stub.press(KEY), "use:4594", "the first press eats")
    eq(Buffs.Waiting(), true, "eating: the key waits")
    check(KeepnetPanel.kit.foodText:GetText():find("eating", 1, true), "the live panel says so")
    eq(Stub.press(KEY), "nothing", "a press while eating does nothing")
    eq(Stub.channel, nil, "and does not cast, which would interrupt the meal")
    Stub.advance(5)
    eq(Stub.press(KEY), "nothing", "still eating")
    Stub.advance(5.5)
    eq(Buffs.Waiting(), false, "fed: the key works again")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
    check(KeepnetPanel.kit.foodText:GetText():find("fed", 1, true), "the live panel shows fed")
    eq(ns.db.buffOf[4594], 5004, "the food's buff was learned")
    eq(Stub.press(KEY), "cast", "the next press casts")
    eq(Stub.bags[4594], 1, "one cod eaten")
    Stub.reel(nil)
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "fed: no second helping")
    Stub.reel(nil)
    eq(#Buffs.Active(), 1, "one fishing buff showing")
    eq(Buffs.Active()[1].bonus, 12, "with its bonus")

    -- The buff runs out: eat again
    Stub.advance(15 * 60)
    eq(Stub.press(KEY), "use:4594", "the buff ran out: eats again")
    Stub.advance(11)
    eq(Stub.bags[4594], 0, "the cod is gone")
    Stub.advance(15 * 60)
    eq(Stub.press(KEY), "use:5476", "out of cod: the next best food")
    Stub.advance(11)
    eq(ns.db.buffOf[5476], 5005, "the second food's buff was learned too")

    -- A chosen food
    ns.settings.foodMode = "specific"
    Buffs.SetFood(5476)
    eq(Stub.press(KEY), "cast", "specific food, still fed: casts")
    Stub.reel(nil)
    ns.settings.foodMode = "off"

    -- ------------------------------------------------------------------ other items
    Stub.bags[286732] = 6
    Stub.fire("BAG_UPDATE_DELAYED")
    local found = false
    for _, item in ipairs(Buffs.InBags()) do
        if item.id == 286732 then
            found = true
            eq(item.bonus, 30, "the coin's bonus is read from its tooltip")
            eq(item.food, false, "the coin is not food")
        end
    end
    check(found, "the coin is found in the bags")
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "not on the list: not used")
    Stub.reel(nil)
    Stub.advance(2)
    Buffs.AddExtra(286732)
    eq(Stub.press(KEY), "use:286732", "on the list: used")
    eq(Buffs.Waiting(), false, "no waiting for an item that isn't food")
    eq(ns.db.buffOf[286732], 1321323, "the coin's buff was learned")
    eq(Stub.press(KEY), "cast", "then the cast")
    Stub.reel(nil)
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "buff still on: not used again")
    Stub.reel(nil)
    Stub.advance(30 * 60)
    eq(Stub.press(KEY), "use:286732", "after it runs out it is used again")
    Stub.advance(2)

    -- A toy: used through the toy action, and its buff never mentions fishing
    Stub.toys[276274] = true
    Buffs.AddExtra(276274)
    eq(Stub.press(KEY), "use:276274", "a toy on the list is used (through the toy action)")
    eq(ns.db.buffOf[276274], nil, "nothing to learn from a buff that doesn't mention fishing")
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "and not used again straight away")
    Stub.reel(nil)
    Buffs.RemoveExtra(276274)
    eq(Buffs.HasExtra(276274), false, "taken off the list")

    -- An item that can't be used must not stop the fishing
    Stub.advance(31 * 60)
    Stub.useFails = true
    local lines = #Stub.chat
    eq(Stub.press(KEY), "use failed", "the item can't be used")
    Stub.advance(3)
    eq(Stub.press(KEY), "use failed", "nor the second time")
    Stub.advance(3)
    eq(Stub.press(KEY), "cast", "the third press casts without it")
    eq(#Stub.chat, lines + 1, "and says so")
    Stub.reel(nil)
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "it is left alone for a minute")
    Stub.reel(nil)
    Stub.useFails = false
    Stub.advance(61)
    eq(Stub.press(KEY), "use:286732", "then tried again, and it works")
    Stub.advance(2)
    Buffs.RemoveExtra(286732)

    -- -------------------------------------------------------------- a worn lure hat
    -- From the bags it is clothing, not a lure; the Gear option wears it where no fishing
    -- item wants the slot, and worn it is a lure.
    Stub.bags[259846] = 1
    Stub.fire("BAG_UPDATE_DELAYED")
    ns.settings.lureMode = "auto"
    eq(#Lures.InBags(), 0, "a lure hat in the bags is not offered as a lure")
    eq(#Gear.Plan(), 0, "and doesn't push the fishing hat off the head")
    eq(Stub.press(KEY), "cast", "no lure: casts")
    Stub.reel(nil)
    Stub.advance(2)
    Stub.equip(nil)
    Stub.bags[19972] = 0 -- the fishing hat is gone; only the lure hat is left
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], 259846, "with no fishing hat, the lure hat is worn")
    eq(Lures.InBags()[1] and Lures.InBags()[1].worn, HEAD, "worn, it is a lure")
    eq(Stub.press(KEY), "lure", "the key uses the hat to put the lure on")
    eq(Stub.used[#Stub.used], 259846, "it was the hat")
    eq(Stub.press(KEY), "cast", "then casts")
    Stub.reel(nil)
    Stub.enchantUntil = nil
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "the hat is on cooldown: casts without a lure")
    Stub.reel(nil)
    ns.settings.lureMode = "off"

    -- ----------------------------------------------------------------- rare catches
    lines = Count(Stub.chat, "Rare catch")
    Stub.advance(2)
    Stub.press(KEY)
    Stub.nextLoot = { { id = 13756, count = 1 } }
    Stub.press(KEY)
    eq(Count(Stub.chat, "Rare catch"), lines, "an ordinary fish: no alert")
    eq(#Stub.sounds, 0, "and no sound")
    Stub.advance(2)
    Stub.press(KEY)
    Stub.nextLoot = { { id = 2000, count = 1 }, { id = 13756, count = 1 } }
    Stub.press(KEY)
    eq(Count(Stub.chat, "Rare catch"), lines + 1, "a green catch: an alert in chat")
    eq(#Stub.sounds, 1, "with a sound")
    eq(Stub.sounds[1].channel, "Master", "on the master channel")
    eq(Count(Stub.screen, "Shiny Green Thing"), 1, "and a line on the screen")
    ns.settings.rareSound = false
    ns.settings.rareQuality = 0
    ns.settings.rareGold = 3
    Stub.advance(2)
    Stub.press(KEY)
    Stub.nextLoot = { { id = 2000, count = 1 } }
    Stub.press(KEY)
    eq(Count(Stub.chat, "Rare catch"), lines + 1, "quality alerts off: the green thing is quiet")
    Stub.advance(2)
    Stub.press(KEY)
    Stub.nextLoot = { { id = 13422, count = 1 } }
    Stub.press(KEY)
    eq(Count(Stub.chat, "Rare catch"), lines + 2, "worth over 3 gold each: an alert")
    eq(#Stub.sounds, 1, "sound off: no sound")

    -- The screens with all of this on them
    ns.UI.Show("gear")
    ns.UI.Show("settings")
    ns.UI.Show("gear")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)

    -- ------------------------------------------------- gear comes off after combat
    Stub.advance(2)
    Stub.enterCombat()
    Stub.mainHand = nil -- weapons can be swapped in combat
    Stub.fire("PLAYER_EQUIPMENT_CHANGED", 16, false)
    Stub.advance(0.5)
    eq(ns.fishing, false, "pole off in combat: fishing mode off")
    eq(Stub.equipped[HANDS], 15405, "clothing can't change in combat: the gloves stay for now")
    Stub.leaveCombat()
    eq(Stub.equipped[HANDS], 10001, "after combat the plain gloves are back")
    eq(Stub.equipped[HEAD], 10000, "and the plain helm")
    eq(Stub.equipped[FEET], 19969, "the boots stay: there was nothing to put back")
    eq(ns.char.gearSwap, nil, "nothing left to put back")
    eq(Count(Stub.chat, "Your own gear is back on"), 2, "says so (this time and when the pole came off before)")

    -- A slot the player changed by hand is left alone
    Stub.bags[19972] = 1
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], 19972, "the fishing hat is back in the bags, so it goes on")
    C_Item.EquipItemByName("item:99001", HEAD) -- the player puts another hat on
    Stub.equip(nil)
    eq(Stub.equipped[HEAD], 99001, "a hat the player changed is not touched")

    -- The option off: nothing is put on, and turning it off takes the gear off
    Stub.equipped[HEAD] = 10000
    Stub.bags = { [19972] = 1, [15405] = 1 }
    Stub.equipped[HANDS] = 10001
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HANDS], 15405, "gear on again")
    ns.settings.gear = false
    ns.Fire("SETTINGS")
    eq(Stub.equipped[HANDS], 10001, "option off while fishing: the player's own gear is back")
    Stub.equip(nil)
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HANDS], 10001, "option off: nothing is put on")
    Stub.equip(nil)

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
