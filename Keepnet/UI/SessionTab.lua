-- Keepnet: the Session tab. The current session, or one opened from History, with everything
-- caught in it: item, count, price each, total and where the price came from.
local _, ns = ...
local Util, Sessions, Prices, Core, W, UI = ns.Util, ns.Sessions, ns.Prices, ns.Core, ns.Widgets, ns.UI

local SessionTab = {}
ns.SessionTab = SessionTab

-- The session opened from History or Zones, or nil to follow the current one
local viewingId
-- The tab it was opened from ("zones" or "history"), for the button that goes back there
local cameFrom
local TAB_NAMES = { zones = "Zones", history = "History" }

-- Shows one session with everything in it. from, when given, is the tab the player came
-- from: a button on this tab goes back there.
function SessionTab.View(sessionId, from)
    viewingId = sessionId
    cameFrom = TAB_NAMES[from] and from or nil
    UI.Show("session")
end

-- The session being looked at, or nil when the tab follows the current one
function SessionTab.Viewing()
    return viewingId
end

-- "Auctionator", "TSM market" ...: the auction addon the prices come from now
local function AuctionName()
    local source = Prices.Source(ns.settings)
    return source and source.short or "Auction"
end

local function SourceText(row)
    if row.source == "auction" then return AuctionName() end
    if row.source == "vendor" then return "Vendor" end
    if row.source == "opened" then return "|cff9d9d9dopened|r" end
    if row.source == "coins" then return "" end
    return "|cff" .. ns.Tone("none") .. "no price|r"
end

local COINS_ICON = "Interface\\Icons\\INV_Misc_Coin_01"

local COLUMNS = {
    {
        title = "Item", width = 330,
        -- What came out of a catch that was opened says so, to tell it from the catch
        text = function(row)
            if row.money then return "Coins  |cff9d9d9dfrom opened catches|r" end
            return W.QualityText(row.name, row.quality) .. (row.from == "opened" and "  |cff9d9d9dfrom an opened catch|r" or "")
        end,
        value = function(row) return row.name end,
        icon = function(row) return row.money and COINS_ICON or row.icon end,
    },
    {
        title = "Count", width = 70, align = "RIGHT", desc = true,
        text = function(row)
            if row.money then return "" end
            if row.opened then return ("%d  |cff9d9d9d%d opened|r"):format(row.count, row.opened) end
            return tostring(row.count)
        end,
        value = function(row) return row.count end,
    },
    {
        title = "Each", width = 120, align = "RIGHT", desc = true,
        text = function(row) return row.money and "" or Util.Money(row.unit) end,
        value = function(row) return row.unit end,
    },
    {
        title = "Total", width = 130, align = "RIGHT", desc = true,
        text = function(row) return Util.Money(row.total) end,
        value = function(row) return row.total end,
    },
    {
        title = "Price from", width = 108,
        text = SourceText,
        value = function(row) return row.source end,
    },
}

local function ShowItemTooltip(row, frame)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    if type(row.link) == "string" then
        GameTooltip:SetHyperlink(row.link)
    else
        GameTooltip:SetText(row.name)
    end
    if row.from == "opened" then
        GameTooltip:AddLine(row.money and "The coins that were in catches you opened."
            or "Came out of a catch you opened. It counts towards the session the catch was made in.",
            0.6, 0.6, 0.6, true)
    elseif row.opened then
        GameTooltip:AddLine(("%d of %d opened. An opened one counts as what came out of it, not at its own price.")
            :format(row.opened, row.count), 0.6, 0.6, 0.6, true)
    end
    if row.source == "coins" or row.source == "opened" then
        GameTooltip:Show()
        return
    end
    if row.source == "auction" then
        local age = Prices.Age(row.item, ns.settings)
        if age then
            GameTooltip:AddLine(("%s price, %d day%s old"):format(AuctionName(), age, age == 1 and "" or "s"), 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine(AuctionName() .. " price", 0.6, 0.6, 0.6)
        end
    elseif row.source == "vendor" then
        GameTooltip:AddLine("Counted at the vendor price", 0.6, 0.6, 0.6)
    else
        GameTooltip:AddLine("No price known: not counted in the total", 1, 0.4, 0.4)
    end
    GameTooltip:Show()
end

local function Build(frame)
    local heading = W.Text(frame, "GameFontNormal")
    heading:SetPoint("TOPLEFT", UI.LEFT, UI.TOP)
    local summary = W.Text(frame, "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 20)
    local note = W.Text(frame, "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 36)

    local new = W.Button(frame, "New session", 100, 22, function() Core.NewSession() end)
    new:SetPoint("TOPRIGHT", -UI.LEFT, UI.TOP + 2)
    new.tooltip = "End the current session. A new one starts with your next cast."
    local back = W.Button(frame, "Current session", 110, 22, function()
        viewingId, cameFrom = nil, nil
        UI.Refresh()
    end)
    back:SetPoint("RIGHT", new, "LEFT", -6, 0)
    -- Back to the list this session was opened from
    local returnTo = W.Button(frame, "", 110, 22, function()
        if cameFrom then UI.Show(cameFrom) end
    end)
    returnTo:SetPoint("RIGHT", back, "LEFT", -6, 0)
    SessionTab.returnButton = returnTo

    local list = W.Table(frame, COLUMNS, {
        rows = 17,
        sort = 4,
        desc = true,
        onEnter = ShowItemTooltip,
        onLeave = function() GameTooltip:Hide() end,
        emptyText = "Nothing caught in this session yet.",
    })
    list:SetPoint("TOPLEFT", UI.LEFT, UI.TOP - 56)

    return function()
        local session = viewingId and Sessions.Get(viewingId)
        if not session then
            viewingId, cameFrom = nil, nil
            session = Sessions.Current()
        end
        back:SetShown(viewingId ~= nil)
        returnTo:SetShown(viewingId ~= nil and cameFrom ~= nil)
        if cameFrom then returnTo.label:SetText("Back to " .. TAB_NAMES[cameFrom]) end
        if not session then
            heading:SetText("No session running")
            summary:SetText("A session starts with your next cast. Finished sessions are under History.")
            note:SetText("")
            list:SetData({})
            return
        end
        local live = Sessions.IsCurrent(session)
        local rows, liveTotal, liveUnpriced = Core.Rows(session)
        local value = Core.Value(session)
        local perHour = Sessions.PerHour(value, session.active)
        -- "Tanaris  Vale, 23 Nov 14:02 to 14:50": when it started and, once over, when it ended
        local when = Util.DateTime(session.started)
        if not live and session.ended and session.ended > session.started then
            when = when .. " to " .. date("%H:%M", session.ended)
        end
        heading:SetText(("%s  |cffffffff%s, %s|r%s"):format(session.zone, Core.CharacterName(session.char),
            when, live and "  |cff" .. ns.Tone("ok") .. "running|r" or ""))
        summary:SetText(("Time %s    Casts %d    Catches %d    Missed %d    Value %s    Per hour %s"):format(
            Util.Clock(session.active), session.casts, session.catches, session.misses,
            Util.Money(value), perHour and Util.Money(perHour) or "-"))
        local notes = {}
        if not live and value ~= liveTotal then
            notes[#notes + 1] = ("Value as it stood when the session ended. The table below uses today's prices (%s)."):format(
                Util.Money(liveTotal))
        end
        if liveUnpriced > 0 then
            notes[#notes + 1] = ("%d item%s without a price, not counted."):format(liveUnpriced, liveUnpriced == 1 and "" or "s")
        end
        if (session.unknown or 0) > 0 then
            notes[#notes + 1] = ("%d catch%s the game didn't show to addons."):format(session.unknown,
                session.unknown == 1 and "" or "es")
        end
        local description, fine = Prices.Describe(ns.settings)
        if not fine then
            notes[#notes + 1] = description .. "."
        end
        note:SetText(table.concat(notes, "  "))
        list:SetData(rows)
    end
end

UI.AddTab("session", "Session", Build)
