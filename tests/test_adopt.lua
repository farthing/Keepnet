-- The look named after an interface suite: Keepnet is built from the game's templates and each
-- piece is handed to that suite. A stand-in for EllesmereUI's skinning interface records what
-- it is handed.
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
    eq(Adopt.Installed("SomeOtherSuite"), false, "one Keepnet has no adapter for is not")

    Stub.login()
    eq(W.native, true, "the theme builds from the game's templates")
    eq(Adopt.Active(), true, "and is handing pieces over")

    -- The live panel is built before the suite has handed over its primitives: it waits
    Stub.equip(Stub.POLE)
    eq(handed.Panel, nil, "nothing is handed over before the suite is ready")
    Stub.suiteSkin.callback(S)
    eq(handed.Panel, 2, "once it is, the waiting live panel is handed over, and the strip under it")
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

    -- There was an ElvUI look once: a saved choice of it is the Forever look now
    ns.settings.theme = "elvui"
    ns = Stub.reload()
    eq(ns.settings.theme, "forever", "a saved ElvUI look becomes Forever")
    eq(ns.Widgets.native, true, "built from the game's own pieces")
    eq(ns.Adopt.Active(), false, "with nothing handed to a suite")
    ns.UI.Show("appearance")
    eq(KeepnetWindow.__template, "BasicFrameTemplateWithInset", "and it works")
    for _, theme in ipairs(ns.Widgets.THEMES) do
        check(theme.key ~= "elvui", "the list of looks has no ElvUI: " .. theme.key)
    end

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
