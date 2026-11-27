-- Keepnet: the small panel that stays up while fishing mode is on: the current session's
-- live numbers, the Fishing skill bar with the skill points gained this session under it, the
-- fishing buffs, a section for what is in use (the lure with how many are left in the bags,
-- and a small "A" button, lit while the key applies lures, that turns applying it on and off,
-- the food and the fishing gear), and a list of what was caught this session with each item's
-- count and share of the catch. That list scrolls with the mouse wheel once it is longer than
-- its room, and the panel's bottom right corner can be dragged: sideways for the panel's width,
-- up and down for how many catches show before the list scrolls. Keepnet's version is in small
-- print beside the value.
-- Under the panel hangs a small strip while a line is out (by default only while Keepnet has
-- the game's interface hidden, when the game's own cast bar and loot window can't be seen): a
-- bar that runs down with the seconds the line has left, and under it, for a few seconds,
-- what the cast brought up.
-- A cog in the corner opens the settings. Each line of the section for what is in use is a
-- button too: it opens a list of what could be used instead, so the lure, the food and the
-- fishing gear can be changed without opening the window.
local _, ns = ...
local Util, Sessions, Core, Lures, Skill, Buffs, W = ns.Util, ns.Sessions, ns.Core, ns.Lures, ns.Skill, ns.Buffs, ns.Widgets
local Gear = ns.Gear
local Waters = ns.Waters

local LivePanel = {}
ns.LivePanel = LivePanel

local WIDTH, HEIGHT = 260, 178 -- the width it starts at (and its narrowest); the height without the catch list
local MAX_WIDTH = 480
local KIT_TOP = -142           -- where the lure / food / gear section starts
local KIT_ROW = 16
local KIT_HEIGHT = 3 * KIT_ROW + 8
local LURE_TOGGLE = 18         -- the width of the "A" button that turns applying lures on and off
local LIST_TOP = -142          -- where the catch list starts when that section is off
local LIST_ROW = 15
local LIST_ROWS = 8            -- more catches than this and the list scrolls, until the corner is dragged
local MIN_ROWS, MAX_ROWS = 3, 30 -- how few and how many rows the corner can be dragged to
local RARE_SECONDS = 8
-- The game's own small cog, as other addons on this client use it for their settings buttons
local COG = "Interface\\Buttons\\UI-OptionsButton"
local NOTICE_SECONDS = 10
local panel
local hiddenByPlayer = false
local detached = false -- lifted out of the game's interface while that is hidden
local listOffset = 0   -- how far the catch list is scrolled, in rows
local sizing           -- while the corner is being dragged: where the drag began
-- A line that takes the place of the buff line for a while: a rare catch, a whisper, an error
local notice = { text = nil, expires = 0, highlight = false }

-- Kept by its top-left corner, so the panel grows downwards as the catch list fills
local function SavePosition()
    local left, top = panel:GetLeft(), panel:GetTop()
    if not left or not top then return end
    ns.db.panel = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = left, y = top }
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function ApplyPosition()
    panel:ClearAllPoints()
    local saved = ns.db.panel
    if saved and saved.point then
        panel:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
    else
        panel:SetPoint("TOP", UIParent, "CENTER", 0, -100)
    end
end

local function Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

-- The size the player gave the panel by dragging its corner (ns.db.panelSize = { width, rows },
-- either can be missing): how wide it is, and how many catches show before the list scrolls
local function Width()
    local saved = ns.db.panelSize
    return Clamp(tonumber(saved and saved.width) or WIDTH, WIDTH, MAX_WIDTH)
end

local function MaxRows()
    local saved = ns.db.panelSize
    return Clamp(tonumber(saved and saved.rows) or LIST_ROWS, MIN_ROWS, MAX_ROWS)
end

-- Where the catch list starts: under the lure / food / gear section when that is shown
local function ListTop()
    return LIST_TOP - (ns.settings.panelKit and KIT_HEIGHT or 0)
end

-- One line of the catch list: icon, name, count, share
local function ListRow(index)
    local row = panel.rows[index]
    if not row then
        row = {}
        row.icon = panel:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(LIST_ROW - 3, LIST_ROW - 3)
        row.name = W.Text(panel)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.count = W.Text(panel)
        row.percent = W.Text(panel)
        panel.rows[index] = row
    end
    local y = ListTop() - (index - 1) * LIST_ROW
    if row.y ~= y then
        row.y = y
        row.icon:ClearAllPoints()
        row.icon:SetPoint("TOPLEFT", 10, y)
        row.name:ClearAllPoints()
        row.name:SetPoint("TOPLEFT", 10 + LIST_ROW, y)
        row.count:ClearAllPoints()
        row.count:SetPoint("TOPRIGHT", -48, y)
        row.percent:ClearAllPoints()
        row.percent:SetPoint("TOPRIGHT", -10, y)
    end
    -- The name gets what the panel's width leaves it
    local width = Width() - 20 - LIST_ROW - 78
    if row.width ~= width then
        row.width = width
        row.name:SetWidth(width)
    end
    return row
end

local function ItemName(itemID)
    return Util.ItemInfo(itemID) or ("item " .. tostring(itemID))
end

-- The lure / food / gear section: what the fishing key will use, and what is on now
local function RefreshKit()
    local kit = panel.kit
    local shown = ns.settings.panelKit and true or false
    for _, region in ipairs(kit.regions) do region:SetShown(shown) end
    if not shown then
        panel.menu:Close()
        return
    end
    for _, row in ipairs(kit.rows) do
        row.arrow:SetTextColor(unpack(W.COLORS.accent))
    end
    local settings = ns.settings

    -- Lure: the one the key applies (the chosen one, or the best to hand), and its time left
    local mode = settings.lureMode
    local left = Lures.TimeLeft()
    local lure
    if mode == "specific" then
        for _, entry in ipairs(Lures.InBags()) do
            if entry.id == settings.lureItem then lure = entry end
        end
    elseif mode ~= "off" then
        lure = Lures.Best()
    end
    local lureID = lure and lure.id or (mode == "specific" and settings.lureItem) or nil
    kit.lureIcon:SetTexture(lureID and Util.ItemIcon(lureID) or nil)
    local text
    if lureID then
        text = ItemName(lureID)
        -- How many of it are in the bags. A worn item that puts a lure on isn't counted.
        if lure and not lure.worn then text = text .. " x" .. lure.count end
        text = text .. (lure and lure.bonus and ("  +" .. lure.bonus) or "")
        if not lure then text = text .. "  |cffff6060none left|r" end
    elseif mode == "off" then
        text = "|cff9d9d9dnot applied by the key|r"
    else
        text = "|cffff6060none to apply|r"
    end
    if left then
        text = text .. "  |cff40ff40" .. Util.MinutesSeconds(left) .. "|r"
    elseif lure and mode ~= "off" then
        text = text .. "  |cff9d9d9dnext press|r"
    end
    kit.lureText:SetText("Lure: " .. text)
    -- The "A" button: lit while the key applies lures
    local auto = mode ~= "off"
    kit.lureToggle.lit:SetShown(auto)
    if auto then
        kit.lureToggle.label:SetTextColor(1, 1, 1)
    else
        kit.lureToggle.label:SetTextColor(0.5, 0.5, 0.5)
    end
    kit.lureToggle.tooltip = auto
        and "Automatic lures are on: the fishing key puts a lure on the pole when there is none. Click to turn that off."
        or "Automatic lures are off: the fishing key leaves the pole as it is. Click to turn them on."

    -- Food: what the key eats, and whether you are fed
    local food = Buffs.Food()
    kit.foodIcon:SetTexture(food and Util.ItemIcon(food) or nil)
    if settings.foodMode == "off" then
        kit.foodText:SetText("Food: |cff9d9d9doff|r")
    elseif not food then
        kit.foodText:SetText("Food: |cffff6060none in your bags|r")
    elseif Buffs.Waiting() then
        kit.foodText:SetText("Food: " .. ItemName(food) .. "  |cffffd100eating|r")
    elseif Buffs.IsOn(food) then
        kit.foodText:SetText("Food: " .. ItemName(food) .. "  |cff40ff40fed|r")
    else
        kit.foodText:SetText("Food: " .. ItemName(food) .. "  |cff9d9d9dnext press|r")
    end

    -- Gear: the fishing gear Keepnet has put on
    if not settings.gear then
        kit.gearText:SetText("Gear: |cff9d9d9doff|r")
    else
        local names, bonus = {}, 0
        for _, item in ipairs(Gear.Wearing()) do
            names[#names + 1] = Util.LinkName(item.link) or "?"
            if item.bonus >= 1 then bonus = bonus + item.bonus end
        end
        if #names == 0 then
            kit.gearText:SetText("Gear: |cff9d9d9dnothing to put on|r")
        else
            kit.gearText:SetText(("Gear: %s%s"):format(table.concat(names, ", "),
                bonus > 0 and ("  |cff40ff40+" .. bonus .. "|r") or ""))
        end
    end
end

-- ---------------------------------------------------------------------------------------------
-- The lists behind the lines of that section: what could be used instead
-- ---------------------------------------------------------------------------------------------
local function LureEntries()
    local settings = ns.settings
    local mode = settings.lureMode
    local entries = {
        { title = "Lure the fishing key puts on" },
        { text = "Automatic: the strongest I have", checked = mode == "auto",
            onClick = function() Lures.SetMode("auto") end },
    }
    local function Choose(itemID)
        return function()
            settings.lureMode = "specific"
            Lures.SetSpecific(itemID)
            -- The key only puts a lure on a bare pole, so the one that is on stays until then
            if Lures.TimeLeft() then
                LivePanel.Notice("|cff9d9d9dIt goes on when the lure on the pole runs out|r", 6)
            end
        end
    end
    local listed = false
    for _, lure in ipairs(Lures.InBags()) do
        local chosen = mode == "specific" and lure.id == settings.lureItem
        listed = listed or chosen
        entries[#entries + 1] = {
            text = ItemName(lure.id), icon = Util.ItemIcon(lure.id), checked = chosen, dim = not lure.usable,
            right = ("+%d  %s"):format(lure.bonus, lure.worn and "worn" or ("x" .. lure.count)),
            onClick = Choose(lure.id),
        }
    end
    if mode == "specific" and settings.lureItem and not listed then
        entries[#entries + 1] = {
            text = ItemName(settings.lureItem), icon = Util.ItemIcon(settings.lureItem), checked = true,
            dim = true, right = "none left", onClick = Choose(settings.lureItem),
        }
    end
    entries[#entries + 1] = { text = "Off: no lure", checked = mode == "off",
        onClick = function() Lures.SetMode("off") end }
    return entries
end

local function FoodEntries()
    local settings = ns.settings
    local mode = settings.foodMode
    local entries = {
        { title = "Food the fishing key eats" },
        { text = "Automatic: the strongest I have", checked = mode == "auto",
            onClick = function() Buffs.SetFoodMode("auto") end },
    }
    local function Choose(itemID)
        return function()
            settings.foodMode = "specific"
            Buffs.SetFood(itemID)
        end
    end
    local listed = false
    for _, item in ipairs(Buffs.InBags()) do
        if item.food then
            local chosen = mode == "specific" and item.id == settings.foodItem
            listed = listed or chosen
            entries[#entries + 1] = {
                text = ItemName(item.id), icon = Util.ItemIcon(item.id), checked = chosen, dim = not item.usable,
                right = ("+%d  x%d"):format(item.bonus, item.count), onClick = Choose(item.id),
            }
        end
    end
    if mode == "specific" and settings.foodItem and not listed then
        entries[#entries + 1] = {
            text = ItemName(settings.foodItem), icon = Util.ItemIcon(settings.foodItem), checked = true,
            dim = true, right = "none left", onClick = Choose(settings.foodItem),
        }
    end
    entries[#entries + 1] = { text = "Off: no food", checked = mode == "off",
        onClick = function() Buffs.SetFoodMode("off") end }
    return entries
end

local function GearEntries()
    local settings = ns.settings
    local entries = {
        { text = "Wear fishing gear while the pole is on", checked = settings.gear and true or false,
            onClick = function()
                settings.gear = not settings.gear
                ns.Fire("SETTINGS")
            end },
    }
    if not settings.gear then return entries end
    local function Choose(slot, choice)
        return function()
            Gear.Choose(slot, choice)
            if InCombatLockdown() or ns.inCombat then
                LivePanel.Notice("|cff9d9d9dClothing changes when combat ends|r", 6)
            end
        end
    end
    local groups = Gear.Options()
    for _, group in ipairs(groups) do
        entries[#entries + 1] = { title = Gear.SLOT_NAMES[group.slot] or "?" }
        entries[#entries + 1] = { text = "Automatic: the best I have", checked = group.choice == nil,
            onClick = Choose(group.slot, nil) }
        for _, item in ipairs(group.items) do
            entries[#entries + 1] = {
                text = Util.LinkName(item.link) or ItemName(item.id), icon = Util.ItemIcon(item.id),
                checked = group.choice == item.id,
                right = Gear.BonusText(item.bonus) .. (item.worn and "  on" or ""),
                onClick = Choose(group.slot, item.id),
            }
        end
        entries[#entries + 1] = { text = "Leave what I'm wearing", checked = group.choice == false,
            onClick = Choose(group.slot, false) }
    end
    if #groups == 0 then
        entries[#entries + 1] = { note = "No fishing gear in your bags" }
    end
    return entries
end

local function ShowRow(row, shown)
    row.icon:SetShown(shown)
    row.name:SetShown(shown)
    row.count:SetShown(shown)
    row.percent:SetShown(shown)
end

-- "Stonescale Eel   38   41%" for everything caught this session, most first. The panel grows
-- with the list up to MaxRows() rows; a longer list keeps that many rows and scrolls.
local function RefreshList(session)
    local list = {}
    if session and ns.settings.panelCatches then
        list = Sessions.CatchList(session)
    end
    local most = MaxRows()
    local visible = math.min(#list, most)
    local hidden = #list - visible
    listOffset = Clamp(listOffset, 0, hidden)
    for index = 1, visible do
        local entry = list[index + listOffset]
        local row = ListRow(index)
        if entry.unknown then
            row.icon:SetTexture(nil)
            row.name:SetText("|cff9d9d9d" .. entry.name .. "|r")
        else
            row.icon:SetTexture(entry.icon)
            row.name:SetText(W.QualityText(entry.name, entry.quality))
        end
        row.count:SetText(entry.count)
        row.percent:SetText(("|cff9d9d9d%d%%|r"):format(math.floor(entry.percent + 0.5)))
        ShowRow(row, true)
    end
    for index = visible + 1, #panel.rows do
        ShowRow(panel.rows[index], false)
    end
    -- The room the list takes. While the corner is dragged up or down that is the room being
    -- chosen, filled or not, so the corner stays under the mouse.
    local room = visible
    if sizing and sizing.moved then room = most end
    panel.listRoom = room
    panel.listLine:ClearAllPoints()
    panel.listLine:SetPoint("TOPLEFT", 10, ListTop() + 5)
    panel.listLine:SetPoint("TOPRIGHT", -10, ListTop() + 5)
    panel.listLine:SetShown(room > 0)

    -- More than fits: the mouse wheel scrolls, and a mark in the right margin shows where the
    -- rows on show are in the whole list. The wheel is only taken while there is something to
    -- scroll, so it zooms the camera as usual the rest of the time.
    local scrolls = hidden > 0
    panel.listStep = math.max(1, math.floor(visible / 3))
    panel:EnableMouseWheel(scrolls)
    panel.scrollTrack:SetShown(scrolls)
    panel.scrollThumb:SetShown(scrolls)
    if scrolls then
        local height = visible * LIST_ROW
        local thumb = math.max(8, height * visible / #list)
        panel.scrollTrack:ClearAllPoints()
        panel.scrollTrack:SetPoint("TOPRIGHT", -4, ListTop() + 1)
        panel.scrollTrack:SetSize(3, height)
        panel.scrollThumb:ClearAllPoints()
        panel.scrollThumb:SetPoint("TOPRIGHT", -4, ListTop() + 1 - (height - thumb) * listOffset / hidden)
        panel.scrollThumb:SetSize(3, thumb)
    end
    panel:SetHeight(HEIGHT + (ns.settings.panelKit and KIT_HEIGHT or 0)
        + (room > 0 and (room * LIST_ROW + 8) or 0))
end

-- ---------------------------------------------------------------------------------------------
-- The line's strip: a small pane hanging under the panel, with a bar that runs down while
-- the line is out and the seconds it has left ("Line out: 14 s"), and under the bar what the
-- last cast brought up, for a few seconds. It is for when the game's own cast bar and loot
-- window can't be seen: ns.settings.lineStrip is "hidden" (only while Keepnet has the
-- interface hidden; the default), "always" or "off".
-- ---------------------------------------------------------------------------------------------
local STRIP_ROW, STRIP_ROWS = 15, 4
local STRIP_BAR = 13
local CAME_SECONDS, EMPTY_SECONDS = 10, 3 -- (the catch list stayed 8 s until 1.2.8; the owner: 2 s longer)
-- What the last cast brought up, as lines to show ({ icon, text }), and until when
local came = { rows = nil, expires = 0 }

local function StripWanted()
    local mode = ns.settings.lineStrip
    if mode == "off" then return false end
    return mode == "always" or ns.HideUI.IsActive()
end

-- The bar and its seconds: as often as the screen is drawn while the strip shows
local function StripTick()
    local strip = panel.strip
    local now = GetTime()
    local from, ends = strip.lineFrom, strip.lineEnds
    local label
    if not from then
        strip.fill:Hide()
        label = "|cff9d9d9dLine in|r"
    elseif ends and ends > from then
        -- Runs down: full when the line goes out, empty when it comes in by itself
        local left = math.max(0, ends - now)
        local room = Width() - 18
        local width = room * math.min(1, left / (ends - from))
        if width >= 1 then
            strip.fill:SetWidth(width)
            strip.fill:Show()
        else
            strip.fill:Hide()
        end
        label = ("Line out: %d s"):format(math.ceil(left))
    else
        -- The game didn't say when it ends: count up
        strip.fill:SetWidth(Width() - 18)
        strip.fill:Show()
        label = ("Line out for %d s"):format(math.floor(now - from))
    end
    if label ~= strip.label then
        strip.label = label
        strip.text:SetText(label)
    end
end

local function StripRefresh()
    local strip = panel and panel.strip
    if not strip then return end
    if came.rows and GetTime() >= came.expires then came.rows = nil end
    local from, ends = ns.Fishing.Line()
    local rows = came.rows
    if not StripWanted() or not (from or rows) then
        strip:Hide()
        return
    end
    local shown = 0
    for index, row in ipairs(strip.rows) do
        local entry = rows and rows[index]
        if entry then
            row.icon:SetTexture(entry.icon)
            row.name:SetText(entry.text)
            shown = index
        end
        row.icon:SetShown(entry ~= nil)
        row.name:SetShown(entry ~= nil)
    end
    strip:SetHeight(7 + STRIP_BAR + 7 + (shown > 0 and shown * STRIP_ROW or 0))
    strip.lineFrom, strip.lineEnds = from, ends
    strip:Show()
    StripTick()
end

-- What a cast brought up, as the strip's lines
local function CameUp(loot)
    local rows = {}
    for index, drop in ipairs(loot) do
        if index == STRIP_ROWS and #loot > STRIP_ROWS then
            rows[#rows + 1] = { text = ("|cff9d9d9dand %d more|r"):format(#loot - STRIP_ROWS + 1) }
            break
        end
        if drop.hidden then
            rows[#rows + 1] = { text = "|cff9d9d9dsomething the game won't show yet|r" }
        else
            local name = drop.name or Util.LinkName(drop.link) or ("item " .. tostring(drop.id))
            rows[#rows + 1] = {
                icon = drop.icon or Util.ItemIcon(drop.id),
                text = W.QualityText(name, drop.quality) .. ((drop.count or 1) > 1 and ("  x" .. drop.count) or ""),
            }
        end
    end
    -- (coins are not in the list of what was caught)
    if #rows == 0 then rows[1] = { text = "|cff9d9d9dCoins|r" } end
    return rows
end

ns.On("CAST_END", function(result, loot)
    if result == "catch" then
        came.rows, came.expires = CameUp(loot or {}), GetTime() + CAME_SECONDS
    elseif result == "miss" then
        came.rows, came.expires = { { text = "|cff9d9d9dNothing on the line|r" } }, GetTime() + EMPTY_SECONDS
    else
        return -- thrown again: what the cast before brought up stays
    end
    StripRefresh()
end)
ns.On("LINE", function() StripRefresh() end)

local function CreateStrip()
    local retro = W.retro and ns.Retro
    local strip = W.Panel(nil, panel, Width(), 7 + STRIP_BAR + 7, "panel")
    panel.strip = strip
    strip:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -4)
    local bar = CreateFrame("Frame", nil, strip, "BackdropTemplate")
    strip.bar = bar
    bar:SetSize(Width() - 16, STRIP_BAR)
    bar:SetPoint("TOPLEFT", 8, -7)
    W.Skin(bar, W.COLORS.header, nil, "thin")
    if retro then
        strip.fill, strip.text = retro.Progress(bar)
    else
        strip.fill = bar:CreateTexture(nil, "ARTWORK")
        local inset = W.round and 2 or 1
        strip.fill:SetPoint("TOPLEFT", inset, -inset)
        strip.fill:SetPoint("BOTTOMLEFT", inset, inset)
        W.BarFill(strip.fill, W.native and 0.9 or 0.55)
        strip.text = W.Text(bar, "GameFontHighlightSmall")
        strip.text:SetPoint("CENTER")
    end
    strip.rows = {}
    for index = 1, STRIP_ROWS do
        local y = -(7 + STRIP_BAR + 5) - (index - 1) * STRIP_ROW
        local row = {}
        row.icon = strip:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(STRIP_ROW - 3, STRIP_ROW - 3)
        row.icon:SetPoint("TOPLEFT", 9, y)
        row.name = W.Text(strip)
        row.name:SetPoint("TOPLEFT", 9 + STRIP_ROW, y)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        strip.rows[index] = row
    end
    strip:SetScript("OnUpdate", function()
        if came.rows and GetTime() >= came.expires then
            StripRefresh() -- what came up has been shown long enough
        else
            StripTick()
        end
    end)
    strip:Hide()
end

-- Green: the skill (with lure, gear and food) is enough for guaranteed catches here.
-- Yellow: the line can be cast but some fish will get away. Red: it can't be cast here.
local STANDING_COLORS = Waters.COLORS

-- "Tanaris [300]": the zone and the Fishing skill for guaranteed catches in this water.
-- Just the zone where the number isn't known.
local function ZoneText(zone)
    local subzone = (zone == Core.Zone()) and Core.SubZone() or nil
    local guaranteed = Waters.Skill(zone, subzone)
    if not guaranteed then return zone end
    local color = "9d9d9d"
    local rank, _, bonus = Skill.Get()
    if rank then
        color = STANDING_COLORS[Waters.Standing(rank + bonus, guaranteed)]
    end
    return ("%s |cff%s[%d]|r"):format(zone, color, guaranteed)
end

-- "Fishing 187 / 225  +105 (292)" over a bar filled to 187/225: the trained skill, the cap,
-- the bonus from lure, gear and food, and in brackets the skill with that bonus added
local function RefreshSkill()
    local rank, max, bonus = Skill.Get()
    if not rank then
        panel.skillFill:Hide()
        panel.skillText:SetText("|cff9d9d9dFishing skill unknown|r")
        return
    end
    local fraction = max > 0 and math.min(1, rank / max) or 0
    if fraction > 0 then
        panel.skillFill:SetWidth(math.max(1, (Width() - 22) * fraction))
        panel.skillFill:Show()
    else
        panel.skillFill:Hide()
    end
    panel.skillText:SetText(("Fishing %d / %d%s"):format(rank, max,
        bonus > 0 and ("  |cff40ff40+%d (%d)|r"):format(bonus, rank + bonus) or ""))
end

-- "Rockscale Cod 12:30   Shiny Silver Coin 28:10", or what the key is waiting for
local function BuffLine()
    if GetTime() < notice.expires and notice.text then
        return notice.text
    end
    if Buffs.Waiting() then
        return "|cffffd100Eating: the key waits until you're fed|r"
    end
    local parts = {}
    for _, buff in ipairs(Buffs.Active()) do
        parts[#parts + 1] = buff.name .. (buff.left and (" " .. Util.MinutesSeconds(buff.left)) or "")
    end
    return "|cff9d9d9d" .. table.concat(parts, "   ") .. "|r"
end

local function Refresh()
    if not panel or not panel:IsShown() then return end
    local session = Sessions.Current()
    if session then
        -- The clock runs between casts too, up to the break limit, like the saved time will
        local active = session.active
        local sinceLast = time() - (session.last or time())
        if sinceLast > 0 and sinceLast <= Sessions.ACTIVE_GAP then
            active = active + sinceLast
        end
        local value, unpriced = Core.Value(session)
        local perHour = Sessions.PerHour(value, active)
        panel.zone:SetText(ZoneText(session.zone))
        panel.time:SetText(Util.Clock(active))
        panel.casts:SetText(("Casts: %d"):format(session.casts))
        panel.catches:SetText(("Catches: %d"):format(session.catches))
        panel.value:SetText("Value: " .. Util.Money(value)
            .. (unpriced > 0 and ("  |cff9d9d9d(%d without price)|r"):format(unpriced) or ""))
        panel.rate:SetText("Per hour: " .. (perHour and Util.Money(perHour) or "-"))
    else
        panel.zone:SetText(ZoneText(Core.Zone()))
        panel.time:SetText(Util.Clock(0))
        panel.casts:SetText("Casts: 0")
        panel.catches:SetText("Catches: 0")
        panel.value:SetText("Value: -")
        panel.rate:SetText("|cff9d9d9dCast to start a session|r")
    end
    panel.misses:SetText(("Empty: %d"):format(session and session.misses or 0))
    panel.gains:SetText(("Skill gains this session: %d"):format(session and session.skillUps or 0))
    panel.sound.label:SetText(ns.settings.sound and "Splash only" or "Game audio")
    RefreshKit()
    RefreshSkill()
    RefreshList(session)
    StripRefresh()
    panel.buffs:SetText(BuffLine())
    if GetTime() < notice.expires and notice.highlight then
        panel:SetBackdropBorderColor(unpack(W.COLORS.accent))
    else
        panel:SetBackdropBorderColor(W.BorderColor("panel"))
    end
end

-- Everything whose width follows the panel's
local function LayoutWidth()
    local width = Width()
    if panel.laidOut == width then return end
    panel.laidOut = width
    local kit = panel.kit
    panel:SetWidth(width)
    panel.zone:SetWidth(width - 96)
    panel.skillBar:SetWidth(width - 20)
    panel.buffs:SetWidth(width - 20)
    panel.menu:SetMenuWidth(width - 16)
    panel.strip:SetWidth(width)
    panel.strip.bar:SetWidth(width - 16)
    for _, row in ipairs(panel.strip.rows) do row.name:SetWidth(width - 18 - STRIP_ROW) end
    -- The lure line holds the lure's name, how many there are, its bonus and its time: the
    -- button beside it is only an "A" to leave room for all four
    kit.lureText:SetWidth(width - 20 - KIT_ROW - LURE_TOGGLE - 14)
    kit.lureRow:SetWidth(width - 16 - LURE_TOGGLE - 4)
    kit.foodText:SetWidth(width - 20 - KIT_ROW - 12)
    kit.foodRow:SetWidth(width - 16)
    kit.gearText:SetWidth(width - 20 - KIT_ROW - 12)
    kit.gearRow:SetWidth(width - 16)
end

local CreateGrip -- further down, with the rest of the corner that sizes the panel

local function Create()
    panel = W.Panel("KeepnetPanel", UIParent, Width(), HEIGHT, "panel")
    panel:SetFrameStrata("MEDIUM")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not ns.settings.panelLocked then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    -- The retro look gives the panel a title bar: the zone and the clock stand on it, and
    -- the cog is a small button at its end
    local retro = W.retro and ns.Retro
    if retro then retro.Caption(panel) end
    panel.zone = W.Text(panel, "GameFontNormal")
    panel.zone:SetPoint("TOPLEFT", retro and 7 or 10, retro and -6 or -9)
    panel.zone:SetJustifyH("LEFT")
    panel.zone:SetWordWrap(false)
    panel.time = W.Text(panel, "GameFontHighlight")
    panel.time:SetPoint("TOPRIGHT", retro and -26 or -30, retro and -6 or -9)
    if retro then
        -- (not bold: the number after the zone's name has a colour of its own)
        panel.zone.keepnetBold = false
        panel.zone:SetSurface("title")
        panel.time:SetSurface("title")
    end

    -- The cog: the window on its Settings tab, or closed again when that is what it shows
    local function Settings()
        -- The window is part of the interface: bring that back first
        ns.HideUI.Show()
        ns.UI.Toggle("settings")
    end
    if retro then
        panel.cog = retro.CaptionButton(panel, "dots", Settings)
        panel.cog:SetPoint("TOPRIGHT", -5, -5)
    else
        panel.cog = W.IconButton(panel, COG, 14, Settings)
        panel.cog:SetPoint("TOPRIGHT", -9, -8)
    end
    panel.cog.tooltip = "Settings"

    -- The Fishing skill bar
    local bar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.skillBar = bar
    bar:SetSize(Width() - 20, 15)
    bar:SetPoint("TOPLEFT", 10, -28)
    W.Skin(bar, W.COLORS.header, nil, "thin")
    if retro then
        panel.skillFill, panel.skillText = retro.Progress(bar)
    else
        panel.skillFill = bar:CreateTexture(nil, "ARTWORK")
        -- (clear of the round corners, where there are any)
        local inset = W.round and 2 or 1
        panel.skillFill:SetPoint("TOPLEFT", inset, -inset)
        panel.skillFill:SetPoint("BOTTOMLEFT", inset, inset)
        W.BarFill(panel.skillFill, W.native and 0.9 or 0.55)
        panel.skillText = W.Text(bar, "GameFontHighlightSmall")
        panel.skillText:SetPoint("CENTER")
    end

    -- Under the bar: the points of Fishing skill gained in the running session
    panel.gains = W.Text(panel)
    panel.gains:SetPoint("TOPLEFT", 10, -48)

    panel.casts = W.Text(panel)
    panel.casts:SetPoint("TOPLEFT", 10, -66)
    panel.catches = W.Text(panel)
    panel.catches:SetPoint("TOPLEFT", 92, -66)
    panel.misses = W.Text(panel)
    panel.misses:SetPoint("TOPRIGHT", -10, -66)

    panel.value = W.Text(panel, "GameFontHighlight")
    panel.value:SetPoint("TOPLEFT", 10, -84)
    panel.rate = W.Text(panel, "GameFontHighlight")
    panel.rate:SetPoint("TOPLEFT", 10, -102)
    -- Which Keepnet this is, small and dim in the free corner beside the value
    panel.version = W.Text(panel, "GameFontDisableSmall", "v" .. ns.VERSION)
    panel.version:SetPoint("TOPRIGHT", -10, -86)

    -- Switches what is heard while fishing: just the loud splash, or the game as it is set
    panel.sound = W.Button(panel, "Splash only", 78, 16, function()
        ns.settings.sound = not ns.settings.sound
        ns.Fire("SETTINGS")
    end)
    panel.sound:SetPoint("TOPRIGHT", -10, -101)
    panel.sound.tooltip = "Sound while fishing. Splash only: sound effects loud, music and the rest off. "
        .. "Game audio: your own sound settings."

    panel.buffs = W.Text(panel)
    panel.buffs:SetPoint("TOPLEFT", 10, -122)
    panel.buffs:SetJustifyH("LEFT")
    panel.buffs:SetWordWrap(false)

    -- The lure / food / gear section
    local kit = { regions = {}, rows = {} }
    panel.kit = kit
    panel.menu = W.Menu(Width() - 16)
    -- An open list goes with the panel
    panel:SetScript("OnHide", function() panel.menu:Close() end)
    local function Keep(region)
        kit.regions[#kit.regions + 1] = region
        return region
    end
    local kitLine = Keep(panel:CreateTexture(nil, "ARTWORK"))
    kitLine:SetHeight(1)
    kitLine:SetPoint("TOPLEFT", 10, KIT_TOP + 5)
    kitLine:SetPoint("TOPRIGHT", -10, KIT_TOP + 5)
    W.Rule(kitLine)
    local function KitRow(index, withIcon)
        local y = KIT_TOP - (index - 1) * KIT_ROW
        local icon
        if withIcon then
            icon = Keep(panel:CreateTexture(nil, "ARTWORK"))
            icon:SetSize(KIT_ROW - 3, KIT_ROW - 3)
            icon:SetPoint("TOPLEFT", 10, y)
        end
        local text = Keep(W.Text(panel))
        -- Every line starts at the same place, icon or not
        text:SetPoint("TOPLEFT", 10 + KIT_ROW, y - 1)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        return icon, text
    end
    -- Each line is a button as well: it opens the list of what could be used instead. The
    -- panel can still be dragged by these lines.
    local function KitButton(index, entries, tooltip)
        local row = Keep(CreateFrame("Button", nil, panel))
        row:SetHeight(KIT_ROW)
        row:SetPoint("TOPLEFT", 8, KIT_TOP - (index - 1) * KIT_ROW + 2)
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        W.Faint(highlight, 0.08)
        if retro then
            row.arrow = retro.Glyph(row, "down")
            row.arrow:SetPoint("RIGHT", -4, 0)
        else
            row.arrow = W.Text(row, "GameFontHighlightSmall", "v")
            row.arrow:SetPoint("RIGHT", -3, 0)
        end
        row:SetScript("OnClick", function(self)
            GameTooltip:Hide()
            if panel.menu:IsOpenAt(self) then
                panel.menu:Close()
            else
                panel.menu:Open(self, entries())
            end
        end)
        row:SetScript("OnEnter", function(self)
            if panel.menu:IsOpenAt(self) then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:RegisterForDrag("LeftButton")
        row:SetScript("OnDragStart", function() panel:GetScript("OnDragStart")(panel) end)
        row:SetScript("OnDragStop", function() panel:GetScript("OnDragStop")(panel) end)
        kit.rows[#kit.rows + 1] = row
        return row
    end
    kit.lureIcon, kit.lureText = KitRow(1, true)
    kit.lureRow = KitButton(1, LureEntries, "Click to choose the lure the fishing key puts on.")
    kit.lureToggle = Keep(W.Button(panel, "A", LURE_TOGGLE, KIT_ROW, function()
        -- Off, or back to how lures were being applied before (automatic or the chosen one)
        if ns.settings.lureMode == "off" then
            Lures.SetMode(ns.settings.lureModeBefore or "auto")
        else
            Lures.SetMode("off")
        end
    end))
    kit.lureToggle:SetPoint("TOPRIGHT", -10, KIT_TOP + 1)
    -- Its highlight: the accent colour over the button, shown while lures are applied. Above
    -- the button's own background and under its letter, in the flat and the native look alike.
    -- In the retro look the button stays in instead.
    if retro then
        kit.lureToggle.lit = retro.Latch(kit.lureToggle)
    else
        kit.lureToggle.lit = kit.lureToggle:CreateTexture(nil, "BORDER")
        kit.lureToggle.lit:SetPoint("TOPLEFT", 1, -1)
        kit.lureToggle.lit:SetPoint("BOTTOMRIGHT", -1, 1)
        W.Accent(kit.lureToggle.lit, 0.55)
    end
    kit.foodIcon, kit.foodText = KitRow(2, true)
    kit.foodRow = KitButton(2, FoodEntries, "Click to choose the food the fishing key eats.")
    local _, gearText = KitRow(3, false)
    kit.gearText = gearText
    kit.gearRow = KitButton(3, GearEntries, "Click to choose the fishing gear to wear.")

    panel.rows = {}
    panel.listLine = panel:CreateTexture(nil, "ARTWORK")
    panel.listLine:SetHeight(1)
    panel.listLine:SetPoint("TOPLEFT", 10, LIST_TOP + 5)
    panel.listLine:SetPoint("TOPRIGHT", -10, LIST_TOP + 5)
    W.Rule(panel.listLine)
    panel.listLine:Hide()
    -- Where the rows on show are in a list that is longer than its room: a faint track in the
    -- right margin with a mark in the accent colour. The mouse wheel does the scrolling.
    panel.scrollTrack = panel:CreateTexture(nil, "ARTWORK")
    W.Faint(panel.scrollTrack, 0.1)
    panel.scrollTrack:Hide()
    panel.scrollThumb = panel:CreateTexture(nil, "OVERLAY")
    W.Accent(panel.scrollThumb, 0.9)
    panel.scrollThumb:Hide()
    panel:SetScript("OnMouseWheel", function(_, delta)
        listOffset = listOffset - delta * (panel.listStep or 1)
        Refresh()
    end)
    panel:EnableMouseWheel(false)

    panel.new = W.Button(panel, "New session", 10, 22, function() Core.NewSession() end)
    panel.new.tooltip = "End this session. A new one starts with your next cast."
    panel.history = W.Button(panel, "History", 10, 22, function()
        -- The window is part of the interface: bring that back first
        ns.HideUI.Show()
        ns.UI.Show("history")
    end)
    panel.hide = W.Button(panel, "Hide UI", 10, 22, function() ns.HideUI.Toggle() end)
    panel.hide.tooltip = "Hide the game's interface, or bring it back."
    -- Escape brings the interface back. The key is passed on, so nothing else changes; without
    -- that ability the panel doesn't listen at all, or it would swallow every key.
    panel:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" and detached then ns.HideUI.Show() end
    end)

    -- The clock ticks once a second
    local since = 0
    panel:SetScript("OnUpdate", function(_, elapsed)
        since = since + elapsed
        if since >= 1 then
            since = 0
            ns.HideUI.Check()
            Refresh()
        end
    end)
    CreateGrip()
    CreateStrip()
    LayoutWidth()
    ApplyPosition()
    LivePanel.Detach(detached)
end

-- Two buttons, or three when hiding the interface is turned on
local function LayoutButtons()
    local buttons = { panel.new, panel.history }
    if ns.HideUI.Enabled() then
        buttons[3] = panel.hide
        panel.hide.label:SetText(ns.HideUI.IsActive() and "Show UI" or "Hide UI")
    end
    panel.hide:SetShown(#buttons == 3)
    -- The corner for sizing goes when the panel is locked in place
    panel.grip:SetShown(not ns.settings.panelLocked)
    local gap = 6
    local width = (Width() - 20 - gap * (#buttons - 1)) / #buttons
    for i, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetSize(width, 22)
        button:SetPoint("BOTTOMLEFT", 10 + (i - 1) * (width + gap), 9)
    end
end

-- ---------------------------------------------------------------------------------------------
-- The corner that sizes the panel. Dragged sideways it sets the panel's width; dragged up or
-- down it sets how many catches show before the list scrolls (the panel still only takes the
-- room of the catches there are). The drag is followed by hand, a frame at a time, instead of
-- with the game's own sizing: the panel keeps its top left corner, and the height moves a
-- whole row at a time.
-- ---------------------------------------------------------------------------------------------
-- Where the mouse is, in the panel's own measure
local function Cursor()
    local x, y = GetCursorPosition()
    local scale = panel:GetEffectiveScale() or 1
    if scale == 0 then scale = 1 end
    return x / scale, y / scale
end

local function Relayout()
    LayoutWidth()
    LayoutButtons()
    Refresh()
end

local function StopSizing()
    if not sizing then return end
    sizing = nil
    -- Back to the room of the catches there are
    Refresh()
end

local function StartSizing()
    if sizing or ns.settings.panelLocked then return end
    panel.menu:Close()
    GameTooltip:Hide()
    -- Held by its top left corner from here on, so the dragged corner is the one that moves
    SavePosition()
    local x, y = Cursor()
    -- rows: what the list shows now, which is where the corner is
    sizing = { x = x, y = y, width = Width(), rows = panel.listRoom or 0, moved = false }
end

-- Follows the mouse while the corner is held
local function Size()
    if not IsMouseButtonDown("LeftButton") then
        StopSizing()
        return
    end
    local x, y = Cursor()
    local saved = ns.db.panelSize
    local before = saved and saved.rows or nil
    local width = Clamp(math.floor(sizing.width + (x - sizing.x) + 0.5), WIDTH, MAX_WIDTH)
    local rows = before
    -- Up and down only counts once the mouse has gone a row's height, so a drag sideways
    -- leaves the list as it was; and it means nothing with the catch list turned off
    local began = false
    if ns.settings.panelCatches then
        local delta = math.floor((sizing.y - y) / LIST_ROW + 0.5)
        if delta ~= 0 and not sizing.moved then
            sizing.moved, began = true, true
        end
        if sizing.moved then rows = Clamp(sizing.rows + delta, MIN_ROWS, MAX_ROWS) end
    end
    if width == Width() and rows == before and not began then return end
    if width == WIDTH and not rows then
        ns.db.panelSize = nil
    else
        ns.db.panelSize = { width = width, rows = rows }
    end
    if sizing.moved then
        LivePanel.Notice(("|cff9d9d9dUp to %d catches, then the list scrolls|r"):format(rows), 4)
    end
    Relayout()
end

function CreateGrip()
    local grip = CreateFrame("Button", nil, panel)
    panel.grip = grip
    grip:SetSize(12, 12)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    -- Above the buttons along the bottom, whose corner it touches
    grip:SetFrameLevel((panel:GetFrameLevel() or 1) + 5)
    -- Drawn here, not taken from a picture file: six dots stepping up into the corner
    grip.dots = {}
    for _, at in ipairs({ { 2, 0 }, { 6, 0 }, { 10, 0 }, { 6, 4 }, { 10, 4 }, { 10, 8 } }) do
        local dot = grip:CreateTexture(nil, "OVERLAY")
        dot:SetSize(2, 2)
        dot:SetPoint("BOTTOMLEFT", at[1], at[2])
        grip.dots[#grip.dots + 1] = dot
    end
    local function Paint(alpha)
        for _, dot in ipairs(grip.dots) do W.Faint(dot, alpha) end
    end
    Paint(0.4)
    grip:SetScript("OnEnter", function(self)
        Paint(0.9)
        if sizing then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Drag to size the panel: sideways for its width, up and down for how many "
            .. "catches show before the list scrolls. /kn reset puts it back.", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function()
        Paint(0.4)
        GameTooltip:Hide()
    end)
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then StartSizing() end
    end)
    grip:SetScript("OnMouseUp", StopSizing)
    grip:SetScript("OnHide", StopSizing)
    grip:SetScript("OnUpdate", function()
        if sizing then Size() end
    end)
end

local function ApplyScale()
    -- Under the world frame the panel no longer takes the interface's own scale
    local outer = 1
    if detached then
        local world = WorldFrame:GetEffectiveScale() or 1
        outer = (UIParent:GetEffectiveScale() or 1) / (world ~= 0 and world or 1)
    end
    panel:SetScale(outer * (ns.settings.panelScale or 1))
end

-- Lifts the panel out of the game's interface (so it stays when that is hidden) or puts it back
function LivePanel.Detach(out)
    detached = out and true or false
    if not panel then return end
    -- An open list belongs to where the panel was
    panel.menu:Close()
    -- Where it is now, to put it in the same place under its new parent. The numbers stay
    -- valid because the panel's overall scale is kept the same on both sides.
    local left, top = panel:GetLeft(), panel:GetTop()
    local home = detached and WorldFrame or UIParent
    if detached then
        panel:SetParent(WorldFrame)
        if panel.SetPropagateKeyboardInput then
            panel:EnableKeyboard(true)
            panel:SetPropagateKeyboardInput(true)
        end
    else
        panel:EnableKeyboard(false)
        panel:SetParent(UIParent)
    end
    panel:SetFrameStrata(detached and "HIGH" or "MEDIUM")
    ApplyScale()
    if left and top then
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", home, "BOTTOMLEFT", left, top)
    end
end

-- Shows a line on the panel for a few seconds
function LivePanel.Notice(text, seconds, highlight)
    notice.text, notice.expires, notice.highlight = text, GetTime() + (seconds or NOTICE_SECONDS), highlight or false
    if panel then
        panel.buffs:SetText(text)
    end
end

local function UpdateShown()
    local show = ns.fishing and not hiddenByPlayer
    if show and not panel then Create() end
    if panel then
        LayoutButtons()
        panel:SetShown(show and true or false)
        Refresh()
    end
end

-- /kn panel: hide or show it for now; it comes back the next time the pole goes on
function LivePanel.Toggle()
    if panel and panel:IsShown() then
        hiddenByPlayer = true
    else
        hiddenByPlayer = false
        if not ns.fishing then
            Util.Print("The live panel shows while a fishing pole is equipped.")
        end
    end
    UpdateShown()
end

-- Back to the middle of the screen, at the size it started with
function LivePanel.ResetPosition()
    ns.db.panel = nil
    ns.db.panelSize = nil
    if panel then
        ApplyPosition()
        Relayout()
    end
end

ns.On("MODE", function(on)
    if on then hiddenByPlayer = false end
    UpdateShown()
end)
ns.On("SESSION", Refresh)
ns.On("TICK", Refresh)
-- The panel's place and size are the character's own: once it is known who is playing
ns.On("CHARACTER", function()
    if panel then
        ApplyPosition()
        Relayout()
    end
end)
ns.On("SETTINGS", function()
    if panel then
        ApplyScale()
        LayoutButtons()
    end
    Refresh()
end)
ns.On("HIDEUI", function()
    if panel then LayoutButtons() end
    Refresh()
end)
ns.On("THEME", Refresh)
ns.On("BUFFS", Refresh)
ns.On("LURES", Refresh)
ns.On("GEAR", Refresh)
ns.On("RARE", function(item)
    LivePanel.Notice("|cff" .. W.AccentHex() .. "Rare catch: " .. (item.name or Util.LinkName(item.link) or "?") .. "|r",
        RARE_SECONDS, true)
    Refresh()
end)
