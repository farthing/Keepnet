-- Keepnet: hides the game's interface while fishing.
--   "HIDEUI"  the interface was hidden or brought back (true/false)
--
-- Two ways, the player's choice:
--
--   "all"    Everything goes except the live panel. This uses the game's own switch for the
--            whole interface (SetUIVisibility, what its "toggle interface" key calls), so
--            nothing is left behind: no stray art, no shadows, whatever other addons are
--            installed. The live panel is moved under the world frame for that time, so it
--            stays.
--   "parts"  Only the ticked parts go (action bars, unit frames, buffs, minimap, chat, quest
--            tracker), plus anything the player has picked with the mouse. The parts are made
--            see-through, not removed: the game forbids removing many of them in combat. A part
--            that another addon has replaced is not found by name: that is what the picker is
--            for.
--
-- With everything hidden the player can't see dialogs, so the interface comes straight back
-- when combat starts, on death, on moving, on Escape, when the pole comes off, and for
-- anything that needs an answer (an invite, a trade, a summon, a resurrection, a loot roll, a
-- ready check, a duel). Whispers and the game's red error lines ("Inventory is full") are shown
-- on the live panel. Catches are picked up by the addon, since the loot window can't be seen.
--
-- Hiding is not allowed once combat has locked the interface. Showing is reported to be
-- allowed even then; in case it isn't on this client, combat start (which still allows
-- everything for an instant) brings the interface back, and combat end tries once more.
--
-- Using the game's switch, keeping a frame under the world frame at the interface's scale and
-- watching for the player's own toggle key follow Luredon (MIT). Why hiding frame by frame
-- leaves things behind is documented in DynamicCam's source. See CREDITS.md.
local _, ns = ...
local Util = ns.Util

local HideUI = {}
ns.HideUI = HideUI

-- The parts that can be ticked. Frames are looked up by name; the names cover the game's own
-- interface on current and classic-era clients, and any that don't exist are skipped.
HideUI.PARTS = {
    {
        key = "actionbars", text = "Action bars, menu and bags",
        frames = { "MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
            "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar", "PossessActionBar",
            "MainMenuBarVehicleLeaveButton", "MicroMenuContainer", "MicroMenu", "MicroButtonAndBagsBar", "BagsBar",
            "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer", "StatusTrackingBarManager",
            "MainMenuBarArtFrame", "MainMenuExpBar", "ReputationWatchBar" },
    },
    {
        key = "unitframes", text = "Player, target and group frames",
        frames = { "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PartyFrame", "CompactPartyFrame",
            "CompactRaidFrameContainer", "CompactRaidFrameManager", "PartyMemberFrame1", "PartyMemberFrame2",
            "PartyMemberFrame3", "PartyMemberFrame4" },
    },
    { key = "buffs", text = "Buffs and debuffs", frames = { "BuffFrame", "DebuffFrame", "TemporaryEnchantFrame" } },
    { key = "minimap", text = "Minimap", frames = { "MinimapCluster" } },
    {
        key = "chat", text = "Chat",
        frames = { "GeneralDockManager", "ChatFrameMenuButton", "ChatFrameChannelButton",
            "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton", "QuickJoinToastButton" },
    },
    { key = "tracker", text = "Quest tracker", frames = { "ObjectiveTrackerFrame", "WatchFrame", "QuestWatchFrame", "QuestTimerFrame" } },
}
for i = 1, 12 do
    local chat = HideUI.PARTS[5].frames
    chat[#chat + 1] = "ChatFrame" .. i
    chat[#chat + 1] = "ChatFrame" .. i .. "Tab"
    chat[#chat + 1] = "ChatFrame" .. i .. "ButtonFrame"
    chat[#chat + 1] = "ChatFrame" .. i .. "EditBox"
end

-- Things that need the player to see a window or a dialog: the interface comes back for them
local DIALOG_EVENTS = {
    "PLAYER_DEAD", "PLAYER_CONTROL_LOST", "PARTY_INVITE_REQUEST", "TRADE_SHOW", "CONFIRM_SUMMON",
    "RESURRECT_REQUEST", "START_LOOT_ROLL", "READY_CHECK", "DUEL_REQUESTED", "LFG_PROPOSAL_SHOW",
    "GROUP_INVITE_CONFIRMATION", "GOSSIP_SHOW", "MERCHANT_SHOW", "MAIL_SHOW", "BANKFRAME_OPENED",
    "AUCTION_HOUSE_SHOW", "QUEST_DETAIL", "QUEST_GREETING", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}

local REAPPLY_SECONDS = 0.5 -- the game fades some frames back in by itself (chat, on a new line)

local active = false
local hiddenAll = false   -- the interface root is hidden
local faded = {}          -- frame -> the alpha it had, for "parts"
local reapply
local ShowAgain

function HideUI.IsActive()
    return active
end

function HideUI.Enabled()
    return ns.settings.hideMode == "all" or ns.settings.hideMode == "parts"
end

-- ---------------------------------------------------------------------------------------------
-- "parts": frames made see-through
-- ---------------------------------------------------------------------------------------------
local function Resolve(name)
    local frame = type(name) == "string" and _G[name]
    if type(frame) == "table" and frame.SetAlpha and frame.GetAlpha then return frame end
end

-- The frames the player's ticks and picks name, that exist
function HideUI.Targets()
    local list, seen = {}, {}
    local function Add(name)
        local frame = Resolve(name)
        if frame and not seen[frame] and frame ~= UIParent and frame ~= WorldFrame then
            seen[frame] = true
            list[#list + 1] = frame
        end
    end
    for _, part in ipairs(HideUI.PARTS) do
        if ns.settings.hideParts[part.key] then
            for _, name in ipairs(part.frames) do Add(name) end
        end
    end
    for _, name in ipairs(ns.settings.hideFrames) do Add(name) end
    return list
end

local function Fade()
    for _, frame in ipairs(HideUI.Targets()) do
        if faded[frame] == nil then
            faded[frame] = frame:GetAlpha() or 1
        end
        if frame:GetAlpha() ~= 0 then frame:SetAlpha(0) end
    end
end

local function Unfade()
    for frame, alpha in pairs(faded) do
        frame:SetAlpha(alpha)
    end
    faded = {}
end

-- ---------------------------------------------------------------------------------------------
-- Hiding and bringing back
-- ---------------------------------------------------------------------------------------------
-- The game's own switch for the whole interface; hiding and showing its root is the fallback
-- for a client without it. Never throws: whether it worked is read from the root afterwards.
local function SetVisible(visible)
    if SetUIVisibility then
        pcall(SetUIVisibility, visible)
    elseif visible then
        pcall(UIParent.Show, UIParent)
    else
        pcall(UIParent.Hide, UIParent)
    end
end
-- Hides the interface in the way the settings say. Returns true when it is hidden.
function HideUI.Hide()
    if active then return true end
    if not ns.db or not HideUI.Enabled() then return false end
    if InCombatLockdown() or ns.inCombat then return false end
    if ns.settings.hideMode == "all" then
        -- The panel leaves the interface first, or it would vanish with it
        if ns.LivePanel then ns.LivePanel.Detach(true) end
        SetVisible(false)
        if UIParent:IsShown() then
            -- The game refused: leave everything as it was
            if ns.LivePanel then ns.LivePanel.Detach(false) end
            return false
        end
        hiddenAll = true
    else
        Fade()
        reapply = C_Timer.NewTicker(REAPPLY_SECONDS, Fade)
    end
    active = true
    ns.Fire("HIDEUI", true)
    return true
end

-- Brings the interface back. Safe to call at any time.
function HideUI.Show()
    if not active then return end
    if reapply then
        reapply:Cancel()
        reapply = nil
    end
    Unfade()
    if hiddenAll then
        SetVisible(true)
        if not UIParent:IsShown() then
            -- The game refused (combat has locked the interface): combat end tries again, and
            -- the game's own "toggle interface" key still works in the meantime
            return
        end
        hiddenAll = false
        if ns.LivePanel then ns.LivePanel.Detach(false) end
    end
    active = false
    ns.Fire("HIDEUI", false)
end
ShowAgain = HideUI.Show

function HideUI.Toggle()
    if active then
        HideUI.Show()
    elseif not HideUI.Enabled() then
        Util.Print("Choose what to hide first: /kn, Appearance tab.")
    elseif not HideUI.Hide() then
        Util.Print("The interface can't be hidden in combat.")
    end
end

-- The player brought the interface back with the game's own key: tidy up after it. Called
-- when the interface root reports being shown, and once a second by the live panel in case it
-- doesn't report.
function HideUI.Check()
    if active and hiddenAll and UIParent:IsShown() then
        hiddenAll = false
        if ns.LivePanel then ns.LivePanel.Detach(false) end
        active = false
        ns.Fire("HIDEUI", false)
    end
end

if UIParent and UIParent.HookScript then
    UIParent:HookScript("OnShow", HideUI.Check)
end

-- ---------------------------------------------------------------------------------------------
-- When
-- ---------------------------------------------------------------------------------------------
ns.On("CAST_START", function()
    if ns.settings.hideAuto and HideUI.Enabled() then HideUI.Hide() end
end)
ns.On("MODE", function(on)
    if not on then ShowAgain() end
end)
ns.On("COMBAT", function(inCombat)
    -- Combat start: still allowed for an instant. Combat end: in case that was missed.
    if inCombat or (active and hiddenAll) then ShowAgain() end
end)
ns.On("LOGOUT", ShowAgain)
ns.On("SETTINGS", function()
    if active and not HideUI.Enabled() then ShowAgain() end
end)

-- Catches are picked up for the player while nothing can be seen
local function TakeLoot()
    if not (active and hiddenAll and LootSlot and GetNumLootItems) then return end
    for slot = GetNumLootItems(), 1, -1 do
        pcall(LootSlot, slot)
    end
end

local function Notice(text, highlight)
    if ns.LivePanel then ns.LivePanel.Notice(text, 10, highlight) end
end

local events = CreateFrame("Frame")
local function Register(event)
    -- An event name this client doesn't know is an error; skip it
    pcall(events.RegisterEvent, events, event)
end
for _, event in ipairs(DIALOG_EVENTS) do Register(event) end
Register("PLAYER_STARTED_MOVING")
Register("LOOT_READY")
Register("LOOT_BIND_CONFIRM")
Register("CHAT_MSG_WHISPER")
Register("CHAT_MSG_BN_WHISPER")
Register("UI_ERROR_MESSAGE")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if not active then return end
    if event == "PLAYER_STARTED_MOVING" then
        if ns.settings.hideAuto then ShowAgain() end
    elseif event == "LOOT_READY" then
        -- A frame later, so the catch is read and counted first
        C_Timer.After(0, TakeLoot)
    elseif event == "LOOT_BIND_CONFIRM" then
        -- "This item will bind to you": the question can't be seen, and a catch is wanted
        if hiddenAll and ConfirmLootSlot then pcall(ConfirmLootSlot, arg1) end
    elseif event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
        if hiddenAll or ns.settings.hideParts.chat then
            local from = (type(arg2) == "string" and not Util.Hidden(arg2)) and arg2:match("^([^-]+)") or "someone"
            Notice("Whisper from " .. from, true)
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if hiddenAll and type(arg2) == "string" and not Util.Hidden(arg2) then
            Notice("|cffff6060" .. arg2 .. "|r")
        end
    else
        ShowAgain()
    end
end)

-- ---------------------------------------------------------------------------------------------
-- Picking a frame with the mouse, for interfaces the names above don't cover
-- ---------------------------------------------------------------------------------------------
local picker

local function UnderMouse()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return foci and foci[1]
    elseif GetMouseFocus then
        return GetMouseFocus()
    end
end

-- A frame that covers most of the screen is a container (interface suites put everything in
-- one), not the piece the player is pointing at
local function IsContainer(frame)
    local width, height = frame.GetWidth and frame:GetWidth(), frame.GetHeight and frame:GetHeight()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    if not (width and height and screenWidth and screenHeight) or screenWidth == 0 or screenHeight == 0 then
        return false
    end
    return (width * height) / (screenWidth * screenHeight) > 0.5
end

-- The named frames from the top of the interface down to the one under the mouse
local function Chain(frame)
    local chain = {}
    while type(frame) == "table" and frame.GetParent and frame ~= UIParent and frame ~= WorldFrame do
        local name = frame.GetName and frame:GetName()
        if name and _G[name] == frame then
            table.insert(chain, 1, frame)
        end
        frame = frame:GetParent()
    end
    return chain
end

local function Ours(frame)
    local name = frame and frame.GetName and frame:GetName()
    return type(name) == "string" and name:find("^Keepnet") ~= nil
end

function HideUI.IsPicked(name)
    for _, picked in ipairs(ns.settings.hideFrames) do
        if picked == name then return true end
    end
    return false
end

function HideUI.AddPicked(name)
    if type(name) ~= "string" or name == "" or HideUI.IsPicked(name) then return false end
    table.insert(ns.settings.hideFrames, name)
    ns.Fire("SETTINGS")
    return true
end

function HideUI.ClearPicked()
    if active then Unfade() end
    ns.settings.hideFrames = {}
    if active and not hiddenAll then Fade() end
    ns.Fire("SETTINGS")
end

local function StopPicking(name)
    picker:Hide()
    picker:EnableKeyboard(false)
    local done = picker.onDone
    picker.onDone = nil
    if name then HideUI.AddPicked(name) end
    if done then done(name) end
end

-- Starts picking: point at something, Enter adds it, Up and Down widen or narrow the choice,
-- Escape cancels. onDone(name or nil) is called at the end.
function HideUI.StartPicking(onDone)
    if not picker then
        picker = CreateFrame("Frame", "KeepnetPicker", UIParent)
        picker:SetFrameStrata("TOOLTIP")
        picker.tint = picker:CreateTexture(nil, "OVERLAY")
        picker.tint:SetAllPoints()
        picker.tint:SetColorTexture(0.31, 0.76, 0.97, 0.35)
        picker.label = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        picker.label:SetPoint("TOP", UIParent, "TOP", 0, -120)
        picker.depth = 1
        picker:SetScript("OnUpdate", function(self)
            local chain = Chain(UnderMouse())
            if #chain == 0 or Ours(chain[1]) then
                self.target = nil
                self.tint:Hide()
                self.label:SetText("Point at what you want hidden. Escape cancels.")
                return
            end
            -- Start at the widest piece that isn't a whole-screen container
            local first = 1
            while first < #chain and IsContainer(chain[first]) do first = first + 1 end
            local depth = math.max(1, math.min(#chain, first + self.depth - 1))
            local frame = chain[depth]
            self.target = frame:GetName()
            self:ClearAllPoints()
            self:SetAllPoints(frame)
            self.tint:Show()
            self.label:SetText(("%s\nEnter hides this. Up / Down: a wider or narrower piece (%d of %d). Escape cancels.")
                :format(self.target, depth, #chain))
        end)
        picker:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                StopPicking(nil)
            elseif key == "ENTER" or key == "SPACE" then
                if self.target then StopPicking(self.target) end
            elseif key == "UP" then
                self.depth = math.max(1, self.depth - 1)
            elseif key == "DOWN" then
                self.depth = self.depth + 1
            end
        end)
    end
    picker.onDone = onDone
    picker.depth = 1
    picker:EnableKeyboard(true)
    picker:Show()
end
