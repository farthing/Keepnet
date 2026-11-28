-- Keepnet: the Settings tab.
local _, ns = ...
local Util, Lures, Prices, W, UI = ns.Util, ns.Lures, ns.Prices, ns.Widgets, ns.UI

local LURE_MODES = {
    { value = "auto", text = "Auto: the best lure in my bags" },
    { value = "specific", text = "Specific: the lure I choose" },
    { value = "off", text = "Off: no lures" },
}

-- The keys that are held with another key: which of the four a key is ("LCTRL" and "RCTRL"
-- are both CTRL), or nil for an ordinary key. The order is the one the game writes a
-- combination in: ALT-CTRL-SHIFT-META-key.
local MODIFIERS = { "ALT", "CTRL", "SHIFT", "META" }

local function ModifierOf(key)
    if type(key) ~= "string" then return nil end
    for _, name in ipairs(MODIFIERS) do
        if key == name or key == "L" .. name or key == "R" .. name then return name end
    end
end

-- What the game itself says is held, where it says (it may keep the answer to itself)
local HELD_NOW = { ALT = "IsAltKeyDown", CTRL = "IsControlKeyDown", SHIFT = "IsShiftKeyDown", META = "IsMetaKeyDown" }

local function GameSaysHeld(name)
    local ask = _G[HELD_NOW[name]]
    if type(ask) ~= "function" then return false end
    local ok, held = pcall(ask)
    return ok and not Util.Hidden(held) and held and true or false
end

local MOUSE_KEYS = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local MAX_LURE_BUTTONS = 8

local function Changed()
    ns.Fire("SETTINGS")
end

local function Heading(frame, text, x, y)
    local heading = W.Text(frame, "GameFontNormal", text)
    heading:SetPoint("TOPLEFT", x, y)
    return heading
end

local function ItemTooltip(owner, itemID, extra)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(itemID)
    else
        GameTooltip:SetHyperlink("item:" .. itemID)
    end
    if extra then GameTooltip:AddLine(extra, 0.6, 0.6, 0.6, true) end
    GameTooltip:Show()
end

local function Build(frame)
    local settings = ns.settings
    local left, right = UI.LEFT, UI.LEFT + 390
    local y = UI.TOP - 2

    -- ------------------------------------------------------------------ the keys
    -- A button that takes a key or a combination of keys: click it, hold any of Alt, Ctrl,
    -- Shift (and the Windows key) and press a key, or a side button of the mouse. The
    -- combination shows on the button as it is held ("CTRL-SHIFT-..."), and is taken when the
    -- last key, the one that isn't one of those four, goes down: "CTRL-F", "ALT-CTRL-SHIFT-F".
    -- Which of the four are held is followed here, key by key, and the game is asked as
    -- well: either saying so is enough.
    -- get() is the key now; set(key) takes the new one, or refuses it; a right click on a
    -- button that can be cleared sets no key. button:Sync() shows the key again.
    local keysTop = y
    local function KeyButton(x, get, set, clearable)
        local capturing = false
        local held = {}
        local button = W.Button(frame, "", 150, 22)
        button:SetPoint("TOPLEFT", x, keysTop - 20)
        local function Prefix()
            local prefix = ""
            for _, name in ipairs(MODIFIERS) do
                if held[name] or GameSaysHeld(name) then prefix = prefix .. name .. "-" end
            end
            return prefix
        end
        local function Prompt()
            local prefix = Prefix()
            button.label:SetText(prefix ~= "" and (prefix .. "...") or "Press the key or keys (Esc cancels)")
        end
        local function Stop()
            capturing = false
            held = {}
            button:EnableKeyboard(false)
            -- Back among the window's own frames
            button:SetFrameStrata(frame:GetFrameStrata() or "HIGH")
            button.label:SetText(get() or "none")
        end
        local function Take(key)
            set(key)
            Stop()
            Changed()
        end
        button:RegisterForClicks("AnyUp")
        button:SetScript("OnClick", function(_, mouseButton)
            if capturing and MOUSE_KEYS[mouseButton] then
                Take(Prefix() .. MOUSE_KEYS[mouseButton])
            elseif capturing then
                Stop()
            elseif InCombatLockdown() then
                Util.Print("The key can't be changed in combat.")
            elseif mouseButton == "RightButton" and clearable then
                Take(nil)
            elseif mouseButton == "LeftButton" then
                capturing = true
                held = {}
                button:EnableKeyboard(true)
                -- In front of everything while it listens, so that no other addon's frame
                -- takes the keys first
                button:SetFrameStrata("TOOLTIP")
                Prompt()
            end
        end)
        button:SetScript("OnKeyDown", function(_, key)
            if not capturing or Util.Hidden(key) or key == "UNKNOWN" then return end
            local modifier = ModifierOf(key)
            if modifier then
                held[modifier] = true
                Prompt()
                return
            end
            local prefix = Prefix()
            if key == "ESCAPE" and prefix == "" then
                Stop()
                return
            end
            Take(prefix .. key)
        end)
        button:SetScript("OnKeyUp", function(_, key)
            if not capturing then return end
            local modifier = ModifierOf(key)
            if modifier then
                held[modifier] = nil
                Prompt()
            end
        end)
        button:SetScript("OnHide", Stop)
        function button:Sync()
            if not capturing then self.label:SetText(get() or "none") end
        end
        return button
    end

    Heading(frame, "Fishing key", left, y)
    local keyButton = KeyButton(left, function() return settings.key end, function(key)
        if key == settings.gearKey then
            Util.Print("That is the gear key: the fishing key needs one of its own.")
            return false
        end
        settings.key = key
    end)
    -- The gear key: fishing pole and gear on, and off again
    Heading(frame, "Gear key", left + 190, y)
    local gearKeyButton = KeyButton(left + 190, function() return settings.gearKey end, function(key)
        if key and key == settings.key then
            Util.Print("That is the fishing key: the gear key needs one of its own.")
            return false
        end
        settings.gearKey = key
    end, true)
    gearKeyButton.tooltip = "Click, then press the key, with Alt, Ctrl or Shift held if you like. Right click: no key."
    keyButton.tooltip = "Click, then press the key, with Alt, Ctrl or Shift held if you like."
    -- (for the tests, and for anything else that wants to press them)
    frame.keyButton, frame.gearKeyButton = keyButton, gearKeyButton
    ns.SettingsKeys = { fishing = keyButton, gear = gearKeyButton }
    local keyNote = W.Text(frame, "GameFontDisableSmall",
        "Fishing key: casts, and reels in while the line is out; only with a pole equipped. "
        .. "Gear key: puts your fishing pole and gear on, and your own back on the next press.")
    keyNote:SetPoint("TOPLEFT", left, y - 46)
    keyNote:SetWidth(350)
    keyNote:SetJustifyH("LEFT")

    -- ------------------------------------------------------------------ lures
    y = y - 84
    Heading(frame, "Lures", left, y)
    local mode = W.Dropdown(frame, 250, function() return LURE_MODES end, function(value)
        settings.lureMode = value
        Changed()
        UI.Refresh()
    end)
    mode:SetPoint("TOPLEFT", left, y - 20)

    -- The chosen lure: drop an item on it, or click one of the lures found in the bags
    local slot = CreateFrame("Button", nil, frame, "BackdropTemplate")
    slot:SetSize(36, 36)
    slot:SetPoint("TOPLEFT", left, y - 50)
    W.Skin(slot, W.COLORS.button, nil, "slot")
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetPoint("TOPLEFT", 2, -2)
    slot.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    local function TakeCursorItem()
        local kind, itemID = GetCursorInfo()
        if kind == "item" and itemID then
            ClearCursor()
            Lures.SetSpecific(itemID)
        end
    end
    slot:SetScript("OnReceiveDrag", TakeCursorItem)
    slot:SetScript("OnClick", TakeCursorItem)
    slot:SetScript("OnEnter", function(self)
        if settings.lureItem then
            ItemTooltip(self, settings.lureItem, "Drop another item here to change it.")
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Drop a lure here, or click one from your bags on the right.", 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local slotLabel = W.Text(frame, "GameFontHighlightSmall")
    slotLabel:SetPoint("TOPLEFT", slot, "TOPRIGHT", 8, -2)
    local bagLabel = W.Text(frame, "GameFontDisableSmall", "In your bags:")
    bagLabel:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -8)

    local lureButtons = {}
    for i = 1, MAX_LURE_BUTTONS do
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetSize(28, 28)
        button:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 74 + (i - 1) * 32, -2)
        W.Skin(button, W.COLORS.button, nil, "slot")
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        button.count = W.Text(button, "NumberFontNormalSmall")
        button.count:SetPoint("BOTTOMRIGHT", -1, 1)
        button:SetScript("OnClick", function(self)
            if self.lure then Lures.SetSpecific(self.lure.id) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.lure then return end
            ItemTooltip(self, self.lure.id, self.lure.usable and ("Fishing +%d. Click to choose it."):format(self.lure.bonus)
                or (self.lure.worn and "Its cooldown is still running." or "Your fishing skill is too low for this lure."))
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lureButtons[i] = button
    end

    local fallback = W.Check(frame, "When it runs out, use the best lure in my bags", function(checked)
        settings.lureFallback = checked
        Changed()
    end)
    fallback:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -40)

    -- ------------------------------------------------------------------ sound
    local ry = UI.TOP - 2
    Heading(frame, "Sound", right, ry)
    local sound = W.Check(frame, "Fishing sound while the pole is equipped", function(checked)
        settings.sound = checked
        Changed()
    end)
    sound:SetPoint("TOPLEFT", right, ry - 22)
    local soundNote = W.Text(frame, "GameFontDisableSmall",
        "Sound effects at full volume so the splash is loud; music, ambience and dialog off. "
        .. "Your own sound settings come back when the pole comes off.")
    soundNote:SetPoint("TOPLEFT", right, ry - 44)
    soundNote:SetWidth(360)
    soundNote:SetJustifyH("LEFT")
    local volumeLabel = W.Text(frame, "GameFontHighlightSmall", "Master volume")
    volumeLabel:SetPoint("TOPLEFT", right, ry - 82)
    local volume
    volume = W.Slider(frame, 180, 10, 100, 5, function(value)
        volume.value:SetText(("%d%%"):format(value))
        settings.masterVolume = value / 100
        Changed()
    end)
    volume:SetPoint("LEFT", volumeLabel, "RIGHT", 10, 0)

    -- ------------------------------------------------------------------ sessions
    ry = ry - 116
    Heading(frame, "Sessions", right, ry)
    local gapLabel = W.Text(frame, "GameFontHighlightSmall", "New session after a break of")
    gapLabel:SetPoint("TOPLEFT", right, ry - 24)
    local gap
    gap = W.Slider(frame, 130, 5, 120, 5, function(value)
        gap.value:SetText(("%d min"):format(value))
        settings.sessionGap = value
        Changed()
    end)
    gap:SetPoint("LEFT", gapLabel, "RIGHT", 10, 0)
    local zoneSplit = W.Check(frame, "A different zone starts a new session", function(checked)
        settings.zoneSplit = checked
        Changed()
    end)
    zoneSplit:SetPoint("TOPLEFT", right, ry - 46)

    -- ------------------------------------------------------------------ gold
    -- In the left column, under the lures
    y = y - 150
    Heading(frame, "Gold", left, y)
    local sourceLabel = W.Text(frame, "GameFontHighlightSmall", "Prices from")
    sourceLabel:SetPoint("TOPLEFT", left, y - 26)
    local source = W.Dropdown(frame, 280, Prices.Choices, function(value)
        settings.priceSource = value
        ns.Core.Reprice()
        Changed()
        ns.Fire("SESSION")
        UI.Refresh()
    end)
    source:SetPoint("TOPLEFT", left + 76, y - 22)
    local cut = W.Check(frame, "Take the auction house's 5% cut off auction prices", function(checked)
        settings.auctionCut = checked
        ns.Core.Reprice()
        Changed()
        ns.Fire("SESSION")
    end)
    cut:SetPoint("TOPLEFT", left, y - 50)
    local goldNote = W.Text(frame, "GameFontDisableSmall")
    goldNote:SetPoint("TOPLEFT", left, y - 72)
    goldNote:SetWidth(360)
    goldNote:SetJustifyH("LEFT")

    -- ------------------------------------------------------------------ minimap button
    Heading(frame, "Minimap button", left, y - 112)
    local minimapButton = W.Check(frame, "Show Keepnet's button on the minimap", function(checked)
        settings.minimapButton = checked
        Changed()
    end)
    minimapButton:SetPoint("TOPLEFT", left, y - 134)
    ns.SettingsChecks = { minimap = minimapButton } -- (for the tests)

    -- ------------------------------------------------------------------ bobber mark
    -- (The live panel's options moved to the Appearance tab in 1.2.1 to make room here)
    ry = ry - 84
    Heading(frame, "Bobber mark", right, ry)
    local Mark = ns.BobberMark
    local bobber = W.Check(frame, "A mark over my bobber while the line is out", function(checked)
        settings.bobberMark = checked
        Changed()
    end)
    bobber:SetPoint("TOPLEFT", right, ry - 22)

    local markLabel = W.Text(frame, "GameFontHighlightSmall", "Size")
    markLabel:SetPoint("TOPLEFT", right, ry - 50)
    local markSize
    markSize = W.Slider(frame, 110, 60, 200, 10, function(value)
        markSize.value:SetText(("%d%%"):format(value))
        settings.bobberMarkSize = value / 100
        Changed()
    end)
    markSize:SetPoint("TOPLEFT", right + 34, ry - 50)

    -- The circle's and the arrow's colours: a click picks one, a right click goes back to the
    -- default (which the colour blind choice decides)
    local function Swatch(label, x, key, what)
        local text = W.Text(frame, "GameFontHighlightSmall", label)
        text:SetPoint("TOPLEFT", right + x, ry - 50)
        local swatch = CreateFrame("Button", nil, frame, "BackdropTemplate")
        swatch:SetSize(18, 18)
        swatch:SetPoint("LEFT", text, "RIGHT", 6, 0)
        W.Skin(swatch, W.COLORS.button, nil, "slot")
        swatch.color = swatch:CreateTexture(nil, "ARTWORK")
        swatch.color:SetPoint("TOPLEFT", 2, -2)
        swatch.color:SetPoint("BOTTOMRIGHT", -2, 2)
        swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        swatch:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                settings[key] = nil
                Changed()
                UI.Refresh()
                return
            end
            local now = Mark.Colours()[what]
            W.PickColor(now[1], now[2], now[3], function(r, g, b)
                settings[key] = { r, g, b }
                Changed()
                UI.Refresh()
            end)
        end)
        swatch:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(("Click to pick the %s's colour. Right click: back to the default."):format(what),
                1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return swatch
    end
    local ringSwatch = Swatch("Circle", 196, "bobberRingColor", "ring")
    local arrowSwatch = Swatch("Arrow", 272, "bobberArrowColor", "arrow")

    -- Colour blind colours for the circle, the arrow and the middle's three
    local paletteLabel = W.Text(frame, "GameFontHighlightSmall", "Colour blind")
    paletteLabel:SetPoint("TOPLEFT", right, ry - 80)
    local palette = W.Dropdown(frame, 190, Mark.PaletteChoices, function(value)
        settings.bobberPalette = value
        Changed()
        UI.Refresh()
    end)
    palette:SetPoint("TOPLEFT", right + 90, ry - 76)
    -- The middle's three colours with the choice: from the line going out to its end
    local stops = {}
    for i = 1, 3 do
        local square = frame:CreateTexture(nil, "ARTWORK")
        square:SetSize(14, 14)
        square:SetPoint("TOPLEFT", right + 290 + (i - 1) * 18, ry - 80)
        stops[i] = square
    end
    -- (The middle fades through those three as the line's time runs out; this adds a cue
    -- that isn't colour for the last part)
    local pulse = W.Check(frame, "Pulse as the line runs out (from 20 seconds)", function(checked)
        settings.bobberPulse = checked
        Changed()
    end)
    pulse:SetPoint("TOPLEFT", right, ry - 100)
    ns.SettingsBobber = { check = bobber, size = markSize, ring = ringSwatch, arrow = arrowSwatch,
        palette = palette, stops = stops, pulse = pulse } -- (for the tests)

    -- ------------------------------------------------------------------ new versions
    ry = ry - 134 -- (124 until 1.2.7: the pulse checkbox sat right on the heading)
    Heading(frame, "New versions", right, ry)
    local updates = W.Check(frame, "Tell me when a newer Keepnet is out", function(checked)
        settings.updates = checked
        Changed()
        UI.Refresh()
    end)
    updates:SetPoint("TOPLEFT", right, ry - 22)
    local updatesNote = W.Text(frame, "GameFontDisableSmall")
    updatesNote:SetPoint("TOPLEFT", right, ry - 44)
    updatesNote:SetWidth(360)
    updatesNote:SetJustifyH("LEFT")

    -- -------------------------------------------------------------------------- the log
    local collect = W.Button(frame, "Report a problem", 130, 22, function() ns.LogWindow.Show() end)
    -- On the heading's own line, at the right: the note under the tick box runs to the bottom
    collect:SetPoint("TOPRIGHT", frame, "TOPLEFT", right + 360, ry + 4)
    collect.tooltip = "Something not working? This shows what Keepnet has done lately, as text to copy and send to its author."
    ns.LogWindow.button = collect

    return function()
        updates:SetChecked(settings.updates and true or false)
        updatesNote:SetText(ns.Updates and ns.Updates.Describe() or "")
        keyButton:Sync()
        gearKeyButton:Sync()

        for _, option in ipairs(LURE_MODES) do
            if option.value == settings.lureMode then mode:Set(option.value, option.text) end
        end
        local specific = settings.lureMode == "specific"
        if settings.lureItem then
            slot.icon:SetTexture(Util.ItemIcon(settings.lureItem))
            local name = Util.ItemInfo(settings.lureItem) or ("item " .. settings.lureItem)
            local have = Util.ItemCount(settings.lureItem)
            slotLabel:SetText(("%s\n|cff%s%d in your bags|r"):format(name, have > 0 and "9d9d9d" or ns.Tone("none"), have))
        else
            slot.icon:SetTexture(nil)
            slotLabel:SetText("No lure chosen\n|cff9d9d9dDrop one here or click one below|r")
        end
        local alpha = specific and 1 or 0.45
        slot:SetAlpha(alpha)
        slotLabel:SetAlpha(alpha)
        fallback:SetAlpha(alpha)
        fallback:SetChecked(settings.lureFallback and true or false)

        local lures = Lures.InBags()
        for i, button in ipairs(lureButtons) do
            local lure = lures[i]
            button.lure = lure
            if lure then
                button.icon:SetTexture(Util.ItemIcon(lure.id))
                button.icon:SetDesaturated(not lure.usable)
                button.count:SetText(lure.count)
                if lure.id == settings.lureItem then
                    button:SetBackdropBorderColor(unpack(W.COLORS.accent))
                else
                    button:SetBackdropBorderColor(unpack(W.COLORS.border))
                end
                button:Show()
            else
                button:Hide()
            end
        end
        bagLabel:SetText(#lures > 0 and "You have:" or "No lures on you.")

        sound:SetChecked(settings.sound and true or false)
        local percent = math.floor((settings.masterVolume or 1) * 100 + 0.5)
        volume:Set(percent)
        volume.value:SetText(("%d%%"):format(percent))
        gap:Set(settings.sessionGap or 30)
        gap.value:SetText(("%d min"):format(settings.sessionGap or 30))
        zoneSplit:SetChecked(settings.zoneSplit and true or false)
        cut:SetChecked(settings.auctionCut and true or false)
        minimapButton:SetChecked(settings.minimapButton and true or false)
        bobber:SetChecked(settings.bobberMark ~= false)
        pulse:SetChecked(settings.bobberPulse ~= false)
        local markPercent = math.floor((settings.bobberMarkSize or 1) * 100 + 0.5)
        markSize:Set(markPercent)
        markSize.value:SetText(("%d%%"):format(markPercent))
        local colours = Mark.Colours()
        ringSwatch.color:SetColorTexture(colours.ring[1], colours.ring[2], colours.ring[3], 1)
        arrowSwatch.color:SetColorTexture(colours.arrow[1], colours.arrow[2], colours.arrow[3], 1)
        for i, square in ipairs(stops) do
            local c = colours.stops[i]
            square:SetColorTexture(c[1], c[2], c[3], 1)
        end
        for _, choice in ipairs(Mark.PaletteChoices()) do
            if choice.value == (settings.bobberPalette or "normal") then palette:Set(choice.value, choice.text) end
        end
        for _, choice in ipairs(Prices.Choices()) do
            if choice.value == (settings.priceSource or "auto") then source:Set(choice.value, choice.text) end
        end
        local description, fine = Prices.Describe(settings)
        if fine then
            goldNote:SetText("Prices are as fresh as that addon's own data, so scan the auction house now and "
                .. "then. Grey items, items that bind when picked up and items it has no price for count at "
                .. "the vendor price.")
        else
            goldNote:SetText("|cff" .. ns.Tone("none") .. "" .. description .. ".|r")
        end
    end
end

UI.AddTab("settings", "Settings", Build)
