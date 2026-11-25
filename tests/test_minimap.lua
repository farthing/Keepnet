-- The button on the minimap: Keepnet's own where nobody has loaded LibDBIcon, that library's
-- where somebody has; what its clicks do, where it sits, that it can be dragged and hidden,
-- and that where it sits and whether it shows are each character's own.
local T = {}

local ICON = "Interface\\AddOns\\Keepnet\\Media\\Icon"
local RADIUS = 140 / 2 + 5 -- the stand-in minimap is 140 across; the button sits 5 outside it

local FIRST = { name = "Mara", surname = "Tidewell", guid = "Player-4101-00A1B2C3", level = 38 }
local SECOND = { name = "Pell", surname = "Harrow", guid = "Player-4101-00A7B8C9", level = 24 }

function T.before()
    Stub.realm = ""
    Stub.player = FIRST
    function UnitGUID() return Stub.player.guid end
    function UnitLevel() return Stub.player.level end
    -- What a minimap addon says the minimap's shape is (nil: there is no such addon's answer)
    function GetMinimapShape() return Stub.minimapShape end
end

local function Near(actual, expected)
    return type(actual) == "number" and math.abs(actual - expected) < 0.01
end

-- Where the button was last put: how far right and up of the minimap's middle
local function Where(button)
    local last = button.__placed[#button.__placed]
    eq(last[1], "CENTER", "the button is placed by its middle")
    eq(last[2], Minimap, "on the minimap")
    return last[4], last[5]
end

local function At(button, x, y, what)
    local px, py = Where(button)
    check(Near(px, x) and Near(py, y), ("%s: expected %.2f, %.2f, got %s, %s"):format(
        what or "on the round edge, at its angle", x, y, tostring(px), tostring(py)))
end

local function OnEdge(degrees)
    return RADIUS * math.cos(math.rad(degrees)), RADIUS * math.sin(math.rad(degrees))
end

local function Count(list, text)
    local n = 0
    for _, line in ipairs(list) do
        if tostring(line):find(text, 1, true) then n = n + 1 end
    end
    return n
end

-- What a tooltip is given, line by line
local function Lines()
    local lines = {}
    local tooltip = { owner = nil }
    function tooltip:AddLine(text) lines[#lines + 1] = text end
    function tooltip:GetOwner() return self.owner end
    return tooltip, lines
end

-- LibDataBroker and LibDBIcon, as far as an addon with a minimap button uses them
local function Libraries()
    local broker = { objects = {} }
    function broker:NewDataObject(name, object)
        if self.objects[name] then return nil end
        self.objects[name] = object
        return object
    end
    local icons = { buttons = {}, shows = 0, hides = 0, refreshes = 0 }
    function icons:Register(name, object, db)
        if not object.icon then error("Can't register LDB objects without icons set!") end
        if self.buttons[name] then error("already registered") end
        self.buttons[name] = { object = object, db = db, shown = not db.hide, at = db.minimapPos }
    end
    function icons:Show(name)
        local button = self.buttons[name]
        button.shown, button.at = true, button.db.minimapPos
        self.shows = self.shows + 1
    end
    function icons:Hide(name)
        self.buttons[name].shown = false
        self.hides = self.hides + 1
    end
    function icons:Refresh(name, db)
        local button = self.buttons[name]
        if db then button.db = db end
        button.shown, button.at = not button.db.hide, button.db.minimapPos
        self.refreshes = self.refreshes + 1
    end
    return broker, icons
end

function T.run(ns)
    -- ------------------------------------------------------------ nobody brought the library
    eq(ns.MinimapButton.Kind(), nil, "no button before the world is entered")
    Stub.login()
    local button = KeepnetMinimapButton
    check(button ~= nil, "Keepnet's own button is made")
    eq(ns.MinimapButton.Kind(), "own", "it is Keepnet's own: no other addon brought LibDBIcon")
    eq(button:GetParent(), Minimap, "it belongs to the minimap")
    eq(button.icon.__texture, ICON, "it shows Keepnet's own icon")
    eq(Stub.visible(button), true, "it shows from the start")
    eq(ns.settings.minimapButton, true, "which is the setting's default")
    At(button, RADIUS * math.cos(math.rad(190)), RADIUS * math.sin(math.rad(190)), "it starts on the left of a round minimap")

    -- Left click: the window. Right click: the live panel.
    local click = button:GetScript("OnClick")
    click(button, "LeftButton")
    eq(ns.UI.IsShown(), true, "a left click opens the window")
    click(button, "LeftButton")
    eq(ns.UI.IsShown(), false, "another closes it")
    local said = Count(Stub.chat, "live panel shows while a fishing pole")
    click(button, "RightButton")
    eq(Count(Stub.chat, "live panel shows while a fishing pole"), said + 1,
        "a right click is for the live panel: without a pole it says when that shows")
    eq(ns.UI.IsShown(), false, "and leaves the window alone")
    Stub.equip(Stub.POLE)
    check(KeepnetPanel and KeepnetPanel:IsShown(), "with the pole on the live panel shows")
    click(button, "RightButton")
    eq(KeepnetPanel:IsShown(), false, "a right click hides it")
    click(button, "RightButton")
    eq(KeepnetPanel:IsShown(), true, "and the next brings it back")
    Stub.equip(nil)

    -- The tooltip says what the clicks do
    local shown = {}
    GameTooltip.AddLine = function(_, text) shown[#shown + 1] = text end
    button:GetScript("OnEnter")(button)
    check(shown[1] and shown[1]:find("Keepnet", 1, true) and shown[1]:find(ns.VERSION, 1, true), "the tooltip names Keepnet and its version")
    eq(Count(shown, "Left click"), 1, "says what a left click does")
    eq(Count(shown, "Right click"), 1, "what a right click does")
    eq(Count(shown, "Drag"), 1, "and that the button can be dragged")
    button:GetScript("OnLeave")(button)

    -- Dragged: it follows the mouse round the minimap, and stays where it was let go
    Stub.cursor = { 1400, 900 } -- straight above the middle of the minimap
    button:GetScript("OnDragStart")(button)
    check(button:GetScript("OnUpdate") ~= nil, "while it is dragged it follows the mouse")
    button:GetScript("OnUpdate")(button, 0.02)
    check(Near(ns.settings.minimapAngle, 90), "the mouse above the minimap: 90 degrees")
    At(button, 0, RADIUS, "the button is at the top")
    shown = {}
    button:GetScript("OnEnter")(button)
    eq(#shown, 0, "no tooltip while it is dragged")
    Stub.cursor = { 1500, 700 } -- below and to the right
    button:GetScript("OnUpdate")(button, 0.02)
    check(Near(ns.settings.minimapAngle, 315), "below and to the right: 315 degrees")
    At(button, OnEdge(315))
    button:GetScript("OnDragStop")(button)
    eq(button:GetScript("OnUpdate"), nil, "let go: it stops following")
    GameTooltip.AddLine = nil

    -- A minimap addon gave the minimap another shape: the button keeps to its edge
    local function Angle(degrees)
        ns.settings.minimapAngle = degrees
        ns.Fire("SETTINGS")
    end
    Stub.minimapShape = "SQUARE"
    Angle(45)
    At(button, RADIUS, RADIUS, "a square minimap: 45 degrees is its corner")
    Angle(30)
    At(button, RADIUS, RADIUS * math.tan(math.rad(30)), "30 degrees is on its right side")
    Angle(100)
    At(button, RADIUS * math.cos(math.rad(100)) / math.sin(math.rad(100)), RADIUS, "100 degrees is on its top side")
    Stub.minimapShape = "CORNER-TOPLEFT"
    Angle(135)
    At(button, OnEdge(135))
    Angle(45)
    At(button, RADIUS, RADIUS, "only the top left corner round: the top right is a square's")
    Stub.minimapShape = "SIDE-LEFT"
    Angle(225)
    At(button, OnEdge(225))
    Angle(315)
    At(button, RADIUS, -RADIUS, "the left side round: the bottom right is a square's")
    Stub.minimapShape = "TRICORNER-TOPLEFT"
    Angle(45)
    At(button, OnEdge(45))
    Angle(315)
    At(button, RADIUS, -RADIUS, "all round but the corner opposite the top left")
    Stub.minimapShape = Stub.SECRET
    Angle(314)
    At(button, OnEdge(314))
    Stub.minimapShape = nil

    -- It gets another size after login
    Minimap:SetSize(200, 200)
    Minimap:GetScript("OnSizeChanged")(Minimap, 200, 200)
    At(button, 105 * math.cos(math.rad(314)), 105 * math.sin(math.rad(314)), "a bigger minimap: out to its new edge")
    Minimap:SetSize(140, 140)
    Minimap:GetScript("OnSizeChanged")(Minimap, 140, 140)

    -- Something else took the button off the minimap (a collector's drawer): it is not pulled back
    local drawer = CreateFrame("Frame", nil, UIParent)
    button:SetParent(drawer)
    local placed = #button.__placed
    Angle(10)
    Stub.fire("PLAYER_ENTERING_WORLD", false, false)
    Stub.advance(2)
    eq(#button.__placed, placed, "a button in another addon's keeping is left where it was put")
    button:SetParent(Minimap)

    -- Hidden and shown: the tick box on the Settings tab, and /kn minimap
    ns.UI.Show("settings")
    local box = ns.SettingsChecks.minimap
    eq(box:GetChecked(), true, "the Settings tab shows the box ticked")
    box:SetChecked(false)
    box:GetScript("OnClick")(box)
    eq(ns.settings.minimapButton, false, "unticked: the setting is off")
    eq(button:IsShown(), false, "and the button is gone")
    SlashCmdList.KEEPNET("minimap")
    eq(button:IsShown(), true, "/kn minimap brings it back")
    eq(box:GetChecked(), true, "and the box on the open Settings tab follows")
    eq(Count(Stub.chat, "minimap button is back"), 1, "saying so")
    SlashCmdList.KEEPNET("minimap")
    eq(button:IsShown(), false, "/kn minimap again hides it")
    eq(Count(Stub.chat, "/kn minimap brings it back"), 1, "saying how to get it back")
    ns.UI.Toggle()

    -- The addon menu on the minimap: the same clicks, the same lines
    Keepnet_OnAddonCompartmentClick("Keepnet", "LeftButton")
    eq(ns.UI.IsShown(), true, "a click on Keepnet in the addon menu opens the window")
    Keepnet_OnAddonCompartmentClick("Keepnet", "LeftButton")
    eq(ns.UI.IsShown(), false, "and closes it")
    shown = {}
    GameTooltip.AddLine = function(_, text) shown[#shown + 1] = text end
    Keepnet_OnAddonCompartmentEnter("Keepnet", drawer)
    eq(Count(shown, "Left click"), 1, "the addon menu's tooltip says what a click does")
    eq(Count(shown, "Drag"), 0, "and nothing of dragging: there is nothing to drag there")
    Keepnet_OnAddonCompartmentLeave("Keepnet", drawer)
    GameTooltip.AddLine = nil

    -- Hidden, and at 10 degrees: both are kept over a reload
    ns = Stub.reload()
    button = KeepnetMinimapButton
    eq(button:IsShown(), false, "after a reload it is still hidden")
    eq(ns.settings.minimapAngle, 10, "and still knows its place")

    -- Each character has its own: another one starts with a copy, and changes only its own
    Stub.player = SECOND
    ns = Stub.reload()
    button = KeepnetMinimapButton
    eq(button:IsShown(), false, "a new character starts with the last one's settings: hidden")
    SlashCmdList.KEEPNET("minimap")
    ns.settings.minimapAngle = 270
    ns.Fire("SETTINGS")
    At(button, OnEdge(270))
    Stub.player = FIRST
    ns = Stub.reload()
    button = KeepnetMinimapButton
    eq(button:IsShown(), false, "the first character's is still hidden")
    eq(ns.settings.minimapAngle, 10, "and where it was")

    -- ---------------------------------------------------- another addon brought the libraries
    local broker, icons = Libraries()
    Stub.libs["LibDataBroker-1.1"], Stub.libs["LibDBIcon-1.0"] = broker, icons
    Stub.player = SECOND
    ns = Stub.reload()
    eq(ns.MinimapButton.Kind(), "library", "with LibDBIcon loaded the button is that library's")
    eq(KeepnetMinimapButton, nil, "and Keepnet makes none of its own")
    local object = broker.objects.Keepnet
    check(object ~= nil, "Keepnet is known to LibDataBroker")
    eq(object.type, "launcher", "as a launcher, for broker bars")
    eq(object.icon, ICON, "with its own icon")
    local theirs = icons.buttons.Keepnet
    check(theirs ~= nil, "and its button is registered with LibDBIcon")
    eq(theirs.shown, true, "shown, as this character has it")
    eq(theirs.at, 270, "where this character has it")
    eq(icons.shows + icons.hides + icons.refreshes, 0, "the library is told nothing it already knows")

    -- The same clicks
    object.OnClick(nil, "LeftButton")
    eq(ns.UI.IsShown(), true, "a left click on the library's button opens the window")
    object.OnClick(nil, "LeftButton")
    eq(ns.UI.IsShown(), false, "and closes it")
    said = Count(Stub.chat, "live panel shows while a fishing pole")
    object.OnClick(nil, "RightButton")
    eq(Count(Stub.chat, "live panel shows while a fishing pole"), said + 1, "a right click is for the live panel")

    -- The same lines; dragging is only spoken of on the minimap button
    local tooltip, lines = Lines()
    tooltip.owner = { GetName = function() return "LibDBIcon10_Keepnet" end }
    object.OnTooltipShow(tooltip)
    eq(Count(lines, "Left click"), 1, "the library's tooltip says what a left click does")
    eq(Count(lines, "Drag"), 1, "and on the minimap, that the button can be dragged")
    tooltip, lines = Lines()
    tooltip.owner = { GetName = function() return "SomeBrokerBarPlugin" end }
    object.OnTooltipShow(tooltip)
    eq(Count(lines, "Right click"), 1, "on a broker bar the same")
    eq(Count(lines, "Drag"), 0, "without the dragging")

    -- The library's button is dragged: the library writes the place, and it is the setting
    theirs.db.minimapPos = 37
    eq(ns.settings.minimapAngle, 37, "where the library's button is dragged to is this character's setting")
    ns.Fire("SETTINGS")
    eq(icons.refreshes, 0, "and the library is not told what it wrote itself")
    eq(theirs.db.lock, nil, "nothing else is in what the library was handed")
    theirs.db.lock = true
    eq(theirs.db.lock, true, "what the library notes there itself, it reads back")
    theirs.db.lock = nil
    eq(rawget(theirs.db, "minimapPos"), nil, "and nothing of it is kept anywhere but the settings")

    -- Hidden and shown
    SlashCmdList.KEEPNET("minimap")
    eq(theirs.shown, false, "/kn minimap hides the library's button")
    eq(icons.hides, 1, "by telling the library once")
    eq(theirs.db.hide, true, "which reads it as hidden")
    ns.Fire("SETTINGS")
    eq(icons.hides, 1, "a setting changed elsewhere tells it nothing")
    SlashCmdList.KEEPNET("minimap")
    eq(theirs.shown, true, "and /kn minimap shows it again")
    eq(icons.shows, 1, "by telling the library once")

    -- A place changed from outside (as when another character's settings come in)
    ns.settings.minimapAngle = 120
    ns.Fire("SETTINGS")
    eq(icons.refreshes, 1, "a place that changed is passed on to the library")
    eq(theirs.at, 120, "which moves its button there")

    -- The other character: its own place, and hidden
    Stub.player = FIRST
    broker, icons = Libraries()
    Stub.libs["LibDataBroker-1.1"], Stub.libs["LibDBIcon-1.0"] = broker, icons
    ns = Stub.reload()
    theirs = icons.buttons.Keepnet
    eq(theirs.shown, false, "the first character's button is hidden in the library too")
    eq(theirs.db.minimapPos, 10, "and has its own place")

    -- LibDataBroker without LibDBIcon (a broker bar and nothing else): the launcher, and
    -- Keepnet's own button on the minimap
    broker = Libraries()
    Stub.libs["LibDataBroker-1.1"], Stub.libs["LibDBIcon-1.0"] = broker, nil
    ns = Stub.reload()
    check(broker.objects.Keepnet ~= nil, "with only LibDataBroker loaded Keepnet is still a launcher")
    eq(ns.MinimapButton.Kind(), "own", "and the minimap button is Keepnet's own")
    check(KeepnetMinimapButton ~= nil, "which is made")

    -- A library that refuses: Keepnet's own button, and no error
    broker, icons = Libraries()
    function icons:Register() error("no") end
    Stub.libs["LibDataBroker-1.1"], Stub.libs["LibDBIcon-1.0"] = broker, icons
    ns = Stub.reload()
    eq(ns.MinimapButton.Kind(), "own", "a library that refuses the button: Keepnet makes its own")
    Stub.libs = {}

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
