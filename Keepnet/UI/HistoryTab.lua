-- Keepnet: the History tab. One row per session; click a heading to sort, pick a zone to list
-- only that zone's sessions, double-click a row to open it in the Session tab. It shows the
-- sessions of the character being played; the list at the top left changes that to another
-- character of the account, or to all of them (UI.CharacterPicker).
--
-- Typing in "Find a fish or item" swaps the list for where that item was caught: one row per
-- zone, the zone where it made up the largest share of the catch first.
local _, ns = ...
local Util, Sessions, Core, W, UI = ns.Util, ns.Sessions, ns.Core, ns.Widgets, ns.UI

local HistoryTab = {}
ns.HistoryTab = HistoryTab

local ALL_ZONES = "All zones"
-- The zone listed, or nil for all
local zoneFilter
-- What is typed in the search box
local search = ""

-- The search results: where an item was caught
local FOUND_COLUMNS = {
    {
        title = "Item", width = 236,
        text = function(row) return W.QualityText(row.name, row.quality) end,
        value = function(row) return row.name end,
        icon = function(row) return row.icon end,
    },
    {
        title = "Zone", width = 190,
        text = function(row) return row.zone end,
    },
    {
        title = "Share of catch", width = 104, align = "RIGHT", desc = true,
        text = function(row) return ("%.1f%%"):format(row.percent) end,
        value = function(row) return row.percent end,
    },
    {
        title = "Caught", width = 70, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.count) end,
        value = function(row) return row.count end,
    },
    {
        title = "Out of", width = 70, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.total) end,
        value = function(row) return row.total end,
    },
    {
        title = "Sessions", width = 88, align = "RIGHT", desc = true,
        text = function(row) return ("%d of %d"):format(row.sessions, row.zoneSessions) end,
        value = function(row) return row.sessions end,
    },
}

-- Used by the Zones tab: open History showing one zone
function HistoryTab.ShowZone(zone)
    zoneFilter = zone
    UI.Show("history")
end

local COLUMNS = {
    {
        title = "Date", width = 108, desc = true,
        text = function(row) return Util.DateTime(row.session.started) end,
        value = function(row) return row.session.started end,
    },
    {
        title = "Zone", width = 176,
        text = function(row)
            return row.session.zone .. (row.live and "  |cff" .. ns.Tone("ok") .. "running|r" or "")
        end,
        value = function(row) return row.session.zone end,
    },
    {
        title = "Character", width = 104,
        text = function(row) return Core.CharacterName(row.session.char) end,
    },
    {
        title = "Time", width = 62, align = "RIGHT", desc = true,
        text = function(row) return Util.HoursMinutes(row.session.active) end,
        value = function(row) return row.session.active end,
    },
    {
        title = "Casts", width = 58, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.session.casts) end,
        value = function(row) return row.session.casts end,
    },
    {
        title = "Catches", width = 66, align = "RIGHT", desc = true,
        text = function(row) return tostring(row.session.catches) end,
        value = function(row) return row.session.catches end,
    },
    {
        title = "Gold", width = 96, align = "RIGHT", desc = true,
        text = function(row) return Util.Money(row.value) end,
        value = function(row) return row.value end,
    },
    {
        title = "Per hour", width = 88, align = "RIGHT", desc = true,
        text = function(row) return row.perHour and Util.Money(row.perHour) or "-" end,
        value = function(row) return row.perHour end,
    },
}

StaticPopupDialogs["KEEPNET_DELETE_SESSION"] = {
    text = "Delete this fishing session?\n%s",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, sessionId)
        Sessions.Delete(sessionId)
        ns.Fire("SESSION")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function Build(frame)
    -- Whose sessions: the character being played unless another is picked
    local who = UI.CharacterPicker(frame, 160)
    who:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 2)
    HistoryTab.who = who

    local label = W.Text(frame, "GameFontHighlightSmall", "Zone")
    label:SetPoint("LEFT", who, "RIGHT", 12, 0)

    local zones = W.Dropdown(frame, 170, function()
        local options = { { value = false, text = ALL_ZONES } }
        for _, zone in ipairs(Sessions.ZoneNames(UI.Viewed())) do
            options[#options + 1] = { value = zone, text = zone }
        end
        return options
    end, function(value)
        zoneFilter = value or nil
        UI.Refresh()
    end)
    zones:SetPoint("LEFT", label, "RIGHT", 8, 0)

    local today = W.Check(frame, "Today's prices", function(checked)
        ns.settings.todayPrices = checked
        UI.Refresh()
    end)
    today:SetPoint("LEFT", zones, "RIGHT", 14, 0)

    local totals = W.Text(frame, "GameFontHighlightSmall")
    totals:SetPoint("TOPRIGHT", -UI.LEFT, UI.TOP - 4)

    -- The search row
    local findLabel = W.Text(frame, "GameFontHighlightSmall", "Find a fish or item")
    findLabel:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 32)
    local box = W.EditBox(frame, 220, nil, function(text)
        search = text
        UI.Refresh()
    end)
    box:SetPoint("LEFT", findLabel, "RIGHT", 8, 0)
    local clearSearch = W.Button(frame, "x", 20, 20, function()
        box:SetText("")
        box:ClearFocus()
        search = ""
        UI.Refresh()
    end)
    clearSearch:SetPoint("LEFT", box, "RIGHT", 4, 0)
    local findNote = W.Text(frame, "GameFontDisableSmall")
    findNote:SetPoint("LEFT", clearSearch, "RIGHT", 10, 0)

    local list
    local open = W.Button(frame, "Open", 80, 22, function()
        local row = list:Selected()
        if row then ns.SessionTab.View(row.session.id, "history") end
    end)
    local delete = W.Button(frame, "Delete", 80, 22, function()
        local row = list:Selected()
        if not row then return end
        StaticPopup_Show("KEEPNET_DELETE_SESSION",
            ("%s, %s"):format(row.session.zone, Util.DateTime(row.session.started)), nil, row.session.id)
    end)

    local function UpdateButtons()
        local has = list:Selected() ~= nil
        open:SetAlpha(has and 1 or 0.4)
        delete:SetAlpha(has and 1 or 0.4)
    end

    -- Where the searched item was caught; takes the place of the session list
    local found = W.Table(frame, FOUND_COLUMNS, {
        rows = 16,
        sort = 3,
        desc = true,
        id = function(row) return row.zone .. "/" .. tostring(row.id) end,
        onOpen = function(row)
            -- The sessions of that zone
            box:SetText("")
            search = ""
            HistoryTab.ShowZone(row.zone)
        end,
        onEnter = function(row, rowFrame)
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            if type(row.link) == "string" then
                GameTooltip:SetHyperlink(row.link)
            else
                GameTooltip:SetText(row.name)
            end
            GameTooltip:AddLine(("%d of the %d things caught in %s. Double-click for the sessions there.")
                :format(row.count, row.total, row.zone), 0.6, 0.6, 0.6, true)
            GameTooltip:Show()
        end,
        onLeave = function() GameTooltip:Hide() end,
        emptyText = "Nothing by that name has been caught yet.",
    })
    found:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 58)

    list = W.Table(frame, COLUMNS, {
        rows = 16,
        sort = 1,
        desc = true,
        id = function(row) return row.session.id end,
        onSelect = UpdateButtons,
        onOpen = function(row) ns.SessionTab.View(row.session.id, "history") end,
        emptyText = "No sessions yet. One starts with your first cast.",
    })
    list:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 58)
    HistoryTab.list = list
    open:SetPoint("BOTTOMLEFT", UI.LEFT, 12)
    delete:SetPoint("LEFT", open, "RIGHT", 6, 0)
    local hint = W.Text(frame, "GameFontDisableSmall", "Click a heading to sort. Double-click a session to open it.")
    hint:SetPoint("LEFT", delete, "RIGHT", 12, 0)

    return function()
        local character = UI.Viewed()
        who:Sync()
        -- Searching: the zones where the item was caught, in place of the sessions
        local searching = search:match("%S") ~= nil
        found:SetShown(searching)
        list:SetShown(not searching)
        open:SetShown(not searching)
        delete:SetShown(not searching)
        if searching then
            local results = Sessions.FindCatches(search, character)
            found:SetData(results)
            findNote:SetText(#results > 0
                and "Highest share first. A share of very few catches says little: see \"Out of\"."
                or "")
            hint:SetText("Click a heading to sort. Double-click a row for that zone's sessions.")
        else
            findNote:SetText("Part of a name is enough.")
            hint:SetText("Click a heading to sort. Double-click a session to open it.")
        end
        zones:Set(zoneFilter or false, zoneFilter or ALL_ZONES)
        today:SetChecked(ns.settings.todayPrices and true or false)
        local rows, gold, seconds = {}, 0, 0
        for _, session in ipairs(Sessions.List(zoneFilter, character)) do
            local value = Core.Value(session)
            rows[#rows + 1] = {
                session = session,
                live = Sessions.IsCurrent(session),
                value = value,
                perHour = Sessions.PerHour(value, session.active),
            }
            gold = gold + (value or 0)
            seconds = seconds + session.active
        end
        totals:SetText(("%d session%s    %s fishing    %s"):format(#rows, #rows == 1 and "" or "s",
            Util.HoursMinutes(seconds), Util.Money(gold)))
        list:SetData(rows)
        UpdateButtons()
    end
end

UI.AddTab("history", "History", Build)
