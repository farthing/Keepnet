-- The themes named after an interface suite: Keepnet is built from the game's templates and each
-- piece is handed to that suite. Stand-ins for EllesmereUI's skinning interface and for
-- ElvUI's Skins module record what they are handed.
local T = {}

local KEY = "F"
local handed = {}     -- primitive name -> how many frames it was given
local selections = 0
local looksChanged
local accent = { 0.86, 0.65, 0.50 }

local function Primitive(name)
    return function(frame)
        if type(frame) ~= "table" then error("skin primitive " .. name .. " called without a frame") end
        handed[name] = (handed[name] or 0) + 1
    end
end

-- What the suite hands an addon, per its published guide
local S = { apiVersion = 4 }
for _, name in ipairs({ "Shell", "Panel", "Inset", "Button", "StateButtonLabel", "EditBox", "Checkbox",
    "Dropdown", "Tab", "CloseButton", "Font" }) do
    S[name] = Primitive(name)
end
function S.SetTabSelection() selections = selections + 1 end
function S.GetAccentColor() return accent[1], accent[2], accent[3] end
function S.OnLooksChanged(fn) looksChanged = fn end

function T.before()
    EllesmereUI = { RegisterSkin = function(name, callback) Stub.suiteSkin = { name = name, callback = callback } end }
    KeepnetDB = { settings = { theme = "ellesmereui", lureMode = "off", gear = false } }
end

function T.run(ns)
    local W, Adopt = ns.Widgets, ns.Adopt
    check(Stub.suiteSkin ~= nil, "Keepnet registers with the suite as it loads")
    eq(Stub.suiteSkin.name, "Keepnet", "under its own name")
    eq(Adopt.Installed("EllesmereUI"), true, "the installed suite is recognised")
    eq(Adopt.Installed("ElvUI"), false, "one that isn't installed is not")

    Stub.login()
    eq(W.native, true, "the theme builds from the game's templates")
    eq(Adopt.Active(), true, "and is handing pieces over")

    -- The live panel is built before the suite has handed over its primitives: it waits
    Stub.equip(Stub.POLE)
    eq(handed.Panel, nil, "nothing is handed over before the suite is ready")
    Stub.suiteSkin.callback(S)
    eq(handed.Panel, 1, "once it is, the waiting live panel is handed over")
    check((handed.Button or 0) >= 2, "with its buttons")
    eq(KeepnetPanel.__backdrop[4], 0, "Keepnet's own background on it steps aside")

    -- The suite's accent is Keepnet's accent
    W.ApplyTheme()
    check(math.abs(W.COLORS.accent[1] - 0.86) < 0.001, "the suite's accent colour is used")
    accent = { 0.1, 0.9, 0.6 }
    looksChanged()
    check(math.abs(W.COLORS.accent[2] - 0.9) < 0.001, "and followed when the player changes it in the suite")

    -- The window and everything in it
    ns.UI.Show("settings")
    eq(handed.Shell, 1, "the window gets the suite's window look")
    eq(handed.CloseButton, 1, "and its close button")
    check((handed.Tab or 0) >= 7, "every tab is handed over")
    check(selections >= 7, "and told which one is showing")
    check((handed.Checkbox or 0) >= 5, "tick boxes")
    check((handed.Dropdown or 0) >= 2, "drop-downs")
    check((handed.Font or 0) > 20, "and the texts, for the player's font")
    ns.UI.Show("history")
    check((handed.EditBox or 0) >= 1, "the search box")
    -- The sliders have no primitive in this suite: they stay the game's own
    for _, tab in ipairs({ "session", "zones", "gear", "alerts", "appearance" }) do
        ns.UI.Show(tab)
        ns.UI.Refresh()
    end

    -- Fishing is untouched by any of it
    eq(Stub.press(KEY), "cast", "a cast")
    Stub.nextLoot = { { id = 13422, count = 1 } }
    eq(Stub.press(KEY), "reel", "a catch")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)

    -- A primitive that fails must not break Keepnet
    S.Button = function() error("the suite changed its mind") end
    local button = W.Button(KeepnetWindow, "Still here", 80, 22)
    check(button ~= nil and button.label ~= nil, "a failing primitive leaves the game's own piece in place")

    -- Another theme: nothing is handed over
    ns.settings.theme = "forever"
    ns = Stub.reload()
    local before = handed.Shell
    Stub.suiteSkin.callback(S)
    ns.UI.Show("settings")
    eq(ns.Adopt.Active(), false, "the Forever theme hands nothing over")
    eq(handed.Shell, before, "the window stays the game's own")

    -- The Keepnet theme is its own flat look, whatever suite is installed
    ns.settings.theme = "keepnet"
    ns = Stub.reload()
    before = (handed.Shell or 0) + (handed.Panel or 0) + (handed.Font or 0)
    Stub.suiteSkin.callback(S)
    ns.UI.Show("settings")
    eq(ns.Widgets.native, false, "the Keepnet theme is the flat look")
    eq(KeepnetWindow.__template, "BackdropTemplate", "its window is Keepnet's own")
    eq((handed.Shell or 0) + (handed.Panel or 0) + (handed.Font or 0), before, "and the suite is handed nothing")

    -- A suite theme chosen without that suite installed is simply the Forever look
    EllesmereUI = nil
    ns.settings.theme = "ellesmereui"
    ns = Stub.reload()
    eq(ns.Adopt.Installed("EllesmereUI"), false, "the suite is gone")
    eq(ns.Adopt.Active(), false, "so nothing is handed over")
    ns.UI.Show("appearance")
    eq(KeepnetWindow.__template, "BasicFrameTemplateWithInset", "it is built like Forever, and works")

    -- ElvUI: its Skins module is called the way addons skin themselves for it
    local elv = {}
    local skins = {}
    for _, name in ipairs({ "HandleFrame", "HandleButton", "HandleCheckBox", "HandleEditBox", "HandleSliderFrame",
        "HandleDropDownBox", "HandleTab", "HandleCloseButton" }) do
        skins[name] = function(self, frame)
            if self ~= skins or type(frame) ~= "table" then error(name .. " called wrongly") end
            elv[name] = (elv[name] or 0) + 1
        end
    end
    local E = { media = { rgbvaluecolor = { r = 0.2, g = 0.6, b = 1 } } }
    function E:GetModule(name) if name == "Skins" then return skins end end
    ElvUI = { E }
    ns.settings.theme = "elvui"
    ns = Stub.reload()
    eq(ns.Adopt.Installed("ElvUI"), true, "ElvUI is recognised")
    Stub.equip(Stub.POLE)
    ns.UI.Show("settings")
    eq(elv.HandleFrame, 2, "the window and the live panel get ElvUI's frame look")
    eq(elv.HandleCloseButton, 1, "the close button")
    check((elv.HandleButton or 0) >= 4, "buttons")
    check((elv.HandleCheckBox or 0) >= 5, "tick boxes")
    check((elv.HandleSliderFrame or 0) >= 2, "sliders")
    check((elv.HandleDropDownBox or 0) >= 2, "drop-downs")
    check((elv.HandleTab or 0) >= 7, "tabs")
    check(math.abs(ns.Widgets.COLORS.accent[3] - 1) < 0.001, "and ElvUI's accent colour is used")
    ElvUI = nil

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
