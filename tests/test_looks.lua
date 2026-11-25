-- The looks Keepnet draws itself besides its flat one: Windows 95 (grey bevelled windows, dark
-- text, a title bar, colour schemes), Keepnet rounded (the flat look with round corners) and
-- Glass (round panes you can see through).
local T = {}

local KEY = "F"

function T.before()
    KeepnetDB = { settings = { theme = "win95", lureMode = "off", gear = false } }
end

local function Close(a, b)
    return math.abs(a - b) < 0.01
end

local function Is(color, r, g, b)
    return color ~= nil and Close(color[1], r / 255) and Close(color[2], g / 255) and Close(color[3], b / 255)
end

-- Every tab builds and redraws, and everything on it can be pointed at, pressed and let go
local function PokeEveryTab(ns)
    local function Poke()
        local snapshot = {}
        for i, frame in ipairs(Stub.frames) do snapshot[i] = frame end
        for _, frame in ipairs(snapshot) do
            for _, script in ipairs({ "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnMouseWheel", "OnClick", "OnDoubleClick" }) do
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
        Poke()
    end
    -- The poking may have chosen another look, which asks for a reload: that is its job
    Stub.popup = nil
end

function T.run(ns)
    local W, R = ns.Widgets, ns.Retro
    Stub.auction = { [13422] = 41800 }
    Stub.login()
    local settings = ns.settings

    -- ------------------------------------------------------------------- Windows 95
    eq(W.look, "retro", "a look saved from last time is the one built")
    eq(W.retro, true, "the retro pieces are in use")
    eq(W.native, false, "not the game's own")
    eq(Stub.popup, nil, "with no reload asked for")
    eq(#W.Theme("win95").schemes, 19, "it comes in nineteen colour schemes")
    eq(W.Scheme(W.Theme("win95")).name, "Windows Standard", "the first of them from the start")
    check(Is(W.COLORS.background, 192, 192, 192), "a grey face")
    check(Is(W.COLORS.accent, 0, 0, 128), "the selection's navy as the accent")

    -- The colours inside a text are swapped for ones that read on a light background
    eq(R.Ink("Food: |cff40ff40fed|r"), "Food: |cff008000fed|r", "green becomes dark green")
    eq(R.Ink("|cffffffffx|r"), "|cff000000x|r", "white becomes the text colour")
    eq(R.Ink("|cff9d9d9dx|r"), "|cff808080x|r", "grey becomes a darker grey")
    eq(R.Ink("|cffff6060x|r"), "|cff800000x|r", "red becomes maroon")
    eq(R.Ink("|cff0070ddx|r"), "|cff000080x|r", "blue becomes navy")
    eq(R.Ink("|cffa335eex|r"), "|cff800080x|r", "purple becomes dark purple")
    eq(R.Ink("plain"), "plain", "a text without colours is left alone")
    eq(R.Ink(12), 12, "and so is a number")

    -- The live panel: a bevelled window with a title bar
    Stub.equip(Stub.POLE)
    check(KeepnetPanel and KeepnetPanel:IsShown(), "the live panel is up")
    local art = KeepnetPanel.keepnetSkin.retro
    check(art ~= nil, "drawn by the look, not by a backdrop")
    eq(KeepnetPanel.__backdropFile, nil, "its backdrop is gone")
    eq(art.kind, "window", "as a window")
    check(Is(art.fill.__color, 192, 192, 192), "grey")
    check(Is(art.outer.top.__color, 223, 223, 223) and Is(art.outer.left.__color, 223, 223, 223), "light above and to the left")
    check(Is(art.outer.bottom.__color, 0, 0, 0) and Is(art.outer.right.__color, 0, 0, 0), "dark below and to the right")
    check(Is(art.inner.top.__color, 255, 255, 255) and Is(art.inner.bottom.__color, 128, 128, 128), "and the second line inside it")
    check(Is(KeepnetPanel.casts.__textColor, 0, 0, 0), "its text is dark")
    check(Is(KeepnetPanel.zone.__textColor, 255, 255, 255), "the zone stands on the title bar, light")
    check(Is(KeepnetPanel.time.__textColor, 255, 255, 255), "and so does the clock")
    check(KeepnetPanel.cog.glyph ~= nil, "the cog is a small button with dots on it")
    eq(KeepnetPanel.cog.tooltip, "Settings", "that still says what it is for")
    eq(KeepnetPanel.new.keepnetSkin.retro.kind, "button", "its buttons are bevelled buttons")

    -- Fishing works the same through it
    eq(Stub.press(KEY), "cast", "a cast")
    Stub.nextLoot = { { id = 13422, count = 2 } }
    eq(Stub.press(KEY), "reel", "a catch")
    eq(ns.Sessions.Current().catches, 1, "counted")
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
    eq(KeepnetPanel.casts:GetText(), "Casts: 1", "and shown, the text as it was given")
    check(not tostring(KeepnetPanel.rows[1].name.__text):find("|cffffffff", 1, true),
        "a white item name is not written in white")

    -- A button goes in while it is held
    local button = KeepnetPanel.new
    local buttonArt = button.keepnetSkin.retro
    check(Is(buttonArt.outer.top.__color, 255, 255, 255), "a button at rest: bright above")
    button:GetScript("OnMouseDown")(button, "LeftButton")
    check(Is(buttonArt.outer.top.__color, 0, 0, 0), "held: dark above")
    button:GetScript("OnMouseUp")(button, "LeftButton")
    check(Is(buttonArt.outer.top.__color, 255, 255, 255), "let go: bright again")
    -- Hovering changes nothing
    button:GetScript("OnEnter")(button)
    check(Is(buttonArt.fill.__color, 192, 192, 192), "a button under the mouse stays grey")
    button:GetScript("OnLeave")(button)

    -- A frame pointed out by its border gets a line inside the bevel
    KeepnetPanel:SetBackdropBorderColor(1, 0, 0, 1)
    check(art.marked ~= nil and Close(art.marked[1], 1), "a border colour of its own is a line inside the bevel")
    KeepnetPanel:SetBackdropBorderColor(W.BorderColor("panel"))
    eq(art.marked, nil, "the usual border colour takes it away")

    -- The window: a title bar with a close box, tabs on a framed page
    ns.UI.Show("session")
    check(tostring(KeepnetWindow.keepnetTitle:GetText()):find("Keepnet", 1, true), "the window is titled in its title bar")
    check(Is(KeepnetWindow.keepnetTitle.__textColor, 255, 255, 255), "in light letters")
    local tabs = {}
    for _, frame in ipairs(Stub.frames) do
        if frame.retroTab then tabs[#tabs + 1] = frame end
    end
    eq(#tabs, 7, "seven tabs")
    eq(tabs[1].selected, true, "the first is in front")
    eq(tabs[1].__height, 24, "and stands taller")
    eq(tabs[2].__height, 20, "than the others")
    ns.UI.Show("history")
    eq(tabs[1].selected, false, "another tab: the first steps back")
    eq(tabs[2].selected, true, "the new one comes forward")

    -- A tick box shows its tick when ticked
    local check1 = W.Check(KeepnetWindow, "A choice", function() end)
    eq(check1.__width, 13, "a tick box is the small square it was")
    eq(check1.keepnetSkin.retro.kind, "field", "set into the window")
    check(Is(check1.keepnetSkin.retro.fill.__color, 255, 255, 255), "and white")
    local tick
    for _, frame in ipairs(Stub.frames) do
        if frame.__parent == check1 and frame.parts then tick = frame end
    end
    check(tick ~= nil and not tick:IsShown(), "no tick to begin with")
    check1:SetChecked(true)
    check(tick:IsShown(), "ticked: the tick shows")
    check1:SetChecked(false)
    check(not tick:IsShown(), "unticked: it goes")

    -- A table: the chosen line is the selection's colour with light text
    local chosenRow
    local list = W.Table(KeepnetWindow, {
        { title = "Name", width = 120, text = function(row) return row.name end },
    }, { rows = 3, id = function(row) return row.name end, onSelect = function(row) chosenRow = row end })
    list:SetData({ { name = "|cff1eff00Pike|r" }, { name = "Bream" } })
    check(Is(list.rows[1].cells[1].__textColor, 0, 0, 0), "a line of a list: dark text")
    eq(list.rows[2].cells[1].__text, "|cff008000Pike|r", "an item's colour darkened for the white sheet")
    list.rows[2]:GetScript("OnClick")(list.rows[2])
    eq(chosenRow.name, "|cff1eff00Pike|r", "a line is chosen")
    check(list.rows[2].selected:IsShown(), "it is marked")
    check(Is(list.rows[2].cells[1].__textColor, 255, 255, 255), "with light text")
    eq(list.rows[2].cells[1].__text, "|cff1eff00Pike|r", "and the item's own bright colour")
    check(Is(list.rows[1].cells[1].__textColor, 0, 0, 0), "the other line stays dark")

    PokeEveryTab(ns)

    -- Another colour scheme: at once, everything follows
    settings.theme = "win95"
    W.SetScheme(W.Theme("win95"), "rose")
    Stub.reloads = 0
    W.ApplyTheme()
    eq(Stub.reloads, 0, "other colours need no reload")
    check(Is(art.fill.__color, 207, 175, 183), "the live panel in the new face colour")
    check(Is(art.inner.bottom.__color, 159, 96, 112), "and its shadow")
    check(Is(W.COLORS.accent, 159, 96, 112), "the selection is the accent")
    -- Light text on a dark face is left as it is
    W.SetScheme(W.Theme("win95"), "highcontrastblack")
    W.ApplyTheme()
    check(Is(art.fill.__color, 0, 0, 0), "High Contrast Black: a black face")
    check(Is(KeepnetPanel.casts.__textColor, 255, 255, 255), "with light text")
    KeepnetPanel.buffs:SetText("|cff40ff40fed|r")
    eq(KeepnetPanel.buffs.__text, "|cff40ff40fed|r", "and bright colours kept bright")
    -- The player's own accent is the title bar and the selection
    W.SetScheme(W.Theme("win95"), "standard")
    settings.accentMode, settings.accentColor = "custom", { 1, 1, 0 }
    W.ApplyTheme()
    check(Is(R.COLORS.title, 255, 255, 0) and Is(R.COLORS.select, 255, 255, 0), "an accent of the player's own colours the title bar and the selection")
    check(Is(R.COLORS.titleText, 0, 0, 0), "with dark letters on a light one")
    settings.accentMode, settings.accentColor = "theme", nil
    W.ApplyTheme()
    check(Is(R.COLORS.title, 0, 0, 128) and Is(R.COLORS.titleText, 255, 255, 255), "and back")

    -- ------------------------------------------------------------- Keepnet rounded
    settings.theme = "rounded"
    Stub.popup = nil
    W.ApplyTheme()
    eq(Stub.popup, "KEEPNET_RELOAD_FOR_THEME", "a look drawn another way asks to reload")
    eq(W.look, "retro", "and nothing changes until then")
    ns = Stub.reload()
    W = ns.Widgets
    settings = ns.settings
    eq(W.look, "round", "after the reload the rounded look is built")
    eq(W.round, true, "its pieces are in use")
    eq(W.retro, false, "the retro ones are not")
    Stub.equip(Stub.POLE)
    local round = KeepnetPanel.keepnetSkin.round
    check(round ~= nil, "the live panel is drawn with round corners")
    eq(KeepnetPanel.__backdropFile, nil, "its square backdrop is gone")
    eq(#round.corners, 4, "four corners")
    check(tostring(round.corners[1].__texture):find("RoundFill8", 1, true), "big ones for a big frame")
    check(Close(round.corners[1].__vertex[1], 0.06) and Close(round.corners[1].__vertex[4], 0.94), "in the background colour, as see-through as chosen")
    check(Close(round.bands[1].__color[1], 0.06), "and so is what lies between them")
    check(tostring(KeepnetPanel.new.keepnetSkin.round.corners[1].__texture):find("RoundFill4", 1, true), "small ones for a button")
    check(Is(KeepnetPanel.casts.__textColor or { 1, 1, 1 }, 255, 255, 255), "the text is the game's light text")

    -- The screens colour a round frame the way they colour a square one
    local roundButton = KeepnetPanel.new
    roundButton:GetScript("OnEnter")(roundButton)
    check(Close(roundButton.keepnetSkin.round.bands[1].__color[1], 0.24), "a button under the mouse lights up")
    roundButton:GetScript("OnLeave")(roundButton)
    check(Close(roundButton.keepnetSkin.round.bands[1].__color[1], 0.17), "and goes back")
    KeepnetPanel:SetBackdropBorderColor(1, 0, 0, 1)
    check(Close(round.ringLines[1].__color[1], 1) and Close(round.ringCorners[1].__vertex[1], 1), "a border colour reaches the round border")

    -- The same colours as the Keepnet look, changed at once
    eq(W.Theme("rounded").schemes, W.Theme("keepnet").schemes, "it shares Keepnet's colours")
    W.SetScheme(W.Theme("rounded"), "forest")
    Stub.reloads = 0
    W.ApplyTheme()
    eq(Stub.reloads, 0, "other colours need no reload")
    check(Close(round.bands[1].__color[2], 0.08), "the panel in the new colours")
    eq(W.Scheme(W.Theme("keepnet")).key, "forest", "and the Keepnet look has them too")
    settings.borders = false
    W.ApplyTheme()
    eq(round.ringLines[1].__color[4], 0, "borders switched off: the round border goes")
    settings.borders = true
    W.ApplyTheme()

    -- Column headings stay square
    local heading = W.Header(KeepnetPanel, "Name", 100, 18)
    eq(heading.keepnetSkin.round, nil, "a column heading is not rounded")
    check(heading.__backdropFile ~= nil, "it keeps its square backdrop")

    PokeEveryTab(ns)

    -- ------------------------------------------------------------------------- Glass
    settings.panelOpacity, settings.windowOpacity = 0.9, 0.8
    settings.theme = "glass"
    Stub.popup = nil
    W.ApplyTheme()
    eq(Stub.popup, "KEEPNET_RELOAD_FOR_THEME", "glass is drawn another way again: a reload")
    ns = Stub.reload()
    W = ns.Widgets
    settings = ns.settings
    eq(W.look, "glass", "after the reload the Glass look is built")
    eq(W.glass, true, "its pieces are in use")
    eq(W.round, true, "which are round ones")
    eq(#W.Theme("glass").schemes, 6, "it comes in six colours")
    eq(W.Scheme(W.Theme("glass")).name, "Smoked", "smoked from the start")
    Stub.equip(Stub.POLE)
    local glass = KeepnetPanel.keepnetSkin.round
    check(glass ~= nil and glass.glass, "the live panel is a pane of glass")
    -- The tint: 65 % dense unless the player says otherwise, whatever the other looks are set to
    check(Close(glass.bands[1].__color[1], 0.085) and Close(glass.bands[1].__color[4], 0.65), "tinted, 65 % dense to begin with")
    check(Close(glass.corners[1].__vertex[4], 0.65), "corners and all")
    -- The rim of light: bright along the top, faint along the bottom, fading down the sides
    check(Close(glass.lineTop.__color[1], 1) and Close(glass.lineTop.__color[4], 0.55), "a rim of light, bright along the top")
    check(Close(glass.lineBottom.__color[4], 0.12), "faint along the bottom")
    local side = glass.lineLeft.__gradient
    check(side ~= nil and side[1] == "VERTICAL" and Close(side[2].a, 0.12) and Close(side[3].a, 0.55), "fading down the sides")
    for _, corner in ipairs(glass.ringCorners) do
        check(Close(corner.__vertex[4], corner.top and 0.55 or 0.12), "and round each corner to match")
    end
    -- The wash of light and the shadow
    check(glass.wash ~= nil and Close(glass.wash.__gradient[3].a, 0.10) and glass.wash.__gradient[2].a == 0, "a wash of light fading down from the top")
    eq(#glass.shadow, 8, "a soft shadow round it: four corners and four sides")
    check(tostring(glass.shadow[1].__texture):find("GlassShadow8", 1, true), "from its own picture")
    check(glass.shadow[1].__vertex[1] == 0 and glass.shadow[1].__vertex[4] > 0.5, "in black")

    -- The small pieces: a button lightens the pane, what is set into it darkens it
    local glassButton = KeepnetPanel.new.keepnetSkin.round
    check(Close(glassButton.bands[1].__color[1], 1) and Close(glassButton.bands[1].__color[4], 0.09), "a button is a lighter patch of glass")
    eq(glassButton.shadow, nil, "without a shadow of its own")
    check(glassButton.wash ~= nil, "with the wash of light")
    check(Close(glassButton.lineTop.__color[4], 0.55 * 0.6), "and a fainter rim")
    KeepnetPanel.new:GetScript("OnEnter")(KeepnetPanel.new)
    check(Close(glassButton.bands[1].__color[4], 0.20), "under the mouse it lights up")
    KeepnetPanel.new:GetScript("OnLeave")(KeepnetPanel.new)
    check(Close(glassButton.bands[1].__color[4], 0.09), "and goes back")
    local bar = KeepnetPanel.skillBar.keepnetSkin.round
    check(bar.bands[1].__color[1] == 0 and Close(bar.bands[1].__color[4], 0.32), "the skill bar is a darker channel in the pane")
    eq(bar.wash, nil, "without the wash")

    -- A frame pointed out by its border gets that colour all round, then its rim back
    KeepnetPanel:SetBackdropBorderColor(1, 0, 0, 1)
    check(Close(glass.lineTop.__color[2], 0) and Close(glass.lineBottom.__color[4], 1), "a border colour of its own goes all round the rim")
    KeepnetPanel:SetBackdropBorderColor(W.BorderColor("panel"))
    check(Close(glass.lineBottom.__color[4], 0.12) and Close(glass.lineTop.__color[2], 1), "and the rim of light comes back")

    -- The tint is the player's to change: the two background sliders, kept apart from the
    -- other looks' settings
    eq(settings.panelOpacity, 0.9, "the other looks' setting is untouched")
    settings.glassPanel = 0.3
    W.ApplyTheme()
    check(Close(glass.bands[1].__color[4], 0.3), "the live panel's tint follows its setting")
    ns.UI.Show("appearance")
    check(Close(KeepnetWindow.keepnetSkin.round.bands[1].__color[4], 0.65), "the window has its own, 65 % too")
    settings.glassWindow = 0.8
    W.ApplyTheme()
    check(Close(KeepnetWindow.keepnetSkin.round.bands[1].__color[4], 0.8), "which follows its setting")
    settings.borders = false
    W.ApplyTheme()
    eq(glass.lineTop.__color[4], 0, "borders switched off: the rim goes")
    settings.borders = true

    -- Other colours at once; a menu is nearly solid so it reads over what it covers
    W.SetScheme(W.Theme("glass"), "water")
    Stub.reloads = 0
    W.ApplyTheme()
    eq(Stub.reloads, 0, "other colours need no reload")
    check(Close(glass.bands[1].__color[3], 0.14), "the pane takes the new tint")
    check(Close(KeepnetPanel.menu.keepnetSkin.round.bands[1].__color[4], 0.93), "a menu is nearly solid")
    check(Close(KeepnetPanel.menu.keepnetSkin.round.bands[1].__color[3], 0.14), "in the pane's tint")

    -- Matrix on glass: black glass, a green rim, green buttons, green writing
    W.SetScheme(W.Theme("glass"), "matrix")
    W.ApplyTheme()
    check(Close(glass.bands[1].__color[2], 0.04) and glass.bands[1].__color[1] == 0, "Matrix: the pane is black with a breath of green")
    check(Close(glass.lineTop.__color[1], 0.30) and Close(glass.lineTop.__color[2], 1), "its rim is green")
    check(Close(glassButton.bands[1].__color[2], 1) and glassButton.bands[1].__color[1] == 0, "its buttons are green patches")
    check(Close(KeepnetGameFontHighlightSmall.__textColor[2], 1) and KeepnetGameFontHighlightSmall.__textColor[1] == 0, "and its writing is green")
    W.SetScheme(W.Theme("glass"), "water")
    W.ApplyTheme()
    eq(KeepnetGameFontHighlightSmall.__textColor[1], 1, "other colours: the writing is white again")

    PokeEveryTab(ns)

    -- Back to the square look: another way of drawing, so a reload
    settings.theme = "keepnet"
    Stub.popup = nil
    W.ApplyTheme()
    eq(Stub.popup, "KEEPNET_RELOAD_FOR_THEME", "back to the square look asks to reload")
    ns = Stub.reload()
    eq(ns.Widgets.look, "flat", "and is built after it")
    Stub.equip(Stub.POLE)
    check(KeepnetPanel.__backdropFile ~= nil, "the live panel has its backdrop again")
    check(Close(KeepnetPanel.__backdrop[2], 0.08), "in the colours chosen for the rounded look")
    check(Close(KeepnetPanel.__backdrop[4], 0.9), "and as solid as it was set for these looks")

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
