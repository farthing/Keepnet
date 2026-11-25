-- Keepnet: the themes named after an interface suite ("EllesmereUI", "ElvUI"). The player picks
-- the suite they use; Keepnet is then built from the game's own templates (as in the Forever
-- theme) and each piece is handed to that suite to paint like the rest of their interface.
--
-- There is no one way to do this for every suite: each has its own interface for other addons.
-- So each suite has an adapter, below, and a theme entry in Widgets.lua. Adding a suite is
-- adding both. A suite theme chosen without that suite installed looks like Forever.
--
--   EllesmereUI  through its published skinning interface for addons (EllesmereUI.RegisterSkin
--                and the primitives it hands over; its SKINNING_API.md). The player can turn
--                this off per addon in EllesmereUI's own options.
--   ElvUI        through its Skins module (HandleFrame, HandleButton ...), the way addons skin
--                themselves for ElvUI. Written from that module's interface and not run
--                against ElvUI: every call is guarded, so the worst case is the Forever look.
--
-- The other themes (Keepnet's own flat look and its colour variants, and Forever) never come
-- through here. See CREDITS.md.
local _, ns = ...
local W = ns.Widgets

local Adopt = {}
ns.Adopt = Adopt

local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
    return nil
end

local ADAPTERS = {}

-- ---------------------------------------------------------------------------------------------
-- EllesmereUI
-- ---------------------------------------------------------------------------------------------
local eui -- the primitives EllesmereUI hands over, once it has

ADAPTERS.EllesmereUI = {
    installed = function()
        return type(EllesmereUI) == "table" and type(EllesmereUI.RegisterSkin) == "function"
    end,
    -- The primitives arrive at login, after Keepnet has loaded
    ready = function() return eui ~= nil end,
    apply = function(kind, frame)
        local S = eui
        if kind == "window" then
            Try(S.Shell, frame)
            if frame.CloseButton then Try(S.CloseButton, frame.CloseButton) end
            if frame.Inset then Try(S.Inset, frame.Inset) end
        elseif kind == "panel" then
            Try(S.Panel, frame)
        elseif kind == "button" then
            Try(S.Button, frame)
            Try(S.StateButtonLabel, frame)
        elseif kind == "check" then
            Try(S.Checkbox, frame)
        elseif kind == "editbox" then
            Try(S.EditBox, frame)
        elseif kind == "dropdown" then
            Try(S.Dropdown, frame)
        elseif kind == "tab" then
            Try(S.Tab, frame)
        elseif kind == "text" then
            Try(S.Font, frame)
        end
    end,
    tabSelected = function(tab, selected)
        if eui and eui.SetTabSelection then Try(eui.SetTabSelection, tab, selected) end
    end,
    accent = function()
        if eui and eui.GetAccentColor then
            local r, g, b = Try(eui.GetAccentColor)
            if type(r) == "number" then return { r, g, b } end
        end
    end,
}

if ADAPTERS.EllesmereUI.installed() then
    -- Registering is free; pieces are only handed over when the player chose this theme
    Try(EllesmereUI.RegisterSkin, "Keepnet", function(S)
        eui = S
        if S.OnLooksChanged then
            Try(S.OnLooksChanged, function()
                if W.adopting == "EllesmereUI" then W.ApplyTheme() end
            end)
        end
        Adopt.Flush()
    end)
end

-- ---------------------------------------------------------------------------------------------
-- ElvUI
-- ---------------------------------------------------------------------------------------------
local function ElvSkins()
    if type(ElvUI) ~= "table" then return nil end
    local E = ElvUI[1]
    local S = type(E) == "table" and Try(E.GetModule, E, "Skins", true)
    return S, E
end

ADAPTERS.ElvUI = {
    installed = function() return ElvSkins() ~= nil end,
    ready = function() return ElvSkins() ~= nil end,
    apply = function(kind, frame)
        local S = ElvSkins()
        if not S then return end
        if kind == "window" then
            Try(S.HandleFrame, S, frame, true)
            if frame.CloseButton then Try(S.HandleCloseButton, S, frame.CloseButton) end
        elseif kind == "panel" then
            Try(S.HandleFrame, S, frame, true)
        elseif kind == "button" then
            Try(S.HandleButton, S, frame)
        elseif kind == "check" then
            Try(S.HandleCheckBox, S, frame)
        elseif kind == "editbox" then
            Try(S.HandleEditBox, S, frame)
        elseif kind == "slider" then
            Try(S.HandleSliderFrame, S, frame)
        elseif kind == "dropdown" then
            Try(S.HandleDropDownBox, S, frame)
        elseif kind == "tab" then
            Try(S.HandleTab, S, frame)
        end
    end,
    accent = function()
        local _, E = ElvSkins()
        local color = type(E) == "table" and type(E.media) == "table" and E.media.rgbvaluecolor
        if type(color) == "table" then
            local r, g, b = color.r or color[1], color.g or color[2], color.b or color[3]
            if type(r) == "number" then return { r, g, b } end
        end
    end,
}

-- ---------------------------------------------------------------------------------------------
-- Handing pieces over
-- ---------------------------------------------------------------------------------------------
-- Whether a suite Keepnet has an adapter for is installed
function Adopt.Installed(suite)
    local adapter = ADAPTERS[suite]
    return adapter ~= nil and (Try(adapter.installed) and true or false)
end

-- The adapter of the suite whose theme is in use and which is installed, or nil
local function Current()
    local adapter = W.native and W.adopting and ADAPTERS[W.adopting]
    if adapter and Try(adapter.installed) then return adapter end
end

-- Whether pieces are being handed to a suite
function Adopt.Active()
    return Current() ~= nil
end

local queue = {}

-- Hands one piece to the suite. kind is "window", "panel", "button", "check", "slider",
-- "editbox", "dropdown", "tab" or "text". Pieces made before the suite is ready are kept and
-- handed over when it is.
function Adopt.Apply(kind, frame)
    local adapter = Current()
    if not adapter or not frame then return end
    if not adapter.ready() then
        queue[#queue + 1] = { kind, frame }
        return
    end
    if kind == "panel" then
        -- The suite paints it: Keepnet's own background on it steps aside (see Paint)
        frame.keepnetAdopted = true
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    adapter.apply(kind, frame)
end

function Adopt.Flush()
    local waiting = queue
    queue = {}
    for _, entry in ipairs(waiting) do
        Adopt.Apply(entry[1], entry[2])
    end
end

-- A tab shows as selected the suite's way too
function Adopt.TabSelected(tab, selected)
    local adapter = Current()
    if adapter and adapter.tabSelected and adapter.ready() then
        adapter.tabSelected(tab, selected and true or false)
    end
end

-- The suite's own accent colour as { r, g, b }, or nil
function Adopt.Accent()
    local adapter = Current()
    if adapter and adapter.accent then return adapter.accent() end
end
