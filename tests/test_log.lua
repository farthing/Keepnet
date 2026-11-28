-- The log: a line for everything Keepnet does, kept in the saved data, shown for copying.
local T = {}

function T.run(ns)
    Stub.login()
    local text, lines = ns.LogText()
    check(lines > 0 and text:find("loaded", 1, true), "loading is logged")
    eq(ns.db.log ~= nil and #ns.db.log, lines, "the lines live in the saved data")

    ns.LogClear()
    ns.Fire("SOMETHING", "a", 2, true, {})
    ns.Fire("TICK")
    ns.Util.Print("hello there")
    text, lines = ns.LogText()
    eq(lines, 2, "a message between files and a printed line are logged; the tick is not")
    check(text:find("event SOMETHING a 2 true <table>", 1, true), "with what was sent along")
    check(text:find("said hello there", 1, true), "and what was printed")

    for i = 1, 1600 do ns.Log("line", i) end
    text, lines = ns.LogText()
    eq(lines, 1500, "only the newest lines are kept")
    check(text:find("line 1600", 1, true) and not text:find("line 50\n", 1, true), "the oldest go first")
    eq(#ns.db.log, 1500, "the saved data holds the same")

    -- What is handed over for sending says which Keepnet, and never who the player is
    ns.Log("session of", ns.Core.Character(), "and", (UnitName("player")), "Player-1234-0ABCDEF9")
    local report = ns.LogReport()
    check(report:find("Keepnet " .. ns.VERSION .. " log", 1, true), "the report starts with the version")
    check(report:find("github.com/farthing/Keepnet/issues", 1, true), "and where to send it")
    check(report:find("session of <character> and <character> <player>", 1, true),
        "the character's name, its key and a player's number are taken out")
    check(not report:find((UnitName("player")), 1, true), "the name is nowhere in it")
    check(ns.LogText():find((UnitName("player")), 1, true), "(the log itself is left as it was)")

    -- The button on the Settings tab opens the text for copying
    ns.UI.Show("settings")
    local button = ns.LogWindow.button
    button:GetScript("OnClick")(button)
    check(KeepnetLogWindow:IsShown(), "Collect logs opens the log window")
    check(ns.LogWindow.box:GetText():find("line 1600", 1, true), "with the lines in a box to copy")
    check(ns.LogWindow.count:GetText():find("%d+ lines"), "and how many there are")
    -- A report never outgrows one GitHub issue: the newest lines that fit
    for i = 1, 1500 do ns.Log(("x"):rep(100), i) end
    local long, sent = ns.LogReport()
    check(#long < 65536 and sent < 1500 and sent > 300, "a long log is cut to what one issue takes")
    check(long:find(" 1500", 1, true) and long:find("the newest " .. sent .. " of 1500 lines", 1, true),
        "the newest lines are the ones kept, and the header says so")
    local how = ns.LogWindow.how:GetText()
    check(how:find("Select all", 1, true) and how:find("Ctrl+C", 1, true) and how:find("Ctrl+V", 1, true)
        and how:find("github.com/farthing/Keepnet/issues", 1, true), "the window says how to send it, step by step")
    check(not how:find("curseforge", 1, true), "one place only: GitHub")
    eq(button.label and button.label:GetText() or button:GetText(), "Report a problem", "the button says why to press it")
    local all = ns.LogWindow.all
    all:GetScript("OnClick")(all)
    check(ns.LogWindow.count:GetText():find("Ctrl+C", 1, true), "Select all says what is left to do")
end

return T
