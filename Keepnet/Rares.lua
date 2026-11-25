-- Keepnet: the catches that are rare and come from fishing: the list behind the rare-catch
-- alert. Pure data and a lookup, no frames.
--
-- Item quality alone doesn't find these: the trophy fish, the quest fish and Message in a Bottle
-- are ordinary white items, and the named coins are grey. So they are listed here by item ID,
-- in kinds the player can turn on and off in the Alerts tab.
--
-- Where the list comes from (2026-11-23; see CREDITS.md):
--   - every ID and name was checked against the public item data for this client (Wowhead's
--     Forever tooltips);
--   - which items are fished, where and how rarely: the classic loot tables as rebuilt by the
--     CMaNGOS project, and catches logged on this client and shared by the One Key Fishing
--     addon. Trophy fish run from about 1 catch in 150 down to 1 in 10,000; The 1 Ring and
--     the fish weapons about 1 in 2,000; the open-water chests and crates 1 in 200 to 500.
-- Left out on purpose: things that are valuable but common where they live (Stonescale Eel,
-- the seasonal fish), things often thought fished that aren't (fishing poles, the Lucky
-- Fishing Hat, the Shiny Silver Coin), and world drops that merely turn up in catches.
local _, ns = ...

local Rares = {}
ns.Rares = Rares

-- The kinds, in the order the Alerts tab shows them. on = alerted unless the player says not.
Rares.KINDS = {
    { key = "trophy", text = "Trophy fish (the \"N Pound\" ones)", on = true },
    { key = "gear", text = "Gear only fishing gives", on = true },
    { key = "quest", text = "Message in a Bottle, quest catches", on = true },
    { key = "tournament", text = "Tournament fish", on = true },
    { key = "bloated", text = "Bloated fish (they hold gems)", on = true },
    { key = "chest", text = "Chests and crates from open water", on = true },
    { key = "coin", text = "Named coins", on = true },
    { key = "trunk", text = "Trunks (common at wreckage)", on = false },
}

local LISTS = {
    trophy = {
        6292,  -- 10 Pound Mud Snapper
        6294,  -- 12 Pound Mud Snapper
        6295,  -- 15 Pound Mud Snapper
        6309,  -- 17 Pound Catfish
        6310,  -- 19 Pound Catfish
        6311,  -- 22 Pound Catfish
        6363,  -- 26 Pound Catfish
        6364,  -- 32 Pound Catfish
        13876, -- 40 Pound Yellowtail
        13877, -- 47 Pound Yellowtail
        13878, -- 53 Pound Yellowtail
        13879, -- 59 Pound Yellowtail
        13880, -- 68 Pound Yellowtail
        13885, -- 34 Pound Redgill
        13886, -- 37 Pound Redgill
        13882, -- 42 Pound Redgill
        13883, -- 45 Pound Redgill
        13884, -- 49 Pound Redgill
        13887, -- 52 Pound Redgill
        13901, -- 15 Pound Salmon
        13902, -- 18 Pound Salmon
        13903, -- 22 Pound Salmon
        13904, -- 25 Pound Salmon
        13905, -- 29 Pound Salmon
        13906, -- 32 Pound Salmon
        13907, -- 7 Pound Lobster
        13908, -- 9 Pound Lobster
        13909, -- 12 Pound Lobster
        13910, -- 15 Pound Lobster
        13911, -- 19 Pound Lobster
        13912, -- 21 Pound Lobster
        13913, -- 22 Pound Lobster
        13914, -- 70 Pound Mightfish
        13915, -- 85 Pound Mightfish
        13916, -- 92 Pound Mightfish
        13917, -- 103 Pound Mightfish
    },
    gear = {
        8350,  -- The 1 Ring
        6360,  -- Steelscale Crushfish
        19808, -- Rockhide Strongfish (tournament pools only)
    },
    quest = {
        6307,   -- Message in a Bottle (opens for recipes and scrolls)
        274974, -- Message in a Bottle (the one new to this client; where it is caught isn't known)
        16967,  -- Feralas Ahi
        16968,  -- Sar'theris Striker
        16969,  -- Savage Coast Blue Sailfin
        16970,  -- Misty Reed Mahi Mahi
        1467,   -- Spotted Sunfish
        6718,   -- Electropeller
        6717,   -- Gaffer Jack
    },
    tournament = {
        19803, -- Brownell's Blue Striped Racer
        19805, -- Keefer's Angelfish
        19806, -- Dezian Queenfish
    },
    bloated = {
        6643,  -- Bloated Brilliant Smallfish
        6644,  -- Bloated Mackerel
        6645,  -- Bloated Mud Snapper
        6646,  -- Bloated Albacore
        6647,  -- Bloated Bristle Whisker Catfish
        8366,  -- Bloated Mithril Head Trout
        13881, -- Bloated Redgill
        13891, -- Bloated Whitescale Salmon
        21162, -- Bloated Oily Blackmouth
        21163, -- Bloated Firefin Snapper
        21164, -- Bloated Rockscale Cod
        21243, -- Bloated Glossy Mightfish
    },
    chest = {
        6353,  -- Small Chest
        6351,  -- Dented Crate
        6354,  -- Small Locked Chest
        6352,  -- Waterlogged Crate
        6355,  -- Sturdy Locked Chest
        6357,  -- Sealed Crate
        13875, -- Ironbound Locked Chest
        13874, -- Heavy Crate
        13918, -- Reinforced Locked Chest
    },
    -- New to this client: grey coins named after people. One has been reported fished.
    coin = {
        286263, 286264, 286265, 286266, 286267, 286268, 286270, 286271, 286272, 286273, 286274, 286275,
        286328, -- the silver ones (Muradin Bronzebeard's Silver Coin ... Elaadrin Evengale's)
        286279, 286280, 286281, 286283, 286284, 286287, 286288, 286290, 286291, 286292, 286293, 286294,
        286298, 286299, 286300, 286302, 286327, -- the gold ones (Anduin Wrynn's Gold Coin ... Rhonin's)
        286304, 286306, 286307, 286308, 286309, 286310, 286311, 286312, 286313, 286314, 286315, 286316,
        286317, 286318, -- the copper ones (A Footman's Copper Coin ... Sair's)
    },
    trunk = {
        6356,  -- Battered Chest (about 1 catch in 50 on the starter coasts)
        20708, -- Tightly Sealed Trunk
        21113, -- Watertight Trunk
        21150, -- Iron Bound Trunk
        21228, -- Mithril Bound Trunk
    },
}

local kindOf = {}
for kind, ids in pairs(LISTS) do
    for _, id in ipairs(ids) do
        kindOf[id] = kind
    end
end

-- The kind an item is listed under ("trophy", "gear" ...), or nil when it isn't listed
function Rares.Kind(itemID)
    return kindOf[itemID]
end

-- What to call a kind in a message: "trophy fish"
local LABELS = {
    trophy = "trophy fish", gear = "fishing-only gear", quest = "quest catch",
    tournament = "tournament fish", bloated = "bloated fish", chest = "chest",
    coin = "named coin", trunk = "trunk",
}
function Rares.Label(kind)
    return LABELS[kind] or kind
end

-- How many items are listed, for the Alerts tab
function Rares.Count()
    local n = 0
    for _ in pairs(kindOf) do n = n + 1 end
    return n
end
