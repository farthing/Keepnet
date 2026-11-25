-- The session and price rules on their own, with no game around them.
local T = {}

function T.run(ns)
    local Util, Sessions, Prices = ns.Util, ns.Sessions, ns.Prices
    local MIN = 60

    -- ------------------------------------------------------------------------------ text
    eq(Util.Money(841234), "84|cffffd100g|r 12|cffc7c7cfs|r", "gold and silver")
    eq(Util.Money(12345678), "1,234|cffffd100g|r 56|cffc7c7cfs|r", "thousands of gold")
    eq(Util.Money(1240), "12|cffc7c7cfs|r 40|cffeda55fc|r", "silver and copper")
    eq(Util.Money(7), "7|cffeda55fc|r", "copper only")
    eq(Util.Money(nil), "-", "no price")
    eq(Util.Clock(2537), "0:42:17", "clock")
    eq(Util.HoursMinutes(4200), "1:10", "hours and minutes")
    eq(Util.MinutesSeconds(754), "12:34", "minutes and seconds")
    eq(Util.ShortName("Tester-Realm"), "Tester", "short name")
    eq(Util.LinkName("|cffffffff|Hitem:1::|h[Raw Fish]|h|r"), "Raw Fish", "link name")

    -- --------------------------------------------------------------------------- sorting
    local rows = { { n = "b", v = 2 }, { n = "A", v = nil }, { n = "c", v = 9 }, { n = "a", v = 2 } }
    Util.Sort(rows, function(r) return r.v end, false)
    eq(rows[1].n .. rows[2].n .. rows[3].n .. rows[4].n, "bacA", "ascending, equal values keep their order, empty last")
    Util.Sort(rows, function(r) return r.v end, true)
    eq(rows[1].n, "c", "descending puts the highest first")
    eq(rows[4].n, "A", "empty stays last when descending")
    Util.Sort(rows, function(r) return r.n end, false)
    eq(rows[1].n:lower() .. rows[2].n:lower() .. rows[3].n .. rows[4].n, "aabc", "text sorts without regard to case")

    -- -------------------------------------------------------------------------- sessions
    local settings = { sessionGap = 30, zoneSplit = true }
    local db = {}
    Sessions.Init(db, settings)
    local t = 1000000
    eq(Sessions.Current(), nil, "no session before the first cast")

    local first = Sessions.CastStarted(t, "Tanaris", "A-R")
    eq(first.casts, 1, "the first cast starts a session")
    eq(first.zone, "Tanaris", "session zone")
    Sessions.CastEnded(t + 15, "catch", { { id = 1, count = 2, name = "Eel", quality = 1 }, { id = 2, count = 1 } }, "Tanaris", "A-R")
    eq(first.catches, 1, "catch counted")
    eq(first.items[1].count, 2, "item count")
    eq(first.active, 15, "fishing time runs during the cast")

    Sessions.CastStarted(t + 20, "Tanaris", "A-R")
    Sessions.CastEnded(t + 40, "miss", nil, "Tanaris", "A-R")
    eq(first.casts, 2, "second cast in the same session")
    eq(first.misses, 1, "miss counted")
    eq(first.active, 40, "fishing time adds up")

    Sessions.CastStarted(t + 45, "Tanaris", "A-R")
    Sessions.CastEnded(t + 46, "recast", nil, "Tanaris", "A-R")
    eq(first.casts, 2, "a recast is not a cast")
    Sessions.CastStarted(t + 46, "Tanaris", "A-R")
    Sessions.CastEnded(t + 60, "catch", { { id = 1, count = 1 }, { hidden = true } }, "Tanaris", "A-R")
    eq(first.casts, 3, "the cast after a recast counts")
    eq(first.items[1].count, 3, "the same item adds up")
    eq(first.unknown, 1, "a hidden catch is counted as unknown")

    -- A break shorter than the session gap: same session, but the break isn't fishing time
    local before = first.active
    local same = Sessions.CastStarted(t + 60 + 10 * MIN, "Tanaris", "A-R")
    eq(same.id, first.id, "a 10 minute break keeps the session")
    eq(first.active, before, "a break over two minutes is not fishing time")

    -- A break longer than the gap: new session
    local second = Sessions.CastStarted(t + 60 + 10 * MIN + 31 * MIN, "Tanaris", "A-R")
    check(second.id ~= first.id, "a 31 minute break starts a new session")
    eq(Sessions.IsCurrent(second), true, "the new session is the current one")
    eq(Sessions.IsCurrent(first), false, "the old one is not")

    -- Another zone: new session
    local t2 = second.last + 30
    local third = Sessions.CastStarted(t2, "Azshara", "A-R")
    check(third.id ~= second.id, "another zone starts a new session")
    eq(third.zone, "Azshara", "zone of the new session")

    -- Zone split off: stays
    settings.zoneSplit = false
    local still = Sessions.CastStarted(t2 + 20, "Feralas", "A-R")
    eq(still.id, third.id, "with zone split off, another zone keeps the session")
    settings.zoneSplit = true

    -- Another character: new session
    local fourth = Sessions.CastStarted(t2 + 40, "Azshara", "B-R")
    check(fourth.id ~= third.id, "another character starts a new session")

    -- New session by hand; a session without casts is dropped
    Sessions.StartNew()
    eq(Sessions.Current(), nil, "New session ends the current one")
    eq(#Sessions.List(), 4, "four sessions so far")
    local empty = Sessions.CastStarted(t2 + 60, "Azshara", "B-R")
    Sessions.CastEnded(t2 + 60.2, "recast", nil, "Azshara", "B-R")
    eq(empty.casts, 0, "only a recast in it")
    Sessions.StartNew()
    eq(#Sessions.List(), 4, "a session with no casts is not kept")

    -- A catch whose cast wasn't seen (a /reload mid-cast) still has a cast
    local fifth = Sessions.CastEnded(t2 + 100, "catch", { { id = 3, count = 1 } }, "Azshara", "B-R")
    eq(fifth.casts, 1, "a catch always has a cast")
    eq(fifth.catches, 1, "the catch counted")

    -- The catch list of the live panel
    local caught = { unknown = 1, items = {
        [1] = { id = 1, count = 38, name = "Eel", quality = 1 },
        [2] = { id = 2, count = 30, link = "|cffffffff|Hitem:2::|h[Squid]|h|r" },
        [3] = { id = 3, count = 23, name = "Clam" },
        [4] = { id = 4, count = 8, name = "Bass" },
    } }
    local list, total = Sessions.CatchList(caught)
    eq(total, 100, "everything caught, hidden catches included")
    eq(#list, 5, "one row per item, and one for the hidden catches")
    eq(list[1].name, "Eel", "most caught first")
    eq(list[1].count, 38, "its count")
    eq(list[1].percent, 38, "its share of the catch")
    eq(list[2].name, "Squid", "the name comes from the link when there is no other")
    eq(list[5].unknown, true, "the hidden catches come last here")
    eq(list[5].percent, 1, "and have a share too")
    local shares = 0
    for _, row in ipairs(list) do shares = shares + row.percent end
    eq(shares, 100, "the shares add up to 100")
    list, total = Sessions.CatchList({ items = {} })
    eq(#list, 0, "nothing caught: an empty list")
    eq(total, 0, "and a total of 0")
    list = Sessions.CatchList({ items = { [9] = { id = 9, count = 2, name = "b" }, [8] = { id = 8, count = 2, name = "A" } } })
    eq(list[1].name, "A", "equal counts go by name")

    -- Searching the history for a fish: the zones where it made up most of the catch
    local saved = db
    local history = { sessions = {
        { zone = "Tanaris", unknown = 0, items = {
            [1] = { id = 1, count = 30, name = "Stonescale Eel", quality = 1 },
            [2] = { id = 2, count = 70, name = "Raw Summer Bass" } } },
        { zone = "Tanaris", unknown = 0, items = {
            [1] = { id = 1, count = 20, link = "|cffffffff|Hitem:1::|h[Stonescale Eel]|h|r" },
            [2] = { id = 2, count = 80, name = "Raw Summer Bass" } } },
        { zone = "Azshara", unknown = 10, items = {
            [1] = { id = 1, count = 60, name = "Stonescale Eel" },
            [3] = { id = 3, count = 30, name = "Darkclaw Lobster" } } },
        { zone = "Feralas", unknown = 0, items = {
            [1] = { id = 1, count = 1, name = "Stonescale Eel" } } },
        { zone = "Feralas", unknown = 0, items = {
            [4] = { id = 4, count = 1, name = "Big-mouth Clam" } } },
    } }
    Sessions.Init(history, settings)
    local hits = Sessions.FindCatches("stonescale")
    eq(#hits, 3, "one row for each zone the fish was caught in")
    eq(hits[1].zone, "Azshara", "the zone where it was the largest share of the catch comes first")
    eq(hits[1].percent, 60, "60 of the 100 things caught there (hidden catches count in the total)")
    eq(hits[1].count, 60, "how many were caught there")
    eq(hits[1].total, 100, "out of how many")
    eq(hits[2].zone, "Feralas", "then the next highest share")
    eq(hits[2].percent, 50, "1 of 2 caught there")
    eq(hits[2].total, 2, "which the total shows to be very few")
    eq(hits[3].zone, "Tanaris", "then the lowest")
    eq(hits[3].percent, 25, "added up over both sessions there: 50 of 200")
    eq(hits[3].sessions, 2, "caught in two sessions there")
    eq(hits[3].zoneSessions, 2, "of two")
    eq(hits[2].sessions, 1, "in Feralas, caught in one session")
    eq(hits[2].zoneSessions, 2, "of two")
    eq(hits[3].name, "Stonescale Eel", "the name is found whether saved or only in the link")
    eq(#Sessions.FindCatches("  EEL "), 3, "any case, and spaces round it don't matter")
    eq(#Sessions.FindCatches("a"), 6, "part of a name finds every item that has it, zone by zone")
    eq(#Sessions.FindCatches("lobster"), 1, "a fish caught in one zone only")
    eq(#Sessions.FindCatches("salmon"), 0, "nothing by that name")
    eq(#Sessions.FindCatches(""), 0, "an empty search finds nothing")
    eq(#Sessions.FindCatches(nil), 0, "nor does no search")
    eq(#Sessions.FindCatches("%"), 0, "odd characters are just text")
    Sessions.Init(saved, settings)

    -- Lists
    eq(Sessions.List()[1].id, fifth.id, "newest first")
    eq(#Sessions.List("Tanaris"), 2, "listing one zone")
    local names = Sessions.ZoneNames()
    eq(table.concat(names, ","), "Azshara,Tanaris", "zone names, A to Z")

    -- Zones added up
    local zones = Sessions.Zones(function(session) return session.catches * 1000 end)
    local tanaris
    for _, row in ipairs(zones) do
        if row.zone == "Tanaris" then tanaris = row end
    end
    eq(tanaris.sessions, 2, "sessions in the zone")
    eq(tanaris.catches, 2, "catches in the zone")
    eq(tanaris.value, 2000, "gold in the zone")

    -- Per hour
    eq(Sessions.PerHour(1000, 30), nil, "no per-hour figure in the first minute")
    eq(Sessions.PerHour(1000, 1800), 2000, "per hour")

    -- Delete
    eq(Sessions.Delete(fifth.id), true, "delete")
    eq(Sessions.Current(), nil, "deleting the current session leaves none")
    eq(#Sessions.List(), 4, "one fewer after delete")
    eq(Sessions.Delete(99999), false, "deleting one that isn't there")

    -- ---------------------------------------------------------------------------- waters
    local Waters = ns.Waters
    local guaranteed, minimum = Waters.Skill("Tanaris")
    eq(guaranteed, 300, "Tanaris: skill for guaranteed catches")
    eq(minimum, 205, "Tanaris: least skill to cast")
    guaranteed, minimum = Waters.Skill("Elwynn Forest")
    eq(guaranteed, 25, "a starting zone")
    eq(minimum, 1, "can be fished from skill 1")
    eq(Waters.Skill("Azshara"), 300, "Azshara")
    eq(Waters.Skill("Azshara", "Bay of Storms"), 425, "a harder water inside a zone")
    eq(Waters.Skill("Azshara", "Some Beach"), 300, "an ordinary part of the zone")
    eq(Waters.Skill("Nowhere"), nil, "an unknown zone has no number")
    eq(Waters.Skill("Silithus"), 425, "one of the hardest zones")
    eq(Waters.Skill("Stranglethorn Vale"), 225, "Stranglethorn")
    eq(Waters.Skill("Stranglethorn Vale", "Jaguero Isle"), 300, "its harder island")
    eq(Waters.Skill("Stranglethorn Vale", "Zul'Gurub"), 225, "the ruins outside the raid are ordinary Stranglethorn")
    eq(Waters.Skill("Zul'Gurub"), 425, "inside the raid it is the hardest water")
    eq(Waters.Skill("Zephras Isle"), nil, "a zone new to this client has no published number")
    eq(Waters.Skill(nil), nil, "no zone, no number")
    eq(Waters.Standing(300, 300), "ok", "enough skill: guaranteed")
    eq(Waters.Standing(250, 300), "some", "castable, but fish get away")
    eq(Waters.Standing(204, 300), "none", "too low to cast")

    -- ---------------------------------------------------------------------------- prices
    local auction = { [1] = 5000, [2] = 300, [4] = 9000, [5] = 100 }
    local vendor = { [1] = 40, [2] = 5, [3] = 12, [4] = 33, [5] = 0 }
    local saved = Prices.provider
    Prices.provider = {
        auction = function(item) return auction[item.id] end,
        vendor = function(item) return vendor[item.id] end,
        age = function() return 2 end,
    }
    local price, source = Prices.Unit({ id = 1, quality = 1 })
    eq(price, 5000, "auction price")
    eq(source, "auction", "auction source")
    price, source = Prices.Unit({ id = 3, quality = 1 })
    eq(price, 12, "no auction price: vendor price")
    eq(source, "vendor", "vendor source")
    price, source = Prices.Unit({ id = 4, quality = 0 })
    eq(price, 33, "a grey item counts at the vendor price even with an auction price")
    price, source = Prices.Unit({ id = 1, quality = 1, bind = true })
    eq(price, 40, "an item that binds counts at the vendor price")
    price, source = Prices.Unit({ id = 6, quality = 1 })
    eq(price, nil, "no price at all")
    eq(source, nil, "no source")
    price = Prices.Unit({ id = 5, quality = 1, bind = true })
    eq(price, nil, "a vendor price of 0 is no price")
    price = Prices.Unit({ id = 1, quality = 1 }, { auctionCut = true })
    eq(price, 4750, "5% auction cut")
    price = Prices.Unit({ id = 3, quality = 1 }, { auctionCut = true })
    eq(price, 12, "no cut on vendor prices")

    local session = { items = {
        [1] = { id = 1, count = 3, quality = 1, name = "Eel" },
        [3] = { id = 3, count = 10, quality = 1, name = "Bass" },
        [6] = { id = 6, count = 2, quality = 1, name = "Clam" },
    } }
    local priced, total, unpriced = Prices.Rows(session)
    eq(#priced, 3, "one row per item")
    eq(total, 3 * 5000 + 10 * 12, "session total")
    eq(unpriced, 1, "items without a price are counted, not added as 0")
    local value, missing = Prices.SessionValue(session, { auctionCut = true })
    eq(value, 3 * 4750 + 10 * 12, "session total with the cut")
    eq(missing, 1, "still one without a price")
    Prices.provider = saved

    -- The real provider against the fake Auctionator (which rejects bad arguments)
    Stub.auction[13422] = 41800
    price, source = Prices.Unit({ id = 13422, quality = 1, link = Stub.link(13422) })
    eq(price, 41800, "Auctionator price by link")
    price, source = Prices.Unit({ id = 13422, quality = 1 })
    eq(price, 41800, "Auctionator price by ID")
    price, source = Prices.Unit({ id = 13756, quality = 1, sell = 5 })
    eq(price, 5, "falls back to the item's vendor price")
    eq(source, "vendor", "vendor source from the real provider")
    price = Prices.Unit({ id = 13756, quality = 1 })
    eq(price, 5, "falls back to Auctionator's vendor price")
    Stub.auctionAge[13422] = 3
    eq(Prices.Age({ id = 13422 }), 3, "price age")
    local realApi = Auctionator.API.v1.GetAuctionPriceByItemID
    Auctionator.API.v1.GetAuctionPriceByItemID = function() error("boom") end
    price = Prices.Unit({ id = 13756, quality = 1 })
    eq(price, 5, "an error inside Auctionator doesn't break pricing")
    Auctionator.API.v1.GetAuctionPriceByItemID = realApi
    local keep = Auctionator
    Auctionator = nil
    eq(Prices.HasAuctionator(), false, "Auctionator missing is noticed")
    price, source = Prices.Unit({ id = 13422, quality = 1, sell = 40 })
    eq(price, 40, "without Auctionator: vendor price")
    Auctionator = keep

    -- -------------------------------------------------------------- the choice of auction addon
    local eel = { id = 13422, quality = 1, sell = 40, link = Stub.link(13422) }
    local function From(choice)
        local unit, from = Prices.Unit(eel, { priceSource = choice })
        return unit, from
    end
    eq(Prices.Source({ priceSource = "auto" }).key, "auctionator", "automatic: the first one installed")
    eq(Prices.Source({}).key, "auctionator", "no choice saved yet: automatic")
    eq(From("auto"), 41800, "automatic prices from Auctionator")
    eq(From("auctionator"), 41800, "Auctionator chosen")

    -- TradeSkillMaster isn't installed yet
    local chosen, missing = Prices.Source({ priceSource = "tsm-market" })
    eq(chosen, nil, "a chosen addon that isn't installed gives no source")
    eq(missing, true, "and is reported as missing")
    price, source = From("tsm-market")
    eq(price, 40, "its prices fall to the vendor price, not to another addon")
    eq(source, "vendor", "and say so")
    local text, fine = Prices.Describe({ priceSource = "tsm-market" })
    eq(fine, false, "the screens are told")
    check(text:find("TradeSkillMaster", 1, true) and text:find("isn't loaded", 1, true), "by name")

    -- Now it is: each of its price kinds is its own choice
    local asked = {}
    TSM_API = {
        ToItemString = function(link) return "i:" .. link:match("item:(%d+)") end,
        GetCustomPriceValue = function(kind, itemString)
            asked[#asked + 1] = kind .. " " .. itemString
            if kind == "DBRegionMarketAvg" then error("no region data") end
            return ({ DBMarket = 50000, DBMinBuyout = 45000 })[kind]
        end,
    }
    eq(From("tsm-market"), 50000, "TradeSkillMaster market value")
    eq(asked[#asked], "DBMarket i:13422", "asked for by its own price name and item form")
    eq(From("tsm-minbuyout"), 45000, "TradeSkillMaster lowest buyout")
    price, source = From("tsm-region")
    eq(price, 40, "a price kind it can't give falls to the vendor price")
    eq(Prices.Unit({ id = 13422, quality = 1 }, { priceSource = "tsm-market" }), 50000, "an item without a link is asked by ID")
    eq(From("auto"), 41800, "automatic still prefers Auctionator while it is installed")

    -- aux for this client: a price and how many days old it is
    AuxForeverAPI = {
        GetLatestPrice = function(thing) return tostring(thing):find("13422") and 36000 or nil, 2.4 end,
        GetUsualPrice = function() return 35000 end,
    }
    eq(From("aux-latest"), 36000, "aux: the latest price")
    eq(From("aux-usual"), 35000, "aux: the usual price")
    eq(Prices.Age(eel, { priceSource = "aux-latest" }), 2, "aux tells how old its price is")
    eq(Prices.Unit({ id = 13422, quality = 1 }, { priceSource = "aux-latest" }), 36000, "asked by ID when there is no link")

    -- Auctioneer, RECrystallize, Oribos Exchange
    AucAdvanced = { API = { GetMarketValue = function(link) return link:find("13422") and 39000 or nil, 12 end } }
    eq(From("auctioneer"), 39000, "Auctioneer")
    RECrystallize_PriceCheck = function(link) return link:find("13422") and 38000 or nil end
    eq(From("recrystallize"), 38000, "RECrystallize")
    OEMarketInfo = function(_, info) info.market, info.region = 0, 37000 end
    eq(From("oribos"), 37000, "Oribos Exchange: the region price when the realm has none")

    -- Vendor only
    price, source = From("vendor")
    eq(price, 40, "vendor prices only")
    eq(source, "vendor", "from the vendor")
    eq(select(2, Prices.Describe({ priceSource = "vendor" })), true, "which is a choice, not a problem")

    -- With Auctionator gone, automatic moves on to the next one installed
    Auctionator = nil
    eq(Prices.Source({ priceSource = "auto" }).key, "tsm-market", "automatic moves to the next installed addon")
    eq(From("auto"), 50000, "and prices from it")
    eq(Prices.Age(eel, { priceSource = "auto" }), nil, "an addon that doesn't tell a price's age gives none")
    TSM_API, AucAdvanced, RECrystallize_PriceCheck, OEMarketInfo, AuxForeverAPI = nil, nil, nil, nil, nil
    eq(Prices.Source({ priceSource = "auto" }), nil, "no auction addon at all: no source")
    text, fine = Prices.Describe({ priceSource = "auto" })
    eq(fine, false, "which the screens are told too")
    Auctionator = keep

    -- The drop-down
    local choices = Prices.Choices()
    eq(choices[1].value, "auto", "the list starts with automatic")
    check(choices[1].text:find("Auctionator", 1, true), "naming what automatic is using")
    eq(choices[#choices].value, "vendor", "and ends with vendor prices only")
    local marked
    for _, choice in ipairs(choices) do
        if choice.value == "tsm-market" then marked = choice.text:find("not installed", 1, true) end
    end
    check(marked, "an addon that isn't installed is marked")
end

return T
