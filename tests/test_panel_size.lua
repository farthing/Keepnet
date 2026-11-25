-- The live panel's catch list scrolls once it is longer than its room, and the panel's bottom
-- right corner sizes the panel: sideways for its width, up and down for how many catches show
-- before the list scrolls.
local T = {}

local KEY = "F"
local EEL = 13422
local PLAIN = 178          -- the panel without the catch list
local KIT = 3 * 16 + 8     -- the lure / food / gear section
local ROW = 15

function T.run(ns)
    Stub.bags = {}
    Stub.login()
    Stub.equip(Stub.POLE)
    local panel = KeepnetPanel
    local grip = panel.grip

    -- A session, then as many different catches in it as a test asks for: "Fish A" caught
    -- most, "Fish B" next, and so on
    eq(Stub.press(KEY), "cast", "the line goes out")
    Stub.advance(12)
    Stub.reel({ { EEL, 1 } })
    local session = ns.Sessions.Current()
    local function Caught(howMany)
        session.items, session.unknown = {}, 0
        for i = 1, howMany do
            session.items[100 + i] = { id = 100 + i, count = 60 - i, name = "Fish " .. string.char(64 + i) }
        end
        ns.Fire("SESSION")
    end
    -- The letters of the fish on show, top to bottom
    local function Shown()
        local letters = {}
        for _, row in ipairs(panel.rows) do
            if row.name:IsShown() then
                letters[#letters + 1] = tostring(row.name:GetText()):match("Fish (%a)") or "?"
            end
        end
        return table.concat(letters)
    end
    local function Height(rows)
        return PLAIN + KIT + (rows > 0 and (rows * ROW + 8) or 0)
    end
    local function Wheel(delta)
        panel:GetScript("OnMouseWheel")(panel, delta)
    end
    -- The mouse on the corner: press, move, let go
    local function Press(x, y)
        Stub.cursor = { x, y }
        Stub.mouseDown = true
        grip:GetScript("OnMouseDown")(grip, "LeftButton")
    end
    local function Move(x, y)
        Stub.cursor = { x, y }
        grip:GetScript("OnUpdate")(grip, 0.02)
    end
    local function Release()
        Stub.mouseDown = false
        grip:GetScript("OnMouseUp")(grip, "LeftButton")
    end

    -- ------------------------------------------------------------------ a list that fits
    Caught(5)
    eq(Shown(), "ABCDE", "five catches: all five listed")
    eq(panel:GetHeight(), Height(5), "and the panel is as tall as they need")
    eq(panel.__wheel, false, "nothing to scroll: the mouse wheel is left to the game")
    eq(panel.scrollThumb:IsShown(), false, "and there is no scroll mark")
    eq(panel:GetWidth(), 260, "the panel starts at its own width")
    eq(grip:IsShown(), true, "the corner for sizing is there")

    -- ------------------------------------------------------------------ a list that doesn't
    Caught(11)
    eq(Shown(), "ABCDEFGH", "eleven catches: the first eight, each a row of its own (no row adding up the rest)")
    eq(panel:GetHeight(), Height(8), "the panel stops growing at eight rows")
    eq(panel.__wheel, true, "the mouse wheel scrolls the list now")
    eq(panel.scrollThumb:IsShown(), true, "and the scroll mark shows")
    Wheel(-1)
    eq(Shown(), "CDEFGHIJ", "wheel down: further down the list")
    Wheel(-1)
    eq(Shown(), "DEFGHIJK", "again: the end of the list, and no further")
    Wheel(-1)
    eq(Shown(), "DEFGHIJK", "the end stays the end")
    eq(panel:GetHeight(), Height(8), "scrolling doesn't change the panel's size")
    Wheel(1)
    Wheel(1)
    Wheel(1)
    eq(Shown(), "ABCDEFGH", "wheel up: back to the top, and no further")
    -- Scrolled down, then the list gets shorter: it can't be left pointing past its end
    Wheel(-1)
    Wheel(-1)
    Caught(9)
    eq(Shown(), "BCDEFGHI", "a shorter list is pulled back so its room stays full")
    Caught(6)
    eq(Shown(), "ABCDEF", "and one that fits again shows whole")
    eq(panel.__wheel, false, "with the wheel given back")

    -- ------------------------------------------------------- the corner, dragged up and down
    Caught(11)
    Press(1000, 500)
    eq(panel:GetHeight(), Height(8), "pressing the corner changes nothing by itself")
    eq(ns.db.panelSize, nil, "and saves nothing")
    Move(1000, 500 - 3 * ROW)
    eq(Shown(), "ABCDEFGHIJK", "dragged three rows down: all eleven show")
    eq(panel:GetHeight(), Height(11), "in a panel three rows taller")
    eq(panel.__wheel, false, "with nothing left to scroll")
    eq(ns.db.panelSize.rows, 11, "the number of rows is saved")
    check(tostring(panel.buffs:GetText()):find("Up to 11 catches", 1, true), "and the panel says what was chosen")
    -- Further than there are catches: the room being chosen shows while the corner is held
    Move(1000, 500 - 10 * ROW)
    eq(ns.db.panelSize.rows, 18, "ten rows down: room for eighteen")
    eq(panel:GetHeight(), Height(18), "the corner stays under the mouse while it is held")
    Release()
    eq(panel:GetHeight(), Height(11), "let go: the panel takes the room of the catches there are")
    eq(ns.db.panelSize.rows, 18, "and keeps the room for more")
    Caught(20)
    eq(#Shown(), 18, "more catches: the list grows to the chosen eighteen rows")
    eq(panel.__wheel, true, "and scrolls from there")
    -- Dragged up: fewer rows, never fewer than three
    Press(1000, 500)
    Move(1000, 500 + 5 * ROW)
    eq(Shown(), "ABCDEFGHIJKLM", "five rows up: thirteen of the twenty")
    Move(1000, 5000)
    eq(Shown(), "ABC", "as far up as it goes: three rows")
    Move(1000, -5000)
    eq(ns.db.panelSize.rows, 30, "as far down as it goes: thirty rows")
    Move(1000, 500 + 15 * ROW)
    Release()
    eq(Shown(), "ABC", "left at three rows")
    Wheel(-1)
    eq(Shown(), "BCD", "a short list scrolls a row at a time")
    Wheel(1)

    -- -------------------------------------------------------------- the corner, sideways
    Press(1000, 500)
    Move(1100, 500 - 4)
    eq(panel:GetWidth(), 360, "dragged a hundred to the right: a hundred wider")
    eq(ns.db.panelSize.width, 360, "the width is saved")
    eq(ns.db.panelSize.rows, 3, "a drag sideways leaves the rows as they were")
    eq(panel.rows[1].name:GetWidth(), 360 - 20 - ROW - 78, "the names get the new room")
    eq(panel.skillBar:GetWidth(), 340, "the skill bar follows")
    eq(panel.kit.foodRow:GetWidth(), 344, "so do the lines for what is in use")
    eq(panel.kit.lureRow:GetWidth(), 360 - 16 - 18 - 4, "the lure line leaving room for its A button")
    eq(panel.new:GetWidth(), (340 - 6) / 2, "and the buttons along the bottom")
    Move(5000, 500)
    eq(panel:GetWidth(), 480, "no wider than its widest")
    Move(-5000, 500)
    eq(panel:GetWidth(), 260, "no narrower than it started")
    Move(1100, 500)
    Release()
    eq(panel:GetWidth(), 360, "let go at a hundred wider")
    -- The lists that open from the panel are as wide as the panel
    local row = panel.kit.foodRow
    row:GetScript("OnClick")(row)
    eq(panel.menu:IsOpen(), true, "a list opens from the wider panel")
    eq(panel.menu:GetWidth(), 344, "as wide as the line it opens from")
    panel.menu:Close()

    -- The panel shown larger or smaller (the size setting): the mouse's way is measured in the
    -- panel's own measure
    panel.GetEffectiveScale = function() return 2 end
    Press(1000, 500)
    Move(1100, 500)
    eq(panel:GetWidth(), 410, "at twice the size a hundred on the screen is fifty on the panel")
    Move(1000, 500)
    Release()
    panel.GetEffectiveScale = nil
    eq(panel:GetWidth(), 360, "(put back)")

    -- The button let go somewhere the corner never hears of it: the drag still ends
    Press(1000, 500)
    Move(1020, 500)
    eq(panel:GetWidth(), 380, "dragging")
    Stub.mouseDown = false
    Move(1200, 500)
    eq(panel:GetWidth(), 380, "the button is up: the mouse no longer sizes the panel")
    Move(1300, 500)
    eq(panel:GetWidth(), 380, "nor afterwards")

    -- ------------------------------------------------------------ what the corner leaves alone
    -- The catch list turned off: up and down means nothing
    ns.settings.panelCatches = false
    ns.Fire("SETTINGS")
    eq(panel:GetHeight(), PLAIN + KIT, "the list turned off: no room for it")
    Press(1000, 500)
    Move(1000, 500 - 6 * ROW)
    eq(ns.db.panelSize.rows, 3, "dragging down changes no rows")
    eq(panel:GetHeight(), PLAIN + KIT, "and makes no room")
    Release()
    ns.settings.panelCatches = true
    ns.Fire("SETTINGS")
    eq(Shown(), "ABC", "the list back on: as it was")

    -- A locked panel isn't sized either
    ns.settings.panelLocked = true
    ns.Fire("SETTINGS")
    eq(grip:IsShown(), false, "locked in place: the corner is gone")
    Press(1000, 500)
    Move(1100, 400)
    eq(panel:GetWidth(), 380, "and pressing where it was does nothing")
    Release()
    ns.settings.panelLocked = false
    ns.Fire("SETTINGS")
    eq(grip:IsShown(), true, "unlocked: the corner is back")

    -- ----------------------------------------------------------------- kept, and put back
    ns = Stub.reload()
    Stub.equip(Stub.POLE)
    panel = KeepnetPanel
    grip = panel.grip
    session = ns.Sessions.Current()
    eq(panel:GetWidth(), 380, "after a /reload the panel is as wide as it was left")
    Caught(20)
    eq(Shown(), "ABC", "and lists as many catches as it was left with")

    ns.LivePanel.ResetPosition()
    eq(ns.db.panelSize, nil, "/kn reset: the size is forgotten")
    eq(panel:GetWidth(), 260, "the panel is its own width again")
    eq(Shown(), "ABCDEFGH", "and lists eight catches before it scrolls")
    eq(panel.new:GetWidth(), (240 - 6) / 2, "the buttons fit it again")

    -- A size the saved data can't mean is brought into range
    ns.db.panelSize = { width = 9000, rows = "many" }
    ns.LivePanel.ResetPosition()
    ns.db.panelSize = { width = 9000, rows = 0 }
    ns.Fire("SETTINGS")
    eq(#Shown(), 3, "a saved size out of range: the nearest that is allowed")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
