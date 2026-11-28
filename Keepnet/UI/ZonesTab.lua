-- Keepnet: the Zones tab. On the left every zone whose Fishing skill is known (Waters.lua),
-- fished or not, and any other zone that has been fished: its name, the skill its water asks
-- for, and how many sessions it has. The zones fished come first, A to Z; the others follow
-- by the skill they ask for, lowest first, greyed until a session is fished there (the
-- owner's order; a click on a heading sorts by that column instead). Click a zone and the
-- right side lists that zone's sessions, the newest first and no further back than RECENT of
-- them, each with its own numbers. Click a session and it opens in the Session tab with
-- everything in it (that tab has a button back here); double-click a zone for all of its
-- sessions in History. The sessions counted and listed are those of the character being
-- played; the list at the top right changes that to another character of the account, or
-- to all of them (UI.CharacterPicker).
--
-- A button beside that list turns the right side into the fishing trainers and tackle vendors
-- (Anglers.lua) instead: those of the clicked zone, or of every zone while none is clicked,
-- and only the ones the character's side can use (its own and the neutral ones).
local _, ns = ...
local Util, Sessions, Core, Waters, Skill, W, UI = ns.Util, ns.Sessions, ns.Core, ns.Waters, ns.Skill, ns.Widgets, ns.UI
local Anglers = ns.Anglers

local ZonesTab = {}
ns.ZonesTab = ZonesTab

-- How far back the session list goes
local RECENT = 20
ZonesTab.RECENT = RECENT

local ZONES_WIDTH = 274
local GAP = 14
local PICKER_WIDTH = 136
local SWITCH_WIDTH = 124
local SHOW_PEOPLE, SHOW_SESSIONS = "Trainers & vendors", "Sessions"

-- What the right side lists: the zone's sessions, or its trainers and vendors
local people = false

-- The skill from which nothing gets away in the zone, in the colour the live panel uses for
-- it: enough, some will get away, or can't be cast there. "-" where the number isn't known.
local function SkillText(row)
    if not row.skill then return "|cff9d9d9d-|r" end
    local color = "9d9d9d"
    local rank, _, bonus = Skill.Get()
    if rank then
        color = Waters.COLORS[Waters.Standing(rank + bonus, row.skill)]
    end
    return ("|cff%s%d|r"):format(color, row.skill)
end

local ZONE_COLUMNS = {
    {
        title = "Zone", width = 150,
        -- Greyed until it has been fished
        text = function(row)
            return row.sessions > 0 and row.zone or ("|cff9d9d9d" .. row.zone .. "|r")
        end,
        value = function(row) return row.zone end,
    },
    {
        title = "Skill", width = 54, align = "RIGHT",
        text = SkillText,
        value = function(row) return row.skill end,
    },
    {
        title = "Sessions", width = 70, align = "RIGHT", desc = true,
        text = function(row) return row.sessions > 0 and tostring(row.sessions) or "|cff9d9d9d-|r" end,
        value = function(row) return row.sessions end,
    },
}

local SESSION_COLUMNS = {
    {
        title = "Date", width = 128, desc = true,
        text = function(row)
            return Util.DateTime(row.session.started) .. (row.live and "  |cff" .. ns.Tone("ok") .. "running|r" or "")
        end,
        value = function(row) return row.session.started end,
    },
    {
        title = "Time", width = 54, align = "RIGHT", desc = true,
        text = function(row) return Util.HoursMinutes(row.session.active) end,
        value = function(row) return row.session.active end,
    },
    {
        title = "Casts", width = 54, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.session.casts) end,
        value = function(row) return row.session.casts end,
    },
    {
        title = "Catches", width = 66, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.session.catches) end,
        value = function(row) return row.session.catches end,
    },
    {
        title = "Gold", width = 86, align = "RIGHT", desc = true,
        text = function(row) return Util.Money(row.value) end,
        value = function(row) return row.value end,
    },
    {
        title = "Per hour", width = 82, align = "RIGHT", desc = true,
        text = function(row) return row.perHour and Util.Money(row.perHour) or "-" end,
        value = function(row) return row.perHour end,
    },
}

local PEOPLE_COLUMNS = {
    {
        title = "Name", width = 150,
        text = function(row) return row.name end,
    },
    {
        title = "What", width = 128,
        text = function(row) return Anglers.Kind(row) end,
    },
    {
        title = "Zone", width = 132,
        text = function(row) return row.zone end,
    },
    {
        title = "Where", width = 60, align = "RIGHT",
        text = function(row) return Anglers.Where(row) end,
    },
}

-- The trainers and vendors the character's side can use: the zone's, or everybody's (zone nil)
function ZonesTab.PeopleRows(zone)
    return Anglers.List(zone, Anglers.Side())
end

-- "for the Horde", or "" when the game doesn't say which side the character is on
local function ForSide()
    local name = Anglers.SideName(Anglers.Side())
    return name and (" for the " .. name) or ""
end

-- One row per zone, in the list's own order: { zone, skill (nil when not known), sessions }. Every zone whose
-- skill is known is there from the start with no sessions; a zone that isn't known joins the
-- list once it has been fished.
function ZonesTab.ZoneRows()
    local rows, byName = {}, {}
    for _, water in ipairs(Waters.List()) do
        local row = { zone = water.zone, skill = water.skill, sessions = 0 }
        rows[#rows + 1] = row
        byName[water.zone] = row
    end
    for _, fished in ipairs(Sessions.Zones(nil, UI.Viewed())) do
        local row = byName[fished.zone]
        if not row then
            row = { zone = fished.zone, skill = (Waters.Skill(fished.zone)), sessions = 0 }
            rows[#rows + 1] = row
            byName[fished.zone] = row
        end
        row.sessions = fished.sessions
    end
    -- Fished zones first, A to Z; then the ones not fished yet by the skill they ask for,
    -- lowest first, and A to Z where that is the same
    table.sort(rows, function(a, b)
        local fishedA, fishedB = a.sessions > 0, b.sessions > 0
        if fishedA ~= fishedB then return fishedA end
        if not fishedA and a.skill ~= b.skill then
            return (a.skill or math.huge) < (b.skill or math.huge)
        end
        return a.zone < b.zone
    end)
    return rows
end

-- The zone's newest sessions, at most RECENT of them, and how many it has in all:
-- { { session, live, value, perHour } }, total
function ZonesTab.SessionRows(zone)
    local rows = {}
    local all = Sessions.List(zone, UI.Viewed())
    for index = 1, math.min(#all, RECENT) do
        local session = all[index]
        local value = Core.Value(session)
        rows[#rows + 1] = {
            session = session,
            live = Sessions.IsCurrent(session),
            value = value,
            perHour = Sessions.PerHour(value, session.active),
        }
    end
    return rows, #all
end

local function Build(frame)
    local hint = W.Text(frame, "GameFontDisableSmall", "Skill: from this Fishing, nothing gets away")
    hint:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 4)

    local heading = W.Text(frame, "GameFontHighlightSmall")
    heading:SetPoint("TOPLEFT", UI.LEFT + ZONES_WIDTH + GAP, UI.TOP - 4)
    heading:SetWidth(UI.WIDTH - 2 * UI.LEFT - ZONES_WIDTH - GAP - PICKER_WIDTH - SWITCH_WIDTH - 16)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)

    -- Whose sessions: the character being played unless another is picked
    local who = UI.CharacterPicker(frame, PICKER_WIDTH)
    who:SetPoint("TOPRIGHT", -UI.LEFT, UI.TOP + 2)

    -- Sessions, or trainers and vendors: the button names what a click changes to
    local switch = W.Button(frame, SHOW_PEOPLE, SWITCH_WIDTH, 20, function()
        people = not people
        UI.Refresh()
    end)
    switch:SetPoint("TOPRIGHT", -UI.LEFT - PICKER_WIDTH - 8, UI.TOP + 2)
    -- Under the button while the trainers and vendors show: what a click on one does
    local clickHint = W.Text(frame, "GameFontHighlightSmall",
        "|cff" .. ns.Tone("ok") .. "Click one: Keepnet makes a targeting macro for them, and a waypoint when you are in their zone.|r")
    clickHint:SetPoint("TOPRIGHT", -UI.LEFT, UI.TOP - 19)
    clickHint:SetJustifyH("RIGHT")
    clickHint:Hide()
    ZonesTab.clickHint = clickHint

    -- Shown in the order ZoneRows gives until a heading is clicked; after that, rows of the
    -- same value keep that order among themselves
    local zones = W.Table(frame, ZONE_COLUMNS, {
        rows = 18,
        sort = 0,
        id = function(row) return row.zone end,
        onSelect = function() UI.Refresh() end,
        onOpen = function(row)
            if row.sessions > 0 then ns.HistoryTab.ShowZone(row.zone) end
        end,
        onEnter = function(row, rowFrame)
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.zone)
            if row.skill then
                GameTooltip:AddLine(("Nothing gets away from Fishing %d. The line can be cast from %d.")
                    :format(row.skill, math.max(1, row.skill - Waters.CAST_GAP)), 1, 1, 1, true)
                for _, part in ipairs(Waters.Parts(row.zone)) do
                    GameTooltip:AddLine(("%s asks for %d."):format(part.name, part.skill), 1, 0.82, 0, true)
                end
            else
                GameTooltip:AddLine("Nobody has published the skill this water asks for.", 0.6, 0.6, 0.6, true)
            end
            GameTooltip:Show()
        end,
        onLeave = function() GameTooltip:Hide() end,
    })
    zones:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 30)

    local sessions = W.Table(frame, SESSION_COLUMNS, {
        rows = 18,
        sort = 1,
        desc = true,
        id = function(row) return row.session.id end,
        -- One click opens the session with everything in it; the Session tab has a button back
        onSelect = function(row) ns.SessionTab.View(row.session.id, "zones") end,
        emptyText = "Click a zone to list its sessions.",
    })
    sessions:SetPoint("TOPLEFT", UI.LEFT + ZONES_WIDTH + GAP, UI.TOP - 30)

    -- In the same place as the sessions, one or the other showing
    local folk = W.Table(frame, PEOPLE_COLUMNS, {
        rows = 18,
        sort = 0,
        id = function(row) return row.id end,
        -- A click: a macro that targets them, and a map mark when they are in this zone
        onSelect = function(row) Anglers.Go(row) end,
        onEnter = function(row, rowFrame)
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.name)
            if row.title then GameTooltip:AddLine(row.title, 1, 0.82, 0, true) end
            local place = Anglers.Where(row)
            GameTooltip:AddLine(row.zone .. (place ~= "" and ("  " .. place) or ""), 1, 1, 1, true)
            if row.sells then GameTooltip:AddLine("Sells: " .. row.sells, 1, 1, 1, true) end
            if row.side == "N" then GameTooltip:AddLine("Serves both sides.", 0.6, 0.6, 0.6, true) end
            if row.note then GameTooltip:AddLine(row.note, 0.6, 0.6, 0.6, true) end
            GameTooltip:AddLine("Click: a macro that targets them, and a map mark when you are in their zone.",
                0.6, 0.6, 0.6, true)
            GameTooltip:Show()
        end,
        onLeave = function() GameTooltip:Hide() end,
    })
    folk:SetPoint("TOPLEFT", UI.LEFT + ZONES_WIDTH + GAP, UI.TOP - 30)
    folk:Hide()

    ZonesTab.zones, ZonesTab.sessions, ZonesTab.heading, ZonesTab.who = zones, sessions, heading, who
    ZonesTab.people, ZonesTab.switch = folk, switch

    return function()
        who:Sync()
        local own = UI.Viewed() == Core.Character()
        zones:SetData(ZonesTab.ZoneRows())
        local chosen = zones:Selected()
        switch:SetText(people and SHOW_SESSIONS or SHOW_PEOPLE)
        sessions:SetShown(not people)
        folk:SetShown(people)
        clickHint:SetShown(people)
        -- Whose sessions doesn't matter to the trainers and vendors
        who:SetShown(not people)
        if people then
            local rows = ZonesTab.PeopleRows(chosen and chosen.zone)
            folk:SetData(rows)
            if not chosen then
                folk.empty:SetText("No trainers or vendors are known.")
                heading:SetText(("Every fishing trainer and vendor%s"):format(ForSide()))
            else
                folk.empty:SetText(("No fishing trainer or vendor here%s."):format(ForSide()))
                heading:SetText(("%s: %d%s"):format(chosen.zone, #rows, ForSide()))
            end
            return
        end
        if not chosen then
            sessions.empty:SetText("Click a zone to list its sessions.")
            sessions:SetData({})
            heading:SetText("|cff9d9d9dClick a zone to list its sessions.|r")
            return
        end
        local rows, total = ZonesTab.SessionRows(chosen.zone)
        sessions.empty:SetText(own and "You haven't fished here yet." or "No sessions here.")
        sessions:SetData(rows)
        if total == 0 then
            heading:SetText(chosen.zone .. ": no sessions yet")
            return
        end
        local count
        if total > #rows then
            count = ("the last %d of %d sessions"):format(#rows, total)
        else
            count = ("%d session%s"):format(total, total == 1 and "" or "s")
        end
        heading:SetText(("%s: %s  |cff9d9d9dclick one for all of its details|r"):format(chosen.zone, count))
    end
end

UI.AddTab("zones", "Zones", Build)
