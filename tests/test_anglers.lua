-- Fishing trainers and tackle vendors, zone by zone: only the ones the character's side can
-- use (its own and the neutral ones), listed on the Zones tab in place of the sessions.
local T = {}

function T.run(ns)
    local Anglers = ns.Anglers
    Stub.faction = "Horde"
    Stub.login()

    -- ------------------------------------------------------------------------- the data
    local all = Anglers.List()
    check(#all >= 40, "the trainers and vendors of the world are known")
    local kinds, sides, sound, ids = { trainer = 0, vendor = 0, both = 0 }, { A = 0, H = 0, N = 0 }, true, {}
    for _, row in ipairs(all) do
        if not (kinds[row.kind] and sides[row.side] and type(row.name) == "string" and type(row.zone) == "string"
            and type(row.id) == "number" and not ids[row.id]) then
            sound = false
        else
            kinds[row.kind] = kinds[row.kind] + 1
            sides[row.side] = sides[row.side] + 1
        end
        ids[row.id] = true
        if (row.x == nil) ~= (row.y == nil) then sound = false end
        if row.x and (row.x < 0 or row.x > 100 or row.y < 0 or row.y > 100) then sound = false end
    end
    check(sound, "every row has a name, a zone, a kind, a side and its own number")
    check(kinds.trainer + kinds.both >= 20 and kinds.vendor + kinds.both >= 15, "trainers and vendors both")
    check(sides.A > 5 and sides.H > 5 and sides.N > 0, "for each side, and neutral ones")

    -- ------------------------------------------------------------------------- by side
    local function Names(list)
        local names = {}
        for _, row in ipairs(list) do names[row.name] = row end
        return names
    end
    local horde, alliance = Anglers.List(nil, "H"), Anglers.List(nil, "A")
    local clean = true
    for _, row in ipairs(horde) do if row.side == "A" then clean = false end end
    for _, row in ipairs(alliance) do if row.side == "H" then clean = false end end
    check(clean, "a side never sees the other side's people")
    eq(#horde, sides.H + sides.N, "its own and the neutral ones")
    eq(#alliance, sides.A + sides.N, "the same for the other side")
    check(Names(horde)["Lumak"] and not Names(alliance)["Lumak"], "Orgrimmar's trainer: Horde only")
    check(Names(alliance)["Arnold Leland"] and not Names(horde)["Arnold Leland"], "Stormwind's: Alliance only")
    check(Names(horde)["Myizz Luckycatch"] and Names(alliance)["Myizz Luckycatch"], "Booty Bay's serves both")
    eq(Names(horde)["Lumak"].zone, "Orgrimmar", "each in its zone")
    eq(Anglers.Kind(Names(horde)["Lumak"]), "Trainer", "what they do, in words")
    eq(Anglers.Where({ x = 44.6, y = 60 }), "44.6, 60.0", "where they stand")
    eq(Anglers.Where({}), "", "nothing where the spot isn't confirmed")
    eq(Anglers.Kind({ kind = "both" }), "Trainer and vendor", "both in one")

    -- One zone: trainers before vendors, and only that zone's
    local orgrimmar = Anglers.List("Orgrimmar", "H")
    check(#orgrimmar >= 2, "a city has a trainer and a vendor")
    eq(orgrimmar[1].kind, "trainer", "the trainer first")
    eq(Anglers.Count("Orgrimmar", "H"), #orgrimmar, "counted the same way")
    eq(Anglers.Count("Orgrimmar", "A"), 0, "none of them for the other side")
    eq(#Anglers.List("Stormwind City", "H"), 0, "and nothing in the other side's city")
    eq(#Anglers.List("Orgrimmar"), #orgrimmar, "no side given: nobody is left out")
    local ordered = true
    for index = 2, #horde do
        if horde[index - 1].zone > horde[index].zone then ordered = false end
    end
    check(ordered, "the whole list goes zone by zone, A to Z")

    eq(Anglers.Side(), "H", "the side comes from the character")
    Stub.faction = "Alliance"
    eq(Anglers.Side(), "A", "either one")
    Stub.faction = nil
    eq(Anglers.Side(), nil, "or none when the game doesn't say")
    Stub.faction = "Horde"

    -- ------------------------------------------------------------------- the Zones tab
    ns.UI.Show("zones")
    local tab = ns.ZonesTab
    local zones, people, switch = tab.zones, tab.people, tab.switch
    check(tab.sessions:IsShown() and not people:IsShown(), "the tab opens on the sessions")
    switch:GetScript("OnClick")(switch)
    check(people:IsShown() and not tab.sessions:IsShown(), "the button swaps them for the trainers and vendors")
    check(not tab.who:IsShown(), "whose sessions doesn't matter there")
    check(tab.clickHint:IsShown() and tab.clickHint:GetText():find("targeting macro", 1, true)
        and tab.clickHint:GetText():find("waypoint", 1, true), "under the button: what a click on one does")
    eq(#people.data, #horde, "no zone clicked: everybody for this side")
    check(tab.heading:GetText():find("for the Horde", 1, true), "and the heading says for whom")
    eq(#people.columns, 4, "name, what, zone and where")

    local function ZoneRow(name)
        for index = 1, #zones.data do
            if zones.data[index].zone == name then
                zones.offset = math.max(0, index - 1)
                zones:Refresh()
                for _, row in ipairs(zones.rows) do
                    if row.data and row.data.zone == name then return row end
                end
            end
        end
    end
    local row = ZoneRow("Orgrimmar")
    row:GetScript("OnClick")(row)
    eq(#people.data, #orgrimmar, "a zone clicked: that zone's")
    check(tab.heading:GetText():find("Orgrimmar: " .. #orgrimmar .. " for the Horde", 1, true), "counted in the heading")
    local first = people.rows[1]
    eq(first.cells[1]:GetText(), orgrimmar[1].name, "the name")
    eq(first.cells[2]:GetText(), "Trainer", "what they do")
    first:GetScript("OnEnter")(first)
    first:GetScript("OnLeave")(first)
    -- A click asks for a target macro and a map mark; where the game offers neither (as
    -- here) or the character is elsewhere, it says so and nothing breaks
    first:GetScript("OnClick")(first)
    local _, why = Anglers.Waypoint(orgrimmar[1])
    check(type(why) == "string", "no map mark outside the zone, with the reason")
    eq(select(2, Anglers.Waypoint({ zone = "Orgrimmar" })), "the spot isn't known", "nor without a spot")

    row = ZoneRow("Stormwind City")
    row:GetScript("OnClick")(row)
    eq(#people.data, 0, "the other side's city: nobody")
    check(people.empty:IsShown(), "and it says so")

    switch:GetScript("OnClick")(switch)
    check(tab.sessions:IsShown() and tab.who:IsShown() and not people:IsShown(), "the button goes back to the sessions")
    check(not tab.clickHint:IsShown(), "and the line about clicking goes with the list")
end

return T
