-- Keepnet: fishing food and other items that raise Fishing for a while (a coin, a toy ...).
-- The fishing key uses them when their buff is missing, before the lure and the cast.
--   "BUFFS"  the items in the bags, the chosen ones or the active buffs changed
--
-- Food: Off, Auto (the strongest fishing food in the bags that the character can eat) or
-- Specific. Other items: only the ones the player adds to the list.
--
-- How it knows a buff is on: the first time Keepnet uses an item it watches which new buff
-- that mentions Fishing appears, and remembers that buff for the item. Until it has learned
-- one, a Fishing buff of the same strength as the item's tooltip promises counts, and after
-- that the time since the item was last used. So an item is never used over and over.
--
-- Eating takes about ten seconds and casting interrupts it, so after food the key does nothing
-- until the buff is on.
--
-- The fishing food list and reading a buff's tooltip for its Fishing bonus come from
-- FishyWashy by veiset; the item list for this client was checked against Forever Fishing's
-- guide. Remembering a "pending" use and matching buffs by spell ID is how LibFishing (Fishing
-- Buddy) does it. Written from scratch; see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Buffs = {}
ns.Buffs = Buffs

-- Known fishing food and its bonus: a fallback for when the tooltip can't be read
local KNOWN_FOOD = {
    [13930] = 18, -- Filet of Redgill
    [8957] = 18,  -- Spinefin Halibut
    [4594] = 12,  -- Rockscale Cod
    [4593] = 8,   -- Bristle Whisker Catfish
    [5476] = 5,   -- Fillet of Frenzy
    [6316] = 3,   -- Loch Frenzy Delight
}

local EAT_SECONDS = 11      -- eating for 10 seconds gives the buff
local LEARN_SECONDS = 30    -- how long after a use a new buff is taken to be that item's
local USE_SECONDS = 2       -- a use that worked is confirmed by the game within this time
local MAX_TRIES = 2         -- uses that didn't work before the item is left alone for a while
local RETRY_SECONDS = 60
local DEFAULT_MINUTES = 10  -- assumed length of a buff whose tooltip doesn't say
local CONSUMABLE, FOOD_AND_DRINK = 0, 5

local function IsRed(color)
    return color and color.r and color.r > 0.99 and color.g < 0.2 and color.b < 0.2
end

local function ItemLines(itemID)
    if not (C_TooltipInfo and C_TooltipInfo.GetItemByID) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetItemByID, itemID)
    if ok and data and data.lines then return data.lines end
end

-- ---------------------------------------------------------------------------------------------
-- What an item does, from its tooltip
-- ---------------------------------------------------------------------------------------------
local described = {} -- itemID -> { bonus, minutes, food } or false; only once readable

-- { bonus, minutes, food } for an item whose "Use:" raises Fishing (not a lure, which goes on
-- the pole), false for anything else, nil when the tooltip can't be read yet. English wording.
local function Describe(itemID)
    local cached = described[itemID]
    if cached ~= nil then return cached end
    local lines = ItemLines(itemID)
    local result
    if lines then
        result = false
        for _, line in ipairs(lines) do
            local text = line.leftText
            if type(text) == "string" and not Util.Hidden(text) then
                local lower = text:lower()
                -- Not lures (they go on the pole) and not clothing (using it would put it on)
                if lower:match("^use:") and lower:find("fishing", 1, true) and not lower:find("fishing pole", 1, true)
                    and not Util.IsEquippable(itemID) then
                    local _, _, _, _, _, classID, subclassID = Util.ItemInfoInstant(itemID)
                    result = {
                        bonus = tonumber(lower:match("fishing skill by (%d+)") or lower:match("fishing by (%d+)")
                            or lower:match("%+(%d+) fishing") or lower:match("(%d+) fishing")) or 1,
                        minutes = tonumber(lower:match("for (%d+) min")) or (tonumber(lower:match("for (%d+) hour")) or 0) * 60,
                        food = (lower:find("eating", 1, true) or lower:find("well fed", 1, true)
                            or (classID == CONSUMABLE and subclassID == FOOD_AND_DRINK)) and true or false,
                    }
                    if result.minutes == 0 then result.minutes = nil end
                    break
                end
            end
        end
        described[itemID] = result
    end
    if not result and KNOWN_FOOD[itemID] then
        return { bonus = KNOWN_FOOD[itemID], minutes = 15, food = true }
    end
    return result
end

function Buffs.Describe(itemID)
    return Describe(itemID) or nil
end

local function CanUse(itemID)
    for _, line in ipairs(ItemLines(itemID) or {}) do
        if line.leftText and IsRed(line.leftColor) then return false end
    end
    return true
end

-- ---------------------------------------------------------------------------------------------
-- The bags
-- ---------------------------------------------------------------------------------------------
local bagItems -- cached until the bags change

-- Items in the bags whose use raises Fishing, strongest first:
-- { id, bonus, food, count, usable }
function Buffs.InBags()
    if bagItems then return bagItems end
    local list, seen = {}, {}
    Util.EachBagSlot(function(_, _, itemID)
        if seen[itemID] then return end
        seen[itemID] = true
        local info = Describe(itemID)
        if info then
            list[#list + 1] = {
                id = itemID, bonus = info.bonus, food = info.food,
                count = Util.ItemCount(itemID), usable = CanUse(itemID),
            }
        end
    end)
    table.sort(list, function(a, b)
        if a.bonus ~= b.bonus then return a.bonus > b.bonus end
        if a.count ~= b.count then return a.count > b.count end
        return a.id < b.id
    end)
    bagItems = list
    return list
end

-- The strongest fishing food in the bags that the character can eat, or nil
function Buffs.BestFood()
    for _, item in ipairs(Buffs.InBags()) do
        if item.food and item.usable then return item.id end
    end
end

-- ---------------------------------------------------------------------------------------------
-- The buffs on the character
-- ---------------------------------------------------------------------------------------------
local scan = { at = -1, fishing = {}, all = {} }

local function ReadAuras()
    local fishing, all = {}, {}
    local byIndex = C_UnitAuras and C_UnitAuras.GetBuffDataByIndex
    if not byIndex then return fishing, all end
    for i = 1, 40 do
        local aura = byIndex("player", i)
        if not aura then break end
        local spellID = aura.spellId
        if spellID and not Util.Hidden(spellID) then
            all[spellID] = true
            local lines
            if C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID and aura.auraInstanceID then
                local data = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", aura.auraInstanceID)
                lines = data and data.lines
            end
            for _, line in ipairs(lines or {}) do
                local text = line.leftText
                local lower = type(text) == "string" and not Util.Hidden(text) and text:lower()
                if lower and lower:find("fishing", 1, true) then
                    local expires = aura.expirationTime
                    fishing[#fishing + 1] = {
                        spellID = spellID,
                        name = (not Util.Hidden(aura.name)) and aura.name or "Buff",
                        bonus = tonumber(lower:match("fishing[^%d]-(%d+)") or lower:match("(%d+)[^%d]-fishing")),
                        expires = (expires and not Util.Hidden(expires) and expires > 0) and expires or nil,
                    }
                    break
                end
            end
        end
    end
    return fishing, all
end

-- The buffs that mention Fishing, and every buff's spell ID. Buffs can't be read in combat,
-- so the last reading is kept.
local function Auras(fresh)
    if fresh or GetTime() - scan.at > 0.5 then
        local hidden = C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
        if not InCombatLockdown() and not hidden then
            local ok, fishing, all = pcall(ReadAuras)
            if ok then scan.fishing, scan.all = fishing, all end
        end
        scan.at = GetTime()
    end
    return scan.fishing, scan.all
end

-- { { name, bonus, left (seconds or nil) } } for the live panel
function Buffs.Active()
    local list = {}
    for _, buff in ipairs(Auras()) do
        local left = buff.expires and (buff.expires - GetTime()) or nil
        if not left or left > 0 then
            list[#list + 1] = { name = buff.name, bonus = buff.bonus, left = left }
        end
    end
    return list
end

-- The item a learned buff belongs to, or nil
local function OwnerOf(spellID)
    for itemID, learned in pairs(ns.db.buffOf or {}) do
        if learned == spellID then return itemID end
    end
end

-- Whether the item's buff is on now
function Buffs.IsOn(itemID)
    local fishing, all = Auras()
    local learned = ns.db.buffOf and ns.db.buffOf[itemID]
    if learned then
        return all[learned] and true or false
    end
    local info = Describe(itemID)
    -- Not learned yet: a Fishing buff of the same strength that isn't another item's
    if info then
        for _, buff in ipairs(fishing) do
            if buff.bonus == info.bonus and not OwnerOf(buff.spellID) then return true end
        end
    end
    -- Or it was used and should still be running
    local usedAt = ns.char.usedAt and ns.char.usedAt[itemID]
    if usedAt and time() - usedAt < ((info and info.minutes) or DEFAULT_MINUTES) * 60 then
        return true
    end
    return false
end

-- Whether a food buff is on: any Fishing buff that isn't known to come from one of the
-- other items
local function FedNow()
    for _, buff in ipairs(Auras()) do
        local owner = OwnerOf(buff.spellID)
        local info = owner and Describe(owner)
        if not owner or (info and info.food) then return true end
    end
    return false
end

local function OnCooldown(itemID)
    local get = C_Container and C_Container.GetItemCooldown
    if not get then return false end
    local start, duration = get(itemID)
    return type(start) == "number" and type(duration) == "number" and start > 0 and duration > 1.5
end

-- ---------------------------------------------------------------------------------------------
-- What the key should use next
-- ---------------------------------------------------------------------------------------------
local pending      -- the use in flight: { id, at, food, auras, ok }
local waitUntil = 0
local tries, skipUntil = {}, {}

-- Eating: the key must not cast yet
function Buffs.Waiting()
    return GetTime() < waitUntil
end

local function Ready(itemID)
    if not Util.Owns(itemID) or OnCooldown(itemID) then return false end
    if (skipUntil[itemID] or 0) > GetTime() then return false end
    if (tries[itemID] or 0) >= MAX_TRIES then
        tries[itemID] = 0
        skipUntil[itemID] = GetTime() + RETRY_SECONDS
        Util.Print((Util.ItemInfo(itemID) or "That item") .. " couldn't be used. Leaving it for a minute.")
        return false
    end
    return true
end

-- The food the key would eat: the best in the bags, or the chosen one; nil when food is off
-- or there is none
function Buffs.Food()
    local settings = ns.settings
    if settings.foodMode == "auto" then
        return Buffs.BestFood()
    elseif settings.foodMode == "specific" and settings.foodItem and Util.ItemCount(settings.foodItem) > 0 then
        return settings.foodItem
    end
end

local function FoodChoice()
    local settings = ns.settings
    if settings.foodMode == "auto" then
        return Buffs.BestFood()
    elseif settings.foodMode == "specific" and settings.foodItem and Util.ItemCount(settings.foodItem) > 0 then
        return settings.foodItem
    end
end

-- The item this key press should use instead of casting, or nil
function Buffs.ToUse()
    if Buffs.Waiting() then return nil end
    local food = FoodChoice()
    if food and not FedNow() and not Buffs.IsOn(food) and Ready(food) then
        return food
    end
    for _, itemID in ipairs(ns.settings.extraItems or {}) do
        if not Buffs.IsOn(itemID) and Ready(itemID) then
            return itemID
        end
    end
end

function Buffs.UseMacro(itemID)
    return "/use item:" .. itemID
end

-- OneKey calls this for the key press that is about to use the item
function Buffs.Offered(itemID)
    local info = Describe(itemID)
    local _, all = Auras(true)
    local before = {}
    for spellID in pairs(all) do before[spellID] = true end
    tries[itemID] = (tries[itemID] or 0) + 1
    pending = {
        id = itemID, at = GetTime(), food = info and info.food or false, auras = before,
        count = Util.ItemCount(itemID),
    }
end

local function OnUseConfirmed()
    pending.ok = true
    tries[pending.id] = 0
    ns.char.usedAt = ns.char.usedAt or {}
    ns.char.usedAt[pending.id] = time()
    if pending.food then
        waitUntil = GetTime() + EAT_SECONDS
    end
end

-- A buff that mentions Fishing and wasn't there before the use is that item's buff
local function Learn()
    for _, buff in ipairs((Auras(true))) do
        if not pending.auras[buff.spellID] then
            ns.db.buffOf = ns.db.buffOf or {}
            ns.db.buffOf[pending.id] = buff.spellID
            pending = nil
            waitUntil = 0
            ns.Fire("BUFFS")
            return
        end
    end
end

-- ---------------------------------------------------------------------------------------------
-- The player's choices
-- ---------------------------------------------------------------------------------------------
function Buffs.SetFood(itemID)
    ns.settings.foodItem = itemID
    ns.Fire("BUFFS")
    ns.Fire("SETTINGS")
end

-- "off", "auto" or "specific"
function Buffs.SetFoodMode(mode)
    ns.settings.foodMode = mode
    ns.Fire("BUFFS")
    ns.Fire("SETTINGS")
end

function Buffs.HasExtra(itemID)
    for _, id in ipairs(ns.settings.extraItems or {}) do
        if id == itemID then return true end
    end
    return false
end

function Buffs.AddExtra(itemID)
    if Buffs.HasExtra(itemID) then return end
    ns.settings.extraItems = ns.settings.extraItems or {}
    table.insert(ns.settings.extraItems, itemID)
    ns.Fire("BUFFS")
    ns.Fire("SETTINGS")
end

function Buffs.RemoveExtra(itemID)
    local list = ns.settings.extraItems or {}
    for i = #list, 1, -1 do
        if list[i] == itemID then table.remove(list, i) end
    end
    ns.Fire("BUFFS")
    ns.Fire("SETTINGS")
end

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterUnitEvent("UNIT_AURA", "player")
-- Any buff that wasn't there before the use (the "Food" buff of a meal, for one)
local function NewBuffAppeared()
    local _, all = Auras(true)
    for spellID in pairs(all) do
        if not pending.auras[spellID] then return true end
    end
    return false
end

events:SetScript("OnEvent", function(_, event)
    if not ns.db then return end
    if event == "BAG_UPDATE_DELAYED" then
        bagItems = nil
        ns.Fire("BUFFS")
    end
    if not pending then return end
    local age = GetTime() - pending.at
    if age > LEARN_SECONDS then
        pending = nil
        return
    end
    -- The use worked if, within a moment, the game says a spell went off, one of the item
    -- left the bags, or a new buff appeared. Any one will do: which of them this client
    -- sends for a meal isn't known for certain, and a meal taken for a failure would be
    -- eaten twice.
    if not pending.ok and age <= USE_SECONDS then
        if event == "UNIT_SPELLCAST_SUCCEEDED"
            or (event == "BAG_UPDATE_DELAYED" and Util.ItemCount(pending.id) < pending.count)
            or (event == "UNIT_AURA" and NewBuffAppeared()) then
            OnUseConfirmed()
        end
    end
    if pending.ok and event == "UNIT_AURA" then
        Learn()
    end
end)
