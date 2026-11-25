-- The Zones tab: every fished zone with the skill its water asks for and its number of
-- sessions; a click on a zone lists that zone's newest sessions with their numbers.
local T = {}

local EEL, BASS = 13422, 13756
local HOUR = 3600

function T.run(ns)
    local Sessions = ns.Sessions
    Stub.auction = { [EEL] = 40000, [BASS] = 900 }
    Stub.login()

    -- 25 sessions in Tanaris, 2 in Desolace and 1 in a zone whose skill nobody has published,
    -- an hour apart (a break that long starts a new session). Each has i casts, one fewer
    -- catches, and five minutes of fishing.
    local start = time() - 40 * HOUR
    local made = 0
    local function Session(zone, casts)
        made = made + 1
        local now = start + made * HOUR
        for cast = 1, casts do
            Sessions.CastStarted(now + (cast - 1) * 100, zone, "Tester-Realm")
            if cast < casts then
                Sessions.CastEnded(now + (cast - 1) * 100 + 20, "catch",
                    { { id = EEL, count = 1, name = "Stonescale Eel" } }, zone, "Tester-Realm")
            end
        end
        local session = Sessions.Current()
        Sessions.CloseCurrent()
        return session
    end
    Session("Desolace", 3)
    local tanaris = {}
    for i = 1, 25 do
        tanaris[i] = Session("Tanaris", 4)
    end
    Session("Zephras Isle", 2)
    local newestDesolace = Session("Desolace", 5)

    -- ----------------------------------------------------------------------- the zone list
    ns.UI.Show("zones")
    local tab = ns.ZonesTab
    local zones, sessions = tab.zones, tab.sessions
    eq(#zones.columns, 3, "the zone list has three columns")
    eq(zones.columns[1].title .. "," .. zones.columns[2].title .. "," .. zones.columns[3].title,
        "Zone,Skill,Sessions", "the name, the skill the water asks for and the number of sessions")
    -- Every zone whose skill is known is listed from the start, fished or not
    local known = ns.Waters.List()
    check(#known > 40, "the table of waters knows the zones of the world")
    local seen, sorted = {}, true
    for index, water in ipairs(known) do
        seen[water.zone] = water.skill
        if index > 1 and known[index - 1].zone >= water.zone then sorted = false end
    end
    check(sorted, "listed A to Z, each once")
    eq(seen["Felwood"], 300, "each with its skill")
    eq(seen["Sunken Temple"], nil, "a second name for the same place is not listed twice")
    eq(seen["The Temple of Atal'Hakkar"], 300, "its first name is")
    eq(ns.Waters.Skill("Sunken Temple"), 300, "though both names are still looked up")
    eq(#ns.Waters.Parts("Azshara"), 3, "the harder waters inside a zone are known")
    eq(#ns.Waters.Parts("Tanaris"), 0, "a zone without any has none")

    eq(#zones.data, #known + 1, "every known zone, and the fished one that isn't known")
    eq(zones.data[1].zone, "Desolace", "the zones fished come first, A to Z, however often they were fished")
    eq(zones.data[2].zone, "Tanaris", "then the next")
    eq(zones.data[3].zone, "Zephras Isle", "a fished zone with no published number is among them")
    eq(zones.data[4].zone, "Dun Morogh", "then the zones not fished yet, the lowest skill first")
    eq(zones.data[5].zone, "Durotar", "A to Z where the skill is the same")
    eq(zones.data[9].zone, "Tirisfal Glades", "to the last zone of that skill")
    eq(zones.data[10].zone, "Blackfathom Deeps", "then the next skill up, from A again")
    local rising = true
    for index = 5, #zones.data do
        local above, here = zones.data[index - 1], zones.data[index]
        if here.skill < above.skill or (here.skill == above.skill and here.zone < above.zone) then rising = false end
    end
    check(rising, "all the way down: by skill, then by name")
    eq(zones.data[#zones.data].skill, 425, "the hardest waters last")
    eq(zones.data[2].sessions, 25, "every session counts, not only the ones listed")
    eq(zones.data[1].sessions, 2, "with its number of sessions")
    eq(zones.data[4].sessions, 0, "none where nothing was fished")
    eq(zones.data[1].skill, 225, "the skill for guaranteed catches there")
    eq(zones.data[2].skill, 300, "and for the harder water")
    eq(zones.data[3].skill, nil, "a zone with no published number has none")
    eq(zones.data[4].skill, 25, "a zone not fished yet has its skill all the same")

    local function ZoneRow(name)
        for _, row in ipairs(zones.rows) do
            if row.data and row.data.zone == name then return row end
        end
    end
    eq(ZoneRow("Dun Morogh").cells[1]:GetText(), "|cff9d9d9dDun Morogh|r", "not fished yet: greyed")
    eq(ZoneRow("Dun Morogh").cells[3]:GetText(), "|cff9d9d9d-|r", "with a dash for its sessions")
    eq(ZoneRow("Tanaris").cells[1]:GetText(), "Tanaris", "a fished zone in plain text")
    -- The tooltip of a row builds without error, with and without harder waters or a number
    for _, name in ipairs({ "Tanaris", "Zephras Isle", "Dun Morogh" }) do
        local zoneRow = ZoneRow(name)
        zoneRow:GetScript("OnEnter")(zoneRow)
        zoneRow:GetScript("OnLeave")(zoneRow)
    end
    -- The character has 187 + 105 = 292: enough for Desolace, not quite for Tanaris
    eq(ZoneRow("Desolace").cells[2]:GetText(), "|cff40ff40225|r", "skill enough: green")
    eq(ZoneRow("Tanaris").cells[2]:GetText(), "|cffffd100300|r", "some will get away: yellow")
    eq(ZoneRow("Zephras Isle").cells[2]:GetText(), "|cff9d9d9d-|r", "not known: a dash")
    eq(ZoneRow("Tanaris").cells[3]:GetText(), "25", "the session count as text")

    -- -------------------------------------------------------------- nothing chosen yet
    eq(#sessions.data, 0, "no sessions listed before a zone is clicked")
    check(tab.heading:GetText():find("Click a zone", 1, true), "the heading says what to do")

    -- ------------------------------------------------------------------ a zone clicked
    local row = ZoneRow("Tanaris")
    row:GetScript("OnClick")(row)
    eq(#sessions.data, 20, "a click lists the zone's sessions, no more than twenty")
    check(tab.heading:GetText():find("Tanaris: the last 20 of 25 sessions", 1, true), "the heading says how many of how many")
    eq(sessions.data[1].session.id, tanaris[25].id, "the newest first")
    eq(sessions.data[20].session.id, tanaris[6].id, "going back twenty")
    eq(#sessions.columns, 6, "each with its numbers")
    local first = sessions.rows[1]
    eq(first.cells[2]:GetText(), "0:05", "the fishing time")
    eq(first.cells[3]:GetText(), "4", "the casts")
    eq(first.cells[4]:GetText(), "3", "the catches")
    check(first.cells[5]:GetText():find("12", 1, true), "the gold: three eels at 4 gold")
    check(first.cells[6]:GetText() ~= "-", "and the gold per hour")
    for _, listed in ipairs(sessions.data) do
        eq(listed.session.zone, "Tanaris", "only that zone's sessions")
    end

    row = ZoneRow("Desolace")
    row:GetScript("OnClick")(row)
    eq(#sessions.data, 2, "another zone: its two sessions")
    check(tab.heading:GetText():find("Desolace: 2 sessions", 1, true), "fewer than twenty: just the number")
    eq(sessions.data[1].session.id, newestDesolace.id, "the newest first")
    eq(sessions.rows[1].cells[3]:GetText(), "5", "with its own casts")

    row = ZoneRow("Zephras Isle")
    row:GetScript("OnClick")(row)
    check(tab.heading:GetText():find("Zephras Isle: 1 session ", 1, true), "one session, in the singular")

    -- A zone that hasn't been fished: nothing to list, and it says so
    row = ZoneRow("Dun Morogh")
    row:GetScript("OnClick")(row)
    eq(#sessions.data, 0, "a zone not fished yet has no sessions to list")
    eq(tab.heading:GetText(), "Dun Morogh: no sessions yet", "and the heading says so")
    eq(sessions.empty:GetText(), "You haven't fished here yet.", "as does the empty list")
    row:GetScript("OnDoubleClick")(row)
    check(zones:Selected() ~= nil and ns.UI.IsShown(), "a double-click on it goes nowhere")
    row = ZoneRow("Zephras Isle")
    row:GetScript("OnClick")(row)

    -- ------------------------------------------- a session clicked: all of its details
    local function OnScreen(text)
        for _, frame in ipairs(Stub.frames) do
            if frame.__kind == "FontString" and tostring(frame.__text):find(text, 1, true) then return true end
        end
        return false
    end
    row = ZoneRow("Tanaris")
    row:GetScript("OnClick")(row)
    local listed = sessions.rows[2]
    local wanted = listed.data.session
    eq(wanted.id, tanaris[24].id, "(the second newest session of the zone)")
    eq(ns.SessionTab.Viewing(), nil, "no session is open before one is clicked")
    listed:GetScript("OnClick")(listed)
    eq(ns.UI.Current(), "session", "one click on a session opens the Session tab")
    eq(ns.SessionTab.Viewing(), wanted.id, "on the session that was clicked")
    check(OnScreen("Casts 4    Catches 3"), "with that session's numbers")
    check(OnScreen(" to " .. date("%H:%M", wanted.ended)), "and when it ended")
    local back = ns.SessionTab.returnButton
    eq(back:IsShown(), true, "the Session tab offers the way back")
    eq(back.label:GetText(), "Back to Zones", "to where the player came from")
    back:GetScript("OnClick")(back)
    eq(ns.UI.Current(), "zones", "one click and the Zones tab is back")
    eq(zones:Selected().zone, "Tanaris", "with the zone still chosen")
    eq(#sessions.data, 20, "its sessions still listed")
    eq(sessions:Selected().session.id, wanted.id, "and the session just looked at marked")
    -- Opened from History, the way back is to History
    ns.SessionTab.View(wanted.id, "history")
    eq(back.label:GetText(), "Back to History", "a session opened from History goes back there")
    back:GetScript("OnClick")(back)
    eq(ns.UI.Current(), "history", "and does")
    -- Opened from nowhere in particular: no way back is offered
    ns.SessionTab.View(wanted.id)
    eq(back:IsShown(), false, "no button back when it wasn't opened from a list")
    ns.UI.Show("zones")
    row = ZoneRow("Desolace")
    row:GetScript("OnDoubleClick")(row)
    eq(ns.UI.Current(), "history", "a double-click on a zone still lists all its sessions in History")
    ns.UI.Show("zones")

    -- ------------------------------------------------------- the running session
    Stub.zone = "Desolace"
    Stub.equip(Stub.POLE)
    Stub.press("F")
    row = ZoneRow("Desolace")
    row:GetScript("OnClick")(row)
    eq(#sessions.data, 3, "a session being fished is listed with the rest")
    check(sessions.rows[1].cells[1]:GetText():find("running", 1, true), "and marked as running")
    eq(ZoneRow("Desolace").cells[3]:GetText(), "3", "and counted")

    -- A zone whose sessions are all deleted leaves the list, and takes its sessions with it
    for _, session in ipairs(Sessions.List("Zephras Isle")) do
        Sessions.Delete(session.id)
    end
    row = ZoneRow("Zephras Isle")
    row:GetScript("OnClick")(row)
    ns.Fire("SESSION")
    eq(#zones.data, #known, "an unknown zone with no sessions left is gone from the list")
    eq(#sessions.data, 0, "and so are its sessions")

    -- A known zone stays when its sessions are deleted: it goes back among the unfished
    for _, session in ipairs(Sessions.List("Tanaris")) do
        Sessions.Delete(session.id)
    end
    ns.Fire("SESSION")
    eq(#zones.data, #known, "a known zone stays in the list without sessions")
    eq(zones.data[1].zone, "Desolace", "the zone still fished is on top now")
    eq(zones.data[2].sessions, 0, "and everything after it is unfished")
    eq(zones.data[2].zone, "Dun Morogh", "in order of skill again")

    -- A click on a heading sorts by that column; the list's own order breaks the ties
    local header = zones.headers[3]
    header:GetScript("OnClick")(header)
    eq(zones.data[1].zone, "Desolace", "by sessions: the fished zone first")
    eq(zones.data[2].zone, "Dun Morogh", "the rest, all at none, still by skill")
    header = zones.headers[1]
    header:GetScript("OnClick")(header)
    eq(zones.data[1].zone, "Alterac Mountains", "by name: plain A to Z, fished or not")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
