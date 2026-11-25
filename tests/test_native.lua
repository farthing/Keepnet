-- The Forever theme: every window, button, tick box, slider, text box, drop-down and tab is made
-- from the game's own templates, and the addon works the same through them.
local T = {}

local KEY = "F"

function T.before()
    KeepnetDB = { settings = { theme = "forever", lureMode = "off", gear = false } }
end

local function CountTemplate(template)
    local n = 0
    for _, frame in ipairs(Stub.frames) do
        if frame.__template == template and Stub.visible(frame) then n = n + 1 end
    end
    return n
end

function T.run(ns)
    local W = ns.Widgets
    Stub.auction = { [13422] = 41800 }
    Stub.login()
    eq(W.native, true, "a native theme saved from last time is the look from the start")
    eq(Stub.popup, nil, "with no reload asked for")
    check(math.abs(W.COLORS.accent[2] - 0.82) < 0.001, "and the game's gold as accent")

    Stub.equip(Stub.POLE)
    check(KeepnetPanel and KeepnetPanel:IsShown(), "the live panel is up")
    check(tostring(KeepnetPanel.__backdropFile):find("UI-Tooltip-Background", 1, true), "drawn with the game's tooltip frame")
    eq(KeepnetPanel.new.__template, "UIPanelButtonTemplate", "its buttons are the game's buttons")

    -- Fishing works the same through it
    eq(Stub.press(KEY), "cast", "a cast")
    Stub.nextLoot = { { id = 13422, count = 2 } }
    eq(Stub.press(KEY), "reel", "a catch")
    eq(ns.Sessions.Current().catches, 1, "counted")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)

    -- The window
    ns.UI.Show("session")
    eq(KeepnetWindow.__template, "BasicFrameTemplateWithInset", "the window is the game's framed window")
    check(tostring(KeepnetWindow.TitleText:GetText()):find("Keepnet", 1, true), "titled in its own title bar")
    eq(KeepnetWindowTab1.__template, "PanelTabButtonTemplate", "with the game's tabs")
    eq(Stub.selectedTabs[KeepnetWindowTab1], true, "the tab showing is marked the game's way")
    ns.UI.Show("history")
    eq(Stub.selectedTabs[KeepnetWindowTab1], nil, "another tab: the first is no longer marked")
    eq(Stub.selectedTabs[KeepnetWindowTab2], true, "the new one is")

    -- Every tab builds and redraws, and everything on it can be pressed
    local function Poke()
        local snapshot = {}
        for i, frame in ipairs(Stub.frames) do snapshot[i] = frame end
        for _, frame in ipairs(snapshot) do
            for _, script in ipairs({ "OnEnter", "OnLeave", "OnMouseWheel", "OnClick", "OnDoubleClick" }) do
                local fn = frame.__scripts[script]
                if fn and Stub.visible(frame) and frame.__name ~= "KeepnetCastButton" then
                    local ok, err = pcall(fn, frame, script == "OnMouseWheel" and -1 or "LeftButton", false)
                    if not ok then Stub.errors[#Stub.errors + 1] = script .. ": " .. tostring(err) end
                end
            end
        end
    end
    for _, tab in ipairs({ "session", "history", "zones", "gear", "alerts", "appearance", "settings" }) do
        ns.UI.Show(tab)
        ns.UI.Refresh()
        if tab == "settings" then
            check(CountTemplate("UICheckButtonTemplate") >= 5, "Settings: the tick boxes are the game's")
            check(CountTemplate("OptionsSliderTemplate") >= 2, "Settings: the sliders are the game's")
            check(CountTemplate("WowStyle1DropdownTemplate") >= 2, "Settings: the drop-downs are the game's")
            check(CountTemplate("UIPanelButtonTemplate") >= 2, "Settings: the buttons are the game's")
        elseif tab == "history" then
            check(CountTemplate("InputBoxTemplate") >= 1, "History: the search box is the game's")
        end
        Poke()
    end
    -- The poking may have chosen another look, which asks for a reload: that is its job
    Stub.popup = nil

    -- A drop-down through the game's own menu: the Zone list of History
    ns.settings.theme = "forever"
    ns.settings.hideMode = "off"
    ns.UI.Show("settings")
    local source
    for _, frame in ipairs(Stub.frames) do
        if frame.__template == "WowStyle1DropdownTemplate" and Stub.visible(frame) and frame.__menu then
            for _, entry in ipairs(Stub.menu(frame)) do
                if entry.value == "vendor" then source = frame end
            end
        end
    end
    check(source ~= nil, "the price source drop-down offers its choices through the game's menu")
    local entries = Stub.menu(source)
    eq(entries[1].value, "auto", "automatic first")
    local ticked
    for _, entry in ipairs(entries) do
        if entry.selected then ticked = entry.value end
    end
    eq(ticked, ns.settings.priceSource, "the saved choice is the one ticked")
    for _, entry in ipairs(entries) do
        if entry.value == "vendor" then entry.pick() end
    end
    eq(ns.settings.priceSource, "vendor", "picking an entry sets the setting")
    check(entries.scroll ~= nil, "a long list scrolls inside the game's menu")
    ns.settings.priceSource = "auto"

    -- A template this client hasn't got: that piece falls back to the flat one, nothing breaks
    Stub.templates.UIPanelButtonTemplate = nil
    local plain = W.Button(KeepnetWindow, "Fallback", 80, 22)
    eq(plain.__template, "BackdropTemplate", "a missing template falls back to the flat piece")
    check(plain.label ~= nil, "which still has its text")
    Stub.templates.UIPanelButtonTemplate = { "Text" }

    -- Changing to a flat theme from here asks for a reload; another native choice wouldn't
    ns.settings.theme = "keepnet"
    W.ApplyTheme()
    eq(Stub.popup, "KEEPNET_RELOAD_FOR_THEME", "leaving the native look asks to reload")
    eq(W.native, true, "and stays native until then")
    ns.settings.theme = "forever"
    Stub.popup = nil
    W.ApplyTheme()
    eq(Stub.popup, nil, "staying with it asks nothing")

    -- After the reload the flat look is built
    ns.settings.theme = "keepnet"
    ns = Stub.reload()
    eq(ns.Widgets.native, false, "after a reload the chosen flat look is in use")
    ns.UI.Show("settings")
    eq(KeepnetWindow.__template, "BackdropTemplate", "and the window is Keepnet's own again")

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
