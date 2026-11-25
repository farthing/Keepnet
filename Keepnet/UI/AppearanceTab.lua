-- Keepnet: the Appearance tab: the look, its colours, the accent colour, how solid the
-- backgrounds are, the size of the live panel, and hiding the game's own interface while
-- fishing. Everything changes as it is set; only a look that is drawn another way needs the
-- interface reloaded.
local _, ns = ...
local W, UI, HideUI = ns.Widgets, ns.UI, ns.HideUI

local HIDE_MODES = {
    { value = "off", text = "Off" },
    { value = "all", text = "Everything except the live panel" },
    { value = "parts", text = "Only the parts I tick" },
}

local ACCENT_MODES = {
    { value = "theme", text = "The colours' own" },
    { value = "class", text = "My class colour" },
    { value = "custom", text = "My own colour" },
}

local function Heading(frame, text, x, y)
    local heading = W.Text(frame, "GameFontNormal", text)
    heading:SetPoint("TOPLEFT", x, y)
    return heading
end

local function Note(frame, text, x, y, width)
    local note = W.Text(frame, "GameFontDisableSmall", text)
    note:SetPoint("TOPLEFT", x, y)
    note:SetWidth(width or 360)
    note:SetJustifyH("LEFT")
    return note
end

local function Build(frame)
    local settings = ns.settings
    local left, right = UI.LEFT, UI.LEFT + 390

    -- A theme change repaints everything, which redraws this tab; the settings event then
    -- lets the live panel pick up its size
    local function Apply()
        W.ApplyTheme()
        ns.Fire("SETTINGS")
    end

    -- --------------------------------------------------------------- look and colours
    local y = UI.TOP - 2
    Heading(frame, "Look and colours", left, y)
    local themeLabel = W.Text(frame, "GameFontHighlightSmall", "Look")
    themeLabel:SetPoint("TOPLEFT", left, y - 26)
    local theme = W.Dropdown(frame, 200, function()
        local options = {}
        for _, entry in ipairs(W.THEMES) do
            local text = entry.name
            if entry.adopt and not ns.Adopt.Installed(entry.adopt) then
                text = text .. "  (not installed)"
            end
            options[#options + 1] = { value = entry.key, text = text }
        end
        return options
    end, function(value)
        settings.theme = value
        Apply()
    end)
    theme:SetPoint("TOPLEFT", left + 90, y - 22)

    -- The colours the chosen look comes in. A look with only its own has nothing to choose.
    local OWN = "The look's own"
    local schemeLabel = W.Text(frame, "GameFontHighlightSmall", "Colours")
    schemeLabel:SetPoint("TOPLEFT", left, y - 52)
    local scheme = W.Dropdown(frame, 200, function()
        local options = {}
        for _, entry in ipairs(W.Theme(settings.theme).schemes or {}) do
            options[#options + 1] = { value = entry.key, text = entry.name }
        end
        if #options == 0 then options[1] = { value = false, text = OWN } end
        return options
    end, function(value)
        if value then W.SetScheme(W.Theme(settings.theme), value) end
        Apply()
    end)
    scheme:SetPoint("TOPLEFT", left + 90, y - 48)

    local accentLabel = W.Text(frame, "GameFontHighlightSmall", "Accent colour")
    accentLabel:SetPoint("TOPLEFT", left, y - 78)
    local accent = W.Dropdown(frame, 200, function() return ACCENT_MODES end, function(value)
        settings.accentMode = value
        if value == "custom" and not settings.accentColor then
            settings.accentColor = { W.COLORS.accent[1], W.COLORS.accent[2], W.COLORS.accent[3] }
        end
        Apply()
    end)
    accent:SetPoint("TOPLEFT", left + 90, y - 74)

    -- The swatch shows the accent in use; clicking it opens the colour picker
    local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", accent, "RIGHT", 8, 0)
    W.Skin(swatch, W.COLORS.button, nil, "slot")
    swatch.color = swatch:CreateTexture(nil, "ARTWORK")
    swatch.color:SetPoint("TOPLEFT", 2, -2)
    swatch.color:SetPoint("BOTTOMRIGHT", -2, 2)
    W.Accent(swatch.color)
    swatch:SetScript("OnClick", function()
        local now = W.COLORS.accent
        W.PickColor(now[1], now[2], now[3], function(r, g, b)
            settings.accentMode = "custom"
            settings.accentColor = { r, g, b }
            Apply()
        end)
    end)
    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Pick your own accent colour", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Note(frame, "Keepnet, Keepnet rounded and Windows 95 are drawn by Keepnet. Forever is the game's "
        .. "own windows; a look named after an interface suite lets that suite paint Keepnet. A "
        .. "look drawn another way reloads the interface.", left, y - 102)

    -- ------------------------------------------------------------------- backgrounds
    local ry = UI.TOP - 2
    Heading(frame, "Backgrounds", right, ry)
    local panelLabel = W.Text(frame, "GameFontHighlightSmall", "Live panel")
    panelLabel:SetPoint("TOPLEFT", right, ry - 26)
    local panelOpacity
    panelOpacity = W.Slider(frame, 170, 0, 100, 5, function(value)
        panelOpacity.value:SetText(("%d%%"):format(value))
        settings.panelOpacity = value / 100
        Apply()
    end)
    panelOpacity:SetPoint("TOPLEFT", right + 90, ry - 26)
    local windowLabel = W.Text(frame, "GameFontHighlightSmall", "This window")
    windowLabel:SetPoint("TOPLEFT", right, ry - 52)
    local windowOpacity
    windowOpacity = W.Slider(frame, 170, 20, 100, 5, function(value)
        windowOpacity.value:SetText(("%d%%"):format(value))
        settings.windowOpacity = value / 100
        Apply()
    end)
    windowOpacity:SetPoint("TOPLEFT", right + 90, ry - 52)
    Note(frame, "How solid the background is. Text, bars and buttons stay fully visible; at 0% the "
        .. "live panel is just its text over the game.", right, ry - 76)

    -- --------------------------------------------------------------------------- size
    ry = ry - 124
    Heading(frame, "Size", right, ry)
    local scaleLabel = W.Text(frame, "GameFontHighlightSmall", "Live panel")
    scaleLabel:SetPoint("TOPLEFT", right, ry - 26)
    local scale
    scale = W.Slider(frame, 170, 70, 150, 5, function(value)
        scale.value:SetText(("%d%%"):format(value))
        settings.panelScale = value / 100
        ns.Fire("SETTINGS")
    end)
    scale:SetPoint("TOPLEFT", right + 90, ry - 26)

    local borders = W.Check(frame, "Thin borders round panels and buttons", function(checked)
        settings.borders = checked
        Apply()
    end)
    borders:SetPoint("TOPLEFT", right, ry - 54)

    -- The font of Keepnet's own looks
    local fontLabel = W.Text(frame, "GameFontHighlightSmall", "Font")
    fontLabel:SetPoint("TOPLEFT", right, ry - 84)
    -- (Keepnet's own, and every font another addon here shares)
    local font = W.Dropdown(frame, 170, function()
        local options = {}
        for _, entry in ipairs(W.FontChoices()) do
            options[#options + 1] = { value = entry.key, text = entry.name }
        end
        return options
    end, function(value)
        settings.font = value
        Apply()
    end)
    font:SetPoint("TOPLEFT", right + 90, ry - 80)

    local reset = W.Button(frame, "Look, colours, backgrounds and size back to the defaults", 320, 22, function()
        settings.theme, settings.accentMode, settings.accentColor = "keepnet", "theme", nil
        settings.schemes = nil
        settings.font = W.FONTS[1].key
        settings.windowOpacity, settings.panelOpacity, settings.panelScale = 0.94, 0.94, 1
        settings.borders = true
        Apply()
    end)
    reset:SetPoint("TOPLEFT", right, ry - 114)

    -- ------------------------------------------------- hiding the game's interface
    y = y - 144
    Heading(frame, "Hide the game's interface while fishing", left, y)
    local hide = W.Dropdown(frame, 290, function() return HIDE_MODES end, function(value)
        settings.hideMode = value
        ns.Fire("SETTINGS")
        UI.Refresh()
    end)
    hide:SetPoint("TOPLEFT", left, y - 22)
    local auto = W.Check(frame, "Hide when I cast, bring it back when I move", function(checked)
        settings.hideAuto = checked
        ns.Fire("SETTINGS")
    end)
    auto:SetPoint("TOPLEFT", left, y - 50)
    local hideNote = Note(frame, "", left, y - 72)

    local partChecks = {}
    for i, part in ipairs(HideUI.PARTS) do
        local check = W.Check(frame, part.text, function(checked)
            settings.hideParts[part.key] = checked
            ns.Fire("SETTINGS")
        end)
        check:SetPoint("TOPLEFT", left + ((i - 1) % 2) * 190, y - 118 - math.floor((i - 1) / 2) * 20)
        partChecks[part.key] = check
    end
    local picked = W.Text(frame, "GameFontDisableSmall")
    local pick = W.Button(frame, "Pick something on screen...", 170, 22, function()
        -- This window is in the way of what is to be picked
        UI.Toggle()
        HideUI.StartPicking(function() UI.Show("appearance") end)
    end)
    pick.tooltip = "For anything the ticks don't cover, such as another addon's bars: point at it and press Enter."
    pick:SetPoint("TOPLEFT", left, y - 184)
    local clear = W.Button(frame, "Forget the picked", 120, 22, function()
        HideUI.ClearPicked()
        UI.Refresh()
    end)
    clear:SetPoint("LEFT", pick, "RIGHT", 6, 0)
    picked:SetPoint("TOPLEFT", left, y - 212)
    picked:SetWidth(360)
    picked:SetJustifyH("LEFT")

    return function()
        for _, option in ipairs(HIDE_MODES) do
            if option.value == (settings.hideMode or "off") then hide:Set(option.value, option.text) end
        end
        auto:SetChecked(settings.hideAuto and true or false)
        local mode = settings.hideMode
        if mode == "all" then
            hideNote:SetText("Everything goes, with nothing left behind. It comes back by itself for combat, "
                .. "Escape, and anything that needs an answer. The live panel gets a Hide UI button; /kn ui does the same.")
        elseif mode == "parts" then
            hideNote:SetText("The ticked parts are made see-through (the game doesn't allow removing them in "
                .. "combat). The live panel gets a Hide UI button; /kn ui does the same.")
        else
            hideNote:SetText("Off: the interface stays as it is.")
        end
        local parts = mode == "parts"
        for _, part in ipairs(HideUI.PARTS) do
            local check = partChecks[part.key]
            check:SetChecked(settings.hideParts[part.key] and true or false)
            check:SetAlpha(parts and 1 or 0.45)
        end
        pick:SetAlpha(parts and 1 or 0.45)
        clear:SetAlpha((parts and #settings.hideFrames > 0) and 1 or 0.45)
        if #settings.hideFrames > 0 then
            picked:SetText("Picked: " .. table.concat(settings.hideFrames, ", "))
        else
            picked:SetText("")
        end
        borders:SetChecked(settings.borders ~= false)
        local current = W.Theme(settings.theme)
        theme:Set(current.key, current.name)
        if current.schemes then
            local colours = W.Scheme(current)
            scheme:Set(colours.key, colours.name)
        else
            scheme:Set(false, OWN)
        end
        scheme:SetAlpha(current.schemes and 1 or 0.45)
        -- The font is a matter of Keepnet's own looks: the others bring theirs
        local chosenFont = W.FontChoice(settings.font)
        font:Set(chosenFont.key, chosenFont.name)
        font:SetAlpha((W.native or W.retro) and 0.45 or 1)
        for _, option in ipairs(ACCENT_MODES) do
            if option.value == (settings.accentMode or "theme") then accent:Set(option.value, option.text) end
        end
        local panelPercent = math.floor((settings.panelOpacity or 0.94) * 100 + 0.5)
        panelOpacity:Set(panelPercent)
        panelOpacity.value:SetText(("%d%%"):format(panelPercent))
        local windowPercent = math.floor((settings.windowOpacity or 0.94) * 100 + 0.5)
        windowOpacity:Set(windowPercent)
        windowOpacity.value:SetText(("%d%%"):format(windowPercent))
        local scalePercent = math.floor((settings.panelScale or 1) * 100 + 0.5)
        scale:Set(scalePercent)
        scale.value:SetText(("%d%%"):format(scalePercent))
    end
end

UI.AddTab("appearance", "Appearance", Build)
