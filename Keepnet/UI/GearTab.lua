-- Keepnet: the "Gear & food" tab: fishing gear worn while the pole is on, lures bought from
-- vendors, fishing food, and other items the fishing key uses when their buff is missing.
local _, ns = ...
local Util, Gear, Buffs, Skill, W, UI = ns.Util, ns.Gear, ns.Buffs, ns.Skill, ns.Widgets, ns.UI
local Vendor = ns.Vendor

local FOOD_MODES = {
    { value = "off", text = "Off: no food" },
    { value = "auto", text = "Auto: the best fishing food in my bags" },
    { value = "specific", text = "Specific: the food I choose" },
}

local ROW = 8 -- item buttons in a row

local function Changed()
    ns.Fire("SETTINGS")
end

local function Heading(frame, text, x, y)
    local heading = W.Text(frame, "GameFontNormal", text)
    heading:SetPoint("TOPLEFT", x, y)
    return heading
end

local function Note(frame, text, x, y, width)
    local note = W.Text(frame, "GameFontDisableSmall", text)
    note:SetPoint("TOPLEFT", x, y)
    note:SetWidth(width or 360)
    note:SetJustifyH("LEFT")
    return note
end

-- Takes the item on the cursor, if there is one
local function CursorItem()
    local kind, itemID = GetCursorInfo()
    if kind == "item" and itemID then
        ClearCursor()
        return itemID
    end
end

local function ItemRow(frame, x, y, size, onClick, hint)
    local buttons = {}
    for i = 1, ROW do
        local button = W.ItemButton(frame, size, onClick)
        button:SetPoint("TOPLEFT", x + (i - 1) * (size + 4), y)
        button.hint = hint
        buttons[i] = button
    end
    return buttons
end

local function Build(frame)
    local settings = ns.settings
    local left, right = UI.LEFT, UI.LEFT + 390

    -- --------------------------------------------------------------------- fishing gear
    local y = UI.TOP - 2
    Heading(frame, "Fishing gear", left, y)
    local gear = W.Check(frame, "Wear fishing gear from my bags while the pole is equipped", function(checked)
        settings.gear = checked
        Changed()
    end)
    gear:SetPoint("TOPLEFT", left, y - 22)
    Note(frame, "Hats, boots, gloves with a fishing enchant: anything in your bags that raises Fishing "
        .. "more than what you're wearing. What it replaces is put back when the pole comes off. "
        .. "Clothing can't change in combat, so it waits for combat to end.", left, y - 44)
    local gearList = W.Text(frame, "GameFontHighlightSmall")
    gearList:SetPoint("TOPLEFT", left, y - 96)
    gearList:SetWidth(360)
    gearList:SetJustifyH("LEFT")

    -- ------------------------------------------------------------------ skill and buffs
    y = y - 166
    Heading(frame, "Fishing skill now", left, y)
    local status = W.Text(frame, "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", left, y - 22)
    status:SetWidth(360)
    status:SetJustifyH("LEFT")

    -- --------------------------------------------------------------- lures from vendors
    -- Bought when a vendor's window opens (Vendor.lua): the ticked ones of the five basic
    -- lures up to a number in the bags, and, as a choice of its own, every Aquadynamic Fish
    -- Attractor the vendor has
    y = y - 82
    Heading(frame, "Lures from vendors", left, y)
    local buy = W.Check(frame, "Buy lures when a vendor has them", function(checked)
        settings.buyLures = checked
        Changed()
        UI.Refresh()
    end)
    buy:SetPoint("TOPLEFT", left, y - 22)
    local count = W.EditBox(frame, 44, nil, function(text)
        local number = tonumber(text)
        if number then
            settings.buyLureCount = math.max(1, math.min(Vendor.MOST, math.floor(number)))
        end
    end)
    count:SetPoint("TOPLEFT", left + 22, y - 43)
    count:SetMaxLetters(3)
    local countLabel = W.Text(frame, "GameFontHighlightSmall", "of each in my bags: buy up to that many")
    countLabel:SetPoint("LEFT", count, "RIGHT", 8, 0)
    -- Three on the first line, the two long names on the second
    local LURE_PLACES = { { 22, 68 }, { 132, 68 }, { 250, 68 }, { 22, 88 }, { 190, 88 } }
    local lureChecks = {}
    for index, lure in ipairs(Vendor.LURES) do
        local check = W.Check(frame, lure.name, function(checked)
            settings.buyLureItems[lure.id] = checked or nil
            Changed()
        end)
        check:SetPoint("TOPLEFT", left + LURE_PLACES[index][1], y - LURE_PLACES[index][2])
        check.lure = lure
        lureChecks[index] = check
    end
    local attractors = W.Check(frame, "Buy every " .. Vendor.ATTRACTOR.name .. " a vendor has", function(checked)
        settings.buyAttractors = checked
        Changed()
    end)
    attractors:SetPoint("TOPLEFT", left, y - 112)
    frame.buyLures, frame.buyLureCount, frame.buyLureChecks, frame.buyAttractors = buy, count, lureChecks, attractors

    -- ----------------------------------------------------------------------------- food
    local ry = UI.TOP - 2
    Heading(frame, "Fishing food", right, ry)
    local mode = W.Dropdown(frame, 270, function() return FOOD_MODES end, function(value)
        settings.foodMode = value
        Changed()
        UI.Refresh()
    end)
    mode:SetPoint("TOPLEFT", right, ry - 20)

    -- The chosen food: drop one on it, or click one of the foods found in the bags
    local function TakeFood()
        local itemID = CursorItem()
        if itemID then Buffs.SetFood(itemID) end
    end
    local foodSlot = W.ItemButton(frame, 36)
    foodSlot:SetPoint("TOPLEFT", right, ry - 50)
    foodSlot.hint = "Drop another food here to change it."
    foodSlot:SetScript("OnClick", TakeFood) -- works on the empty slot too
    foodSlot:SetScript("OnReceiveDrag", TakeFood)
    local foodLabel = W.Text(frame, "GameFontHighlightSmall")
    foodLabel:SetPoint("TOPLEFT", foodSlot, "TOPRIGHT", 8, -2)
    local foodBagLabel = W.Text(frame, "GameFontDisableSmall")
    foodBagLabel:SetPoint("TOPLEFT", right, ry - 98)
    local foodButtons = ItemRow(frame, right + 78, ry - 92, 28, function(itemID)
        Buffs.SetFood(itemID)
    end, "Click to choose this food.")
    Note(frame, "Eaten through the fishing key when the food buff is missing. Eating takes ten "
        .. "seconds and casting would interrupt it, so the key does nothing until you're fed.", right, ry - 130)

    -- ---------------------------------------------------------------------- other items
    ry = ry - 186
    Heading(frame, "Other items", right, ry)
    Note(frame, "Anything else that raises Fishing for a while: a coin, a toy, a trinket. The fishing "
        .. "key uses each item on this list when its buff is missing.", right, ry - 20)
    local chosenLabel = W.Text(frame, "GameFontDisableSmall", "On the list:")
    chosenLabel:SetPoint("TOPLEFT", right, ry - 62)
    local chosenButtons = ItemRow(frame, right + 78, ry - 56, 28, function(itemID)
        Buffs.RemoveExtra(itemID)
    end, "Click to take it off the list.")
    local add = W.Button(frame, "+", 28, 28, function()
        local itemID = CursorItem()
        if itemID then Buffs.AddExtra(itemID) end
    end)
    add.tooltip = "Drop any item here to put it on the list."
    add:SetScript("OnReceiveDrag", function()
        local itemID = CursorItem()
        if itemID then Buffs.AddExtra(itemID) end
    end)
    local foundLabel = W.Text(frame, "GameFontDisableSmall")
    foundLabel:SetPoint("TOPLEFT", right, ry - 98)
    local foundButtons = ItemRow(frame, right + 78, ry - 92, 28, function(itemID)
        Buffs.AddExtra(itemID)
    end, "Click to put it on the list.")

    return function()
        -- Gear
        gear:SetChecked(settings.gear and true or false)
        local lines = {}
        for _, item in ipairs(Gear.Wearing()) do
            lines[#lines + 1] = ("|cff40ff40On|r  %s: %s  %s"):format(Gear.SLOT_NAMES[item.slot] or "?",
                Util.LinkName(item.link) or "?", Gear.BonusText(item.bonus))
        end
        for _, item in ipairs(Gear.Plan()) do
            lines[#lines + 1] = ("|cffffd100In bags|r  %s: %s  %s%s"):format(Gear.SLOT_NAMES[item.slot] or "?",
                Util.LinkName(item.link) or "?", Gear.BonusText(item.bonus),
                item.wornBonus > 0 and ("  (wearing %s)"):format(Gear.BonusText(item.wornBonus)) or "")
        end
        if #lines == 0 then
            lines[1] = "|cff9d9d9dNo fishing gear in your bags that beats what you're wearing.|r"
        end
        gearList:SetText(table.concat(lines, "\n", 1, math.min(#lines, 5)))

        -- Skill and buffs
        local parts = {}
        local rank, max, bonus = Skill.Get()
        if rank then
            parts[#parts + 1] = ("Fishing %d / %d%s"):format(rank, max,
                bonus > 0 and ("  |cff40ff40+%d|r from lure and gear"):format(bonus) or "")
        else
            parts[#parts + 1] = "|cff9d9d9dFishing skill unknown.|r"
        end
        for _, buff in ipairs(Buffs.Active()) do
            parts[#parts + 1] = ("%s%s%s"):format(buff.name, buff.bonus and ("  +" .. buff.bonus) or "",
                buff.left and ("  |cff9d9d9d" .. Util.MinutesSeconds(buff.left) .. " left|r") or "")
        end
        status:SetText(table.concat(parts, "\n", 1, math.min(#parts, 5)))

        -- Lures from vendors
        local buying = settings.buyLures and true or false
        buy:SetChecked(buying)
        if not (count.HasFocus and count:HasFocus()) then
            count:SetText(tostring(Vendor.Count()))
        end
        count:SetAlpha(buying and 1 or 0.45)
        countLabel:SetAlpha(buying and 1 or 0.45)
        for _, check in ipairs(lureChecks) do
            -- (the item's name in the game's own language, once the game has told it)
            check.label:SetText(Util.ItemInfo(check.lure.id) or check.lure.name)
            check:SetChecked(settings.buyLureItems[check.lure.id] and true or false)
            check:SetAlpha(buying and 1 or 0.45)
        end
        attractors:SetChecked(settings.buyAttractors and true or false)

        -- Food
        for _, option in ipairs(FOOD_MODES) do
            if option.value == settings.foodMode then mode:Set(option.value, option.text) end
        end
        local specific = settings.foodMode == "specific"
        if settings.foodItem then
            local have = Util.ItemCount(settings.foodItem)
            foodSlot:SetItem(settings.foodItem, have, have == 0, true)
            foodLabel:SetText(("%s\n|cff%s%d in your bags|r"):format(Util.ItemInfo(settings.foodItem) or ("item " .. settings.foodItem),
                have > 0 and "9d9d9d" or "ff6060", have))
        else
            foodSlot:SetItem(nil)
            foodSlot:Show() -- stays as an empty slot to drop food on
            foodSlot.icon:SetTexture(nil)
            foodSlot.count:SetText("")
            foodLabel:SetText("No food chosen\n|cff9d9d9dDrop one here or click one below|r")
        end
        foodSlot:SetAlpha(specific and 1 or 0.45)
        foodLabel:SetAlpha(specific and 1 or 0.45)

        local foods, others = {}, {}
        for _, item in ipairs(Buffs.InBags()) do
            if item.food then
                foods[#foods + 1] = item
            elseif not Buffs.HasExtra(item.id) then
                others[#others + 1] = item
            end
        end
        for i, button in ipairs(foodButtons) do
            local item = foods[i]
            button:SetItem(item and item.id, item and item.count, item and not item.usable, item and item.id == settings.foodItem)
        end
        foodBagLabel:SetText(#foods > 0 and "In your bags:" or "No fishing food in your bags.")

        -- Other items
        local extras = settings.extraItems or {}
        for i, button in ipairs(chosenButtons) do
            local itemID = extras[i]
            button:SetItem(itemID, itemID and Util.ItemCount(itemID), itemID and not Util.Owns(itemID), false)
        end
        add:ClearAllPoints()
        add:SetPoint("TOPLEFT", chosenButtons[1], "TOPLEFT", math.min(#extras, ROW - 1) * 32, 0)
        add:SetShown(#extras < ROW)
        for i, button in ipairs(foundButtons) do
            local item = others[i]
            button:SetItem(item and item.id, item and item.count, item and not item.usable, false)
        end
        foundLabel:SetText(#others > 0 and "In your bags:" or "")
    end
end

UI.AddTab("gear", "Gear & food", Build)
ns.On("GEAR", UI.Refresh)
ns.On("BUFFS", UI.Refresh)
