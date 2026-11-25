-- Keepnet: the building blocks of the screens: flat panels and buttons, a tick box, a slider,
-- a drop-down list, a text box and the sortable table, and the theme that colours them all.
-- Built from plain frames so they don't depend on game templates that differ between client
-- versions.
--   "THEME"  the colours changed; screens redraw what they coloured themselves
local _, ns = ...
local Util = ns.Util

local W = {}
ns.Widgets = W

local FLAT = "Interface\\Buttons\\WHITE8x8"

-- ---------------------------------------------------------------------------------------------
-- Themes. All dark, since the text is the game's own light fonts. The first is the default.
--
-- A theme is six colours, and one of two looks:
--   flat    (the default) plain coloured frames with thin borders, all drawn by Keepnet;
--   native  (native = true) everything made from the game's own templates and art.
-- Themes of the same look switch at once. Going from one look to the other rebuilds every
-- frame, which needs the interface reloaded; the player is asked.
-- A native theme names the game art for the pieces that have no template: "art" for the live
-- panel, "smallArt" for bars and item slots; its colours only tint that art.
-- A native theme may also name an interface suite in "adopt": every piece is then handed to
-- that suite to paint (UI\Adopt.lua, which needs an adapter for the suite).
-- To add a theme, add an entry here: nothing else needs to know.
-- ---------------------------------------------------------------------------------------------
-- The game's tooltip frame, for the pieces of a native theme that have no template of their own
local NATIVE_ART = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local NATIVE_SMALL_ART = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

W.THEMES = {
    {
        -- Keepnet's own look: flat, blue-black, a cyan accent
        key = "keepnet", name = "Keepnet",
        background = { 0.06, 0.07, 0.09 }, header = { 0.13, 0.15, 0.19 }, button = { 0.17, 0.20, 0.25 },
        buttonHover = { 0.24, 0.29, 0.36 }, border = { 0, 0, 0 }, accent = { 0.31, 0.76, 0.97 },
    },
    {
        -- The game's own look. native = true: every window, button, tick box, slider, text box,
        -- drop-down and tab is made from the client's own templates (UI\Native.lua), so it
        -- looks like whatever this client ships. The colours below only tint the few pieces
        -- that have no template of their own: the live panel, bars and item slots, which are
        -- drawn with the game's tooltip frame.
        key = "forever", name = "Forever", native = true,
        background = { 0.05, 0.05, 0.08 }, header = { 0.10, 0.09, 0.08 }, button = { 0.08, 0.08, 0.08 },
        buttonHover = { 0.20, 0.20, 0.20 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
        art = NATIVE_ART, smallArt = NATIVE_SMALL_ART,
        artBorder = { 0.8, 0.8, 0.8 },
    },
    {
        -- EllesmereUI: built like Forever, then every piece is handed to EllesmereUI to paint
        -- (UI\\Adopt.lua). The accent is that suite's own. Without EllesmereUI installed it is the
        -- Forever look.
        key = "ellesmereui", name = "EllesmereUI", native = true, adopt = "EllesmereUI",
        background = { 0.05, 0.05, 0.08 }, header = { 0.10, 0.10, 0.11 }, button = { 0.08, 0.08, 0.08 },
        buttonHover = { 0.20, 0.20, 0.20 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
        art = NATIVE_ART, smallArt = NATIVE_SMALL_ART, artBorder = { 0.8, 0.8, 0.8 },
    },
    {
        -- ElvUI: built like Forever, then every piece is handed to ElvUI to paint
        -- (UI\\Adopt.lua). The accent is that suite's own. Without ElvUI installed it is the
        -- Forever look.
        key = "elvui", name = "ElvUI", native = true, adopt = "ElvUI",
        background = { 0.05, 0.05, 0.08 }, header = { 0.10, 0.10, 0.11 }, button = { 0.08, 0.08, 0.08 },
        buttonHover = { 0.20, 0.20, 0.20 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
        art = NATIVE_ART, smallArt = NATIVE_SMALL_ART, artBorder = { 0.8, 0.8, 0.8 },
    },
    {
        key = "slate", name = "Slate",
        background = { 0.10, 0.10, 0.11 }, header = { 0.17, 0.17, 0.19 }, button = { 0.23, 0.23, 0.26 },
        buttonHover = { 0.32, 0.32, 0.36 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
    },
    {
        key = "forest", name = "Forest",
        background = { 0.05, 0.08, 0.06 }, header = { 0.10, 0.17, 0.12 }, button = { 0.14, 0.23, 0.16 },
        buttonHover = { 0.20, 0.33, 0.23 }, border = { 0, 0, 0 }, accent = { 0.52, 0.88, 0.45 },
    },
    {
        key = "ember", name = "Ember",
        background = { 0.10, 0.06, 0.05 }, header = { 0.20, 0.12, 0.09 }, button = { 0.27, 0.16, 0.12 },
        buttonHover = { 0.38, 0.23, 0.16 }, border = { 0, 0, 0 }, accent = { 1.00, 0.58, 0.22 },
    },
    {
        key = "dusk", name = "Dusk",
        background = { 0.06, 0.05, 0.10 }, header = { 0.13, 0.11, 0.21 }, button = { 0.18, 0.15, 0.29 },
        buttonHover = { 0.26, 0.22, 0.41 }, border = { 0, 0, 0 }, accent = { 0.74, 0.58, 1.00 },
    },
    {
        key = "black", name = "Plain black",
        background = { 0, 0, 0 }, header = { 0.10, 0.10, 0.10 }, button = { 0.17, 0.17, 0.17 },
        buttonHover = { 0.28, 0.28, 0.28 }, border = { 0.30, 0.30, 0.30 }, accent = { 1, 1, 1 },
    },
}

-- The colours in use. These tables are filled by W.ApplyTheme and never replaced, so anything
-- holding one of them sees a new theme at once.
W.COLORS = {
    background = { 0.06, 0.07, 0.09, 1 },
    border = { 0, 0, 0, 1 },
    header = { 0.13, 0.15, 0.19, 1 },
    button = { 0.17, 0.20, 0.25, 1 },
    buttonHover = { 0.24, 0.29, 0.36, 1 },
    accent = { 0.31, 0.76, 0.97 },
}

-- How see-through the background of each kind of top-level frame is: "window" and "panel"
W.opacity = { window = 0.94, panel = 0.94 }

local skinned = {} -- every frame given a backdrop: { frame, color, group }
local accents = {} -- every texture drawn in the accent colour: { texture, alpha }

local FLAT_BACKDROP = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 }
local activeTheme -- set by W.ApplyTheme

local function Paint(entry)
    if entry.frame.keepnetAdopted then
        -- The player's interface suite paints this one (UI\Adopt.lua)
        entry.frame:SetBackdropColor(0, 0, 0, 0)
        entry.frame:SetBackdropBorderColor(0, 0, 0, 0)
        return
    end
    -- A theme with frame art: the big frames (those with a group) take "art", the small
    -- pieces "smallArt"
    local art
    if activeTheme then
        art = entry.group and activeTheme.art or (not entry.group and activeTheme.smallArt) or nil
    end
    local backdrop = art or FLAT_BACKDROP
    if entry.backdrop ~= backdrop then
        entry.frame:SetBackdrop(backdrop)
        entry.backdrop = backdrop
    end
    local color = entry.color
    local alpha = entry.group and W.opacity[entry.group] or 1
    entry.frame:SetBackdropColor(color[1], color[2], color[3], alpha)
    if art then
        local tint = activeTheme.artBorder or W.COLORS.border
        entry.frame:SetBackdropBorderColor(tint[1], tint[2], tint[3], W.COLORS.border[4] or 1)
    else
        entry.frame:SetBackdropBorderColor(unpack(W.COLORS.border))
    end
end

-- The border colour a frame goes back to after being highlighted
function W.BorderColor(group)
    local art = activeTheme and (group and activeTheme.art or (not group and activeTheme.smallArt))
    local tint = art and activeTheme.artBorder or W.COLORS.border
    return tint[1], tint[2], tint[3], W.COLORS.border[4] or 1
end

-- Gives a frame a background in one of the W.COLORS and a border. group is "window" or "panel"
-- for a big frame: its background follows that opacity setting and takes the theme's frame
-- art, when the theme has any.
function W.Skin(frame, color, group)
    local entry = { frame = frame, color = color or W.COLORS.background, group = group }
    skinned[#skinned + 1] = entry
    W.built = true
    Paint(entry)
end

-- A bar's filling in the accent colour: flat, or the game's status bar art in a native theme
local BAR_ART = "Interface\\TargetingFrame\\UI-StatusBar"
function W.BarFill(texture, alpha)
    if not W.native then
        W.Accent(texture, alpha)
        return
    end
    local accent = W.COLORS.accent
    texture:SetTexture(BAR_ART)
    texture:SetVertexColor(accent[1], accent[2], accent[3], alpha or 1)
    accents[#accents + 1] = { texture = texture, alpha = alpha or 1, vertex = true }
end

-- Colours a texture in the accent colour, now and whenever the theme changes
function W.Accent(texture, alpha)
    local accent = W.COLORS.accent
    texture:SetColorTexture(accent[1], accent[2], accent[3], alpha or 1)
    accents[#accents + 1] = { texture = texture, alpha = alpha or 1 }
end

-- The accent colour as "rrggbb", for colouring text
function W.AccentHex()
    local accent = W.COLORS.accent
    return ("%02x%02x%02x"):format(accent[1] * 255, accent[2] * 255, accent[3] * 255)
end

function W.Theme(key)
    for _, theme in ipairs(W.THEMES) do
        if theme.key == key then return theme end
    end
    return W.THEMES[1]
end

-- The character's class colour, or nil
local function ClassColor()
    local _, class = UnitClass("player")
    local color = class and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
    if color and color.r then return { color.r, color.g, color.b } end
end

-- Takes the theme, accent and opacity from the settings and recolours everything on screen
StaticPopupDialogs["KEEPNET_RELOAD_FOR_THEME"] = {
    text = "Keepnet has to reload the interface to change to this look.",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function W.ApplyTheme()
    local settings = ns.settings or {}
    local theme = W.Theme(settings.theme)
    local native = theme.native and true or false
    local adopting = theme.adopt or false -- the suite's name
    if W.native == nil or not W.built then
        -- Nothing is on screen yet: the look is free to choose
        W.native, W.adopting = native, adopting
    elseif native ~= W.native or adopting ~= W.adopting then
        -- Frames of the other look are already built. The choice is saved and takes effect
        -- at the next reload; until then everything stays as it is.
        StaticPopup_Show("KEEPNET_RELOAD_FOR_THEME")
        return
    end
    activeTheme = theme
    for _, name in ipairs({ "background", "header", "button", "buttonHover", "border" }) do
        local from, to = theme[name], W.COLORS[name]
        to[1], to[2], to[3], to[4] = from[1], from[2], from[3], 1
    end
    -- (the border's fourth number is set below: borders can be turned off)
    local accent = theme.accent
    if adopting and ns.Adopt then
        accent = ns.Adopt.Accent() or accent
    end
    if settings.accentMode == "class" then
        accent = ClassColor() or accent
    elseif settings.accentMode == "custom" and settings.accentColor then
        accent = settings.accentColor
    end
    W.COLORS.accent[1], W.COLORS.accent[2], W.COLORS.accent[3] = accent[1], accent[2], accent[3]
    W.COLORS.border[4] = (settings.borders == false) and 0 or 1
    W.opacity.window = settings.windowOpacity or 0.94
    W.opacity.panel = settings.panelOpacity or 0.94
    for _, entry in ipairs(skinned) do
        Paint(entry)
    end
    for _, entry in ipairs(accents) do
        if entry.vertex then
            entry.texture:SetVertexColor(accent[1], accent[2], accent[3], entry.alpha)
        else
            entry.texture:SetColorTexture(accent[1], accent[2], accent[3], entry.alpha)
        end
    end
    ns.Fire("THEME")
end

ns.On("INIT", W.ApplyTheme)

-- Opens the game's colour picker. onChange(r, g, b) is called as the player drags, and with
-- the old colour again on Cancel.
function W.PickColor(r, g, b, onChange)
    local function Picked()
        onChange(ColorPickerFrame:GetColorRGB())
    end
    local function Cancelled()
        onChange(r, g, b)
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false, swatchFunc = Picked, cancelFunc = Cancelled,
        })
    else
        -- Clients before the picker was reworked
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = Picked
        ColorPickerFrame.cancelFunc = Cancelled
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

function W.Panel(name, parent, width, height, group)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    W.Skin(frame, W.COLORS.background, group)
    if group == "panel" and ns.Adopt then
        ns.Adopt.Apply("panel", frame)
    end
    return frame
end

function W.Text(parent, font, text)
    local fontString = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fontString:SetText(text or "")
    if ns.Adopt then ns.Adopt.Apply("text", fontString) end
    return fontString
end

-- A flat button. button.label is its text.
function W.Button(parent, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 22)
    W.Skin(button, W.COLORS.button)
    button.label = W.Text(button, "GameFontHighlightSmall", text)
    button.label:SetPoint("CENTER")
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(W.COLORS.buttonHover))
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(W.COLORS.button))
        GameTooltip:Hide()
    end)
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

-- A tab of the window. tab:SetSelected(true/false) marks it as the one showing.
function W.Tab(parent, name, title, onClick)
    local tab = W.Button(parent, title, 100, 22, onClick)
    tab.line = tab:CreateTexture(nil, "OVERLAY")
    tab.line:SetHeight(2)
    tab.line:SetPoint("BOTTOMLEFT")
    tab.line:SetPoint("BOTTOMRIGHT")
    W.Accent(tab.line)
    function tab:SetSelected(selected)
        if selected then
            self.label:SetTextColor(unpack(W.COLORS.accent))
        else
            self.label:SetTextColor(1, 1, 1)
        end
        self.line:SetShown(selected and true or false)
    end
    return tab
end

-- A column heading of a table. header.label is its text.
function W.Header(parent, title, width, height, right)
    local header = CreateFrame("Button", nil, parent, "BackdropTemplate")
    header:SetSize(width, height)
    W.Skin(header, W.COLORS.header)
    header.label = W.Text(header, "GameFontNormalSmall", title)
    header.label:SetPoint(right and "RIGHT" or "LEFT", right and -6 or 6, 0)
    return header
end

-- A tick box with its text to the right. onChange(checked) is called when the player clicks.
function W.Check(parent, text, onChange)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetSize(16, 16)
    W.Skin(check, W.COLORS.button)
    local tick = check:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT", 3, -3)
    tick:SetPoint("BOTTOMRIGHT", -3, 3)
    W.Accent(tick)
    check:SetCheckedTexture(tick)
    check.label = W.Text(check, "GameFontHighlightSmall", text)
    check.label:SetPoint("LEFT", check, "RIGHT", 6, 0)
    -- Clicking the text ticks the box too
    check:SetHitRectInsets(0, -(check.label:GetStringWidth() or 0) - 8, 0, 0)
    check:SetScript("OnClick", function(self)
        if onChange then onChange(self:GetChecked() and true or false) end
    end)
    return check
end

-- A horizontal slider. onChange(value) is called while the player drags.
function W.Slider(parent, width, low, high, step, onChange)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetSize(width, 14)
    slider:SetOrientation("HORIZONTAL")
    W.Skin(slider, W.COLORS.header)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 14)
    W.Accent(thumb)
    slider:SetThumbTexture(thumb)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider.value = W.Text(slider, "GameFontHighlightSmall")
    slider.value:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    slider:SetScript("OnValueChanged", function(self, value, userInput)
        -- Snap by hand as well: older clients don't hold to the step while dragging
        value = math.floor(value / step + 0.5) * step
        if self.silent then return end
        if onChange then onChange(value, userInput) end
    end)
    -- Sets the position without calling onChange
    function slider:Set(value)
        self.silent = true
        self:SetValue(value)
        self.silent = false
    end
    return slider
end

-- A one-line text box. onEnter(text) is called when the player presses Enter, and
-- onChange(text), when given, on every change the player types.
function W.EditBox(parent, width, onEnter, onChange)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 20)
    W.Skin(box, W.COLORS.header)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetAutoFocus(false)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetMaxLetters(64)
    box:SetScript("OnEnterPressed", function(self)
        if onEnter then onEnter(self:GetText()) end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if onChange then
        box:SetScript("OnTextChanged", function(self) onChange(self:GetText() or "") end)
    end
    return box
end

-- ---------------------------------------------------------------------------------------------
-- Drop-down list. One list frame is shared by every drop-down.
-- ---------------------------------------------------------------------------------------------
local POPUP_ROWS = 14
local POPUP_ROW_HEIGHT = 18
local POPUP_MORE_HEIGHT = 16 -- the line under a long list that says it scrolls
local popup

local function PopupRefresh()
    local options = popup.options
    for i, row in ipairs(popup.rows) do
        local option = options[i + popup.offset]
        if option then
            row.option = option
            row.label:SetText(option.text)
            if option.value == popup.owner.value then
                row.label:SetTextColor(unpack(W.COLORS.accent))
            else
                row.label:SetTextColor(1, 1, 1)
            end
            row:Show()
        else
            row:Hide()
        end
    end
    -- A list longer than fits says so, and how much is out of sight each way
    local above = popup.offset
    local below = math.max(0, #options - POPUP_ROWS - popup.offset)
    if #options > POPUP_ROWS then
        local parts = {}
        if above > 0 then parts[#parts + 1] = above .. " above" end
        if below > 0 then parts[#parts + 1] = below .. " more below" end
        popup.more:SetText(table.concat(parts, ", ") .. ": mouse wheel")
        popup.more:Show()
    else
        popup.more:Hide()
    end
end

local function PopupCreate()
    -- Catches a click anywhere else and closes the list
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()

    popup = CreateFrame("Frame", nil, catcher, "BackdropTemplate")
    W.Skin(popup, W.COLORS.header)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup.catcher = catcher
    popup.rows = {}
    popup.offset = 0
    catcher:SetScript("OnClick", function() catcher:Hide() end)
    for i = 1, POPUP_ROWS do
        local row = CreateFrame("Button", nil, popup)
        row:SetHeight(POPUP_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 1, -1 - (i - 1) * POPUP_ROW_HEIGHT)
        row:SetPoint("RIGHT", -1, 0)
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.12)
        row.label = W.Text(row, "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", 6, 0)
        row:SetScript("OnClick", function(self)
            local dropdown = popup.owner
            catcher:Hide()
            dropdown:Set(self.option.value, self.option.text)
            if dropdown.onSelect then dropdown.onSelect(self.option.value) end
        end)
        popup.rows[i] = row
    end
    popup.more = W.Text(popup, "GameFontDisableSmall")
    popup.more:SetPoint("BOTTOMLEFT", 6, 3)
    popup.more:SetTextColor(unpack(W.COLORS.accent))
    popup:EnableMouseWheel(true)
    popup:SetScript("OnMouseWheel", function(_, delta)
        local most = math.max(0, #popup.options - POPUP_ROWS)
        popup.offset = math.max(0, math.min(most, popup.offset - delta))
        PopupRefresh()
    end)
end

-- getOptions() returns { { value = ..., text = "..." }, ... }; onSelect(value) is called when
-- the player picks one. dropdown:Set(value, text) shows a choice without calling onSelect.
function W.Dropdown(parent, width, getOptions, onSelect)
    local dropdown = W.Button(parent, "", width, 20)
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", 6, 0)
    dropdown.label:SetPoint("RIGHT", -18, 0)
    dropdown.label:SetJustifyH("LEFT")
    dropdown.label:SetWordWrap(false)
    local arrow = W.Text(dropdown, "GameFontHighlightSmall", "v")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetTextColor(unpack(W.COLORS.accent))
    ns.On("THEME", function() arrow:SetTextColor(unpack(W.COLORS.accent)) end)
    dropdown.onSelect = onSelect

    function dropdown:Set(value, text)
        self.value = value
        self.label:SetText(text or tostring(value))
    end

    dropdown:SetScript("OnClick", function(self)
        if not popup then PopupCreate() end
        if popup.catcher:IsShown() and popup.owner == self then
            popup.catcher:Hide()
            return
        end
        popup.owner = self
        popup.options = getOptions()
        popup.offset = 0
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
        popup:SetSize(width, math.min(#popup.options, POPUP_ROWS) * POPUP_ROW_HEIGHT + 2
            + (#popup.options > POPUP_ROWS and POPUP_MORE_HEIGHT or 0))
        PopupRefresh()
        popup.catcher:Show()
    end)
    return dropdown
end

-- ---------------------------------------------------------------------------------------------
-- A button that is only a picture (the cog on the live panel). It has no frame of its own in
-- any look: it is dimmed until the mouse is on it. button.tooltip is shown when set.
-- ---------------------------------------------------------------------------------------------
function W.IconButton(parent, texture, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture(texture)
    button.icon:SetAlpha(0.65)
    button:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(0.65)
        GameTooltip:Hide()
    end)
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

-- ---------------------------------------------------------------------------------------------
-- Menu: a list of choices that opens under the frame that was clicked (above it when there is
-- no room below). Unlike the drop-down's list it can have headings, and any number of its
-- entries can be marked as the ones in use.
--   menu:Open(anchor, entries), menu:Close(), menu:IsOpen(), menu:IsOpenAt(anchor),
--   menu:SetMenuWidth(width) for the next time it opens
--   entries: { { title = "Head" }, { note = "Nothing to choose from" },
--              { text = ..., right = ..., icon = ..., checked = ..., dim = ..., onClick = fn }, ... }
-- A click on an entry closes the menu and calls its onClick; a click anywhere else closes it.
--
-- It is built the way the drop-down's list above is, which is known to draw properly in the
-- game: a frame of its own under a click catcher that covers the screen, both in the topmost
-- layer. (The first version was a child of the live panel and came out see-through there.)
-- The catcher sits under whatever the clicked frame's window sits under, so the menu also
-- shows when that window has been lifted out of the game's interface, and the menu takes the
-- clicked frame's scale. Its background is a plain filled texture as well as the theme's
-- frame, so it is solid whatever the theme draws.
-- ---------------------------------------------------------------------------------------------
local MENU_ROW = 16

function W.Menu(width)
    -- Catches a click anywhere else and closes the menu
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()

    local menu = CreateFrame("Frame", nil, catcher, "BackdropTemplate")
    menu:SetSize(width, MENU_ROW)
    W.Skin(menu, W.COLORS.header)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:EnableMouse(true)
    menu.catcher = catcher
    menu.rows = {}

    -- The solid background, under the theme's frame
    local fill = menu:CreateTexture(nil, "BACKGROUND", nil, -8)
    local function PaintFill()
        local inset = W.native and 3 or 1
        local color = W.COLORS.header
        fill:ClearAllPoints()
        fill:SetPoint("TOPLEFT", inset, -inset)
        fill:SetPoint("BOTTOMRIGHT", -inset, inset)
        fill:SetColorTexture(color[1], color[2], color[3], 1)
    end
    PaintFill()
    ns.On("THEME", PaintFill)

    local function Row(index)
        local row = menu.rows[index]
        if row then return row end
        row = CreateFrame("Button", nil, menu)
        row:SetHeight(MENU_ROW)
        row:SetPoint("TOPLEFT", 1, -3 - (index - 1) * MENU_ROW)
        row:SetPoint("TOPRIGHT", -1, -3 - (index - 1) * MENU_ROW)
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.12)
        -- The mark of an entry in use
        row.mark = row:CreateTexture(nil, "ARTWORK")
        row.mark:SetSize(5, 5)
        row.mark:SetPoint("LEFT", 6, 0)
        W.Accent(row.mark)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(MENU_ROW - 3, MENU_ROW - 3)
        row.icon:SetPoint("LEFT", 16, 0)
        row.right = W.Text(row, "GameFontHighlightSmall")
        row.right:SetPoint("RIGHT", -6, 0)
        row.right:SetJustifyH("RIGHT")
        row.label = W.Text(row, "GameFontHighlightSmall")
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        row:SetScript("OnClick", function(self)
            local entry = self.entry
            if not entry or not entry.onClick then return end
            menu:Close()
            entry.onClick()
        end)
        menu.rows[index] = row
        return row
    end

    -- What the clicked frame's window sits under: the game's interface, or the world frame
    -- when the window has been lifted out of the interface
    local function HomeOf(frame)
        local parent = frame:GetParent()
        while parent and parent ~= UIParent and parent ~= WorldFrame do
            parent = parent:GetParent()
        end
        return parent or UIParent
    end

    function menu:Open(anchor, entries)
        self.anchor = anchor
        local home = HomeOf(anchor)
        if catcher:GetParent() ~= home then
            catcher:SetParent(home)
            catcher:ClearAllPoints()
            catcher:SetAllPoints(home)
        end
        -- A new parent hands down its own layer: back to the top
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        -- The same size on screen as the frame it opens from
        local outer = home:GetEffectiveScale() or 1
        local scale = (anchor:GetEffectiveScale() or 1) / (outer ~= 0 and outer or 1)
        self:SetScale(scale > 0 and scale or 1)

        for index, entry in ipairs(entries) do
            local row = Row(index)
            row.entry = entry
            local heading = entry.title or entry.note
            local left = heading and 6 or 16
            row.mark:SetShown(entry.checked and true or false)
            if entry.icon and not heading then
                row.icon:SetTexture(entry.icon)
                row.icon:SetDesaturated(entry.dim and true or false)
                row.icon:Show()
                left = left + MENU_ROW
            else
                row.icon:Hide()
            end
            row.right:SetText(entry.right and ("|cff9d9d9d" .. entry.right .. "|r") or "")
            -- The text gets what the figures on the right leave it
            local taken = entry.right and ((row.right:GetStringWidth() or 0) + 12) or 6
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", left, 0)
            row.label:SetWidth(math.max(20, width - 2 - left - taken))
            row.label:SetText(heading or entry.text or "")
            if entry.title then
                row.label:SetTextColor(1, 0.82, 0)
            elseif entry.note or entry.dim then
                row.label:SetTextColor(0.62, 0.62, 0.62)
            elseif entry.checked then
                row.label:SetTextColor(unpack(W.COLORS.accent))
            else
                row.label:SetTextColor(1, 1, 1)
            end
            -- Headings and notes are not for clicking, and don't light up
            row:EnableMouse(entry.onClick ~= nil)
            row:Show()
        end
        for index = #entries + 1, #self.rows do
            self.rows[index]:Hide()
        end
        local height = #entries * MENU_ROW + 6
        self:SetSize(width, height)
        self:ClearAllPoints()
        -- Under the clicked frame, or above it when the screen ends first
        local bottom = anchor:GetBottom()
        if bottom and bottom * (anchor:GetEffectiveScale() or 1) < (height + 4) * (self:GetEffectiveScale() or 1) then
            self:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 1)
        else
            self:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
        end
        catcher:Show()
    end

    function menu:Close()
        self.anchor = nil
        catcher:Hide()
    end

    -- A new width, used from the next time the menu opens (an open one is closed)
    function menu:SetMenuWidth(newWidth)
        if newWidth == width then return end
        width = newWidth
        self:Close()
    end

    function menu:IsOpen()
        return catcher:IsShown() and true or false
    end

    function menu:IsOpenAt(anchor)
        return self:IsOpen() and self.anchor == anchor
    end

    catcher:SetScript("OnClick", function() menu:Close() end)
    return menu
end

-- ---------------------------------------------------------------------------------------------
-- Sortable table.
--   columns: { { title, width, align ("LEFT"/"RIGHT"), text = function(row), value =
--              function(row) for sorting (defaults to text), desc = true to sort high-to-low
--              on the first click, icon = function(row) for a picture before the text } }
--   options: rows (how many are visible), sort (column number; 0 to show the rows in the
--            order they are given until a heading is clicked), desc, id = function(row) for
--            keeping the selection, onSelect(row), onOpen(row) on a double-click,
--            onEnter(row, frame), onLeave()
-- Click a heading to sort by it; click it again to turn the order round. The mouse wheel
-- scrolls.
-- ---------------------------------------------------------------------------------------------
local ROW_HEIGHT = 18

function W.Table(parent, columns, options)
    options = options or {}
    local visible = options.rows or 12
    local width = 0
    for _, column in ipairs(columns) do
        width = width + column.width
    end

    local t = CreateFrame("Frame", nil, parent)
    t:SetSize(width, ROW_HEIGHT * (visible + 2))
    t.columns = columns
    t.data = {}
    t.offset = 0
    t.sortIndex = options.sort or 1
    t.sortDesc = options.desc or false
    t.headers = {}
    t.rows = {}

    local x = 0
    for i, column in ipairs(columns) do
        local header = W.Header(t, column.title, column.width, ROW_HEIGHT, column.align == "RIGHT")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetScript("OnClick", function()
            if t.sortIndex == i then
                t.sortDesc = not t.sortDesc
            else
                t.sortIndex = i
                t.sortDesc = column.desc or false
            end
            t:Sort()
        end)
        t.headers[i] = header
        x = x + column.width
    end

    for r = 1, visible do
        local row = CreateFrame("Button", nil, t)
        row:SetSize(width, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -ROW_HEIGHT * r)
        if r % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.04)
        end
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.08)
        row.selected = row:CreateTexture(nil, "BORDER")
        row.selected:SetAllPoints()
        W.Accent(row.selected, 0.25)
        row.selected:Hide()
        row.cells, row.icons = {}, {}
        local cx = 0
        for i, column in ipairs(columns) do
            local left = cx + 6
            if column.icon then
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
                icon:SetPoint("LEFT", cx + 4, 0)
                row.icons[i] = icon
                left = cx + ROW_HEIGHT + 4
            end
            local cell = W.Text(row, "GameFontHighlightSmall")
            cell:SetPoint("LEFT", left, 0)
            cell:SetWidth(cx + column.width - 6 - left)
            cell:SetJustifyH(column.align or "LEFT")
            cell:SetWordWrap(false)
            row.cells[i] = cell
            cx = cx + column.width
        end
        row:SetScript("OnClick", function(self)
            if not self.data then return end
            if options.id then
                t.selectedId = options.id(self.data)
                t:Refresh()
            end
            if options.onSelect then options.onSelect(self.data) end
        end)
        row:SetScript("OnDoubleClick", function(self)
            if self.data and options.onOpen then options.onOpen(self.data) end
        end)
        row:SetScript("OnEnter", function(self)
            if self.data and options.onEnter then options.onEnter(self.data, self) end
        end)
        row:SetScript("OnLeave", function()
            if options.onLeave then options.onLeave() end
        end)
        t.rows[r] = row
    end

    t.footer = W.Text(t, "GameFontDisableSmall")
    t.footer:SetPoint("TOPRIGHT", 0, -ROW_HEIGHT * (visible + 1) - 3)
    t.empty = W.Text(t, "GameFontDisable", options.emptyText or "Nothing here yet.")
    t.empty:SetPoint("TOP", 0, -ROW_HEIGHT * 3)

    function t:Refresh()
        local data = self.data
        local most = math.max(0, #data - visible)
        if self.offset > most then self.offset = most end
        for i, header in ipairs(self.headers) do
            local title = columns[i].title
            if i == self.sortIndex then
                header.label:SetText(title .. (self.sortDesc and " v" or " ^"))
                header.label:SetTextColor(unpack(W.COLORS.accent))
            else
                header.label:SetText(title)
                header.label:SetTextColor(1, 0.82, 0)
            end
        end
        for r, row in ipairs(self.rows) do
            local entry = data[r + self.offset]
            row.data = entry
            if entry then
                for i, column in ipairs(columns) do
                    row.cells[i]:SetText(column.text(entry) or "")
                    if row.icons[i] then
                        row.icons[i]:SetTexture(column.icon(entry))
                    end
                end
                if options.id and self.selectedId ~= nil and options.id(entry) == self.selectedId then
                    row.selected:Show()
                else
                    row.selected:Hide()
                end
                row:Show()
            else
                row:Hide()
            end
        end
        if #data > visible then
            self.footer:SetText(("%d-%d of %d  (mouse wheel scrolls)"):format(
                self.offset + 1, math.min(#data, self.offset + visible), #data))
        else
            self.footer:SetText("")
        end
        self.empty:SetShown(#data == 0)
    end

    -- Rows of equal value keep the order they were given in
    function t:Sort()
        local column = columns[self.sortIndex]
        if column then
            Util.Sort(self.data, column.value or column.text, self.sortDesc)
        end
        self:Refresh()
    end

    -- Shows these rows, keeping the sort order, the scroll position and the selection
    function t:SetData(rows)
        self.data = rows
        self:Sort()
    end

    -- The selected row, or nil
    function t:Selected()
        if not options.id or self.selectedId == nil then return nil end
        for _, entry in ipairs(self.data) do
            if options.id(entry) == self.selectedId then return entry end
        end
    end

    t:EnableMouseWheel(true)
    t:SetScript("OnMouseWheel", function(self, delta)
        local most = math.max(0, #self.data - visible)
        self.offset = math.max(0, math.min(most, self.offset - delta * 3))
        self:Refresh()
    end)

    return t
end

-- A square button showing an item: its icon, how many there are, and the item's tooltip with
-- button.hint under it. button:SetItem(itemID, count, dimmed, chosen); nil hides the button.
function W.ItemButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    W.Skin(button, W.COLORS.button)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count = W.Text(button, "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", -1, 1)

    function button:SetItem(itemID, count, dimmed, chosen)
        self.itemID = itemID
        if not itemID then
            self:Hide()
            return
        end
        self.icon:SetTexture(Util.ItemIcon(itemID))
        self.icon:SetDesaturated(dimmed and true or false)
        self.count:SetText((count and count > 1) and count or "")
        self:SetBackdropBorderColor(unpack(chosen and W.COLORS.accent or W.COLORS.border))
        self:Show()
    end

    button:SetScript("OnClick", function(self)
        if onClick and self.itemID then onClick(self.itemID, self) end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(self.itemID)
        else
            GameTooltip:SetHyperlink("item:" .. self.itemID)
        end
        if self.hint then GameTooltip:AddLine(self.hint, 0.6, 0.6, 0.6, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

-- Item names in their quality colour
function W.QualityText(text, quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color and color.hex then
        return color.hex .. text .. "|r"
    end
    return text
end
