-- The live panel's cog, and the lists behind its lure, food and gear lines: changing what the
-- fishing key uses, and what is worn, without opening the window.
local T = {}

local KEY = "F"
local HEAD, FEET = 1, 8
local BAUBLE, CRAWLERS, BRIGHT = 6529, 6530, 6532
local COD, FRENZY = 4594, 5476
local PLAIN_HELM, LUCKY_HAT, LURE_HAT, BOOTS = 10000, 19972, 259846, 19969

function T.run(ns)
    local Gear, Lures = ns.Gear, ns.Lures

    -- Wearing a plain helm, no boots. In the bags: three lures (one needs more skill), two
    -- fishing foods, a fishing hat, a hat that puts a lure on the pole, and fishing boots.
    Stub.equipped = { [HEAD] = PLAIN_HELM }
    Stub.bags = {
        [BAUBLE] = 3, [CRAWLERS] = 2, [BRIGHT] = 5, [COD] = 2, [FRENZY] = 3,
        [LUCKY_HAT] = 1, [LURE_HAT] = 1, [BOOTS] = 1,
    }
    Stub.login()
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    local panel = KeepnetPanel
    local kit, menu = panel.kit, panel.menu

    -- The entries of the list that is open, as { text, entry } in order
    local function Listed()
        local list = {}
        for _, line in ipairs(menu.rows) do
            if line:IsShown() then list[#list + 1] = line end
        end
        return list
    end
    local function Find(text, under)
        local inSection = under == nil
        for _, line in ipairs(Listed()) do
            local entry = line.entry
            if entry.title then
                inSection = under == nil or entry.title == under
            elseif inSection and entry.text and entry.text:find(text, 1, true) then
                return line
            end
        end
    end
    local function Open(row)
        if not menu:IsOpenAt(row) then row:GetScript("OnClick")(row) end
    end
    -- Opens the list behind a line of the panel and clicks an entry of it
    local function Pick(row, text, under)
        Open(row)
        local line = Find(text, under)
        check(line ~= nil, "the list has an entry '" .. text .. "'")
        if line then line:GetScript("OnClick")(line) else menu:Close() end
    end
    -- --------------------------------------------------------------------------- the cog
    check(panel.cog ~= nil, "the panel has a cog")
    eq(KeepnetWindow, nil, "the window isn't built yet")
    panel.cog:GetScript("OnClick")(panel.cog)
    check(KeepnetWindow and KeepnetWindow:IsShown(), "the cog opens the window")
    check(Stub.selectedTabs ~= nil and ns.UI.IsShown(), "(on a tab)")
    panel.cog:GetScript("OnClick")(panel.cog)
    eq(KeepnetWindow:IsShown(), false, "the cog again closes it")
    ns.UI.Show("history")
    panel.cog:GetScript("OnClick")(panel.cog)
    eq(KeepnetWindow:IsShown(), true, "from another tab the cog goes to the settings and leaves the window open")
    panel.cog:GetScript("OnClick")(panel.cog)
    eq(KeepnetWindow:IsShown(), false, "and closes it from there")

    -- ------------------------------------------------- the version, and how many lures are left
    eq(panel.version:GetText(), "v" .. ns.VERSION, "the panel says which Keepnet this is")
    check(kit.lureText:GetText():find("Nightcrawlers x2  +50", 1, true),
        "the lure line counts the lure the key will put on: the strongest usable one")

    -- ------------------------------------------------------------------ opening and closing
    eq(menu:IsOpen(), false, "no list until a line is clicked")
    Open(kit.lureRow)
    eq(menu:IsOpenAt(kit.lureRow), true, "a click on the lure line opens its list")
    eq(menu.catcher:GetParent(), UIParent, "it sits in the game's interface, like the panel")
    -- While it is open a catcher covers the screen: a click anywhere but on the list closes it
    menu.catcher:GetScript("OnClick")(menu.catcher)
    eq(menu:IsOpen(), false, "a click anywhere else closes it")
    Open(kit.lureRow)
    Open(kit.foodRow)
    eq(menu:IsOpenAt(kit.foodRow), true, "another line takes the list over")
    menu:Close()
    -- Near the bottom of the screen the list opens upwards
    kit.gearRow.__bottom = 20
    Open(kit.gearRow)
    eq(menu:IsOpen(), true, "a line near the bottom of the screen opens its list too")
    menu:Close()
    kit.gearRow.__bottom = nil

    -- ------------------------------------------------------------------------------ lures
    Open(kit.lureRow)
    local lines = Listed()
    eq(#lines, 6, "lure list: a heading, automatic, three lures, off")
    check(lines[1].entry.title ~= nil, "the heading comes first")
    eq(lines[2].entry.checked, true, "automatic is the one in use")
    eq(lines[3].entry.text, "Bright Baubles", "the strongest lure first")
    eq(lines[3].entry.dim, true, "dimmed: the character's skill is too low for it")
    eq(lines[3].entry.right, "+75  x5", "with its bonus and how many there are")
    eq(lines[4].entry.text, "Nightcrawlers", "then the next")
    eq(lines[6].entry.text, "Off: no lure", "off comes last")
    eq(lines[1]:GetScript("OnClick")(lines[1]), nil, "a click on the heading does nothing")
    eq(menu:IsOpen(), true, "and leaves the list open")

    Pick(kit.lureRow, "Shiny Bauble")
    eq(menu:IsOpen(), false, "choosing closes the list")
    eq(ns.settings.lureMode, "specific", "choosing a lure makes it the chosen one")
    eq(ns.settings.lureItem, BAUBLE, "the one that was clicked")
    check(kit.lureText:GetText():find("Shiny Bauble", 1, true), "the panel's line names it")
    check(kit.lureText:GetText():find("Shiny Bauble x3  +25", 1, true), "with how many of it are in the bags")
    Stub.bags[BAUBLE] = 2
    Stub.fire("BAG_UPDATE_DELAYED")
    check(kit.lureText:GetText():find("Shiny Bauble x2", 1, true), "the count follows the bags")
    Stub.bags[BAUBLE] = 3
    Stub.fire("BAG_UPDATE_DELAYED")
    eq(Stub.press(KEY), "lure", "the next press puts a lure on")
    eq(Stub.used[#Stub.used], BAUBLE, "the chosen one, not the strongest")
    Open(kit.lureRow)
    eq(Find("Shiny Bauble").entry.checked, true, "the list marks the chosen lure")
    eq(Find("Automatic").entry.checked, false, "and no longer automatic")
    menu:Close()

    -- With a lure on the pole, a new choice waits for it to run out
    Pick(kit.lureRow, "Nightcrawlers")
    eq(ns.settings.lureItem, CRAWLERS, "another lure chosen while one is on the pole")
    check(panel.buffs:GetText():find("runs out", 1, true), "the panel says it goes on when that one runs out")
    eq(Stub.press(KEY), "cast", "the key casts: the lure on the pole stays")
    Stub.reel(nil)
    Stub.enchantUntil = nil
    Stub.advance(2)
    eq(Stub.press(KEY), "lure", "once it has run out, the key puts a lure on")
    eq(Stub.used[#Stub.used], CRAWLERS, "the newly chosen one")

    Pick(kit.lureRow, "Off: no lure")
    eq(ns.settings.lureMode, "off", "off in the list turns lures off")
    eq(kit.lureToggle.label:GetText(), "A", "the button beside it is an A")
    eq(kit.lureToggle.lit:IsShown(), false, "not lit: lures are off")
    kit.lureToggle:GetScript("OnClick")(kit.lureToggle)
    eq(ns.settings.lureMode, "specific", "and the button brings back the chosen lure")
    eq(kit.lureToggle.lit:IsShown(), true, "lit again")
    Pick(kit.lureRow, "Automatic")
    eq(ns.settings.lureMode, "auto", "automatic in the list")

    -- A chosen lure that has run out is still shown, as the one in use
    Lures.SetMode("specific")
    Lures.SetSpecific(BAUBLE)
    Stub.bags[BAUBLE] = 0
    Stub.fire("BAG_UPDATE_DELAYED")
    Open(kit.lureRow)
    local gone = Find("Shiny Bauble")
    check(gone and gone.entry.right == "none left" and gone.entry.checked, "a chosen lure with none left is listed as such")
    menu:Close()
    check(kit.lureText:GetText():find("none left", 1, true), "the panel's line says there is none left")
    check(not kit.lureText:GetText():find("Shiny Bauble x", 1, true), "and shows no count for it")
    Pick(kit.lureRow, "Off: no lure")

    -- ------------------------------------------------------------------------------- food
    Open(kit.foodRow)
    eq(#Listed(), 5, "food list: a heading, automatic, two foods, off")
    eq(Find("Off: no food").entry.checked, true, "food starts off")
    eq(Listed()[3].entry.text, "Rockscale Cod", "the strongest food first")
    menu:Close()
    Pick(kit.foodRow, "Fillet of Frenzy")
    eq(ns.settings.foodMode, "specific", "choosing a food makes it the chosen one")
    eq(ns.settings.foodItem, FRENZY, "the one that was clicked")
    check(kit.foodText:GetText():find("Fillet of Frenzy", 1, true), "the panel's line names it")
    Stub.enchantUntil = nil
    Stub.advance(2)
    eq(Stub.press(KEY), "use:" .. FRENZY, "the next press eats it, not the stronger food")
    Stub.advance(11)
    Pick(kit.foodRow, "Automatic")
    eq(ns.settings.foodMode, "auto", "automatic in the list")
    Pick(kit.foodRow, "Off: no food")
    eq(ns.settings.foodMode, "off", "off in the list")

    -- ------------------------------------------------------------------------------- gear
    eq(Stub.equipped[HEAD], LUCKY_HAT, "to start with, the best hat is on")
    eq(Stub.equipped[FEET], BOOTS, "and the boots")
    Open(kit.gearRow)
    lines = Listed()
    eq(#lines, 10, "gear list: the switch, then a heading, automatic, the items and 'leave' per slot")
    eq(lines[1].entry.checked, true, "the switch shows fishing gear is being worn")
    eq(lines[2].entry.title, "Head", "the head first")
    eq(lines[3].entry.checked, true, "on automatic")
    eq(lines[4].entry.text, "Lucky Fishing Hat", "the hat that is on")
    eq(lines[4].entry.right, "+5  on", "marked as on, with its bonus")
    eq(lines[5].entry.text, "Wide-Brimmed Fishing Hat", "and the other hat in the bags")
    eq(lines[5].entry.right, "lure", "which is worn for its lure")
    eq(lines[7].entry.title, "Feet", "then the feet")
    menu:Close()

    -- Another hat for the head, though it raises Fishing less
    Pick(kit.gearRow, "Wide-Brimmed Fishing Hat", "Head")
    eq(Stub.equipped[HEAD], LURE_HAT, "the chosen hat goes on at once")
    eq(Stub.bags[LUCKY_HAT], 1, "the better hat is back in the bags")
    eq(ns.char.gearChoice[HEAD], LURE_HAT, "the choice is saved")
    check(ns.char.gearSwap[HEAD].was:find("item:" .. PLAIN_HELM, 1, true), "what to put back is still the player's own helm")
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], LURE_HAT, "it isn't swapped back for the better one")
    eq(Stub.equipped[FEET], BOOTS, "the other slots are untouched")
    check(kit.gearText:GetText():find("Wide-Brimmed", 1, true), "the panel's line names it")
    -- The hat puts a lure on the pole itself: as the lure in use it has no count
    Lures.SetMode("specific")
    Lures.SetSpecific(LURE_HAT)
    check(kit.lureText:GetText():find("Wide-Brimmed Fishing Hat  +", 1, true), "a worn lure item is named with its bonus")
    check(not kit.lureText:GetText():find("Hat x", 1, true), "and without a count")
    Lures.SetMode("off")
    Open(kit.gearRow)
    eq(Find("Wide-Brimmed", "Head").entry.checked, true, "the list marks the chosen hat")
    eq(Find("Automatic", "Head").entry.checked, false, "the head is no longer on automatic")
    eq(Find("Automatic", "Feet").entry.checked, true, "the feet still are")
    menu:Close()

    -- Bare feet before: leaving them alone has nothing to put back, so the boots stay
    eq(ns.char.gearSwap[FEET].was, false, "the feet were bare before the boots went on")
    Pick(kit.gearRow, "Leave what I'm wearing", "Feet")
    eq(Stub.equipped[FEET], BOOTS, "nothing to put back on the feet: the boots stay")
    eq(ns.char.gearSwap[FEET], nil, "and they are the player's own from here on")
    check(ns.char.gearSwap[HEAD] ~= nil, "the head's swap is still remembered")
    Pick(kit.gearRow, "Automatic", "Feet")
    eq(ns.char.gearChoice[FEET], nil, "the feet back on automatic")

    -- The choice holds from one fishing trip to the next
    Stub.equip(nil)
    eq(Stub.equipped[HEAD], PLAIN_HELM, "pole off: the player's own helm is back")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], LURE_HAT, "pole on again: the chosen hat, not the best one")

    -- A slot left alone
    Pick(kit.gearRow, "Leave what I'm wearing", "Head")
    eq(Stub.equipped[HEAD], PLAIN_HELM, "left alone: the player's own helm goes back on at once")
    eq(ns.char.gearSwap, nil, "with nothing more to put back")
    eq(Stub.equipped[FEET], BOOTS, "the boots stay on")
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], PLAIN_HELM, "and no fishing hat comes back")
    check(not kit.gearText:GetText():find("Hat", 1, true), "the panel's line no longer names a hat")
    Open(kit.gearRow)
    eq(Find("Leave what I'm wearing", "Head").entry.checked, true, "the list marks the head as left alone")
    check(Find("Lucky Fishing Hat", "Head") ~= nil, "and still offers the hats")
    menu:Close()

    Pick(kit.gearRow, "Automatic", "Head")
    eq(ns.char.gearChoice[HEAD], nil, "back on automatic: the choice is forgotten")
    eq(Stub.equipped[HEAD], LUCKY_HAT, "and the best hat goes on")

    -- In combat clothing can't change: the choice waits
    Stub.enterCombat()
    Pick(kit.gearRow, "Wide-Brimmed Fishing Hat", "Head")
    eq(Stub.equipped[HEAD], LUCKY_HAT, "chosen in combat: nothing changes yet")
    check(panel.buffs:GetText():find("combat ends", 1, true), "the panel says when it will")
    Stub.leaveCombat()
    eq(Stub.equipped[HEAD], LURE_HAT, "after combat the chosen hat goes on")

    -- A chosen item that is gone: the slot gets the best again
    Stub.equip(nil)
    Stub.bags[LURE_HAT] = 0
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    eq(Stub.equipped[HEAD], LUCKY_HAT, "the chosen hat is gone: the best one is worn")

    -- The switch at the top
    Pick(kit.gearRow, "Wear fishing gear")
    eq(ns.settings.gear, false, "the switch turns fishing gear off")
    eq(Stub.equipped[HEAD], PLAIN_HELM, "and the player's own helm is back")
    Open(kit.gearRow)
    eq(#Listed(), 1, "with gear off the list is just the switch")
    menu:Close()
    Pick(kit.gearRow, "Wear fishing gear")
    eq(ns.settings.gear, true, "the switch turns it on again")
    eq(Stub.equipped[HEAD], LUCKY_HAT, "and the hat goes back on")

    -- No fishing gear at all
    Stub.equip(nil)
    Stub.bags[LUCKY_HAT], Stub.bags[BOOTS] = 0, 0
    Stub.equipped[FEET] = nil
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    Open(kit.gearRow)
    lines = Listed()
    eq(#lines, 2, "no fishing gear: the switch and a note")
    check(lines[2].entry.note ~= nil, "the note says there is none")
    menu:Close()

    -- The section turned off takes an open list with it
    Open(kit.lureRow)
    ns.settings.panelKit = false
    ns.Fire("SETTINGS")
    eq(menu:IsOpen(), false, "the section hidden: its list closes")
    ns.settings.panelKit = true
    ns.Fire("SETTINGS")

    -- With the game's interface hidden the panel is lifted out of it: the list follows
    ns.LivePanel.Detach(true)
    Open(kit.lureRow)
    eq(menu.catcher:GetParent(), WorldFrame, "interface hidden: the list sits where the panel now sits")
    eq(menu:IsOpen(), true, "and is open there")
    ns.LivePanel.Detach(false)
    eq(menu:IsOpen(), false, "the panel put back: the open list closes")
    Open(kit.lureRow)
    eq(menu.catcher:GetParent(), UIParent, "and the next one is in the interface again")
    menu:Close()

    -- The pole comes off with a list open: it goes with the panel
    Open(kit.foodRow)
    Stub.equip(nil)
    eq(panel:IsShown(), false, "pole off: the panel goes")
    eq(menu:IsOpen(), false, "and the open list with it")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
