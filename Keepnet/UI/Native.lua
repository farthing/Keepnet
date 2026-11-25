-- Keepnet: the building blocks made from the game's own interface, for themes that ask for it
-- (the "Forever" theme). Windows, buttons, tick boxes, sliders, text boxes, drop-downs, tabs
-- and column headers all come from the client's templates and art, so they look like whatever
-- this client ships.
--
-- Each of these stands in for the flat version of the same name in Widgets.lua and offers the
-- same fields and methods, so the screens don't know which they got. If a template isn't there
-- on a client, the flat version is used for that one piece.
--
-- Which templates exist here and how they are called was read from addons made for this
-- client that use them: Forever Tooltip (window, slider), BugSack (tabs, drop-down), and
-- Auctionator. See CREDITS.md.
local _, ns = ...
local W = ns.Widgets

local N = {}
ns.Native = N

-- Creates a frame from one of the game's templates; nil when this client hasn't got it
local function Make(kind, name, parent, template)
    if DoesTemplateExist and not DoesTemplateExist(template) then return nil end
    local ok, frame = pcall(CreateFrame, kind, name, parent, template)
    if ok then return frame end
    return nil
end

local function Tooltip(frame)
    frame:HookScript("OnEnter", function(self)
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ---------------------------------------------------------------------------------------------
-- The window: the game's standard framed window with a title bar and a close button
-- ---------------------------------------------------------------------------------------------
local windows = {}

local function WindowOpacity()
    for _, frame in ipairs(windows) do
        for _, key in ipairs({ "Bg", "InsetBg" }) do
            local region = frame[key]
            if type(region) == "table" and region.SetAlpha then region:SetAlpha(W.opacity.window) end
        end
    end
end

function N.Panel(flat, name, parent, width, height, group)
    if group ~= "window" then return nil end -- the live panel keeps its tooltip-style frame
    local frame = Make("Frame", name, parent or UIParent, "BasicFrameTemplateWithInset")
    if not frame then return nil end
    frame:SetSize(width, height)
    frame.nativeFrame = true
    windows[#windows + 1] = frame
    WindowOpacity()
    return frame
end

ns.On("THEME", WindowOpacity)

-- ---------------------------------------------------------------------------------------------
-- Button
-- ---------------------------------------------------------------------------------------------
function N.Button(flat, parent, text, width, height, onClick)
    local button = Make("Button", nil, parent, "UIPanelButtonTemplate")
    if not button then return nil end
    button:SetSize(width, height or 22)
    button:SetText(text or "")
    button.label = button:GetFontString() or button.Text
    if not button.label then
        button.label = W.Text(button, "GameFontNormalSmall", text)
        button.label:SetPoint("CENTER")
    end
    Tooltip(button)
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

-- ---------------------------------------------------------------------------------------------
-- Tick box
-- ---------------------------------------------------------------------------------------------
function N.Check(flat, parent, text, onChange)
    local check = Make("CheckButton", nil, parent, "UICheckButtonTemplate")
    if not check then return nil end
    check:SetSize(20, 20)
    -- The template has a text of its own; ours sits where the screens expect it
    local own = check.Text or check.text
    if type(own) == "table" and own.SetText then own:SetText("") end
    check.label = W.Text(check, "GameFontHighlightSmall", text)
    check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check:SetHitRectInsets(0, -(check.label:GetStringWidth() or 0) - 6, 0, 0)
    check:SetScript("OnClick", function(self)
        if onChange then onChange(self:GetChecked() and true or false) end
    end)
    return check
end

-- ---------------------------------------------------------------------------------------------
-- Slider
-- ---------------------------------------------------------------------------------------------
function N.Slider(flat, parent, width, low, high, step, onChange)
    local slider = Make("Slider", nil, parent, "OptionsSliderTemplate")
    if not slider then return nil end
    slider:SetSize(width, 17)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    -- The template's own low, high and title texts aren't used: the value is shown beside it
    for _, key in ipairs({ "Low", "High", "Text" }) do
        local region = slider[key]
        if type(region) == "table" and region.SetText then region:SetText("") end
    end
    slider.value = W.Text(slider, "GameFontHighlightSmall")
    slider.value:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    slider:SetScript("OnValueChanged", function(self, value, userInput)
        value = math.floor(value / step + 0.5) * step
        if self.silent then return end
        if onChange then onChange(value, userInput) end
    end)
    function slider:Set(value)
        self.silent = true
        self:SetValue(value)
        self.silent = false
    end
    return slider
end

-- ---------------------------------------------------------------------------------------------
-- Text box
-- ---------------------------------------------------------------------------------------------
function N.EditBox(flat, parent, width, onEnter, onChange)
    local box = Make("EditBox", nil, parent, "InputBoxTemplate")
    if not box then return nil end
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
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
-- Drop-down: the game's own, with its own list
-- ---------------------------------------------------------------------------------------------
local MENU_HEIGHT = 320 -- a longer list scrolls inside the game's menu

function N.Dropdown(flat, parent, width, getOptions, onSelect)
    local dropdown = Make("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if not dropdown or not dropdown.SetupMenu then return nil end
    dropdown:SetWidth(width)
    dropdown.onSelect = onSelect

    -- Shows a choice without calling onSelect
    function dropdown:Set(value, text)
        self.value = value
        -- The game shows the ticked entry's text; this covers a value that isn't in the list
        if self.SetDefaultText then pcall(self.SetDefaultText, self, text or tostring(value)) end
        if self.GenerateMenu then pcall(self.GenerateMenu, self) end
    end

    dropdown:SetupMenu(function(_, root)
        if root.SetScrollMode then root:SetScrollMode(MENU_HEIGHT) end
        for _, option in ipairs(getOptions()) do
            root:CreateRadio(option.text,
                function(value) return dropdown.value == value end,
                function(value)
                    dropdown.value = value
                    if dropdown.onSelect then dropdown.onSelect(value) end
                end,
                option.value)
        end
    end)
    return dropdown
end

-- ---------------------------------------------------------------------------------------------
-- Window tab: the game's tabs, which hang under the window
-- ---------------------------------------------------------------------------------------------
function N.Tab(flat, parent, name, title, onClick)
    local tab = Make("Button", name, parent, "PanelTabButtonTemplate")
    if not tab then return nil end
    tab.nativeTab = true
    if type(tab.Text) == "table" and tab.Text.SetText then
        tab.Text:SetText(title)
    else
        tab:SetText(title)
    end
    if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
    tab:SetScript("OnClick", onClick)
    function tab:SetSelected(selected)
        if selected then
            if PanelTemplates_SelectTab then PanelTemplates_SelectTab(self) end
        else
            if PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(self) end
        end
        if ns.Adopt then ns.Adopt.TabSelected(self, selected) end
    end
    return tab
end

-- ---------------------------------------------------------------------------------------------
-- Column header of a table: the game's list header art (as in the Who and guild lists)
-- ---------------------------------------------------------------------------------------------
local HEADER_ART = "Interface\\FriendsFrame\\WhoFrame-ColumnTabs"

function N.Header(flat, parent, title, width, height, right)
    -- Interface suites paint flat column headers; the game's list art would stand out
    if W.adopting then return nil end
    local header = CreateFrame("Button", nil, parent)
    header:SetSize(width, height)
    local left = header:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(HEADER_ART)
    left:SetTexCoord(0, 0.078125, 0, 0.75)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(5)
    local rightEnd = header:CreateTexture(nil, "BACKGROUND")
    rightEnd:SetTexture(HEADER_ART)
    rightEnd:SetTexCoord(0.90625, 0.96875, 0, 0.75)
    rightEnd:SetPoint("TOPRIGHT")
    rightEnd:SetPoint("BOTTOMRIGHT")
    rightEnd:SetWidth(4)
    local middle = header:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(HEADER_ART)
    middle:SetTexCoord(0.078125, 0.90625, 0, 0.75)
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", rightEnd, "BOTTOMLEFT")
    local highlight = header:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()
    header.label = W.Text(header, "GameFontHighlightSmall", title)
    header.label:SetPoint(right and "RIGHT" or "LEFT", right and -8 or 8, 0)
    return header
end

-- What each building block is called when it is handed to the player's interface suite
local KINDS = {
    Panel = "window", Button = "button", Check = "check", Slider = "slider", EditBox = "editbox",
    Dropdown = "dropdown", Tab = "tab",
}

-- Every building block named here takes the native version when the theme asks for it, and
-- the flat one otherwise or when the native one can't be made. In the "Match my interface"
-- theme each native piece then goes to the player's interface suite (Adopt.lua).
for name, native in pairs(N) do
    local flat = W[name]
    W[name] = function(...)
        if W.native then
            local made = native(flat, ...)
            if made then
                W.built = true
                if KINDS[name] and ns.Adopt then ns.Adopt.Apply(KINDS[name], made) end
                return made
            end
        end
        return flat(...)
    end
end
