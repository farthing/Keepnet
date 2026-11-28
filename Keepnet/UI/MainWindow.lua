-- Keepnet: the window (/keepnet, /kn, the minimap button, or the addon menu on the minimap)
-- with its tabs:
-- Session, History, Zones, Settings. Each tab file adds itself with ns.UI.AddTab.
local _, ns = ...
local W = ns.Widgets

local UI = {}
ns.UI = UI

UI.WIDTH, UI.HEIGHT = 790, 470
-- Where a tab's content starts, below the title and the tab buttons
UI.TOP = -62
UI.LEFT = 16

local window
local tabs, order = {}, {}
local current

-- build(frame) creates the tab's content on first use and returns its refresh function
function UI.AddTab(key, title, build)
    tabs[key] = { key = key, title = title, build = build }
    order[#order + 1] = key
end

local function Select(key)
    if not tabs[key] then key = order[1] end
    current = key
    for _, name in ipairs(order) do
        local tab = tabs[name]
        if name == key then
            if not tab.frame then
                tab.frame = CreateFrame("Frame", nil, window)
                tab.frame:SetAllPoints(window)
                tab.refresh = tab.build(tab.frame)
            end
            tab.frame:Show()
            tab.button:SetSelected(true)
        else
            if tab.frame then tab.frame:Hide() end
            tab.button:SetSelected(false)
        end
    end
    if tabs[key].refresh then tabs[key].refresh() end
end

local function Create()
    window = W.Panel("KeepnetWindow", UIParent, UI.WIDTH, UI.HEIGHT, "window")
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    -- Escape closes it
    if UISpecialFrames then
        table.insert(UISpecialFrames, "KeepnetWindow")
    end

    if window.nativeFrame then
        -- The game's own window: it has a title bar and a close button of its own, and its
        -- tabs hang underneath, so the content starts higher up
        if window.TitleText then window.TitleText:SetText("Keepnet  v" .. ns.VERSION) end
        UI.TOP = -34
    elseif W.retro and ns.Retro then
        -- A title bar with a close box, and the tabs on the top edge of a framed page
        ns.Retro.Caption(window, "Keepnet  v" .. ns.VERSION, function() window:Hide() end)
        ns.Retro.Page(window)
    else
        local title = W.Text(window, "GameFontNormalLarge", "Keepnet")
        title:SetPoint("TOPLEFT", UI.LEFT, -10)
        local version = W.Text(window, "GameFontDisableSmall", "v" .. ns.VERSION)
        version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
        local close = W.Button(window, "x", 22, 20, function() window:Hide() end)
        close:SetPoint("TOPRIGHT", -8, -8)
    end

    local x, previous = UI.LEFT, nil
    for i, key in ipairs(order) do
        local tab = tabs[key]
        local button = W.Tab(window, "KeepnetWindowTab" .. i, tab.title, function() Select(key) end)
        if button.nativeTab then
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
            else
                button:SetPoint("TOPLEFT", window, "BOTTOMLEFT", 10, 2)
            end
        elseif button.retroTab then
            -- Side by side, each as wide as its name
            x = button:Place(window, previous and x or ns.Retro.PAGE_SIDE + 2)
        else
            button:SetPoint("TOPLEFT", x, -34)
            x = x + 104
        end
        tab.button = button
        previous = button
    end
end

-- The window takes the size chosen on the Appearance tab (the same one the live panel has)
function UI.ApplyScale()
    if not window then return end
    local scale = tonumber(ns.settings and ns.settings.panelScale) or 1
    window:SetScale(math.max(0.7, math.min(1.5, scale)))
end

-- Opens the window on a tab ("session", "history", "zones" or "settings")
function UI.Show(key)
    if not window then Create() end
    UI.ApplyScale()
    window:Show()
    Select(key or current or order[1])
end

-- With a tab named: opens the window on that tab, or closes it when that tab is the one showing
function UI.Toggle(key)
    if window and window:IsShown() and (not key or key == current) then
        window:Hide()
    else
        UI.Show(key)
    end
end

function UI.IsShown()
    return window ~= nil and window:IsShown()
end

-- The tab showing ("session", "zones" ...), or the one last shown; nil before the first
function UI.Current()
    return current
end

-- ---------------------------------------------------------------------------------------------
-- Whose sessions the History and Zones tabs show
-- ---------------------------------------------------------------------------------------------
-- Every character has its own history, and the window opens on the one being played. The
-- list on those two tabs (UI.CharacterPicker) changes whose is shown: any character Keepnet
-- has seen on this account, or all of them together. The choice lasts until the next login
-- or reload.
local ALL_CHARACTERS = "All characters"
local viewed -- nil: the character being played; false: all of them; or a character's key

-- The characters there are to choose from, the one being played first and the others A to Z:
-- { { key, name } }
function UI.Characters()
    local own = ns.Core.Character()
    local seen, list = { [own] = true }, {}
    local function Add(key)
        if not seen[key] then
            seen[key] = true
            list[#list + 1] = { key = key, name = ns.Core.CharacterName(key) }
        end
    end
    -- While the sample sessions show, only the sample character: no real name on screen
    if not (ns.Demo and ns.Demo.IsOn()) then
        for key in pairs(ns.db.chars or {}) do Add(key) end
    end
    for _, key in ipairs(ns.Sessions.Characters()) do Add(key) end
    table.sort(list, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.key < b.key
    end)
    table.insert(list, 1, { key = own, name = ns.Core.CharacterName(own) })
    return list
end

-- The character whose sessions are shown: a key, or nil for every character's
function UI.Viewed()
    if viewed == false then return nil end
    if viewed then
        for _, character in ipairs(UI.Characters()) do
            if character.key == viewed then return viewed end
        end
        viewed = nil -- gone (the sample sessions were switched on or off)
    end
    return ns.Core.Character()
end

-- key: a character's key, or false for all of them
function UI.View(key)
    if key == ns.Core.Character() then key = nil end
    viewed = key
    UI.Refresh()
end

-- The list a tab offers for it. Call picker:Sync() when the tab is redrawn.
function UI.CharacterPicker(parent, width)
    local picker = W.Dropdown(parent, width or 160, function()
        local options = {}
        for _, character in ipairs(UI.Characters()) do
            options[#options + 1] = { value = character.key, text = character.name }
        end
        options[#options + 1] = { value = false, text = ALL_CHARACTERS }
        return options
    end, function(value)
        UI.View(value or false)
    end)
    function picker:Sync()
        local key = UI.Viewed()
        self:Set(key or false, key and ns.Core.CharacterName(key) or ALL_CHARACTERS)
    end
    return picker
end

-- Redraws the tab on screen
function UI.Refresh()
    if not UI.IsShown() or not current then return end
    local tab = tabs[current]
    if tab.refresh then tab.refresh() end
end

ns.On("SESSION", UI.Refresh)
ns.On("TICK", UI.Refresh)
ns.On("LURES", UI.Refresh)
ns.On("THEME", function()
    if UI.IsShown() and current then Select(current) end
end)
