-- Keepnet: helpers shared by every file.
-- Nothing here creates frames, so the session and price logic can run outside the game
-- (tests\run_tests.py).
local ADDON, ns = ...
ns.ADDON = ADDON or "Keepnet"
ns.VERSION = "1.2.16"

local Util = {}
ns.Util = Util

-- ---------------------------------------------------------------------------------------------
-- Messages between files: ns.On("NAME", fn) listens, ns.Fire("NAME", ...) tells every listener.
-- A listener that fails is reported and the others still run, so one broken screen can't stop
-- the sound settings or the key from being put back.
-- ---------------------------------------------------------------------------------------------
local listeners = {}

-- ---------------------------------------------------------------------------------------------
-- The log: one line for everything Keepnet does (every message between its files, every line
-- it prints, every purchase it weighs up), the newest LOG_MOST of them. Kept in the saved data
-- so it survives a reload; the Settings tab has a button that shows it for copying. It never
-- leaves the game by itself.
-- ---------------------------------------------------------------------------------------------
local LOG_MOST = 1500
local log = {}
-- Fired many times a minute with nothing to tell
local LOG_QUIET = { TICK = true }

local function Plain(value)
    local kind = type(value)
    if kind == "string" then return value end
    if kind == "number" or kind == "boolean" or kind == "nil" then return tostring(value) end
    return "<" .. kind .. ">"
end

function ns.Log(...)
    local parts = {}
    for i = 1, select("#", ...) do
        -- (a value the game hides can't even be looked at)
        local ok, text = pcall(Plain, (select(i, ...)))
        parts[i] = ok and text or "<hidden>"
    end
    local stamp = date and date("%m-%d %H:%M:%S") or ""
    log[#log + 1] = stamp .. "  " .. table.concat(parts, " ")
    while #log > LOG_MOST do table.remove(log, 1) end
end

-- Continues in the saved table (what was logged before it was known is carried over)
function ns.LogKeepIn(saved)
    if type(saved) ~= "table" then return end
    for _, line in ipairs(log) do saved[#saved + 1] = line end
    while #saved > LOG_MOST do table.remove(saved, 1) end
    log = saved
end

-- Everything logged, oldest first, as one text; and how many lines that is
function ns.LogText()
    return table.concat(log, "\n"), #log
end

function ns.LogClear()
    for i = #log, 1, -1 do log[i] = nil end
end

function ns.On(name, fn)
    local list = listeners[name]
    if not list then
        list = {}
        listeners[name] = list
    end
    list[#list + 1] = fn
end

function ns.Fire(name, ...)
    if not LOG_QUIET[name] then ns.Log("event", name, ...) end
    local list = listeners[name]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then
            ns.Log("ERROR in a listener of", name, tostring(err))
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
-- ---------------------------------------------------------------------------------------------
-- The three colours text uses to say good, careful and bad ("ok", "some", "none"): green,
-- yellow and red, or those of the colour blind set chosen on the Settings tab (the same choice
-- the bobber mark follows; "game" takes the game's own colour blind mode). Lighter than the
-- mark's own colours where those would be hard to read as small text on a dark window.
-- ---------------------------------------------------------------------------------------------
local TONES = {
    normal = { ok = "40ff40", some = "ffd100", none = "ff6060" },
    -- sky blue, yellow, vermillion
    protanopia = { ok = "57b5e8", some = "f0e342", none = "e8742a" },
    deuteranopia = { ok = "57b5e8", some = "f0e342", none = "e8742a" },
    -- cyan, pink, red
    tritanopia = { ok = "4fd1d1", some = "ffa1c7", none = "ff5050" },
    -- by brightness alone
    mono = { ok = "ffffff", some = "b0b0b0", none = "808080" },
}
local GAME_TONES = { [1] = "protanopia", [2] = "deuteranopia", [3] = "tritanopia" }

function ns.Tone(kind)
    local key = (ns.settings and ns.settings.bobberPalette) or "normal"
    if key == "game" then
        local filter = tonumber(Util.GetCVar and Util.GetCVar("colorblindSimulator") or "")
        key = GAME_TONES[filter or 0] or "normal"
    end
    return (TONES[key] or TONES.normal)[kind] or "ffffff"
end

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
    ns.Log("said", tostring(message))
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
