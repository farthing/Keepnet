-- Keepnet: fishing gear. While the pole is equipped, clothing in the bags that raises Fishing
-- (a fishing hat, boots, gloves with a fishing enchant ...) is put on, and what it replaced is
-- put back when the pole comes off.
--   "GEAR"  the plan or what is worn changed
--
-- An item's bonus is read from its own tooltip ("Equip: Increased Fishing +5.", "Fishing +2"),
-- so enchants count and items new to this client are found without a list. The pole itself is
-- never swapped: equipping it is what turns fishing mode on.
--
-- What was replaced is written to the saved data before anything is equipped, so it can still
-- be put back after a /reload, a logout or a crash. Clothing can't be changed in combat; both
-- directions wait for combat to end.
--
-- Reading the bonus from tooltip lines follows FishyWashy by veiset; scoring every item and
-- restoring the previous ones is what Fishing Buddy's outfit and Forever Fishing's Gear button
-- do. Written from scratch; see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Gear = {}
ns.Gear = Gear

-- Where each kind of item goes. Weapons are left out on purpose.
local SLOTS_FOR = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
}

Gear.SLOT_NAMES = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest", [6] = "Waist",
    [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Ring", [12] = "Ring",
    [13] = "Trinket", [14] = "Trinket", [15] = "Back",
}

local function IsRed(color)
    return color and color.r and color.r > 0.99 and color.g < 0.2 and color.b < 0.2
end

-- Clothing whose use puts a lure on the pole (a lure hat) only works while worn. It ranks
-- below any standing bonus, so it is worn only where no fishing item wants the slot.
local LURE_ITEM_SCORE = 0.5

-- The Fishing an item gives while worn, and whether the character can wear it (no red line)
local function ReadLines(lines)
    local bonus, usable, lureItem = 0, true, false
    for _, line in ipairs(lines or {}) do
        local text = line.leftText
        if type(text) == "string" and not Util.Hidden(text) then
            if IsRed(line.leftColor) then usable = false end
            local lower = text:lower()
            if lower:match("^use:") and lower:find("fishing pole", 1, true) then lureItem = true end
            -- Not "Use:" effects (those are lures and buffs) and not "Requires Fishing (100)"
            if lower:find("fishing", 1, true) and not lower:match("^use:") and not lower:find("requires", 1, true) then
                local n = lower:match("fishing %+(%d+)") or lower:match("%+(%d+) fishing")
                    or lower:match("fishing skill by (%d+)") or lower:match("fishing by (%d+)")
                bonus = bonus + (tonumber(n) or 0)
            end
        end
    end
    if bonus == 0 and lureItem then bonus = LURE_ITEM_SCORE end
    return bonus, usable
end

-- "+5", or "lure" for an item worn for the lure it can put on the pole
function Gear.BonusText(bonus)
    if bonus == LURE_ITEM_SCORE then return "lure" end
    return ("+%d"):format(bonus)
end

local function Tooltip(getter, ...)
    if not (C_TooltipInfo and C_TooltipInfo[getter]) then return nil end
    local ok, data = pcall(C_TooltipInfo[getter], ...)
    if ok and data then return data.lines end
end

local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- The exact item (with its enchant), in the form the game's equip call takes
local function ItemString(link)
    return type(link) == "string" and (link:match("|H(item:[^|]+)|h") or link) or link
end

local function LinkName(link)
    return Util.LinkName(link) or "item"
end

local function Worn(slot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    if not link or Util.Hidden(link) then return nil, 0 end
    local bonus = ReadLines(Tooltip("GetInventoryItem", "player", slot))
    return link, bonus
end

local plan -- cached until the bags or the equipment change

-- The fishing clothing in the bags that the character can wear:
-- { { id, link, bonus, slots (where it can go) } }
local function Candidates()
    local list = {}
    Util.EachBagSlot(function(bag, slot, itemID)
        local _, _, _, equipLoc = Util.ItemInfoInstant(itemID)
        local slots = equipLoc and SLOTS_FOR[equipLoc]
        if not slots then return end
        local link = C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot)
        if not link or Util.Hidden(link) then return end
        local bonus, usable = ReadLines(Tooltip("GetBagItem", bag, slot))
        if bonus <= 0 or not usable then return end
        list[#list + 1] = { id = itemID, link = link, bonus = bonus, slots = slots }
    end)
    return list
end

local function Fits(item, invSlot)
    for _, slot in ipairs(item.slots) do
        if slot == invSlot then return true end
    end
    return false
end

-- What would be put on now: { { slot, link, bonus, worn (link or nil), wornBonus } }
--
-- A slot normally gets the item in the bags that raises Fishing most, when that beats what is
-- worn. The player can choose otherwise for a slot (Gear.Choose): a named item goes on
-- whatever its bonus, and a slot to be left alone gets nothing. A named item that is neither
-- worn nor in the bags any more is ignored, and the slot gets the best again.
function Gear.Plan()
    if plan then return plan end
    local choice = (ns.char and ns.char.gearChoice) or {}
    local best, wornCache = {}, {}
    local function WornBonus(slot)
        if not wornCache[slot] then
            local link, bonus = Worn(slot)
            wornCache[slot] = { link = link, bonus = bonus }
        end
        return wornCache[slot]
    end
    local candidates = Candidates()
    -- The player's own choices first. "held" slots are closed to the automatic pass below.
    local held, used = {}, {}
    for slot, wanted in pairs(choice) do
        if wanted == false then
            held[slot] = true
        elseif ItemID(WornBonus(slot).link) == wanted then
            held[slot] = true
        else
            local pick
            for index, item in ipairs(candidates) do
                if item.id == wanted and not used[index] and Fits(item, slot)
                    and (not pick or item.bonus > candidates[pick].bonus) then
                    pick = index
                end
            end
            if pick then
                used[pick], held[slot] = true, true
                best[slot] = { slot = slot, link = candidates[pick].link, bonus = candidates[pick].bonus }
            end
        end
    end
    for index, item in ipairs(candidates) do
        if not used[index] then
            -- For rings and trinkets: the slot that gains the most
            local target, toBeat
            for _, invSlot in ipairs(item.slots) do
                if not held[invSlot] then
                    local standing = best[invSlot] and best[invSlot].bonus or WornBonus(invSlot).bonus
                    if not toBeat or standing < toBeat then
                        target, toBeat = invSlot, standing
                    end
                end
            end
            if target and item.bonus > toBeat then
                best[target] = { slot = target, link = item.link, bonus = item.bonus }
            end
        end
    end
    plan = {}
    for slot, candidate in pairs(best) do
        candidate.worn = WornBonus(slot).link
        candidate.wornBonus = WornBonus(slot).bonus
        plan[#plan + 1] = candidate
    end
    table.sort(plan, function(a, b) return a.slot < b.slot end)
    return plan
end

-- The fishing gear Keepnet has put on: { { slot, link, bonus, was (link or false) } }
function Gear.Wearing()
    local list = {}
    for slot, swap in pairs(ns.char.gearSwap or {}) do
        local link, bonus = Worn(slot)
        if link and ItemID(link) == ItemID(swap.put) then
            list[#list + 1] = { slot = slot, link = link, bonus = bonus, was = swap.was }
        end
    end
    table.sort(list, function(a, b) return a.slot < b.slot end)
    return list
end

local function EquipCall(link, slot)
    local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if not equip then return false end
    return (pcall(equip, ItemString(link), slot))
end

-- For the live panel's list: each slot there is fishing gear for, and what could go in it.
-- { { slot, choice (nil: the best, false: left alone, or the item ID chosen),
--     items = { { id, link, bonus, worn (true when it is on now) } } } }
-- Only slots where there is something to decide: fishing gear in the bags, a piece that
-- Keepnet has put on, or a choice made earlier that can be taken back.
function Gear.Options()
    local choice = (ns.char and ns.char.gearChoice) or {}
    local swaps = (ns.char and ns.char.gearSwap) or {}
    local bySlot = {}
    local function Add(slot, item, decides)
        local group = bySlot[slot]
        if not group then
            group = { slot = slot, choice = choice[slot], items = {} }
            bySlot[slot] = group
        end
        group.decides = group.decides or decides
        for _, have in ipairs(group.items) do
            if have.id == item.id then
                have.worn = have.worn or item.worn
                if item.bonus > have.bonus then have.bonus, have.link = item.bonus, item.link end
                return
            end
        end
        group.items[#group.items + 1] = item
    end
    for slot in pairs(Gear.SLOT_NAMES) do
        local link, bonus = Worn(slot)
        if link and bonus > 0 then
            Add(slot, { id = ItemID(link), link = link, bonus = bonus, worn = true },
                swaps[slot] ~= nil or choice[slot] ~= nil)
        end
    end
    for _, item in ipairs(Candidates()) do
        for _, slot in ipairs(item.slots) do
            Add(slot, { id = item.id, link = item.link, bonus = item.bonus }, true)
        end
    end
    local list = {}
    for _, group in pairs(bySlot) do
        if group.decides then
            table.sort(group.items, function(a, b)
                if a.bonus ~= b.bonus then return a.bonus > b.bonus end
                return a.id < b.id
            end)
            list[#list + 1] = group
        end
    end
    table.sort(list, function(a, b) return a.slot < b.slot end)
    return list
end

local passes = 0

-- A slot the player wants left as it is: what Keepnet put there goes back to the bags.
-- Returns whether any slot was let go.
local function Release()
    local swaps = ns.char.gearSwap
    if not swaps then return false end
    local choice = ns.char.gearChoice or {}
    local names, released = {}, false
    for slot, swap in pairs(swaps) do
        if choice[slot] == false then
            if swap.was and GetInventoryItemID("player", slot) == ItemID(swap.put)
                and Util.ItemCount(ItemID(swap.was)) > 0 then
                EquipCall(swap.was, slot)
                names[#names + 1] = LinkName(swap.was)
            end
            swaps[slot] = nil
            released = true
        end
    end
    if next(swaps) == nil then ns.char.gearSwap = nil end
    if #names > 0 then
        Util.Print("Your own gear is back on: " .. table.concat(names, ", "))
    end
    return released
end

-- What was swapped is kept per character (ns.char.gearSwap). Before 1.0.0 it was kept once
-- for the whole account: a note left over from then goes to the character that is wearing
-- what it says was put on, and waits for that character otherwise.
local function Inherit()
    local old = ns.db.gearSwap
    if not old or ns.char.gearSwap then return end
    for slot, swap in pairs(old) do
        if type(swap) == "table" and GetInventoryItemID("player", slot) == ItemID(swap.put) then
            ns.char.gearSwap = old
            ns.db.gearSwap = nil
            return
        end
    end
end

-- Puts on what the plan says. Safe to call again: it only acts where the bags hold something
-- better than what is worn, or something the player chose.
function Gear.Equip()
    if not ns.db or not ns.settings.gear or not ns.fishing then return end
    if InCombatLockdown() or ns.inCombat then return end -- combat end calls this again
    Inherit()
    plan = nil
    local released = Release()
    local todo = Gear.Plan()
    if #todo == 0 then
        if released then
            plan = nil
            ns.Fire("GEAR")
        end
        return
    end
    local swaps = ns.char.gearSwap or {}
    local names = {}
    for _, item in ipairs(todo) do
        if swaps[item.slot] then
            -- Already swapped once (a better item turned up): keep the original to put back
            swaps[item.slot].put = item.link
        else
            swaps[item.slot] = { was = item.worn or false, put = item.link }
        end
        -- Saved before the swap, so it can be undone whatever happens next
        ns.char.gearSwap = swaps
        EquipCall(item.link, item.slot)
        names[#names + 1] = ("%s (%s)"):format(LinkName(item.link), Gear.BonusText(item.bonus))
    end
    plan = nil
    Util.Print("Fishing gear on: " .. table.concat(names, ", "))
    ns.Fire("GEAR")
    -- The game can refuse a swap while another is in flight; look once more
    passes = passes + 1
    if passes < 2 then
        C_Timer.After(1, Gear.Equip)
    end
end

-- The player's own choice for a slot, made on the live panel: nil for the best there is, an
-- item ID to wear that item whatever its bonus, false to leave the slot as it is. It is
-- saved, and acted on at once; in combat it waits for combat to end, like every change of
-- clothing.
function Gear.Choose(slot, choice)
    -- Kept per character: the choice names an item of this character's
    ns.char.gearChoice = ns.char.gearChoice or {}
    ns.char.gearChoice[slot] = choice
    plan = nil
    passes = 0
    Gear.Equip()
    ns.Fire("GEAR")
end

-- Puts back what was replaced. A slot the player has since changed by hand is left alone.
function Gear.Restore()
    if not ns.db then return end
    if InCombatLockdown() or ns.inCombat then return end -- combat end calls this again
    Inherit()
    if not ns.char.gearSwap then return end
    local names = {}
    for slot, swap in pairs(ns.char.gearSwap) do
        local wornID = GetInventoryItemID("player", slot)
        if swap.was and wornID == ItemID(swap.put) and Util.ItemCount(ItemID(swap.was)) > 0 then
            EquipCall(swap.was, slot)
            names[#names + 1] = LinkName(swap.was)
        end
    end
    ns.char.gearSwap = nil
    plan = nil
    if #names > 0 then
        Util.Print("Your own gear is back on: " .. table.concat(names, ", "))
    end
    ns.Fire("GEAR")
end

ns.On("MODE", function(on)
    passes = 0
    if on then
        Gear.Equip()
        -- Right after login the game may not know the bag items yet; look again shortly.
        -- Equip only ever acts where the bags hold something better, so this is harmless.
        C_Timer.After(3, Gear.Equip)
    else
        Gear.Restore()
    end
end)

ns.On("COMBAT", function(inCombat)
    if inCombat then return end
    if ns.fishing then
        Gear.Equip()
    else
        Gear.Restore()
    end
end)

ns.On("SETTINGS", function()
    if ns.settings.gear then
        if ns.fishing and not ns.char.gearSwap then
            passes = 0
            Gear.Equip()
        end
    else
        Gear.Restore()
    end
end)

-- The choices and the swaps are this character's: look again once it is known who that is
ns.On("CHARACTER", function() plan = nil end)

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function()
    plan = nil
    if ns.db then ns.Fire("GEAR") end
end)
