-- The strip that hangs under the live panel while a line is out: a bar that runs down with
-- the seconds the line has left, and under it what the last cast brought up. By default only
-- while Keepnet has the game's interface hidden.
local T = {}

local KEY = "F"
local EEL = 13422

function T.run(ns)
    Stub.bags = {}
    Stub.login()
    local settings = ns.settings
    settings.lureMode, settings.gear = "off", false
    Stub.equip(Stub.POLE)
    local panel = KeepnetPanel
    local strip = panel.strip
    check(strip ~= nil, "the live panel has a strip under it")
    eq(settings.lineStrip, "hidden", "by default it is for when the interface is hidden")
    check(not strip:IsShown(), "nothing shows with no line out")

    -- With the interface in sight the game's own cast bar and loot window do the job
    Stub.lineSeconds = 20
    eq(Stub.press(KEY), "cast", "the line goes out")
    check(not strip:IsShown(), "the interface is in sight: no strip")

    -- Asked for always: the line's time shows, and runs down
    settings.lineStrip = "always"
    ns.Fire("SETTINGS")
    panel:GetScript("OnUpdate")(panel, 1.5)
    check(strip:IsShown(), "asked for always: the strip shows while the line is out")
    eq(strip.text:GetText(), "Line out: 20 s", "it says how long the line has left")
    local full = strip.fill.__width
    check(strip.fill:IsShown() and full > 200, "with a full bar")
    Stub.advance(5)
    strip:GetScript("OnUpdate")(strip, 0.1)
    eq(strip.text:GetText(), "Line out: 15 s", "five seconds on: fifteen left")
    check(math.abs(strip.fill.__width - full * 0.75) < 1, "and three quarters of the bar")
    Stub.advance(4.5)
    strip:GetScript("OnUpdate")(strip, 0.1)
    eq(strip.text:GetText(), "Line out: 11 s", "the seconds are those still to come, rounded up")
    check(not strip.rows[1].name:IsShown(), "nothing has come up yet")

    -- A catch: what came up is listed under the bar for a few seconds
    Stub.reel({ { id = EEL, count = 2 } })
    check(strip:IsShown(), "the line is in: the strip stays for what came up")
    check(strip.rows[1].name:IsShown(), "which is listed")
    check(tostring(strip.rows[1].name:GetText()):find("Stonescale Eel", 1, true), "by name")
    check(tostring(strip.rows[1].name:GetText()):find("x2", 1, true), "and how many")
    check(not strip.rows[2].name:IsShown(), "one line for one kind of catch")
    eq(strip.text:GetText(), "|cff9d9d9dLine in|r", "the bar says the line is in")
    check(not strip.fill:IsShown(), "and is empty")
    check(strip.__height > 40, "the strip is taller for the list")
    -- The next cast: the list stays its few seconds beside the new line's time
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "the next cast")
    strip:GetScript("OnUpdate")(strip, 0.1)
    eq(strip.text:GetText(), "Line out: 20 s", "the new line's time")
    check(strip.rows[1].name:IsShown(), "what the last cast brought up is still there")
    Stub.advance(7)
    strip:GetScript("OnUpdate")(strip, 0.1)
    check(not strip.rows[1].name:IsShown(), "and gone after its eight seconds")
    check(strip:IsShown(), "the strip itself stays: a line is out")
    eq(strip.__height, 27, "back to the bar alone")

    -- Nothing on the hook
    Stub.reel(nil)
    Stub.advance(1.1) -- the moment a late catch would have had
    check(strip:IsShown() and tostring(strip.rows[1].name:GetText()):find("Nothing on the line", 1, true), "an empty hook says so")
    Stub.advance(3.5)
    strip:GetScript("OnUpdate")(strip, 0.1)
    check(not strip:IsShown(), "and with no line out and nothing to say the strip goes")

    -- More kinds than there is room for
    eq(Stub.press(KEY), "cast", "another cast")
    Stub.reel({ { id = EEL, count = 1 }, { id = 13756, count = 1 }, { id = 6303, count = 3 }, { id = 4500, count = 1 }, { id = 7973, count = 1 } })
    local last = tostring(strip.rows[4].name:GetText())
    check(strip.rows[4].name:IsShown() and last:find("and 2 more", 1, true), "five kinds: three, then how many more")
    Stub.advance(9)
    strip:GetScript("OnUpdate")(strip, 0.1)

    -- The game keeps the line's times to itself: the strip counts up instead
    Stub.channelTimesHidden = true
    eq(Stub.press(KEY), "cast", "a cast whose times the game won't give")
    Stub.advance(6)
    strip:GetScript("OnUpdate")(strip, 0.1)
    eq(strip.text:GetText(), "Line out for 6 s", "it counts up instead")
    Stub.channelTimesHidden = nil
    Stub.reel({ { id = EEL, count = 1 } })
    Stub.advance(9)
    strip:GetScript("OnUpdate")(strip, 0.1)
    check(not strip:IsShown(), "gone again")

    -- The default: only while Keepnet has the interface hidden
    settings.lineStrip = "hidden"
    settings.hideMode, settings.hideAuto = "all", true
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast that hides the interface")
    eq(ns.HideUI.IsActive(), true, "the interface is hidden")
    check(strip:IsShown(), "so the strip shows")
    eq(strip.text:GetText(), "Line out: 20 s", "with the line's time")
    Stub.reel({ { id = EEL, count = 1 } })
    check(tostring(strip.rows[1].name:GetText()):find("Stonescale Eel", 1, true), "and what came up")
    ns.HideUI.Show()
    panel:GetScript("OnUpdate")(panel, 1.5)
    check(not strip:IsShown(), "the interface is back: the strip goes")

    -- Switched off
    settings.lineStrip = "off"
    settings.hideMode = "off"
    ns.Fire("SETTINGS")
    eq(Stub.press(KEY), "cast", "a cast with the strip switched off")
    panel:GetScript("OnUpdate")(panel, 1.5)
    check(not strip:IsShown(), "never shows")
    Stub.reel({ { id = EEL, count = 1 } })
    check(not strip:IsShown(), "not for a catch either")

    -- The Settings tab offers the three choices
    ns.UI.Show("settings")
    ns.UI.Refresh()

    Stub.equip(nil)
    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
