-- Keepnet: the log, shown as text to copy (the "Collect logs" button on the Settings tab).
-- An addon can't write a file of its own, so the lines are put in a box, selected, and the
-- player copies them with Ctrl+C.
local _, ns = ...
local W = ns.Widgets

local LogWindow = {}
ns.LogWindow = LogWindow

local WIDTH, HEIGHT = 620, 400
local window, box, count

local function Fill()
    local text, lines = ns.LogReport()
    count:SetText(("%d line%s. Ctrl+A, Ctrl+C, then paste into a new issue at %s"):format(lines,
        lines == 1 and "" or "s", ns.ISSUES))
    box:SetText(text)
    box:SetCursorPosition(0)
    box:HighlightText()
    box:SetFocus()
end

local function Create()
    window = W.Panel("KeepnetLogWindow", UIParent, WIDTH, HEIGHT, "window")
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    if UISpecialFrames then table.insert(UISpecialFrames, "KeepnetLogWindow") end

    local title = W.Text(window, "GameFontNormal", "Keepnet log")
    title:SetPoint("TOPLEFT", 14, -32)
    count = W.Text(window, "GameFontDisableSmall")
    count:SetPoint("LEFT", title, "RIGHT", 10, 0)

    local scroll = CreateFrame("ScrollFrame", nil, window)
    scroll:SetPoint("TOPLEFT", 14, -54)
    scroll:SetPoint("BOTTOMRIGHT", -14, 44)
    scroll:EnableMouseWheel(true)
    local at = 0
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local most = math.max(0, (box:GetHeight() or 0) - (self:GetHeight() or 0))
        at = math.max(0, math.min(most, at - delta * 60))
        self:SetVerticalScroll(at)
    end)

    box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetWidth(WIDTH - 28)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- The game lets no addon put text on the clipboard (the call is refused), so the copy is
    -- the player's own Ctrl+C; this only says that it was seen
    box:SetScript("OnKeyDown", function(_, key)
        if key == "C" and IsControlKeyDown and IsControlKeyDown() then
            count:SetText("|cff" .. ns.Tone("ok") .. "Copied.|r Now paste it into a new issue at " .. ns.ISSUES)
        end
    end)
    scroll:SetScrollChild(box)

    local close = W.Button(window, "Close", 80, 22, function() window:Hide() end)
    close:SetPoint("BOTTOMRIGHT", -14, 12)
    local again = W.Button(window, "Refresh", 80, 22, Fill)
    again:SetPoint("RIGHT", close, "LEFT", -8, 0)
    -- Selects everything and puts the cursor in the box, so that Ctrl+C is all that is left
    local all = W.Button(window, "Select all", 90, 22, function()
        box:SetFocus()
        box:HighlightText()
        count:SetText("All selected: press Ctrl+C to copy.")
    end)
    all:SetPoint("BOTTOMLEFT", 14, 12)
    LogWindow.all = all
    local clear = W.Button(window, "Clear", 80, 22, function()
        ns.LogClear()
        Fill()
    end)
    clear:SetPoint("RIGHT", again, "LEFT", -8, 0)
    LogWindow.box, LogWindow.count = box, count
end

function LogWindow.Show()
    if not window then Create() end
    window:Show()
    Fill()
end
