-- Keepnet: sample sessions, for trying the screens out or taking pictures of them before there
-- is any history of your own. /kn demo turns them on, /kn demo again turns them off.
--
-- The sample sessions live in a table of their own. The player's saved sessions are never
-- touched, and nothing caught while the samples are showing is saved. Prices are the real ones
-- from the player's auction addon, so the gold figures are whatever those items are worth here.
local _, ns = ...
local Util, Sessions, Core = ns.Util, ns.Sessions, ns.Core

local Demo = {}
ns.Demo = Demo

local active = false

-- The character the sample sessions belong to. Core.Character() gives this name while they show,
-- so a cast made meanwhile carries on the running sample session and no real name is on screen.
Demo.CHARACTER = "Vale"

-- zone (nil = where the character is now), hours ago, minutes of fishing, casts, empty casts,
-- then what was caught: { item ID, name, count, quality (1 unless given) }
-- and, for a session whose catches were opened: { opened = { [catch's item ID] = how many },
-- out = { what came out of them, written as a catch is }, money = the coins, in copper }
local SAMPLE = {
    { "Wetlands", 170, 38, 120, 9, {
        { 6308, "Raw Bristle Whisker Catfish", 41 }, { 6361, "Raw Rainbow Fin Albacore", 38 },
        { 6358, "Oily Blackmouth", 22 }, { 6359, "Firefin Snapper", 7 }, { 6307, "Message in a Bottle", 1 },
        { 6354, "Small Locked Chest", 1 }, { 6310, "19 Pound Catfish", 1 } } },
    { "Stranglethorn Vale", 122, 55, 190, 21, {
        { 6359, "Firefin Snapper", 62 }, { 6358, "Oily Blackmouth", 48 }, { 6362, "Raw Rockscale Cod", 39 },
        { 4603, "Raw Spotted Yellowtail", 15 }, { 6355, "Sturdy Locked Chest", 1 },
        { 8366, "Bloated Mithril Head Trout", 1, 2 } } },
    { "Tanaris", 98, 72, 250, 12, {
        { 4603, "Raw Spotted Yellowtail", 96 }, { 13422, "Stonescale Eel", 58 },
        { 13754, "Raw Glossy Mightfish", 44 }, { 7973, "Big-mouth Clam", 21 }, { 13755, "Raw Winter Squid", 16 },
        { 13876, "40 Pound Yellowtail", 2 }, { 13875, "Ironbound Locked Chest", 1 } },
        { opened = { [7973] = 21, [13875] = 1 }, money = 34120, out = {
            { 7974, "Zesty Clam Meat", 17 }, { 5500, "Iridescent Pearl", 3, 2 }, { 7971, "Black Pearl", 2, 2 },
            { 13926, "Golden Pearl", 1, 2 }, { 4338, "Mageweave Cloth", 4 } } } },
    { "Feralas", 74, 41, 140, 15, {
        { 13758, "Raw Redgill", 73 }, { 8365, "Raw Mithril Head Trout", 31 },
        { 13759, "Raw Nightfin Snapper", 17 }, { 13874, "Heavy Crate", 2 }, { 13885, "34 Pound Redgill", 1 },
        { 13881, "Bloated Redgill", 1, 2 } } },
    { "Azshara", 50, 88, 300, 34, {
        { 13888, "Darkclaw Lobster", 71 }, { 13893, "Large Raw Mightfish", 64 }, { 13422, "Stonescale Eel", 49 },
        { 13755, "Raw Winter Squid", 38 }, { 13754, "Raw Glossy Mightfish", 31 }, { 7973, "Big-mouth Clam", 11 },
        { 13907, "7 Pound Lobster", 1 }, { 13918, "Reinforced Locked Chest", 1 } } },
    { "Tanaris", 27, 64, 220, 9, {
        { 4603, "Raw Spotted Yellowtail", 81 }, { 13422, "Stonescale Eel", 66 },
        { 13754, "Raw Glossy Mightfish", 37 }, { 7973, "Big-mouth Clam", 18 }, { 13755, "Raw Winter Squid", 9 } } },
    { "Winterspring", 20, 33, 110, 19, {
        { 13889, "Raw Whitescale Salmon", 52 }, { 13760, "Raw Sunscale Salmon", 21 }, { 13757, "Lightning Eel", 12 },
        { 13890, "Raw Plated Armorfish", 5 }, { 13901, "15 Pound Salmon", 1 } } },
    { "Azshara", 3, 47, 160, 14, {
        { 13888, "Darkclaw Lobster", 40 }, { 13893, "Large Raw Mightfish", 33 }, { 13422, "Stonescale Eel", 28 },
        { 13755, "Raw Winter Squid", 24 }, { 7973, "Big-mouth Clam", 8 }, { 13908, "9 Pound Lobster", 1 },
        { 13914, "70 Pound Mightfish", 1 } } },
    -- The one that is running, where the character stands
    { nil, 0.35, 21, 74, 5, {
        { 4603, "Raw Spotted Yellowtail", 27 }, { 13422, "Stonescale Eel", 19 },
        { 13754, "Raw Glossy Mightfish", 13 }, { 7973, "Big-mouth Clam", 6 }, { 13755, "Raw Winter Squid", 3 },
        { 13877, "47 Pound Yellowtail", 1 } },
        { opened = { [7973] = 4 }, out = { { 7974, "Zesty Clam Meat", 3 }, { 7971, "Black Pearl", 1, 2 } } } },
}

local function Build()
    local now = time()
    local character = Core.Character()
    local store = { sessions = {}, nextId = 1, current = {} }
    for index, sample in ipairs(SAMPLE) do
        local zone, hoursAgo, minutes, casts, empty, catch, openings = unpack(sample)
        local running = index == #SAMPLE
        local started = math.floor(now - hoursAgo * 3600)
        local session = {
            id = store.nextId, char = character, zone = zone or Core.Zone(),
            started = started, active = minutes * 60, casts = casts, misses = empty,
            catches = casts - empty, unknown = 0, items = {},
        }
        -- A point of Fishing skill every dozen catches or so
        session.skillUps = math.floor(session.catches / 12)
        session.ended = running and now or (started + minutes * 60 + 180)
        session.last = session.ended
        for _, entry in ipairs(catch) do
            session.items[entry[1]] = {
                id = entry[1], name = entry[2], count = entry[3], quality = entry[4] or 1,
                icon = Util.ItemIcon(entry[1]),
            }
        end
        if openings then
            session.opened, session.money = {}, openings.money
            for id, count in pairs(openings.opened) do session.items[id].opened = count end
            for _, entry in ipairs(openings.out) do
                session.opened[entry[1]] = {
                    id = entry[1], name = entry[2], count = entry[3], quality = entry[4] or 1,
                    icon = Util.ItemIcon(entry[1]),
                }
            end
        end
        store.sessions[#store.sessions + 1] = session
        if running then store.current[character] = session.id end
        store.nextId = store.nextId + 1
    end
    return store
end

function Demo.IsOn()
    return active
end

-- Shows the sample sessions, or goes back to the player's own
function Demo.Toggle()
    if active then
        active = false
        Sessions.Init(ns.db, ns.settings)
        Sessions.SetCharacter(Core.Character())
        Util.Print("Sample sessions off. Your own sessions are back, untouched.")
    else
        active = true
        Sessions.Init(Build(), ns.settings)
        Sessions.SetCharacter(Demo.CHARACTER)
        Util.Print("Sample sessions on, for trying the screens out. Your own sessions are untouched, and "
            .. "nothing you catch now is saved. /kn demo again turns them off.")
    end
    ns.Fire("SESSION")
end
