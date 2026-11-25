-- Keepnet: sees casts and catches, and catches being opened afterwards (second half of the file).
--   "LINE"        the line went out or came in (true/false)
--   "CAST_START"  a cast went out
--   "CAST_END"    result, loot: "catch" with what was caught, "miss", or "recast"
--
-- How casts and fishing loot are recognised (the Fishing channel by spell name, loot read at
-- LOOT_READY or LOOT_OPENED while IsFishingLoot() is true, a short wait before a cast counts as
-- missed) was learned from FishyWashy by veiset. Written from scratch; see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Fishing = {}
ns.Fishing = Fishing

local FISHING_SPELL = 7620
-- Reeling in ends the channel just before the loot opens, so wait before calling it a miss
local LOOT_GRACE = 1
-- A new cast this soon after the old one stopped is a recast, not a miss
local RECAST_WINDOW = 0.3

local fishingName

-- The Fishing spell's name in the client's language; also what the cast button casts
function Fishing.Name()
    if not fishingName then
        fishingName = Util.SpellName(FISHING_SPELL)
    end
    return fishingName
end

-- Every rank of Fishing has the same name
function Fishing.IsFishingSpell(spellID)
    if not spellID or Util.Hidden(spellID) then return false end
    local name = Util.SpellName(spellID)
    return name ~= nil and name == Fishing.Name()
end

function Fishing.LineOut()
    if not UnitChannelInfo then return false end
    local name = UnitChannelInfo("player")
    if not name or Util.Hidden(name) then return false end
    return name == Fishing.Name()
end

-- The cast in the water: { started, stopped }
local cast

local function Finish(result, loot)
    cast = nil
    ns.Fire("CAST_END", result, loot)
end

local function OnChannelStart()
    if cast then
        -- Thrown again while the old line was still out, or right after it came in
        if not cast.stopped or GetTime() - cast.stopped < RECAST_WINDOW then
            Finish("recast")
        else
            Finish("miss")
        end
    end
    cast = { started = GetTime() }
    ns.Fire("CAST_START")
    ns.Fire("LINE", true)
end

local function OnChannelStop()
    ns.Fire("LINE", false)
    local this = cast
    if not this then return end
    this.stopped = GetTime()
    C_Timer.After(LOOT_GRACE, function()
        if cast == this then Finish("miss") end
    end)
end

-- One loot slot as { id, link, name, icon, quality, count }, { hidden = true } when the game
-- won't show it, or nil for money
local function ReadSlot(slot)
    local link = GetLootSlotLink(slot)
    if Util.Hidden(link) then return { hidden = true } end
    if type(link) ~= "string" then return nil end
    local id = tonumber(link:match("item:(%d+)"))
    if not id then return nil end
    local icon, name, quantity, _, quality = GetLootSlotInfo(slot)
    return {
        id = id,
        link = link,
        name = (not Util.Hidden(name)) and name or nil,
        icon = (not Util.Hidden(icon)) and icon or nil,
        quality = (not Util.Hidden(quality)) and quality or nil,
        count = (not Util.Hidden(quantity)) and tonumber(quantity) or 1,
    }
end

-- Opened.lua reads the loot of an opened catch the same way
Fishing.ReadSlot = ReadSlot

-- Set once the open loot has been read, until it closes
local lootRead = false

local function OnLoot()
    -- Only loot that came from a fishing cast: other loot picked up with the pole on is not
    -- a catch
    if lootRead or not IsFishingLoot or not IsFishingLoot() then return end
    lootRead = true
    local loot = {}
    for slot = 1, GetNumLootItems() do
        local ok, drop = pcall(ReadSlot, slot)
        if not ok then
            drop = { hidden = true }
        end
        if drop then loot[#loot + 1] = drop end
    end
    Finish("catch", loot)
end

local events = CreateFrame("Frame")
-- Fast-loot addons take everything at LOOT_READY, before LOOT_OPENED, so read at whichever
-- comes first
events:RegisterEvent("LOOT_READY")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_CLOSED")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
events:SetScript("OnEvent", function(_, event, _, _, spellID)
    if not ns.db then return end
    if event == "LOOT_READY" or event == "LOOT_OPENED" then
        OnLoot()
    elseif event == "LOOT_CLOSED" then
        lootRead = false
    elseif Fishing.IsFishingSpell(spellID) then
        if event == "UNIT_SPELLCAST_CHANNEL_START" then
            OnChannelStart()
        else
            OnChannelStop()
        end
    end
end)

-- ---------------------------------------------------------------------------------------------
-- Catches that are opened: a trunk, a chest, a clam, a bloated fish, a bottle. What comes
-- out counts towards the session the catch was made in (Core.Opened), whenever it is opened:
-- minutes later at the water, or days later in town.
--
-- How the game shows an opening, as seen on this client: opening an item in the bags brings
-- up an ordinary loot window (not fishing loot) whose source is the item itself, a GUID that
-- starts with "Item-"; the item leaves the bags once the window has been emptied.
--   1. A loot window that isn't fishing loot and comes from an item: which item is asked from
--      its GUID. If the game won't say, every catch in the bags that can be opened is
--      watched, and the one whose number goes down within a moment of the window closing is
--      taken to be it. The game sends a loot window more than once (LOOT_READY, LOOT_OPENED,
--      sometimes LOOT_READY again) and may name the source only on a later one, so each
--      sending is looked at.
--   2. Only an item that a session of this character caught, and hasn't seen opened yet,
--      counts. Anything else (a lockbox from a pocket, a bought clam) is left alone, and so
--      is anything worn: disenchanting a fished ring also shows as loot from an item.
--   3. Each thing taken out of the window is counted as it is taken (LOOT_SLOT_CLEARED);
--      when the item has left the bags everything in the window was taken, and the catch is
--      marked as opened. Coins are the change in the character's money between the window
--      opening and a moment after it closes, and only when the window held coins.
-- Windows are kept apart, since clams are opened one straight after another.
--
-- Not seen: a container that hands its contents over without a loot window. Some do on the
-- modern game; none of the classic ones fished here is known to.
--
-- That an opened chest shows as loot from an "Item-" source, and counting it once the item has
-- left the bags, was learned from Mastercraft by Shadowblade, which counts fished chests this
-- way on this client. Asking the game which item a source GUID is follows AllTheThings and
-- Everloot; that the source may only be named on a later loot event is Open Sesame's warning;
-- taking coins as the change in the character's money around the window is how
-- PickPocketTracker counts lockboxes. Written from scratch; see CREDITS.md.
-- ---------------------------------------------------------------------------------------------
local WAIT_SECONDS = 15    -- how long after its loot window closed an opened catch may take to leave the bags
local SETTLE_SECONDS = 0.5 -- coins arrive a moment after the loot window closes
-- When the game didn't say which item a loot window came from, the catch that leaves the bags
-- no later than this after the window closed is taken to be it. Kept short: a longer wait
-- would pin some other window's loot on the next catch to be opened.
local IDENTIFY_SECONDS = 2

local pending = {} -- loot windows of opened catches that aren't settled yet, oldest first
local openWindow   -- the one on screen now

-- Whether an item is one that is opened: it is listed as a chest, trunk or bloated fish, or
-- its tooltip carries the game's own "<Right Click to Open>" line
local OPENED_KINDS = { chest = true, trunk = true, bloated = true }
local openable = {}

local function Openable(itemID)
    local cached = openable[itemID]
    if cached ~= nil then return cached end
    local result = OPENED_KINDS[ns.Rares.Kind(itemID) or ""] or false
    if not result and ITEM_OPENABLE and C_TooltipInfo and C_TooltipInfo.GetItemByID then
        local ok, data = pcall(C_TooltipInfo.GetItemByID, itemID)
        if not (ok and data and data.lines) then return false end -- not readable yet: ask again
        for _, line in ipairs(data.lines) do
            local text = line.leftText
            if not Util.Hidden(text) and text == ITEM_OPENABLE then result = true end
        end
    end
    openable[itemID] = result
    return result
end

local function ItemOfGUID(guid)
    if C_Item and C_Item.GetItemIDByGUID then
        local ok, id = pcall(C_Item.GetItemIDByGUID, guid)
        if ok and not Util.Hidden(id) and type(id) == "number" then return id end
    end
    if C_Item and C_Item.GetItemLinkByGUID then
        local ok, link = pcall(C_Item.GetItemLinkByGUID, guid)
        if ok and not Util.Hidden(link) and type(link) == "string" then
            return tonumber(link:match("item:(%d+)"))
        end
    end
end

-- Where the loot on screen comes from: "item" and its item ID (nil when the game won't say
-- which), "other" for a corpse or something in the world, nil when the game doesn't say
local function LootSource()
    if not GetLootSourceInfo then return nil end
    for slot = 1, GetNumLootItems() do
        local ok, guid = pcall(GetLootSourceInfo, slot)
        if ok and not Util.Hidden(guid) and type(guid) == "string" then
            if not guid:find("^Item%-") then return "other" end
            return "item", ItemOfGUID(guid)
        end
    end
end

local function Money()
    local money = GetMoney and GetMoney()
    if Util.Hidden(money) or type(money) ~= "number" then return nil end
    return money
end

-- The coins a window gave: the change in the character's money since it opened
local function SettleCoins(window)
    if window.coinsGained ~= nil then return end
    local now = Money()
    window.coinsGained = (window.coins and now and window.money) and math.max(0, now - window.money) or 0
end

-- Counts what there is to count of one window. Returns true when the window is finished with.
local function Settle(window, now)
    local closed = window.closedAt and now - window.closedAt >= SETTLE_SECONDS - 0.01
    -- Has the catch left the bags? That also says which one it was, when the game didn't.
    if not window.gone then
        for id, had in pairs(window.counts) do
            if Util.ItemCount(id) < had and (not window.item or window.item == id) then
                window.item, window.gone = id, true
            end
        end
        -- The session is settled on once, here: by the time the coins arrive the catch may
        -- be marked as opened and no longer be found
        if window.item and not window.session then
            window.session = ns.Core.CaughtIn(window.item)
            if not window.session then return true end
        end
    end
    if closed then SettleCoins(window) end
    if window.session then
        local loot = {}
        for slot, drop in pairs(window.slots) do
            if not window.counted[slot] and (window.gone or window.taken[slot]) then
                window.counted[slot] = true
                loot[#loot + 1] = drop
            end
        end
        local coins = 0
        if window.coinsGained and not window.coinsCounted then
            window.coinsCounted = true
            coins = window.coinsGained
        end
        -- What came out first, then the catch itself
        if #loot > 0 or coins > 0 then
            ns.Core.Opened(window.session, loot, coins)
            if ns.LivePanel then
                ns.LivePanel.Notice(("|cff9d9d9d%s opened: added to %s|r"):format(
                    Util.ItemInfo(window.item) or "Catch",
                    ns.Sessions.IsCurrent(window.session) and "this session" or "the session it was caught in"), 6)
            end
        end
        if window.gone and not window.marked then
            window.marked = true
            ns.Core.OpenedGone(window.session, window.item)
        end
    end
    -- Finished: everything counted; or closed long enough ago that the catch isn't going to
    -- leave the bags (not everything was taken out of it); or, when it still isn't known which
    -- item this was, closed for longer than that item would take to leave them. A window
    -- still on screen is never given up on.
    if window.gone and window.coinsCounted then return true end
    local sinceClosed = window.closedAt and now - window.closedAt
    return sinceClosed and sinceClosed > (window.item and WAIT_SECONDS or IDENTIFY_SECONDS) or false
end

local function CheckOpened()
    local now = GetTime()
    local keep = {}
    for _, window in ipairs(pending) do
        -- (dead: the game said late that this window isn't from a catch after all)
        if not window.dead and not Settle(window, now) then
            keep[#keep + 1] = window
        end
    end
    pending = keep
end

-- Whether a loot slot holds coins. Without the game's own answer, a slot with no item in it
-- is taken to be coins the first time the window is read (later an empty slot is a taken one).
local MONEY_SLOT = Enum and Enum.LootSlotType and Enum.LootSlotType.Money or 2

local function IsCoins(slot, firstRead)
    if not GetLootSlotType then return firstRead end
    local ok, kind = pcall(GetLootSlotType, slot)
    return ok and not Util.Hidden(kind) and kind == MONEY_SLOT
end

-- Notes what the window holds. Called again when the game sends the window a second time:
-- only slots not seen before are added.
local function ReadWindow(window, firstRead)
    for slot = 1, GetNumLootItems() do
        if window.slots[slot] == nil and not window.taken[slot] then
            local ok, drop = pcall(ReadSlot, slot)
            if ok and drop and not drop.hidden then
                window.slots[slot] = drop
            elseif ok and not drop and IsCoins(slot, firstRead) then
                window.coins = true
            end
        end
    end
end

-- The session an item being opened was caught in, or nil when it doesn't count: nobody
-- fished it, or it is something to wear, which is never opened (taking a fished ring apart
-- for its dust shows up as loot from an item too).
local function SessionOf(itemID)
    if Util.IsEquippable(itemID) then return nil end
    return ns.Core.CaughtIn(itemID)
end

local function OnOtherLoot()
    if IsFishingLoot and IsFishingLoot() then return end
    if ns.Demo and ns.Demo.IsOn() then return end -- the sample sessions are not the player's
    local kind, itemID = LootSource()
    local window = openWindow
    if window then
        -- The same window again: the game sends both events, sometimes more than once, and
        -- may only now say where the loot is from
        if window.dead then return end
        if kind == "other" then
            window.dead = true
        elseif itemID and not window.item then
            local session = SessionOf(itemID)
            if session then
                window.item, window.session = itemID, session
                window.counts = { [itemID] = Util.ItemCount(itemID) }
            else
                window.dead = true
            end
        end
        if not window.dead then ReadWindow(window, false) end
        return
    end
    window = {
        at = GetTime(), money = Money(), coins = false,
        counts = {},  -- item ID -> how many were in the bags when the window opened
        slots = {},   -- loot slot -> what it held
        taken = {},   -- loot slot -> true once the player has taken it
        counted = {}, -- loot slot -> true once it has gone to a session
    }
    if kind == "other" then
        window.dead = true
    elseif itemID then
        window.item, window.session = itemID, SessionOf(itemID)
        if window.session then
            window.counts[itemID] = Util.ItemCount(itemID)
        else
            window.dead = true
        end
    else
        -- The game hasn't said which item: every catch in the bags that can be opened is
        -- watched, and the one that leaves them is it
        for id in pairs(ns.Sessions.UnopenedItems(ns.Core.Character())) do
            local have = Openable(id) and Util.ItemCount(id) or 0
            if have > 0 then window.counts[id] = have end
        end
        if not next(window.counts) then window.dead = true end
    end
    -- A window that doesn't count is still remembered while it is on screen, so that the
    -- game sending it again doesn't start it afresh
    openWindow = window
    if window.dead then return end
    -- Coins of the windows before this one are theirs up to now, not this one's
    for _, earlier in ipairs(pending) do SettleCoins(earlier) end
    window.money = Money()
    ReadWindow(window, true)
    pending[#pending + 1] = window
end

local opened = CreateFrame("Frame")
opened:RegisterEvent("LOOT_READY")
opened:RegisterEvent("LOOT_OPENED")
opened:RegisterEvent("LOOT_SLOT_CLEARED")
opened:RegisterEvent("LOOT_CLOSED")
opened:RegisterEvent("BAG_UPDATE_DELAYED")
opened:SetScript("OnEvent", function(_, event, slot)
    if not ns.db then return end
    if event == "LOOT_READY" or event == "LOOT_OPENED" then
        OnOtherLoot()
    elseif event == "LOOT_SLOT_CLEARED" then
        if openWindow and not Util.Hidden(slot) and type(slot) == "number" then
            openWindow.taken[slot] = true
        end
    elseif event == "LOOT_CLOSED" then
        if openWindow then
            openWindow.closedAt = GetTime()
            openWindow = nil
            C_Timer.After(SETTLE_SECONDS, CheckOpened)
            C_Timer.After(IDENTIFY_SECONDS + 0.1, CheckOpened)
            C_Timer.After(WAIT_SECONDS + 0.1, CheckOpened)
        end
    elseif #pending > 0 then
        CheckOpened()
    end
end)

-- After a /reload with the line out: the cast was already counted before the reload
ns.On("WORLD", function()
    if Fishing.LineOut() then
        if not cast then cast = { started = GetTime() } end
        ns.Fire("LINE", true)
    else
        cast = nil
        ns.Fire("LINE", false)
    end
end)
