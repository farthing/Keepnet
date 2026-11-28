-- Keepnet: who teaches Fishing and who sells tackle, zone by zone. Pure data and lookups, no
-- frames.
--
-- Each row is one person: { id (the NPC's number), name, kind ("trainer", "vendor" or "both"),
-- title (the line under the name in the game), side ("A" Alliance only, "H" Horde only, "N"
-- anyone), zone (its English name, as the game reports it), x, y (where they stand on the
-- zone's map; left out where it isn't confirmed), sells (for vendors: which tackle), note }.
--
-- The facts come from Wowhead's data for this client (see CREDITS.md): who trains Fishing, who
-- sells a fishing pole or a lure, and where they stand. Nothing here was measured in the game.
local _, ns = ...

local Anglers = {}
ns.Anglers = Anglers

local DATA = {
    { id = 2810, name = "Hammon Karwn", kind = "vendor", title = "Superior Tradesman", side = "A", zone = "Arathi Highlands", x = 46.4, y = 47.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 2821, name = "Keena", kind = "vendor", title = "Trade Goods", side = "H", zone = "Arathi Highlands", x = 74.0, y = 32.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 3954, name = "Dalria", kind = "vendor", title = "Trade Goods", side = "A", zone = "Ashenvale", x = 35.0, y = 52.0, sells = "pole, nightcrawlers, bright baubles" },
    { id = 12961, name = "Kil'Hiwana", kind = "trainer", title = "Fisherman", side = "H", zone = "Ashenvale", x = 10.8, y = 33.4 },
    { id = 3955, name = "Shandrina", kind = "vendor", title = "Trade Goods", side = "A", zone = "Ashenvale", x = 49.4, y = 67.0, sells = "pole, nightcrawlers, bright baubles" },
    { id = 12962, name = "Wik'Tar", kind = "vendor", title = "Fish Merchant & Supplies", side = "H", zone = "Ashenvale", x = 11.8, y = 34.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 12957, name = "Blimo Gadgetspring", kind = "vendor", title = "Trade Supplier", side = "N", zone = "Azshara", x = 45.2, y = 90.8, sells = "pole, nightcrawlers, bright baubles" },
    { id = 6301, name = "Gorbold Steelhand", kind = "vendor", title = "General Trade Supplier", side = "A", zone = "Darkshore", x = 38.0, y = 41.2, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 10216, name = "Gubber Blump", kind = "vendor", side = "A", zone = "Darkshore", x = 36.0, y = 44.8, sells = "pole, bauble" },
    { id = 4194, name = "Ullanna", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Darkshore", x = 43.8, y = 76.4, sells = "pole, bauble, nightcrawlers" },
    { id = 4156, name = "Astaia", kind = "trainer", title = "Fishing Trainer", side = "A", zone = "Darnassus", x = 47.4, y = 56.4 },
    { id = 4229, name = "Mythrin'dir", kind = "vendor", title = "General Trade Supplier", side = "A", zone = "Darnassus", x = 61.0, y = 17.4, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 4222, name = "Voloren", kind = "vendor", title = "Fishing Supplier", side = "A", zone = "Darnassus", x = 46.4, y = 56.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 9636, name = "Kireena", kind = "vendor", title = "Trade Goods", side = "H", zone = "Desolace", x = 51.0, y = 53.4, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 12032, name = "Lui'Mala", kind = "trainer", title = "Fisherman", side = "H", zone = "Desolace", x = 22.6, y = 72.6 },
    { id = 1692, name = "Golorn Frostbeard", kind = "vendor", title = "Tradesman", side = "A", zone = "Dun Morogh", x = 46.6, y = 53.4, sells = "pole, bauble" },
    { id = 8508, name = "Gretta Ganter", kind = "vendor", title = "Fisherman Supplies", side = "A", zone = "Dun Morogh", x = 31.4, y = 44.6, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 1700, name = "Paxton Ganter", kind = "trainer", title = "Fisherman", side = "A", zone = "Dun Morogh", x = 35.4, y = 40.2 },
    { id = 3168, name = "Flakk", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Durotar", x = 52.8, y = 42.0, sells = "pole, bauble" },
    { id = 5941, name = "Lau'Tiki", kind = "trainer", title = "Fisherman", side = "H", zone = "Durotar", x = 53.2, y = 81.4 },
    { id = 3187, name = "Tai'tasi", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Durotar", x = 56.4, y = 73.8, sells = "pole, bauble" },
    { id = 5942, name = "Zansoa", kind = "vendor", title = "Fishing Supplies", side = "H", zone = "Durotar", x = 56.0, y = 73.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 960, name = "Gunder Thornbush", kind = "vendor", title = "Tradesman", side = "A", zone = "Duskwood", x = 73.8, y = 45.0, sells = "nightcrawlers, bright baubles" },
    { id = 4897, name = "Helenia Olden", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Dustwallow Marsh", x = 66.4, y = 51.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 12919, name = "Nat Pagle", kind = "trainer", side = "N", zone = "Dustwallow Marsh", x = 58.4, y = 60.0, note = "Gives the quest for Artisan Fishing." },
    { id = 12941, name = "Jase Farlane", kind = "vendor", title = "Trade Supplies", side = "N", zone = "Eastern Plaguelands", x = 70.8, y = 48.2, sells = "pole, nightcrawlers, bright baubles" },
    { id = 1250, name = "Drake Lindgren", kind = "vendor", title = "General & Trade Supplies", side = "A", zone = "Elwynn Forest", x = 83.0, y = 66.4, sells = "pole, bauble" },
    { id = 1651, name = "Lee Brown", kind = "trainer", title = "Fisherman", side = "A", zone = "Elwynn Forest", x = 47.4, y = 62.2 },
    { id = 66, name = "Tharynn Bouden", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Elwynn Forest", x = 41.8, y = 67.0, sells = "pole, bauble" },
    { id = 7946, name = "Brannock", kind = "trainer", title = "Fisherman", side = "A", zone = "Feralas", x = 32.2, y = 41.4 },
    { id = 7945, name = "Savanne", kind = "vendor", title = "Fishing Supplies", side = "A", zone = "Feralas", x = 31.0, y = 46.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 8145, name = "Sheendra Tallgrass", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Feralas", x = 74.4, y = 42.8, sells = "pole, nightcrawlers, bright baubles" },
    { id = 7947, name = "Vivianna", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Feralas", x = 31.2, y = 43.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 2393, name = "Christoph Jeffcoat", kind = "vendor", title = "Tradesman", side = "H", zone = "Hillsbrad Foothills", x = 62.2, y = 19.0, sells = "nightcrawlers, bright baubles" },
    { id = 2367, name = "Donald Rabonne", kind = "trainer", title = "Fisherman", side = "A", zone = "Hillsbrad Foothills", x = 50.4, y = 61.0 },
    { id = 255877, name = "Hunter Moore", kind = "trainer", title = "Fisherman", side = "A", zone = "Hillsbrad Foothills", x = 54.0, y = 80.2 },
    { id = 2383, name = "Lindea Rabonne", kind = "vendor", title = "Tackle and Bait", side = "A", zone = "Hillsbrad Foothills", x = 50.0, y = 62.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 2381, name = "Micha Yance", kind = "vendor", title = "Trade Goods", side = "A", zone = "Hillsbrad Foothills", x = 49.0, y = 55.0, sells = "nightcrawlers, bright baubles" },
    { id = 5163, name = "Burbik Gearspanner", kind = "vendor", title = "Trade Supplier", side = "A", zone = "Ironforge", x = 46.4, y = 27.2, sells = "nightcrawlers, bright baubles" },
    { id = 5100, name = "Fillius Fizzlespinner", kind = "vendor", title = "Trade Supplier", side = "A", zone = "Ironforge", x = 38.4, y = 73.4, sells = "nightcrawlers, bright baubles" },
    { id = 5161, name = "Grimnur Stonebrand", kind = "trainer", title = "Fishing Trainer", side = "A", zone = "Ironforge", x = 48.2, y = 6.6 },
    { id = 5162, name = "Tansy Puddlefizz", kind = "vendor", title = "Fishing Supplier", side = "A", zone = "Ironforge", x = 47.8, y = 6.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 1465, name = "Drac Roughcut", kind = "vendor", title = "Tradesman", side = "A", zone = "Loch Modan", x = 35.4, y = 48.8, sells = "pole, bauble, nightcrawlers" },
    { id = 1684, name = "Khara Deepwater", kind = "vendor", title = "Fishing Supplies", side = "A", zone = "Loch Modan", x = 39.4, y = 39.2, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 1683, name = "Warg Deepwater", kind = "trainer", title = "Fisherman", side = "A", zone = "Loch Modan", x = 40.4, y = 39.4 },
    { id = 12022, name = "Lorelae Wintersong", kind = "vendor", title = "Trade Supplies", side = "N", zone = "Moonglade", x = 48.4, y = 40.2, sells = "pole, nightcrawlers, bright baubles" },
    { id = 5940, name = "Harn Longcast", kind = "vendor", title = "Fishing Supplies", side = "H", zone = "Mulgore", x = 46.6, y = 59.2, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 5938, name = "Uthan Stillwater", kind = "trainer", title = "Fisherman", side = "H", zone = "Mulgore", x = 44.2, y = 63.8 },
    { id = 3081, name = "Wunna Darkmane", kind = "vendor", title = "Trade Goods", side = "H", zone = "Mulgore", x = 45.4, y = 61.8, sells = "pole, bauble" },
    { id = 3367, name = "Felika", kind = "vendor", title = "General Trade Goods Merchant", side = "H", zone = "Orgrimmar", x = 53.4, y = 57.0, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 3332, name = "Lumak", kind = "trainer", title = "Fishing Trainer", side = "H", zone = "Orgrimmar", x = 69.4, y = 28.4 },
    { id = 3333, name = "Shankys", kind = "vendor", title = "Fishing Supplies", side = "H", zone = "Orgrimmar", x = 69.4, y = 29.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 5817, name = "Shimra", kind = "vendor", title = "General Trade Goods Merchant", side = "H", zone = "Orgrimmar", x = 47.8, y = 80.6, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 777, name = "Amy Davenport", kind = "vendor", title = "Tradeswoman", side = "A", zone = "Redridge Mountains", x = 23.8, y = 47.6, sells = "pole, bauble, nightcrawlers" },
    { id = 1680, name = "Matthew Hooper", kind = "trainer", title = "Fishing Trainer", side = "A", zone = "Redridge Mountains", x = 21.2, y = 50.4 },
    { id = 1678, name = "Vernon Hale", kind = "vendor", title = "Bait and Tackle Supplier", side = "A", zone = "Redridge Mountains", x = 22.2, y = 47.6, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 260559, name = "Gilliwigs", kind = "vendor", title = "Trade Goods", side = "N", zone = "Riverglades", x = 79.2, y = 54.6, sells = "pole, nightcrawlers, bright baubles" },
    { id = 260487, name = "Gritta Chumwater", kind = "vendor", title = "Fisherman", side = "N", zone = "Riverglades", x = 78.4, y = 55.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 260558, name = "Krix", kind = "trainer", title = "Superior Fisherman", side = "N", zone = "Riverglades", x = 79.2, y = 54.8 },
    { id = 255701, name = "Maralus", kind = "vendor", title = "Trade Goods", side = "N", zone = "Shen'dralas", x = 42.8, y = 78.8, sells = "pole, nightcrawlers, bright baubles" },
    { id = 15179, name = "Mishta", kind = "vendor", title = "General Trade Goods Vendor", side = "N", zone = "Silithus", x = 49.8, y = 36.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 3556, name = "Andrew Hilbert", kind = "vendor", title = "Trade Goods", side = "H", zone = "Silverpine Forest", x = 43.0, y = 40.4, sells = "pole, bauble, nightcrawlers" },
    { id = 12043, name = "Kulwia", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Stonetalon Mountains", x = 45.4, y = 59.4, sells = "pole, bauble, nightcrawlers" },
    { id = 5493, name = "Arnold Leland", kind = "trainer", title = "Fishing Trainer", side = "A", zone = "Stormwind City", x = 55.0, y = 69.4 },
    { id = 5494, name = "Catherine Leland", kind = "vendor", title = "Fishing Supplier", side = "A", zone = "Stormwind City", x = 55.0, y = 69.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 1286, name = "Edna Mullby", kind = "vendor", title = "Trade Supplier", side = "A", zone = "Stormwind City", x = 64.4, y = 71.4, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 2834, name = "Myizz Luckycatch", kind = "trainer", title = "Superior Fisherman", side = "N", zone = "Stranglethorn Vale", x = 27.4, y = 77.0 },
    { id = 1148, name = "Nerrist", kind = "vendor", title = "Trade Goods", side = "H", zone = "Stranglethorn Vale", x = 32.6, y = 29.2, sells = "pole, nightcrawlers, bright baubles" },
    { id = 2626, name = "Old Man Heming", kind = "vendor", title = "Fisherman", side = "N", zone = "Stranglethorn Vale", x = 27.4, y = 77.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor", note = "Also sells the book Expert Fishing - The Bass and You." },
    { id = 989, name = "Banalash", kind = "vendor", title = "Trade Goods", side = "H", zone = "Swamp of Sorrows", x = 44.4, y = 57.0, sells = "pole, nightcrawlers, bright baubles" },
    { id = 3607, name = "Androl Oakhand", kind = "trainer", title = "Fisherman", side = "A", zone = "Teldrassil", x = 55.8, y = 93.4 },
    { id = 3614, name = "Narret Shadowgrove", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Teldrassil", x = 55.2, y = 57.0, sells = "pole, bauble" },
    { id = 10118, name = "Nessa Shadowsong", kind = "vendor", title = "Fishing Supplies", side = "A", zone = "Teldrassil", x = 56.2, y = 92.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 3497, name = "Kilxx", kind = "vendor", title = "Fisherman", side = "N", zone = "The Barrens", x = 62.8, y = 38.2, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 3499, name = "Ranik", kind = "vendor", title = "Trade Supplies", side = "H", zone = "The Barrens", x = 61.8, y = 38.6, sells = "pole, bauble, nightcrawlers" },
    { id = 3482, name = "Tari'qa", kind = "vendor", title = "Trade Supplies", side = "H", zone = "The Barrens", x = 51.6, y = 30.0, sells = "pole, bauble, nightcrawlers" },
    { id = 3572, name = "Zizzek", kind = "vendor", title = "Fisherman", side = "H", zone = "The Barrens", x = 62.0, y = 39.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 12958, name = "Gigget Zipcoil", kind = "vendor", title = "Trade Supplies", side = "N", zone = "The Hinterlands", x = 34.4, y = 38.4, sells = "pole, nightcrawlers, bright baubles" },
    { id = 14740, name = "Katoom the Angler", kind = "both", title = "Fishing Trainer & Supplies", side = "H", zone = "The Hinterlands", x = 80.2, y = 81.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 4877, name = "Jandia", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Thousand Needles", x = 46.0, y = 51.4, sells = "nightcrawlers, bright baubles" },
    { id = 3028, name = "Kah Mistrunner", kind = "trainer", title = "Fishing Trainer", side = "H", zone = "Thunder Bluff", x = 55.8, y = 47.6 },
    { id = 3029, name = "Sewa Mistrunner", kind = "vendor", title = "Fishing Supplier", side = "H", zone = "Thunder Bluff", x = 55.2, y = 48.0, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 8363, name = "Shadi Mistrunner", kind = "vendor", title = "Trade Goods Supplier", side = "H", zone = "Thunder Bluff", x = 40.4, y = 63.4, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 2118, name = "Abigail Shiel", kind = "vendor", title = "Trade Supplies", side = "H", zone = "Tirisfal Glades", x = 61.0, y = 52.4, sells = "pole, bauble" },
    { id = 5690, name = "Clyde Kellen", kind = "trainer", title = "Fisherman", side = "H", zone = "Tirisfal Glades", x = 67.2, y = 51.0 },
    { id = 3550, name = "Martine Tramblay", kind = "vendor", title = "Fishing Supplies", side = "H", zone = "Tirisfal Glades", x = 65.8, y = 59.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 4573, name = "Armand Cromwell", kind = "trainer", title = "Fishing Trainer", side = "H", zone = "Undercity", x = 80.4, y = 31.2 },
    { id = 4561, name = "Daniel Bartlett", kind = "vendor", title = "General Trade Supplier", side = "H", zone = "Undercity", x = 64.0, y = 38.8, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 4775, name = "Felicia Doan", kind = "vendor", title = "General Trade Goods Vendor", side = "H", zone = "Undercity", x = 63.8, y = 49.2, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 4574, name = "Lizbeth Cromwell", kind = "vendor", title = "Fishing Supplier", side = "H", zone = "Undercity", x = 81.0, y = 29.2, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 8934, name = "Christopher Hewen", kind = "vendor", title = "General Trade Goods Vendor", side = "A", zone = "Westfall", x = 52.2, y = 52.8, sells = "pole, bauble, nightcrawlers, bright baubles" },
    { id = 843, name = "Gina MacGregor", kind = "vendor", title = "Trade Supplies", side = "A", zone = "Westfall", x = 57.4, y = 54.0, sells = "pole, bauble, nightcrawlers" },
    { id = 3179, name = "Harold Riggs", kind = "trainer", title = "Fishing Trainer", side = "A", zone = "Wetlands", x = 8.0, y = 58.4 },
    { id = 1456, name = "Kersok Prond", kind = "vendor", title = "Tradesman", side = "A", zone = "Wetlands", x = 10.4, y = 60.4, sells = "nightcrawlers, bright baubles" },
    { id = 3178, name = "Stuart Fleming", kind = "vendor", title = "Fisherman", side = "A", zone = "Wetlands", x = 8.0, y = 58.2, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 11189, name = "Qia", kind = "vendor", title = "Trade Goods Supplies", side = "N", zone = "Winterspring", x = 61.2, y = 37.2, sells = "pole, nightcrawlers, bright baubles" },
    { id = 3779, name = "Syurana", kind = "vendor", title = "Trade Goods Supplies", side = "A", zone = "Winterspring", x = 51.4, y = 29.8, sells = "pole, nightcrawlers, bright baubles" },
    { id = 257008, name = "Baelann Swiftcurrent", kind = "both", title = "Fisher", side = "N", zone = "Zephras Isle", x = 63.2, y = 75.4, sells = "pole, strong pole, bauble, nightcrawlers, bright baubles, attractor" },
    { id = 254360, name = "Belandiel Farflight", kind = "vendor", title = "Trade Supplies", side = "N", zone = "Zephras Isle", x = 44.8, y = 45.0, sells = "pole, bauble, nightcrawlers" },
    { id = 251992, name = "Fenn Fairweather", kind = "both", title = "Fisherman", side = "N", zone = "Zephras Isle", x = 45.0, y = 48.4, sells = "pole" },
    { id = 252449, name = "Iallion Featherfall", kind = "vendor", title = "Trade Supplies", side = "N", zone = "Zephras Isle", x = 58.8, y = 75.4, sells = "pole, bauble, nightcrawlers" },
}

local SIDE_NAMES = { A = "Alliance", H = "Horde" }
local KIND_ORDER = { trainer = 1, both = 2, vendor = 3 }

-- The side of the character being played: "A", "H", or nil when the game doesn't say (then
-- nobody is left out)
function Anglers.Side()
    local group = UnitFactionGroup and UnitFactionGroup("player")
    if group == "Alliance" then return "A" end
    if group == "Horde" then return "H" end
    return nil
end

-- "Alliance" or "Horde" for a side; nil for neither
function Anglers.SideName(side)
    return SIDE_NAMES[side]
end

-- Whether a character of that side can use this person
function Anglers.Serves(row, side)
    return side == nil or row.side == "N" or row.side == side
end

-- The people a character of that side can use, in one zone or (zone nil) in all of them: by
-- zone A to Z, the trainers before the vendors, then by name. side nil: everybody.
function Anglers.List(zone, side)
    local list = {}
    for _, row in ipairs(DATA) do
        if (zone == nil or row.zone == zone) and Anglers.Serves(row, side) then
            list[#list + 1] = row
        end
    end
    table.sort(list, function(a, b)
        if a.zone ~= b.zone then return a.zone < b.zone end
        if KIND_ORDER[a.kind] ~= KIND_ORDER[b.kind] then return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end
        return a.name < b.name
    end)
    return list
end

-- How many of them a zone has for that side
function Anglers.Count(zone, side)
    local count = 0
    for _, row in ipairs(DATA) do
        if row.zone == zone and Anglers.Serves(row, side) then count = count + 1 end
    end
    return count
end

-- What the person does, in words: "Trainer", "Vendor" or "Trainer and vendor"
function Anglers.Kind(row)
    if row.kind == "both" then return "Trainer and vendor" end
    return row.kind == "trainer" and "Trainer" or "Vendor"
end

-- "44.6, 60.2", or "" where the spot isn't confirmed
function Anglers.Where(row)
    if not (row.x and row.y) then return "" end
    return ("%.1f, %.1f"):format(row.x, row.y)
end
