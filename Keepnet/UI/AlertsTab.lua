-- Keepnet: the Alerts tab: what counts as a rare catch, the sound for each kind, and the
-- player's own sound files.
local _, ns = ...
local Alerts, Rares, W, UI = ns.Alerts, ns.Rares, ns.Widgets, ns.UI

local RARE_QUALITIES = {
    { value = 2, text = "Green items and better" },
    { value = 3, text = "Blue items and better" },
    { value = 4, text = "Purple items and better" },
    { value = 0, text = "No item quality" },
}

local FILE_ROWS = 9

local function Changed()
    ns.Fire("SETTINGS")
end

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

    -- ------------------------------------------------------------------- what is rare
    local y = UI.TOP - 2
    Heading(frame, "Rare catches", left, y)
    -- The listed fishing rarities, by kind
    local listNote = W.Text(frame, "GameFontDisableSmall",
        ("Fishing rarities, from a list of %d items:"):format(Rares.Count()))
    listNote:SetPoint("TOPLEFT", left, y - 22)
    local kindChecks = {}
    for i, kind in ipairs(Rares.KINDS) do
        local check = W.Check(frame, kind.text, function(checked)
            settings.rareList[kind.key] = checked
            Changed()
        end)
        check:SetPoint("TOPLEFT", left + ((i - 1) % 2) * 200, y - 40 - math.floor((i - 1) / 2) * 20)
        kindChecks[kind.key] = check
    end
    y = y - 20 - math.ceil(#Rares.KINDS / 2) * 20
    local rareLabel = W.Text(frame, "GameFontHighlightSmall", "Also any")
    rareLabel:SetPoint("TOPLEFT", left, y - 24)
    local rare = W.Dropdown(frame, 230, function() return RARE_QUALITIES end, function(value)
        settings.rareQuality = value
        Changed()
    end)
    rare:SetPoint("LEFT", rareLabel, "RIGHT", 8, 0)
    local goldLabel = W.Text(frame, "GameFontHighlightSmall", "and anything worth at least")
    goldLabel:SetPoint("TOPLEFT", left, y - 50)
    local rareGold
    rareGold = W.Slider(frame, 110, 0, 200, 5, function(value)
        rareGold.value:SetText(value > 0 and ("%dg each"):format(value) or "off")
        settings.rareGold = value
        Changed()
    end)
    rareGold:SetPoint("LEFT", goldLabel, "RIGHT", 10, 0)
    -- ------------------------------------------------------------------------ sounds
    y = y - 76
    Heading(frame, "Sounds", left, y)
    local rareSound = W.Check(frame, "Play a sound for a rare catch", function(checked)
        settings.rareSound = checked
        Changed()
    end)
    rareSound:SetPoint("TOPLEFT", left, y - 22)
    local feedback = W.Text(frame, "GameFontDisableSmall")

    local pickers = {}
    for i, kind in ipairs(Alerts.KINDS) do
        local rowY = y - 20 - i * 23
        local label = W.Text(frame, "GameFontHighlightSmall", kind.text)
        label:SetPoint("TOPLEFT", left, rowY - 4)
        local picker = W.Dropdown(frame, 196, Alerts.SoundOptions, function(value)
            settings.rareSounds[kind.key] = value
            Alerts.Play(value) -- hear it as it is chosen
            Changed()
        end)
        picker:SetPoint("TOPLEFT", left + 112, rowY)
        local test = W.Button(frame, "Test", 46, 20, function()
            local choice = settings.rareSounds[kind.key]
            if Alerts.Play(choice) then
                feedback:SetText("")
            else
                feedback:SetText("|cff" .. ns.Tone("none") .. "" .. Alerts.SoundName(choice) .. " didn't play.|r "
                    .. "A file of your own must be in the sounds folder, and the game only sees a new file after a restart.")
            end
        end)
        test:SetPoint("LEFT", picker, "RIGHT", 6, 0)
        pickers[kind.key] = picker
    end
    feedback:SetPoint("TOPLEFT", left, y - 20 - (#Alerts.KINDS + 1) * 23)
    feedback:SetWidth(360)
    feedback:SetJustifyH("LEFT")

    -- --------------------------------------------------------------- your own sounds
    local ry = UI.TOP - 2
    Heading(frame, "Your own sounds", right, ry)
    Note(frame, "1. Make the folder  Interface\\AddOns\\KeepnetSounds  in your game folder and put "
        .. ".ogg or .mp3 files in it.\n2. Restart the game (or log out and in): it only sees files that were there then.\n"
        .. "3. Type each file's name below and press Add. It then appears in the sound lists.", right, ry - 20)
    local addFeedback = W.Text(frame, "GameFontDisableSmall")
    local box
    local function Add()
        local text = box:GetText()
        if Alerts.AddCustom(text) then
            box:SetText("")
            addFeedback:SetText("")
            UI.Refresh()
        else
            addFeedback:SetText("|cff" .. ns.Tone("none") .. "That isn't a sound file name.|r Type just the name, ending in .ogg or .mp3, such as  splash.ogg")
        end
    end
    box = W.EditBox(frame, 230, Add)
    box:SetPoint("TOPLEFT", right, ry - 92)
    local add = W.Button(frame, "Add", 60, 20, Add)
    add:SetPoint("LEFT", box, "RIGHT", 6, 0)
    addFeedback:SetPoint("TOPLEFT", right, ry - 116)
    addFeedback:SetWidth(360)
    addFeedback:SetJustifyH("LEFT")

    local rows = {}
    for i = 1, FILE_ROWS do
        local rowY = ry - 128 - i * 22
        local row = {}
        row.name = W.Text(frame, "GameFontHighlightSmall")
        row.name:SetPoint("TOPLEFT", right, rowY - 3)
        row.name:SetWidth(210)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.play = W.Button(frame, "Play", 46, 20, function()
            if row.file and not Alerts.Play("file:" .. row.file.name) then
                addFeedback:SetText("|cff" .. ns.Tone("none") .. "" .. row.file.name .. " didn't play.|r Is it in the folder, and has the game been restarted since?")
            else
                addFeedback:SetText("")
            end
        end)
        row.play:SetPoint("TOPLEFT", right + 220, rowY)
        row.remove = W.Button(frame, "Remove", 60, 20, function()
            if row.file then
                Alerts.RemoveCustom(row.file.name)
                UI.Refresh()
            end
        end)
        row.remove:SetPoint("LEFT", row.play, "RIGHT", 6, 0)
        rows[i] = row
    end
    local more = W.Text(frame, "GameFontDisableSmall")
    more:SetPoint("TOPLEFT", right, ry - 128 - (FILE_ROWS + 1) * 22)

    return function()
        for _, option in ipairs(RARE_QUALITIES) do
            if option.value == (settings.rareQuality or 0) then rare:Set(option.value, option.text) end
        end
        rareGold:Set(settings.rareGold or 0)
        rareGold.value:SetText((settings.rareGold or 0) > 0 and ("%dg each"):format(settings.rareGold) or "off")
        rareSound:SetChecked(settings.rareSound and true or false)
        for _, kind in ipairs(Rares.KINDS) do
            kindChecks[kind.key]:SetChecked(settings.rareList[kind.key] and true or false)
        end
        for _, kind in ipairs(Alerts.KINDS) do
            local choice = settings.rareSounds[kind.key]
            pickers[kind.key]:Set(choice, Alerts.SoundName(choice))
        end
        local files = Alerts.CustomFiles()
        for i, row in ipairs(rows) do
            local file = files[i]
            row.file = file
            if file then
                row.name:SetText(file.name)
                row.name:Show()
                row.play:Show()
                -- A file named by the folder's own list isn't ours to remove
                row.remove:SetShown(not file.listed)
            else
                row.name:Hide()
                row.play:Hide()
                row.remove:Hide()
            end
        end
        if #files == 0 then
            more:SetText("No sounds of your own yet.")
        elseif #files > FILE_ROWS then
            more:SetText(("and %d more; all of them are in the sound lists."):format(#files - FILE_ROWS))
        else
            more:SetText("")
        end
    end
end

UI.AddTab("alerts", "Alerts", Build)
