-- Keepnet: what a catch is worth. No frames, so the rules are tested outside the game
-- (tests\test_logic.lua) with stand-ins for the auction addons.
--
-- Rule for each item: the price from the auction addon the player chose; when it has none, or
-- the item is grey or binds when picked up (it can't be auctioned), the vendor price. An item
-- with neither has no price: it is left out of the total and counted, never counted as 0.
--
-- The rule (grey and bound items at vendor price, show "n without price") follows what
-- LootAppraiser, Haul and Luredon do; see CREDITS.md.
--
-- Price sources. Each auction addon is asked through the calls it publishes for other addons;
-- none of their code is in here. The player picks one, or "auto": the first in the list below
-- that is installed. A chosen source that isn't installed gives vendor prices only, and the
-- screens say so: it is never quietly swapped for another.
local _, ns = ...

local Prices = {}
ns.Prices = Prices

-- The auction house keeps 5 % of a sale. Off by default: the figure is "potential gold".
Prices.AH_CUT = 0.05

local CALLER = "Keepnet" -- Auctionator wants the calling addon's name on every call

-- Calls a function of another addon. Those throw on arguments they don't like, and a bad item
-- must not break the session.
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    return nil
end

local function Copper(value)
    if type(value) == "number" and value > 0 then return value end
    return nil
end

local function ItemLink(item)
    if type(item.link) == "string" then return item.link end
    if item.id then return "item:" .. item.id end
end

-- ---------------------------------------------------------------------------------------------
-- Auctionator
-- ---------------------------------------------------------------------------------------------
local function AuctionatorCall(name, ...)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    return (Try(api and api[name], CALLER, ...))
end

function Prices.HasAuctionator()
    return (Auctionator and Auctionator.API and Auctionator.API.v1) and true or false
end

-- ---------------------------------------------------------------------------------------------
-- TradeSkillMaster: a price is asked for by the name of one of its price sources
-- ---------------------------------------------------------------------------------------------
local function TSMPrice(source)
    return function(item)
        if not TSM_API then return nil end
        local itemString = type(item.link) == "string" and Try(TSM_API.ToItemString, item.link)
        if not itemString and item.id then itemString = "i:" .. item.id end
        if not itemString then return nil end
        return Copper((Try(TSM_API.GetCustomPriceValue, source, itemString)))
    end
end

local function HasTSM()
    return type(TSM_API) == "table" and type(TSM_API.GetCustomPriceValue) == "function"
end

-- ---------------------------------------------------------------------------------------------
-- The sources, in the order "auto" tries them
--   key        saved in the settings
--   name       shown to the player; short is for table cells
--   available  whether the addon is loaded
--   price      copper for one, or nil
--   age        days since the price was seen, or nil (only where the addon tells)
-- ---------------------------------------------------------------------------------------------
Prices.SOURCES = {
    {
        key = "auctionator", name = "Auctionator", short = "Auctionator",
        available = Prices.HasAuctionator,
        price = function(item)
            local price
            if type(item.link) == "string" then
                price = AuctionatorCall("GetAuctionPriceByItemLink", item.link)
            end
            if not price and item.id then
                price = AuctionatorCall("GetAuctionPriceByItemID", item.id)
            end
            return Copper(price)
        end,
        age = function(item)
            if item.id then return AuctionatorCall("GetAuctionAgeByItemID", item.id) end
        end,
    },
    {
        key = "tsm-market", name = "TradeSkillMaster: market value", short = "TSM market",
        available = HasTSM, price = TSMPrice("DBMarket"),
    },
    {
        key = "tsm-minbuyout", name = "TradeSkillMaster: lowest buyout", short = "TSM min buyout",
        available = HasTSM, price = TSMPrice("DBMinBuyout"),
    },
    {
        key = "tsm-region", name = "TradeSkillMaster: region market average", short = "TSM region",
        available = HasTSM, price = TSMPrice("DBRegionMarketAvg"),
    },
    {
        key = "auctioneer", name = "Auctioneer", short = "Auctioneer",
        available = function()
            return type(AucAdvanced) == "table" and type(AucAdvanced.API) == "table"
                and type(AucAdvanced.API.GetMarketValue) == "function"
        end,
        price = function(item)
            local link = ItemLink(item)
            if not (link and AucAdvanced and AucAdvanced.API) then return nil end
            return Copper((Try(AucAdvanced.API.GetMarketValue, link)))
        end,
    },
    {
        -- aux for this client publishes its prices; the classic aux does not
        key = "aux-latest", name = "aux: latest price", short = "aux latest",
        available = function()
            return type(AuxForeverAPI) == "table" and type(AuxForeverAPI.GetLatestPrice) == "function"
        end,
        price = function(item)
            return Copper((Try(AuxForeverAPI.GetLatestPrice, item.link or item.id)))
        end,
        age = function(item)
            local _, age = Try(AuxForeverAPI.GetLatestPrice, item.link or item.id)
            return type(age) == "number" and math.floor(age) or nil
        end,
    },
    {
        key = "aux-usual", name = "aux: usual price", short = "aux usual",
        available = function()
            return type(AuxForeverAPI) == "table" and type(AuxForeverAPI.GetUsualPrice) == "function"
        end,
        price = function(item)
            return Copper((Try(AuxForeverAPI.GetUsualPrice, item.link or item.id)))
        end,
    },
    {
        key = "recrystallize", name = "RECrystallize", short = "RECrystallize",
        available = function()
            return type(RECrystallize_PriceCheck) == "function" or type(RECrystallize_PriceCheckItemID) == "function"
        end,
        price = function(item)
            local price
            if type(item.link) == "string" then
                price = Try(RECrystallize_PriceCheck, item.link)
            end
            if not price and item.id then
                price = Try(RECrystallize_PriceCheckItemID, item.id)
            end
            return Copper(price)
        end,
    },
    {
        key = "oribos", name = "Oribos Exchange", short = "Oribos Exchange",
        available = function() return type(OEMarketInfo) == "function" end,
        price = function(item)
            local link = ItemLink(item)
            if not link then return nil end
            local info = {}
            Try(OEMarketInfo, link, info)
            return Copper(info.market) or Copper(info.region)
        end,
    },
}

local function FindSource(key)
    for _, source in ipairs(Prices.SOURCES) do
        if source.key == key then return source end
    end
end

-- The source in use: the one the player chose, or for "auto" the first that is installed.
-- Returns the source (nil for vendor prices only) and whether the player's own choice is
-- missing (chosen, but that addon isn't loaded).
function Prices.Source(settings)
    local choice = settings and settings.priceSource or "auto"
    if choice == "vendor" then return nil, false end
    if choice ~= "auto" then
        local source = FindSource(choice)
        if source and Try(source.available) then return source, false end
        return nil, true
    end
    for _, source in ipairs(Prices.SOURCES) do
        if Try(source.available) then return source, false end
    end
    return nil, false
end

-- What the drop-down offers: { { value, text } }. Addons that aren't installed are marked.
function Prices.Choices()
    local auto = Prices.Source({ priceSource = "auto" })
    local choices = {
        { value = "auto", text = "Automatic" .. (auto and (" (" .. auto.name .. ")") or " (no auction addon found)") },
    }
    for _, source in ipairs(Prices.SOURCES) do
        local installed = Try(source.available)
        choices[#choices + 1] = { value = source.key, text = source.name .. (installed and "" or "  (not installed)") }
    end
    choices[#choices + 1] = { value = "vendor", text = "Vendor prices only" }
    return choices
end

-- A line for the screens: where prices come from now
function Prices.Describe(settings)
    local source, missing = Prices.Source(settings)
    if source then return source.name, true end
    if missing then
        local chosen = FindSource(settings.priceSource)
        return (chosen and chosen.name or "The chosen price addon") .. " isn't loaded: vendor prices only", false
    end
    if settings and settings.priceSource == "vendor" then return "Vendor prices only", true end
    return "No auction addon found: vendor prices only", false
end

-- Where the numbers come from. Replaced in the tests.
Prices.provider = {
    -- Copper for one, from the chosen auction addon, or nil
    auction = function(item, settings)
        local source = Prices.Source(settings)
        if source then return source.price(item) end
    end,
    -- Copper a vendor pays for one, or nil
    vendor = function(item)
        if item.sell and item.sell > 0 then return item.sell end
        if item.id then
            return AuctionatorCall("GetVendorPriceByItemID", item.id)
        end
    end,
    -- Days since the price was last seen on the auction house, or nil
    age = function(item, settings)
        local source = Prices.Source(settings)
        if source and source.age then return source.age(item) end
    end,
}

-- The price of one, and where it came from ("auction" or "vendor"); nil, nil when unknown
function Prices.Unit(item, settings)
    local vendorOnly = item.quality == 0 or item.bind
    if not vendorOnly then
        local price = Prices.provider.auction(item, settings)
        if price and price > 0 then
            if settings and settings.auctionCut then
                price = price * (1 - Prices.AH_CUT)
            end
            return price, "auction"
        end
    end
    local price = Prices.provider.vendor(item)
    if price and price > 0 then
        return price, "vendor"
    end
    return nil, nil
end

function Prices.Age(item, settings)
    return Prices.provider.age(item, settings)
end

-- A session's catch as table rows { item, id, name, link, icon, quality, count, unit, total,
-- source }, with the total in copper and how many different items have no price.
--
-- A catch that was opened (a trunk, a clam) no longer counts at its own price: the row keeps
-- its count and says how many were opened (row.opened), and only the ones left are valued.
-- What came out of them follows as rows of its own (row.from = "opened"), and the coins as
-- one row (row.money = true); both are in the total.
function Prices.Rows(session, settings)
    local rows, total, unpriced = {}, 0, 0
    local function Add(item, left, from)
        local unit, source = Prices.Unit(item, settings)
        local sum
        if left <= 0 then
            source = "opened" -- all of them opened: nothing left to price
        elseif unit then
            sum = math.floor(unit * left + 0.5)
            total = total + sum
        else
            unpriced = unpriced + 1
        end
        rows[#rows + 1] = {
            item = item,
            id = item.id,
            name = item.name or (type(item.link) == "string" and item.link:match("%[(.-)%]")) or ("item " .. tostring(item.id)),
            link = item.link,
            icon = item.icon,
            quality = item.quality,
            count = item.count,
            opened = (not from and (item.opened or 0) > 0) and item.opened or nil,
            unit = unit,
            total = sum,
            source = source,
            from = from,
        }
    end
    for _, item in pairs(session.items or {}) do
        Add(item, item.count - (item.opened or 0))
    end
    for _, item in pairs(session.opened or {}) do
        Add(item, item.count, "opened")
    end
    if (session.money or 0) > 0 then
        total = total + session.money
        rows[#rows + 1] = { money = true, name = "Coins", total = session.money, source = "coins", from = "opened" }
    end
    return rows, total, unpriced
end

function Prices.SessionValue(session, settings)
    local _, total, unpriced = Prices.Rows(session, settings)
    return total, unpriced
end
