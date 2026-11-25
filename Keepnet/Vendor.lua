-- Keepnet: buying lures. When a vendor's window opens and the vendor sells a lure the player
-- has ticked, Keepnet buys enough of it to have the number the player set in the bags. One
-- lure has a rule of its own, when the player wants it: every Aquadynamic Fish Attractor the
-- vendor has is bought, however many that is (vendors only ever have a few).
--
-- Everything here is off until the player turns it on (Gear & food tab), and it only ever
-- buys the lures named below. What was bought and what it cost is said in chat.
--
--   ns.settings.buyLures        the five basic lures are bought, those ticked
--   ns.settings.buyLureItems    which: { [item ID] = true }
--   ns.settings.buyLureCount    how many of each to have in the bags (20 unless changed)
--   ns.settings.buyAttractors   every Aquadynamic Fish Attractor a vendor has
--   ns.settings.buyLureFloor    gold that is never spent (0 unless changed): with this much
--                               or less nothing at all is bought, and with more, buying
--                               stops before the money would go under it
--
-- The numbers of the lures and which of them a vendor can sell on this client were checked
-- against Mastercraft's list and two guides for this client; see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Vendor = {}
ns.Vendor = Vendor

-- The five basic lures, weakest first, with the names they have in English (shown until
-- the game has told Keepnet the item's own name)
Vendor.LURES = {
    { id = 6529, name = "Shiny Bauble" },
    { id = 6530, name = "Nightcrawlers" },
    { id = 6811, name = "Aquadynamic Fish Lens" },
    { id = 6532, name = "Bright Baubles" },
    { id = 7307, name = "Flesh Eating Worm" },
}
Vendor.ATTRACTOR = { id = 6533, name = "Aquadynamic Fish Attractor" }

Vendor.DEFAULT_COUNT = 20
Vendor.MOST = 200 -- the most the number can be set to
Vendor.MOST_GOLD = 999999

-- The gold that is never spent, as the player set it
function Vendor.Floor()
    local floor = tonumber(ns.settings.buyLureFloor) or 0
    return math.max(0, math.min(Vendor.MOST_GOLD, math.floor(floor)))
end

-- The number the player set, kept within reason
function Vendor.Count()
    local count = tonumber(ns.settings.buyLureCount) or Vendor.DEFAULT_COUNT
    return math.max(1, math.min(Vendor.MOST, math.floor(count)))
end

local function Number(value)
    if Util.Hidden(value) or type(value) ~= "number" then return nil end
    return value
end

-- What the vendor sells in one place of its list: { id, price (for one), batch (how many a
-- purchase gives), available (nil when there is no limit), most (at once) }, or nil when it
-- can't be bought with coins or the game won't say enough
local function ItemAt(index)
    local id = GetMerchantItemID and Number(GetMerchantItemID(index))
    if not id then return nil end
    local price, batch, available, extended
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
        if not ok or type(info) ~= "table" then return nil end
        price, batch, available, extended = info.price, info.stackCount, info.numAvailable, info.hasExtendedCost
    elseif GetMerchantItemInfo then
        local _
        _, _, price, batch, available, _, _, extended = GetMerchantItemInfo(index)
    else
        return nil
    end
    price, batch, available = Number(price), Number(batch) or 1, Number(available)
    if not price or Util.Hidden(extended) or extended then return nil end
    if batch < 1 then batch = 1 end
    -- (the game says -1 for "as many as you like")
    if available and available < 0 then available = nil end
    local most = GetMerchantItemMaxStack and Number(GetMerchantItemMaxStack(index)) or 1
    return { id = id, price = price / batch, batch = batch, available = available, most = math.max(1, most) }
end

-- How many of an item to buy from this vendor, before money is looked at
local function Wanted(item, settings)
    if item.id == Vendor.ATTRACTOR.id then
        if not settings.buyAttractors then return 0 end
        -- Every one the vendor has. A vendor with no limit on them (none is known to have
        -- that) is treated like the other lures: up to the number in the bags.
        if item.available then return item.available end
        return math.max(0, Vendor.Count() - Util.ItemCount(item.id))
    end
    if not settings.buyLures or not (settings.buyLureItems and settings.buyLureItems[item.id]) then return 0 end
    for _, lure in ipairs(Vendor.LURES) do
        if lure.id == item.id then
            local want = math.max(0, Vendor.Count() - Util.ItemCount(item.id))
            if item.available then want = math.min(want, item.available) end
            return want
        end
    end
    return 0
end

-- Looks through the open vendor's list and buys what the player asked for. Returns how many
-- kinds of lure were bought.
function Vendor.Shop()
    local settings = ns.settings
    if not settings or not (settings.buyLures or settings.buyAttractors) then return 0 end
    if not (GetMerchantNumItems and BuyMerchantItem) then return 0 end
    local money = Number(GetMoney and GetMoney())
    if not money then return 0 end
    -- The gold the player keeps is never spent: what there is to spend is what lies above
    -- it. With that much or less, nothing is bought at all.
    local floor = Vendor.Floor() * 10000
    local budget = money - floor
    local bought, spent, short = {}, 0, {}
    for index = 1, Number(GetMerchantNumItems()) or 0 do
        local ok, item = pcall(ItemAt, index)
        if ok and item then
            local want = Wanted(item, settings)
            if want > 0 and floor > 0 and money <= floor then
                -- Said once, and only where there was something to buy
                Util.Print(("No lures bought: you have %s, and that is not more than the %s you keep."):format(
                    Util.Money(money), Util.Money(floor)))
                return 0
            end
            if want > 0 then
                local name = Util.ItemInfo(item.id) or ("item " .. item.id)
                -- A purchase gives one lure, or several where they are sold several at a
                -- time (then the last purchase may give a few more than were wanted)
                local each = item.price * item.batch
                local purchases = math.ceil(want / item.batch)
                local canPay = each > 0 and math.floor(budget / each) or purchases
                if canPay < purchases then
                    short[#short + 1] = name
                    purchases = math.max(0, canPay)
                end
                local got = 0
                while purchases > 0 do
                    -- (several at once only where a purchase is a single lure)
                    local now = item.batch > 1 and 1 or math.min(purchases, item.most)
                    BuyMerchantItem(index, now)
                    purchases = purchases - now
                    got = got + now * item.batch
                    budget, spent = budget - now * each, spent + now * each
                end
                if got > 0 then bought[#bought + 1] = ("%d %s"):format(got, name) end
            end
        end
    end
    if #bought > 0 then
        Util.Print(("Bought %s for %s."):format(table.concat(bought, ", "), Util.Money(spent)))
    end
    if #short > 0 then
        Util.Print((floor > 0 and ("Not enough money above the %s you keep for all the lures: "):format(Util.Money(floor))
            or "Not enough money for all the lures: ") .. table.concat(short, ", "))
    end
    return #bought
end

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:SetScript("OnEvent", function()
    if not ns.db then return end
    local ok, err = pcall(Vendor.Shop)
    if not ok then Util.Print("Buying lures stopped on an error: " .. tostring(err)) end
end)
