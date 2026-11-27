-- Keepnet: helpers shared by every file.
-- Nothing here creates frames, so the session and price logic can run outside the game
-- (tests\run_tests.py).
local ADDON, ns = ...
ns.ADDON = ADDON or "Keepnet"
ns.VERSION = "1.2.4"

local Util = {}
ns.Util = Util

-- ---------------------------------------------------------------------------------------------
-- Messages between files: ns.On("NAME", fn) listens, ns.Fire("NAME", ...) tells every listener.
-- A listener that fails is reported and the others still run, so one broken screen can't stop
-- the sound settings or the key from being put back.
-- ---------------------------------------------------------------------------------------------
local listeners = {}

function ns.On(name, fn)
    local list = listeners[name]
    if not list then
        list = {}
        listeners[name] = list
    end
    list[#list + 1] = fn
end

function ns.Fire(name, ...)
    local list = listeners[name]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then
                handler(err)
            else
                error(err, 0)
            end
        end
    end
end

-- ---------------------------------------------------------------------------------------------
-- Game API that moved between client versions
-- ---------------------------------------------------------------------------------------------
function Util.ItemInfo(item)
    local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if f then return f(item) end
end

function Util.ItemInfoInstant(item)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if f then return f(item) end
end

function Util.ItemCount(item)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    return f and f(item) or 0
end

function Util.ItemIcon(item)
    local f = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    return f and f(item) or nil
end

-- Calls fn(bag, slot, itemID) for every item in the bags
function Util.EachBagSlot(fn)
    local numSlots = C_Container and C_Container.GetContainerNumSlots
    local itemAt = C_Container and C_Container.GetContainerItemID
    if not (numSlots and itemAt) then return end
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, numSlots(bag) or 0 do
            local itemID = itemAt(bag, slot)
            if itemID and not Util.Hidden(itemID) then
                fn(bag, slot, itemID)
            end
        end
    end
end

-- Whether the item is something to wear or wield. Newer clients give things that aren't an
-- "INVTYPE_NON_EQUIP..." kind rather than an empty one.
function Util.IsEquippable(itemID)
    local _, _, _, equipLoc = Util.ItemInfoInstant(itemID)
    return type(equipLoc) == "string" and equipLoc ~= "" and not equipLoc:find("NON_EQUIP", 1, true)
end

-- A toy the character has learned and doesn't carry: it needs the toy action to be used
function Util.IsToy(itemID)
    return Util.ItemCount(itemID) == 0 and PlayerHasToy ~= nil and PlayerHasToy(itemID) and true or false
end

-- Whether the character has the item: in the bags, or as a toy
function Util.Owns(itemID)
    if Util.ItemCount(itemID) > 0 then return true end
    return (PlayerHasToy and PlayerHasToy(itemID)) and true or false
end

function Util.SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    elseif GetSpellInfo then
        return (GetSpellInfo(spellID))
    end
end

function Util.GetCVar(name)
    local f = (C_CVar and C_CVar.GetCVar) or GetCVar
    return f and f(name) or nil
end

-- Sets a game setting only when it differs, and never throws. Returns true when it was changed.
function Util.SetCVar(name, value)
    local current = Util.GetCVar(name)
    if current == nil then return false end -- this client has no such setting
    value = tostring(value)
    if current == value then return false end
    if tonumber(current) and tonumber(current) == tonumber(value) then return false end
    local f = (C_CVar and C_CVar.SetCVar) or SetCVar
    return (pcall(f, name, value))
end

function Util.IsAddOnLoaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end

-- The Forever client can hide ("secret") some values from addons, and comparing or indexing a
-- hidden value is a Lua error. Check before touching anything read from loot or units.
-- Learned from Luredon (MIT), which guards its loot reads the same way; see CREDITS.md.
function Util.Hidden(value)
    if issecretvalue then
        return issecretvalue(value) and true or false
    end
    return false
end

-- ---------------------------------------------------------------------------------------------
-- Text
-- ---------------------------------------------------------------------------------------------
local GOLD, SILVER, COPPER = "|cffffd100g|r", "|cffc7c7cfs|r", "|cffeda55fc|r"

local function Thousands(n)
    local s = tostring(n)
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return out
end

-- 841234 -> "84g 12s", 1240 -> "12s 40c", 7 -> "7c", nil -> "-"
function Util.Money(copper)
    if not copper then return "-" end
    copper = math.floor(copper + 0.5)
    local g = math.floor(copper / 10000)
    local s = math.floor(copper % 10000 / 100)
    local c = copper % 100
    if g > 0 then
        return ("%s%s %d%s"):format(Thousands(g), GOLD, s, SILVER)
    elseif s > 0 then
        return ("%d%s %d%s"):format(s, SILVER, c, COPPER)
    end
    return ("%d%s"):format(c, COPPER)
end

-- 2537 -> "0:42:17"
function Util.Clock(seconds)
    seconds = math.floor(seconds or 0)
    return ("%d:%02d:%02d"):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
end

-- 2537 -> "0:42"
function Util.HoursMinutes(seconds)
    seconds = math.floor(seconds or 0)
    return ("%d:%02d"):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
end

-- 754 -> "12:34"
function Util.MinutesSeconds(seconds)
    seconds = math.floor(seconds or 0)
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

-- "23 Nov 14:02"
function Util.DateTime(timestamp)
    if not timestamp then return "-" end
    return date("%d %b %H:%M", timestamp)
end

-- "Name" from "Name-Realm"
function Util.ShortName(character)
    return character and character:match("^([^-]+)") or character or "?"
end

-- "[Raw Brilliant Smallfish]" inside an item link -> the name
function Util.LinkName(link)
    return type(link) == "string" and link:match("%[(.-)%]") or nil
end

function Util.Print(message)
    local text = "|cff4fc3f7Keepnet|r: " .. tostring(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

-- ---------------------------------------------------------------------------------------------
-- Sorting for the tables: by value(row), keeping the old order for equal values. Rows with no
-- value go last whichever way the column is sorted. Text is compared without regard to case.
-- ---------------------------------------------------------------------------------------------
function Util.Sort(rows, value, descending)
    local n = #rows
    local keyed = {}
    for i = 1, n do
        local key = value(rows[i])
        if type(key) == "string" then key = key:lower() end
        keyed[i] = { row = rows[i], key = key, index = i }
    end
    table.sort(keyed, function(a, b)
        local x, y = a.key, b.key
        if x == y then return a.index < b.index end
        if x == nil then return false end
        if y == nil then return true end
        if type(x) ~= type(y) then
            x, y = tostring(x), tostring(y)
            if x == y then return a.index < b.index end
        end
        if descending then
            return x > y
        end
        return x < y
    end)
    for i = 1, n do
        rows[i] = keyed[i].row
    end
    return rows
end
