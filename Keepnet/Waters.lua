-- Keepnet: the Fishing skill each water asks for. Pure data and lookups, no frames.
--
-- Every zone has a skill below which the line can't be cast at all, and a higher one from which
-- nothing gets away any more. In between, some bites are lost ("Your fish got away"). The live
-- panel shows the higher number next to the zone: the skill for guaranteed catches. Lures, gear
-- and food count towards it.
--
-- Zones and subzones are looked up by their English names, as the game reports them.
--
-- The numbers are the classic ones: El's Extreme Anglin' measured them (cast from "base" skill,
-- nothing gets away from base + 95), and the CMaNGOS classic database carries the same table,
-- including the five waters that differ from their zone. Guides for this client repeat them;
-- nobody has published a measurement made on this client. The zones new to this client
-- (Zephras Isle, Mount Hyjal, Riverglades ...) have no published number and show none.
-- See CREDITS.md.
local _, ns = ...

local Waters = {}
ns.Waters = Waters

-- The line can be cast from this far below the guaranteed-catch skill
Waters.CAST_GAP = 95

-- Skill for guaranteed catches -> the zones that ask for it
local TIERS = {
    [25] = { "Dun Morogh", "Durotar", "Elwynn Forest", "Mulgore", "Teldrassil", "Tirisfal Glades" },
    [75] = { "The Barrens", "Darkshore", "Darnassus", "Ironforge", "Loch Modan", "Orgrimmar",
        "Silverpine Forest", "Stormwind City", "Thunder Bluff", "Undercity", "Westfall",
        "The Deadmines", "Wailing Caverns", "Blackfathom Deeps" },
    [150] = { "Ashenvale", "Duskwood", "Hillsbrad Foothills", "Redridge Mountains", "Stonetalon Mountains",
        "Wetlands" },
    [225] = { "Alterac Mountains", "Arathi Highlands", "Desolace", "Dustwallow Marsh", "Stranglethorn Vale",
        "Swamp of Sorrows", "Thousand Needles", "Scarlet Monastery" },
    [300] = { "Azshara", "Felwood", "Feralas", "The Hinterlands", "Moonglade", "Tanaris", "Un'Goro Crater",
        "Western Plaguelands", "Sunken Temple", "The Temple of Atal'Hakkar", "Maraudon" },
    [425] = { "Eastern Plaguelands", "Winterspring", "Silithus", "Burning Steppes", "Deadwind Pass",
        "Scholomance", "Stratholme", "Zul'Gurub" },
}

-- Waters that ask for more (or less) than the rest of their zone
local SUBZONES = {
    ["Azshara"] = { ["Bay of Storms"] = 425, ["Hetaera's Clutch"] = 425, ["Scalebeard's Cave"] = 425 },
    ["Feralas"] = { ["Jademir Lake"] = 425 },
    ["Stranglethorn Vale"] = { ["Jaguero Isle"] = 300 },
}

local byZone = {}
for skill, zones in pairs(TIERS) do
    for _, zone in ipairs(zones) do
        byZone[zone] = skill
    end
end

-- The skill for guaranteed catches at a place, and the least skill to cast there; nil when the
-- place isn't known
function Waters.Skill(zone, subzone)
    if not zone then return nil end
    local guaranteed = (subzone and SUBZONES[zone] and SUBZONES[zone][subzone]) or byZone[zone]
    if not guaranteed then return nil end
    return guaranteed, math.max(1, guaranteed - Waters.CAST_GAP)
end

-- A second name for a place that is already in the table: looked up, but listed only once
local ALSO_KNOWN_AS = { ["Sunken Temple"] = true }

-- Every zone whose number is known, A to Z: { { zone, skill } }
function Waters.List()
    local list = {}
    for zone, skill in pairs(byZone) do
        if not ALSO_KNOWN_AS[zone] then
            list[#list + 1] = { zone = zone, skill = skill }
        end
    end
    table.sort(list, function(a, b) return a.zone < b.zone end)
    return list
end

-- The waters inside a zone that ask for another skill than the rest of it, A to Z:
-- { { name, skill } }
function Waters.Parts(zone)
    local list = {}
    for name, skill in pairs(SUBZONES[zone] or {}) do
        list[#list + 1] = { name = name, skill = skill }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- The text colour for each standing below: green, yellow, red
Waters.COLORS = { ok = "40ff40", some = "ffd100", none = "ff6060" }

-- "ok" when the skill is enough for guaranteed catches, "some" when the line can be cast but
-- fish will get away, "none" when it can't be cast there at all
function Waters.Standing(skill, guaranteed)
    if skill >= guaranteed then return "ok" end
    if skill >= math.max(1, guaranteed - Waters.CAST_GAP) then return "some" end
    return "none"
end
