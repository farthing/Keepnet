-- Keepnet: fishing lures. A lure is a temporary enchant on the fishing pole.
--   "LURES"  the lures available, or the chosen one, changed
--
-- Mode "auto" applies the strongest lure the character can use, "specific" applies the one the
-- player chose, "off" leaves lures alone. A lure is either an item in the bags, or a worn item
-- whose use puts a lure on the pole (such as the Wide-Brimmed Fishing Hat).
--
-- The list of known lure item IDs and the "red tooltip line means the character can't use it
-- yet" check come from FishyWashy by veiset. That a lure hat only works while worn is from
-- LibFishing (Fishing Buddy). See CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Lures = {}
ns.Lures = Lures

-- Known lures and their fishing bonus. Only a fallback: the number in the item's own tooltip
-- wins whenever it can be read, since this client's values may differ.
local KNOWN = {
    [68049] = 150,  -- Heat-Treated Spinning Lure
    [6533] = 100,   -- Aquadynamic Fish Attractor
    [34861] = 100,  -- Sharpened Fish Hook
    [46006] = 100,  -- Glow Worm
    [62673] = 100,  -- Feathered Lure
    [7307] = 75,    -- Flesh Eating Worm
    [6532] = 75,    -- Bright Baubles
    [291005] = 60,  -- Camper's Lure (5 minutes; new to this client)
    [6811] = 50,    -- Aquadynamic Fish Lens
    [6530] = 50,    -- Nightcrawlers
    [268880] = 25,  -- "Secret" Bait (new to this client)
    [6529] = 25,    -- Shiny Bauble
}

local MAIN_HAND_SLOT = 16
local FIRST_WORN_SLOT, LAST_WORN_SLOT = 1, 15
-- After a spell finishes, the enchant takes a moment to show on the pole. Don't offer the lure
-- again in that time, or the game asks whether to replace the lure that was just applied.
local SETTLE_SECONDS = 1

local lastCastEnd = 0

-- ---------------------------------------------------------------------------------------------
-- Reading item tooltips
-- ---------------------------------------------------------------------------------------------
local function TooltipLines(getter, ...)
    if not (C_TooltipInfo and C_TooltipInfo[getter]) then return nil end
    local ok, data = pcall(C_TooltipInfo[getter], ...)
    if ok and data and data.lines then return data.lines end
    return nil
end

-- The game's red, which tooltips use for a requirement the character doesn't meet
local function IsRed(color)
    return color and color.r and color.r > 0.99 and color.g < 0.2 and color.b < 0.2
end

-- The fishing bonus the tooltip promises ("Use: When applied to your fishing pole, increases
-- Fishing by 75 for 10 min."), false when the item isn't a lure, nil when it can't be read yet.
-- English wording only.
local function LinesBonus(lines)
    if not lines then return nil end
    for _, line in ipairs(lines) do
        local text = line.leftText
        if type(text) == "string" and not Util.Hidden(text) then
            local lower = text:lower()
            -- Only a "Use:" line counts: a spare fishing pole in the bags also says
            -- "fishing pole" (its name), and using it would swap poles
            if lower:match("^use:") and lower:find("fishing pole", 1, true) then
                local bonus = lower:match("fishing by (%d+)") or lower:match("fishing skill by (%d+)")
                    or lower:match("%+(%d+) fishing") or lower:match("(%d+)")
                return tonumber(bonus) or 1
            end
        end
    end
    return false
end

-- itemID -> bonus (number) or false (not a lure). Only filled once the tooltip could be read.
local bonusCache = {}

-- The fishing bonus of a lure, or nil when the item isn't one
function Lures.Bonus(itemID)
    local cached = bonusCache[itemID]
    if cached == nil then
        cached = LinesBonus(TooltipLines("GetItemByID", itemID))
        if cached ~= nil then bonusCache[itemID] = cached end
    end
    if cached then return cached end
    return KNOWN[itemID]
end

-- Whether the character can use it yet: most lures need some fishing skill, and the tooltip
-- shows that line in red until the skill is high enough. Assumed usable when unreadable.
function Lures.CanUse(itemID)
    for _, line in ipairs(TooltipLines("GetItemByID", itemID) or {}) do
        if line.leftText and IsRed(line.leftColor) then return false end
    end
    return true
end

-- ---------------------------------------------------------------------------------------------
-- The lures at hand
-- ---------------------------------------------------------------------------------------------
local available -- cached list, cleared when the bags or the equipment change

local function SlotReady(slot)
    if not GetInventoryItemCooldown then return true end
    local start, duration = GetInventoryItemCooldown("player", slot)
    return not (type(start) == "number" and type(duration) == "number" and start > 0 and duration > 1.5)
end

local function Scan()
    local list, seen = {}, {}
    Util.EachBagSlot(function(_, _, itemID)
        if seen[itemID] then return end
        seen[itemID] = true
        -- Clothing with a lure on it has to be worn first: "using" it from the bags would
        -- only put it on. The Gear option wears it; it is then found below.
        if Util.IsEquippable(itemID) then return end
        local bonus = Lures.Bonus(itemID)
        if bonus then
            list[#list + 1] = {
                id = itemID,
                bonus = bonus,
                count = Util.ItemCount(itemID),
                usable = Lures.CanUse(itemID),
            }
        end
    end)
    for slot = FIRST_WORN_SLOT, LAST_WORN_SLOT do
        local itemID = GetInventoryItemID("player", slot)
        if itemID and not Util.Hidden(itemID) and not seen[itemID] then
            local bonus = LinesBonus(TooltipLines("GetInventoryItem", "player", slot))
            if bonus then
                seen[itemID] = true
                list[#list + 1] = { id = itemID, bonus = bonus, count = 1, usable = SlotReady(slot), worn = slot }
            end
        end
    end
    -- Strongest first; the same strength keeps the one there is more of
    table.sort(list, function(a, b)
        if a.bonus ~= b.bonus then return a.bonus > b.bonus end
        if a.count ~= b.count then return a.count > b.count end
        return a.id < b.id
    end)
    return list
end

-- The lures in the bags and on the character, strongest first:
-- { id, bonus, count, usable, worn (the slot, for a worn item) }
function Lures.InBags()
    if not available then
        available = Scan()
    end
    -- A worn item's cooldown moves without any event
    for _, lure in ipairs(available) do
        if lure.worn then lure.usable = SlotReady(lure.worn) end
    end
    return available
end

local function Find(itemID)
    for _, lure in ipairs(Lures.InBags()) do
        if lure.id == itemID then return lure end
    end
end

-- The strongest lure the character can use now, or nil
function Lures.Best()
    for _, lure in ipairs(Lures.InBags()) do
        if lure.usable then return lure end
    end
end

-- ---------------------------------------------------------------------------------------------
-- The pole
-- ---------------------------------------------------------------------------------------------
-- Seconds left on the lure, or nil when none is applied
function Lures.TimeLeft()
    if not GetWeaponEnchantInfo then return nil end
    local hasEnchant, expiration = GetWeaponEnchantInfo()
    if hasEnchant and not Util.Hidden(expiration) and expiration then
        return expiration / 1000
    end
end

-- Casting something right now, such as the lure going on
function Lures.Casting()
    if not UnitCastingInfo then return false end
    local name = UnitCastingInfo("player")
    return (Util.Hidden(name) or name) and true or false
end

-- Casting, or only just finished
function Lures.Busy()
    return Lures.Casting() or GetTime() - lastCastEnd < SETTLE_SECONDS
end

local outNoticeFor -- the chosen lure the "run out" notice was last printed for

-- A lure that won't go on (moving, a requirement the tooltip doesn't show) must never stop the
-- fishing: after this many presses in a row that offered a lure and left the pole bare, the
-- next press casts without one.
local MAX_TRIES = 2
local tries = 0
local failNoticed = false

-- OneKey calls this for each key press that is about to apply a lure
function Lures.Offered()
    tries = tries + 1
end

-- The lure the next key press should apply instead of casting ({ id, worn, ... }), or nil to
-- cast
function Lures.ToApply()
    local settings = ns.settings
    if settings.lureMode == "off" then return nil end
    if Lures.TimeLeft() then
        tries, failNoticed = 0, false
        return nil
    end
    if Lures.Busy() then return nil end
    if tries >= MAX_TRIES then
        tries = 0
        if not failNoticed then
            failNoticed = true
            Util.Print("The lure didn't go on. Casting without it; the next press tries again.")
        end
        return nil
    end
    if settings.lureMode ~= "specific" then
        return Lures.Best()
    end
    local chosen = settings.lureItem
    if not chosen then return nil end
    local lure = Find(chosen)
    if lure then
        outNoticeFor = nil
        -- A worn lure item on cooldown: nothing to apply for now, and nothing has run out
        return lure.usable and lure or nil
    end
    if outNoticeFor ~= chosen then
        outNoticeFor = chosen
        local name = Util.ItemInfo(chosen) or "Your chosen lure"
        if settings.lureFallback then
            Util.Print(name .. " has run out. Using the best lure you have instead.")
        else
            Util.Print(name .. " has run out. Casting without a lure.")
        end
    end
    if settings.lureFallback then
        return Lures.Best()
    end
    return nil
end

-- The macro that uses the lure and then clicks it onto the main hand: the item from the bags,
-- or the worn item by its slot. Same method as FishyWashy's bait buttons; see CREDITS.md.
function Lures.ApplyMacro(lure)
    local use = lure.worn and tostring(lure.worn) or ("item:" .. lure.id)
    return "/use " .. use .. "\n/use " .. MAIN_HAND_SLOT
end

function Lures.SetSpecific(itemID)
    ns.settings.lureItem = itemID
    outNoticeFor = nil
    ns.Fire("LURES")
    ns.Fire("SETTINGS")
end

-- How lures are applied: "auto", "specific" or "off". Turning them off remembers how they
-- were applied, for the live panel's button that turns them back on.
function Lures.SetMode(mode)
    local settings = ns.settings
    if mode == "off" and settings.lureMode ~= "off" then
        settings.lureModeBefore = settings.lureMode
    end
    settings.lureMode = mode
    outNoticeFor = nil
    ns.Fire("LURES")
    ns.Fire("SETTINGS")
end

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
events:SetScript("OnEvent", function(_, event)
    if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        available = nil
        if ns.db then ns.Fire("LURES") end
    else
        lastCastEnd = GetTime()
        -- Something was cast (the lure went on, or the line went out): count failures afresh
        if event == "UNIT_SPELLCAST_SUCCEEDED" then tries = 0 end
    end
end)
