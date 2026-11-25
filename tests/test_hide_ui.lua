-- Hiding the game's interface while fishing: everything except the live panel, or chosen parts;
-- everything that must bring it back; picking a frame with the mouse.
local T = {}

local KEY = "F"

function T.run(ns)
    local HideUI = ns.HideUI
    Stub.login()
    local settings = ns.settings
    settings.lureMode = "off"
    settings.gear = false
    Stub.equip(Stub.POLE)

    local function PanelSays(text)
        KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
        for _, frame in ipairs(Stub.frames) do
            if frame.__parent == KeepnetPanel and tostring(frame.__text):find(text, 1, true) then return true end
        end
        return false
    end
    local function Hidden()
        return not UIParent:IsShown()
    end

    -- ------------------------------------------------------------------------- off
    eq(settings.hideMode, "off", "off by default")
    eq(HideUI.Enabled(), false, "nothing to hide")
    eq(Stub.press(KEY), "cast", "a cast")
    eq(Hidden(), false, "off: a cast hides nothing")
    Stub.reel(nil)
    Stub.advance(2)
    local lines = #Stub.chat
    HideUI.Toggle()
    eq(#Stub.chat, lines + 1, "off: asking to hide says where to turn it on")
    eq(Hidden(), false, "and hides nothing")

    -- -------------------------------------------------- everything except the live panel
    settings.hideMode = "all"
    ns.Fire("SETTINGS")
    eq(KeepnetCastButton:GetParent(), nil, "the cast button is not part of the interface, so the key survives")
    eq(KeepnetPanel:GetParent(), UIParent, "the panel starts inside the interface")
    eq(Stub.press(KEY), "cast", "a cast")
    eq(Hidden(), true, "the cast hides the interface")
    eq(HideUI.IsActive(), true, "and says so")
    eq(Stub.visible(KeepnetPanel), true, "the live panel is still there")
    eq(KeepnetPanel:GetParent(), WorldFrame, "because it was moved under the world frame")
    eq(KeepnetPanel.__scale, 0.64, "at the interface's scale, so it keeps its size")
    eq(Stub.visible(MinimapCluster), false, "the minimap is gone")
    eq(Stub.visible(OtherAddonBar), false, "and so is another addon's bar nobody listed")
    eq(KeepnetPanel.hide.label:GetText(), "Show UI", "the panel button now brings the interface back")

    -- The key still works, and the catch is picked up although the loot window can't be seen
    eq(Stub.binding(KEY).command, "INTERACTTARGET", "the key reels in")
    Stub.keepLootOpen = true
    Stub.nextLoot = { { id = 13422, count = 1 }, { id = 13756, count = 2 } }
    eq(Stub.press(KEY), "reel", "reel in")
    eq(#Stub.looted, 0, "the catch is read first")
    Stub.advance(0.1)
    eq(#Stub.looted, 2, "then both loot slots are picked up")
    eq(ns.Sessions.Current().catches, 1, "and the catch was counted")
    Stub.fire("LOOT_BIND_CONFIRM", 2)
    eq(Stub.confirmed[1], 2, "an item that binds is accepted")
    Stub.closeLoot()
    Stub.keepLootOpen = false

    -- What can't be seen is told on the panel
    Stub.fire("CHAT_MSG_WHISPER", "hello", "Bob-Realm")
    check(PanelSays("Whisper from Bob"), "a whisper shows on the panel")
    Stub.fire("UI_ERROR_MESSAGE", 50, "Inventory is full.")
    check(PanelSays("Inventory is full."), "the game's error line shows on the panel")

    -- Moving brings it back
    Stub.fire("PLAYER_STARTED_MOVING")
    eq(Hidden(), false, "moving brings the interface back")
    eq(HideUI.IsActive(), false, "and it knows")
    eq(KeepnetPanel:GetParent(), UIParent, "the panel is back inside the interface")
    eq(KeepnetPanel.__scale, 1, "at its own scale")
    eq(KeepnetPanel.hide.label:GetText(), "Hide UI", "the button offers to hide again")

    -- Combat brings it back before the lock
    Stub.advance(2)
    Stub.press(KEY)
    eq(Hidden(), true, "hidden again on the next cast")
    Stub.enterCombat()
    eq(Hidden(), false, "combat brings the interface back")
    eq(HideUI.Hide(), false, "it can't be hidden in combat")
    Stub.leaveCombat()
    Stub.reel(nil)
    Stub.advance(2)

    -- Escape
    Stub.press(KEY)
    eq(Hidden(), true, "hidden")
    eq(KeepnetPanel.__keyboard, true, "the panel listens for Escape")
    KeepnetPanel:GetScript("OnKeyDown")(KeepnetPanel, "ESCAPE")
    eq(Hidden(), false, "Escape brings the interface back")
    eq(KeepnetPanel.__keyboard, false, "and the panel stops listening")
    Stub.reel(nil)
    Stub.advance(2)

    -- Anything that needs an answer
    for _, event in ipairs({ "PARTY_INVITE_REQUEST", "TRADE_SHOW", "PLAYER_DEAD", "READY_CHECK" }) do
        HideUI.Hide()
        eq(Hidden(), true, "hidden before " .. event)
        Stub.fire(event)
        eq(Hidden(), false, event .. " brings the interface back")
    end

    -- The game's own key
    HideUI.Hide()
    UIParent:Show()
    eq(HideUI.IsActive(), false, "the game's own toggle key is noticed")
    eq(KeepnetPanel:GetParent(), UIParent, "and the panel put back")

    -- The History button
    HideUI.Hide()
    KeepnetPanel.history:GetScript("OnClick")(KeepnetPanel.history)
    eq(Hidden(), false, "History brings the interface back, since its window is part of it")
    check(KeepnetWindow:IsShown(), "and opens")

    -- Pole off
    HideUI.Hide()
    Stub.equip(nil)
    eq(Hidden(), false, "taking the pole off brings the interface back")
    Stub.equip(Stub.POLE)

    -- Not automatic
    settings.hideAuto = false
    Stub.press(KEY)
    eq(Hidden(), false, "automatic off: a cast doesn't hide")
    HideUI.Toggle()
    eq(Hidden(), true, "the button does")
    Stub.fire("PLAYER_STARTED_MOVING")
    eq(Hidden(), true, "and moving doesn't bring it back")
    HideUI.Toggle()
    eq(Hidden(), false, "the button does")
    Stub.reel(nil)
    Stub.advance(2)
    settings.hideAuto = true

    -- Combat that locked the interface before it could be brought back: showing is still
    -- allowed by the game's own switch
    HideUI.Hide()
    Stub.lockdown = true
    HideUI.Show()
    eq(Hidden(), false, "the interface can be brought back even after combat has locked it")
    eq(HideUI.IsActive(), false, "and it knows")
    Stub.lockdown = false

    -- A client where that is refused too: it comes back when combat ends
    HideUI.Hide()
    Stub.lockdown, Stub.showBlockedInCombat = true, true
    HideUI.Show()
    eq(Hidden(), true, "refused in combat: still hidden, and nothing breaks")
    eq(HideUI.IsActive(), true, "it knows it is still hidden")
    Stub.leaveCombat()
    eq(Hidden(), false, "when combat ends it comes back")
    Stub.showBlockedInCombat = false

    -- The game's own key when the interface root doesn't report it: noticed within a second
    HideUI.Hide()
    UIParent.__shown = true -- shown again without any script running
    eq(HideUI.IsActive(), true, "not noticed yet")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
    eq(HideUI.IsActive(), false, "the panel's once-a-second look notices")
    eq(KeepnetPanel:GetParent(), UIParent, "and the panel is put back")

    -- A client without the switch falls back on hiding the interface root itself
    local switch = SetUIVisibility
    SetUIVisibility = nil
    eq(HideUI.Hide(), true, "without the game's switch it still hides")
    eq(Hidden(), true, "by hiding the interface root")
    HideUI.Show()
    eq(Hidden(), false, "and shows it again")
    SetUIVisibility = switch

    -- ------------------------------------------------------------------- chosen parts
    settings.hideMode = "parts"
    settings.hideParts = { minimap = true, unitframes = true, chat = false, actionbars = false, buffs = false, tracker = false }
    PlayerFrame:SetAlpha(0.8)
    eq(HideUI.Hide(), true, "hiding parts")
    eq(Hidden(), false, "the interface as a whole stays")
    eq(MinimapCluster:GetAlpha(), 0, "the minimap is see-through")
    eq(PlayerFrame:GetAlpha(), 0, "so is the player frame")
    eq(ChatFrame1:GetAlpha(), 1, "chat wasn't ticked")
    eq(KeepnetPanel:GetParent(), UIParent, "the panel stays where it is")
    MinimapCluster:SetAlpha(1) -- the game fades something back in
    Stub.advance(0.6)
    eq(MinimapCluster:GetAlpha(), 0, "it is made see-through again")
    Stub.fire("CHAT_MSG_WHISPER", "hello", "Ann-Realm")
    check(not PanelSays("Whisper from Ann"), "chat is visible: no need to repeat a whisper")
    HideUI.Show()
    eq(MinimapCluster:GetAlpha(), 1, "the minimap is back")
    eq(PlayerFrame:GetAlpha(), 0.8, "the player frame is back as it was")

    -- ------------------------------------------------------------ picking with the mouse
    local result = "not called"
    Stub.mouseFocus = OtherAddonBarButton1
    HideUI.StartPicking(function(name) result = name end)
    local picker = KeepnetPicker
    check(picker:IsShown(), "the picker is up")
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, "OtherAddonBar", "it offers the whole piece under the mouse")
    picker:GetScript("OnKeyDown")(picker, "DOWN")
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, "OtherAddonBarButton1", "Down narrows to the part")
    picker:GetScript("OnKeyDown")(picker, "UP")
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, "OtherAddonBar", "Up widens again")
    picker:GetScript("OnKeyDown")(picker, "ENTER")
    eq(result, "OtherAddonBar", "Enter picks it")
    eq(HideUI.IsPicked("OtherAddonBar"), true, "it is remembered")
    check(not picker:IsShown(), "the picker is gone")
    HideUI.Hide()
    eq(OtherAddonBar:GetAlpha(), 0, "the picked piece is hidden with the parts")
    HideUI.ClearPicked()
    eq(OtherAddonBar:GetAlpha(), 1, "forgetting the picked brings it back")
    HideUI.Show()

    -- An interface suite keeps everything in one whole-screen frame: that is never the offer
    Stub.mouseFocus = SuiteBarButton3
    HideUI.StartPicking(function() end)
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, "SuiteBar", "inside a whole-screen container, the bar is offered, not the container")
    picker:GetScript("OnKeyDown")(picker, "DOWN")
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, "SuiteBarButton3", "Down still narrows")
    picker:GetScript("OnKeyDown")(picker, "ESCAPE")

    Stub.mouseFocus = KeepnetPanel
    result = "not called"
    HideUI.StartPicking(function(name) result = name end)
    picker:GetScript("OnUpdate")(picker, 0.1)
    eq(picker.target, nil, "Keepnet's own frames can't be picked")
    picker:GetScript("OnKeyDown")(picker, "ENTER")
    eq(result, "not called", "Enter with nothing under the mouse does nothing")
    picker:GetScript("OnKeyDown")(picker, "ESCAPE")
    eq(result, nil, "Escape cancels")
    Stub.mouseFocus = nil

    -- Turning the option off while hidden brings everything back
    settings.hideMode = "all"
    HideUI.Hide()
    settings.hideMode = "off"
    ns.Fire("SETTINGS")
    eq(Hidden(), false, "turning the option off brings the interface back")

    -- A reload while hidden: the logout brings it back first
    settings.hideMode = "all"
    HideUI.Hide()
    ns = Stub.reload()
    eq(Hidden(), false, "a reload never leaves the interface hidden")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
