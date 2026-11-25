-- The whole addon through a fishing session in the stand-in game: pole on, lure, cast, reel in,
-- a miss, combat, a zone change, a break, the screens, pole off.
local T = {}

local KEY = "F"

local function SoundIs(name, value)
    return tonumber(Stub.cvars[name]) == tonumber(value)
end

function T.run(ns)
    local Sessions, OneKey = ns.Sessions, ns.OneKey
    local original = {}
    for name, value in pairs(Stub.cvars) do original[name] = value end
    local function AllRestored(what)
        for name, value in pairs(original) do
            eq(Stub.cvars[name], value, what .. ": " .. name .. " is back to the player's own value")
        end
    end

    -- Three lures (one needs more skill than the character has) and a spare pole
    Stub.bags = { [6529] = 3, [6530] = 2, [6532] = 5, [6365] = 1 }
    Stub.auction = { [13422] = 41800, [13756] = 900, [4500] = 99999, [19807] = 5000 }
    Stub.addons.FishyWashy = true

    -- ---------------------------------------------------------------- login without the pole
    Stub.login()
    eq(ns.fishing, false, "no pole: fishing mode off")
    eq(Stub.binding(KEY), nil, "no pole: the key is not bound")
    eq(ns.db.soundBackup, nil, "no pole: sound untouched")
    check(#Stub.chat == 1 and Stub.chat[1]:find("FishyWashy", 1, true), "warns that FishyWashy is enabled")
    eq(ns.settings.key, "F", "default key")
    eq(KeepnetPanel, nil, "no panel before fishing")

    -- ------------------------------------------------------------------------------ pole on
    Stub.equip(Stub.POLE)
    eq(ns.fishing, true, "pole on: fishing mode on")
    check(SoundIs("Sound_EnableSFX", 1), "sound effects on")
    check(SoundIs("Sound_SFXVolume", 1), "sound effects at full volume")
    check(SoundIs("Sound_MasterVolume", 1), "master volume at the setting")
    check(SoundIs("Sound_EnableMusic", 0) and SoundIs("Sound_MusicVolume", 0), "music off")
    check(SoundIs("Sound_AmbienceVolume", 0) and SoundIs("Sound_DialogVolume", 0), "ambience and dialog off")
    check(SoundIs("Sound_EnableErrorSpeech", 0), "error speech off")
    check(SoundIs("Sound_EnableSoundWhenGameIsInBG", 1), "sound in the background on")
    eq(ns.db.soundBackup.Sound_MasterVolume, "0.6", "the player's master volume is saved")
    eq(ns.db.soundBackup.Sound_EnableSFX, "0", "the player's sound effects switch is saved")
    eq(Stub.binding(KEY).button, "KeepnetCastButton", "the key casts")
    eq(OneKey.State(), "cast", "state: cast")
    check(KeepnetPanel and KeepnetPanel:IsShown(), "the live panel is up")
    -- The zone on the panel carries the skill for guaranteed catches: Tanaris asks for 300,
    -- the character has 187 + 105 = 292, so it shows in the "some get away" colour
    local function PanelHas(text)
        KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
        for _, frame in ipairs(Stub.frames) do
            if frame.__parent == KeepnetPanel and tostring(frame.__text):find(text, 1, true) then return true end
        end
        return false
    end
    check(PanelHas("Tanaris |cffffd100[300]|r"), "the panel shows the zone with its guaranteed-catch skill")
    Stub.skill = { 220, 225, 105 }
    check(PanelHas("Tanaris |cff40ff40[300]|r"), "green once the skill reaches it")
    Stub.skill = { 60, 75, 0 }
    check(PanelHas("Tanaris |cffff6060[300]|r"), "red when the line can't even be cast there")
    eq(KeepnetPanel.skillText:GetText(), "Fishing 60 / 75", "no bonus: the skill bar shows the skill and its cap alone")
    Stub.skill = { 187, 225, 105 }
    Stub.zone, Stub.subzone = "Azshara", "Bay of Storms"
    check(PanelHas("Azshara |cffff6060[425]|r"), "a harder water inside a zone shows its own number")
    eq(KeepnetPanel.skillText:GetText(), "Fishing 187 / 225  |cff40ff40+105 (292)|r",
        "with a bonus: the bonus, and in brackets the skill with it added, in green")
    Stub.zone, Stub.subzone = "Nowhere Special", ""
    check(PanelHas("Nowhere Special") and not PanelHas("["), "an unknown zone shows no number")
    Stub.zone = "Tanaris"

    -- -------------------------------------------------------------------------------- lure
    local found = ns.Lures.InBags()
    eq(#found, 3, "three lures in the bags; the spare fishing pole is not a lure")
    eq(found[1].id, 6532, "strongest first")
    eq(found[1].usable, false, "the strongest needs more fishing skill")
    eq(found[2].bonus, 50, "bonus read from the tooltip")
    eq(Stub.press(KEY), "lure", "first press applies a lure")
    eq(Stub.used[1], 6530, "auto picks the strongest lure the character can use (not the red one)")
    eq(Stub.bags[6530], 1, "one lure used")
    eq(Stub.channel, nil, "the lure press did not cast")

    -- -------------------------------------------------------------------------------- cast
    eq(Stub.press(KEY), "cast", "second press casts")
    eq(Stub.channel, "Fishing", "line out")
    eq(Stub.binding(KEY).command, "INTERACTTARGET", "with the line out the key is the interact key")
    eq(Stub.cvars.SoftTargetInteract, "3", "interact key on")
    eq(Stub.cvars.SoftTargetInteractArc, "2", "interact arc widened")
    eq(Stub.cvars.SoftTargetInteractRange, "30", "interact range widened")
    eq(ns.db.interactBackup.SoftTargetInteract, "0", "the player's interact setting is saved")
    local session = Sessions.Current()
    check(session ~= nil, "a session started with the cast")
    eq(session.casts, 1, "one cast")
    eq(session.zone, "Tanaris", "session zone")
    eq(session.char, "Tester-Realm", "session character")

    -- ------------------------------------------------------------------------------ reel in
    Stub.advance(12)
    Stub.nextLoot = { { id = 13422, count = 2 }, { id = 4500, count = 1 } }
    eq(Stub.press(KEY), "reel", "third press reels in")
    eq(Stub.channel, nil, "line in")
    eq(Stub.binding(KEY).button, "KeepnetCastButton", "the key casts again")
    eq(Stub.cvars.SoftTargetInteract, "0", "interact key back to the player's setting")
    eq(Stub.cvars.SoftTargetInteractRange, "10", "interact range back")
    eq(ns.db.interactBackup, nil, "nothing left to put back")
    eq(session.catches, 1, "one catch")
    eq(session.items[13422].count, 2, "two eels")
    eq(session.active, 12, "twelve seconds of fishing")
    -- Eel at the auction price, the grey line at the vendor price despite its auction price
    eq(session.value, 2 * 41800 + 33, "session value")
    eq(session.unpriced, 0, "everything priced")
    -- The live panel lists the catch and has grown by two rows
    local shown = ns.Sessions.CatchList(session)
    eq(#shown, 2, "two items in the catch list")
    eq(shown[1].name, "Stonescale Eel", "the eels first")
    eq(math.floor(shown[1].percent + 0.5), 67, "two of three caught")
    local KIT = 3 * 16 + 8 -- the lure / food / gear section
    eq(KeepnetPanel:GetHeight(), 178 + KIT + 2 * 15 + 8, "the panel grew to fit the list")
    ns.settings.panelCatches = false
    ns.Fire("SETTINGS")
    eq(KeepnetPanel:GetHeight(), 178 + KIT, "list turned off: the panel shrinks to fit")
    ns.settings.panelKit = false
    ns.Fire("SETTINGS")
    eq(KeepnetPanel:GetHeight(), 178, "section turned off too: the panel is its plain size")
    ns.settings.panelCatches, ns.settings.panelKit = true, true
    ns.Fire("SETTINGS")

    -- The sound button: from just the loud splash to the game's own sound and back
    local soundButton = KeepnetPanel.sound
    eq(soundButton.label:GetText(), "Splash only", "the sound button says the fishing sound is on")
    soundButton:GetScript("OnClick")(soundButton)
    eq(ns.settings.sound, false, "one press switches to the game's own sound")
    eq(soundButton.label:GetText(), "Game audio", "the button says so")
    eq(Stub.cvars.Sound_MasterVolume, "0.6", "the player's own volume is back")
    eq(Stub.cvars.Sound_EnableSFX, "0", "and their sound effects switch")
    eq(ns.db.soundBackup, nil, "with nothing left to put back")
    soundButton:GetScript("OnClick")(soundButton)
    eq(ns.settings.sound, true, "another press switches back to the splash")
    check(SoundIs("Sound_EnableSFX", 1) and SoundIs("Sound_MusicVolume", 0), "sound effects loud, music off again")
    eq(ns.db.soundBackup.Sound_MasterVolume, "0.6", "the player's own value saved again")

    -- The section for what is in use: the lure, and the button that turns applying it off
    local kit = KeepnetPanel.kit
    check(kit.lureText:GetText():find("Nightcrawlers", 1, true), "the lure on the pole is named")
    check(kit.lureText:GetText():find("+50", 1, true), "with its bonus")
    eq(kit.lureToggle.lit:IsShown(), true, "the A button is lit: lures are being applied")
    check(kit.foodText:GetText():find("off", 1, true), "food is off")
    check(kit.gearText:GetText():find("nothing to put on", 1, true), "no fishing gear in the bags")
    kit.lureToggle:GetScript("OnClick")(kit.lureToggle)
    eq(ns.settings.lureMode, "off", "the button turns applying lures off")
    eq(kit.lureToggle.lit:IsShown(), false, "and is no longer lit")
    check(kit.lureText:GetText():find("not applied", 1, true), "the line says the key won't apply one")
    kit.lureToggle:GetScript("OnClick")(kit.lureToggle)
    eq(ns.settings.lureMode, "auto", "pressing it again goes back to how lures were applied before")
    Stub.advance(2)
    eq(session.misses, 0, "a catch is not also a miss")

    -- -------------------------------------------------------------------------------- miss
    eq(Stub.press(KEY), "cast", "cast again")
    Stub.advance(20)
    Stub.reel(nil)
    eq(session.misses, 0, "not a miss until the loot has had its second to open")
    Stub.advance(1.1)
    eq(session.misses, 1, "the line came in empty: a miss")
    eq(session.casts, 2, "two casts")

    -- ------------------------------------------------------------------------------ recast
    eq(Stub.press(KEY), "cast", "cast")
    Stub.castFishing() -- thrown again by other means while the line is out
    Stub.advance(2)
    eq(session.casts, 3, "a recast replaces the cast, it doesn't add one")
    eq(session.misses, 1, "a recast is not a miss")

    -- ------------------------------------------------------------- combat with the line out
    Stub.enterCombat()
    eq(Stub.binding(KEY), nil, "combat: the key is given back")
    eq(Stub.cvars.SoftTargetInteract, "0", "combat: interact setting put back before the lock")
    Stub.leaveCombat()
    eq(Stub.binding(KEY).command, "INTERACTTARGET", "after combat, line still out: the key reels in again")
    Stub.nextLoot = { { id = 13756, count = 1 }, { id = 19807, count = 1 }, { id = 7973, count = 3 }, { money = true } }
    eq(Stub.press(KEY), "reel", "reel in after combat")
    eq(session.catches, 2, "two catches")
    -- Bass at auction; the tastyfish binds and has no vendor price, the clam has no price at all
    eq(session.value, 2 * 41800 + 33 + 900, "value with the new catch")
    eq(session.unpriced, 2, "two items without a price, left out of the total")

    -- A session survives /reload: logout puts the settings back, the game forgets everything
    -- but the saved data, and the addon loads again with the pole still on
    local id = session.id
    Stub.fire("PLAYER_LOGOUT")
    AllRestored("logout")
    ns = Stub.reload()
    Sessions, OneKey = ns.Sessions, ns.OneKey
    session = Sessions.Current()
    check(session ~= nil and session.id == id, "the session is still the current one after a reload")
    eq(ns.fishing, true, "after the reload, pole still on: fishing mode on")
    check(SoundIs("Sound_EnableSFX", 1), "after the reload: fishing sound again")
    eq(ns.db.soundBackup.Sound_MasterVolume, "0.6", "after the reload: the saved value is the player's own")
    eq(Stub.binding(KEY).button, "KeepnetCastButton", "after the reload: the key casts")
    eq(Stub.press(KEY), "cast", "cast after the reload")
    eq(Sessions.Current().id, id, "the session carries on after a reload")
    eq(session.casts, 4, "and counts the new cast")
    Stub.nextLoot = { { secret = true } }
    eq(Stub.press(KEY), "reel", "reel in a catch the game hides")
    eq(session.unknown, 1, "the hidden catch is counted as unknown")
    eq(session.catches, 3, "and as a catch")

    -- ------------------------------------------------- act on key up: no cast on the release
    Stub.useKeyDown = false
    eq(Stub.press(KEY), "cast", "key-up mode: a press casts")
    Stub.nextLoot = { { id = 13756, count = 1 } }
    eq(Stub.press(KEY), "reel", "key-up mode: a press reels in")
    eq(Stub.channel, nil, "key-up mode: the release of the reel press does not cast again")
    eq(Stub.press(KEY), "cast", "key-up mode: the next press casts")
    Stub.nextLoot = { { id = 13756, count = 1 } }
    Stub.press(KEY)
    Stub.useKeyDown = true

    -- ------------------------------------------------------------------------ another zone
    Stub.advance(5)
    Stub.zone = "Azshara"
    eq(Stub.press(KEY), "cast", "cast in another zone")
    local second = Sessions.Current()
    check(second.id ~= id, "another zone: a new session")
    eq(second.zone, "Azshara", "the new session's zone")
    eq(Sessions.IsCurrent(session), false, "the first session is finished")
    Stub.nextLoot = { { id = 13756, count = 4 } }
    Stub.press(KEY)
    eq(second.value, 4 * 900, "second session value")

    -- A finished session keeps its value when prices move, unless "today's prices" is on
    local firstValue = session.value
    Stub.auction[13422] = 10
    eq(ns.Core.Value(session), firstValue, "a finished session keeps the value it had")
    ns.settings.todayPrices = true
    check(ns.Core.Value(session) < firstValue, "today's prices re-prices it")
    ns.settings.todayPrices = false
    Stub.auction[13756] = 1000
    Stub.advance(6)
    eq(second.value, 4 * 1000, "the running session follows a new Auctionator price within seconds")

    -- ----------------------------------------------------------------------------- a break
    Stub.advance(31 * 60)
    Stub.zone = "Tanaris"
    Stub.enchantUntil = nil -- the lure ran out long ago
    eq(Stub.press(KEY), "lure", "after the break the lure is applied again first")
    eq(Stub.used[2], 6530, "the last Nightcrawlers")
    eq(Stub.press(KEY), "cast", "then the cast")
    local third = Sessions.Current()
    check(third.id ~= second.id, "a 31 minute break: a new session")
    Stub.nextLoot = { { id = 13756, count = 1 } }
    Stub.press(KEY)

    -- ----------------------------------------------------------------------- a chosen lure
    Stub.advance(2)
    Stub.enchantUntil = nil
    ns.settings.lureMode = "specific"
    ns.Lures.SetSpecific(6529)
    eq(Stub.press(KEY), "lure", "specific lure applied")
    eq(Stub.used[3], 6529, "the chosen lure, not the strongest")
    Stub.enchantUntil = nil
    Stub.bags[6529] = 0
    Stub.fire("BAG_UPDATE_DELAYED")
    local lines = #Stub.chat
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "chosen lure run out: casts without one")
    eq(#Stub.chat, lines + 1, "and says so once")
    Stub.reel(nil)
    Stub.advance(2)
    Stub.press(KEY)
    eq(#Stub.chat, lines + 1, "only once")
    Stub.reel(nil)
    Stub.advance(2)
    ns.settings.lureFallback = true
    Stub.bags[6530] = 1
    Stub.fire("BAG_UPDATE_DELAYED")
    eq(Stub.press(KEY), "lure", "with the fallback ticked the best lure is used instead")
    -- A lure that won't go on must not stop the fishing
    Stub.reel(nil)
    Stub.advance(2)
    Stub.enchantUntil = nil
    Stub.bags[6530] = 2
    Stub.fire("BAG_UPDATE_DELAYED")
    Stub.lureFails = true
    lines = #Stub.chat
    eq(Stub.press(KEY), "lure failed", "the lure doesn't go on")
    eq(Stub.press(KEY), "lure failed", "nor on the second try")
    eq(Stub.press(KEY), "cast", "the third press casts without it")
    eq(#Stub.chat, lines + 1, "and says so")
    Stub.reel(nil)
    Stub.advance(2)
    Stub.lureFails = false
    eq(Stub.press(KEY), "lure", "the next press tries the lure again, and it goes on")
    ns.settings.lureMode = "off"
    Stub.enchantUntil = nil
    Stub.advance(2)
    eq(Stub.press(KEY), "cast", "lures off: just casts")
    Stub.reel(nil)
    Stub.advance(2)

    -- ------------------------------------------------------------------------- a new key
    ns.settings.key = "SHIFT-G"
    ns.Fire("SETTINGS")
    eq(Stub.binding(KEY), nil, "the old key is given back")
    eq(Stub.binding("SHIFT-G").button, "KeepnetCastButton", "the new key casts")
    ns.settings.key = KEY
    ns.Fire("SETTINGS")

    -- ------------------------------------------------------- sound setting off and on again
    ns.settings.sound = false
    ns.Fire("SETTINGS")
    eq(Stub.cvars.Sound_MasterVolume, "0.6", "sound mode off: the player's volume is back")
    eq(ns.db.soundBackup, nil, "sound mode off: nothing left to put back")
    ns.settings.sound = true
    ns.settings.masterVolume = 0.8
    ns.Fire("SETTINGS")
    check(SoundIs("Sound_MasterVolume", 0.8), "sound mode on at the chosen master volume")
    eq(ns.db.soundBackup.Sound_MasterVolume, "0.6", "the saved value is still the player's own")

    -- ----------------------------------------------------------------------- new session
    ns.Core.NewSession()
    eq(Sessions.Current(), nil, "New session: none running until the next cast")
    eq(#Sessions.List(), 3, "three sessions in the history")
    eq(#Sessions.List("Tanaris"), 2, "two of them in Tanaris")

    -- ------------------------------------------------------------------------- the screens
    -- Open every tab, then click, hover and scroll everything that is on screen
    local function Poke()
        local snapshot = {}
        for i, frame in ipairs(Stub.frames) do snapshot[i] = frame end
        for _, frame in ipairs(snapshot) do
            for _, script in ipairs({ "OnEnter", "OnLeave", "OnMouseWheel", "OnClick", "OnDoubleClick" }) do
                local fn = frame.__scripts[script]
                if fn and Stub.visible(frame) and frame.__name ~= "KeepnetCastButton" then
                    local ok, err = pcall(fn, frame, script == "OnMouseWheel" and -1 or "LeftButton", false)
                    if not ok then Stub.errors[#Stub.errors + 1] = script .. ": " .. tostring(err) end
                end
            end
        end
    end
    SlashCmdList.KEEPNET("")
    check(KeepnetWindow and KeepnetWindow:IsShown(), "/kn opens the window")
    for _, tab in ipairs({ "session", "history", "zones", "gear", "alerts", "appearance", "settings" }) do
        ns.UI.Show(tab)
        ns.UI.Refresh()
        Poke()
        ns.UI.Show(tab)
        Poke()
    end
    ns.SessionTab.View(id)
    ns.HistoryTab.ShowZone("Tanaris")
    -- Typing in the history's search box swaps the session list for the zones the fish was
    -- caught in
    local results = ns.Sessions.FindCatches("bass")
    check(#results >= 1 and results[1].name == "Raw Summer Bass", "the session's bass is found by the search")
    for _, frame in ipairs(Stub.frames) do
        local typed = frame.__kind == "EditBox" and frame.__scripts.OnTextChanged
        if typed and Stub.visible(frame) then
            frame:SetText("bass")
            typed(frame, true)
            frame:SetText("")
            typed(frame, true)
        end
    end
    SlashCmdList.KEEPNET("panel")
    SlashCmdList.KEEPNET("panel")
    SlashCmdList.KEEPNET("reset")
    SlashCmdList.KEEPNET("help")
    SlashCmdList.KEEPNET("new")
    Keepnet_OnAddonCompartmentClick()
    -- A panel update, as the game would run it each frame
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
    -- Sample sessions for trying the screens out: shown in place of the player's own, which
    -- are never touched
    local mine, saved = #Sessions.List(), #ns.db.sessions
    SlashCmdList.KEEPNET("demo")
    eq(ns.Demo.IsOn(), true, "/kn demo turns the sample sessions on")
    eq(#Sessions.List(), 9, "nine sample sessions")
    eq(#ns.db.sessions, saved, "the player's saved sessions are untouched")
    check(Sessions.Current() ~= nil, "one of the samples is running, so the live panel has something to show")
    eq(Sessions.Current().zone, Stub.zone, "in the zone the character stands in")
    local real = false
    for _, session in ipairs(Sessions.List()) do
        if session.char ~= ns.Demo.CHARACTER then real = true end
    end
    eq(real, false, "the samples carry a sample name, never the character's own")
    eq(ns.Core.Character(), ns.Demo.CHARACTER, "and a cast made meanwhile carries on the running sample")
    check(#Sessions.FindCatches("stonescale") >= 2, "the samples can be searched")
    check(ns.Core.Value(Sessions.Current()) ~= nil, "and are priced from the player's own auction addon")
    -- Two of the samples had catches opened, so the screens have opened catches to show
    local current = Sessions.Current()
    eq(current.items[7973].opened, 4, "the running sample has four of its six clams opened")
    eq(current.opened[7971].count, 1, "with a pearl out of them")
    local fromOpened, coins = 0, 0
    for _, session in ipairs(Sessions.List()) do
        for _, row in ipairs((ns.Core.Rows(session))) do
            if row.money then coins = coins + row.total
            elseif row.from == "opened" then fromOpened = fromOpened + 1 end
        end
        for id, count in pairs(session.items) do
            check((count.opened or 0) <= count.count, "no sample opens more of a catch than it caught: " .. id)
        end
    end
    eq(fromOpened, 7, "seven rows of things that came out of opened catches")
    eq(coins, 34120, "and the coins of the opened chest")
    for _, tab in ipairs({ "session", "history", "zones" }) do
        ns.UI.Show(tab)
        ns.UI.Refresh()
    end
    KeepnetPanel:GetScript("OnUpdate")(KeepnetPanel, 1.5)
    SlashCmdList.KEEPNET("demo")
    eq(ns.Demo.IsOn(), false, "/kn demo again turns them off")
    eq(#Sessions.List(), mine, "and the player's own sessions are back")

    -- The poking pressed Delete and New session and changed settings; put the key back
    ns.settings.key = KEY
    ns.settings.sound = true
    ns.settings.hideMode = "off"
    ns.Fire("SETTINGS")

    -- ----------------------------------------------------------------------------- pole off
    Stub.equip(nil)
    eq(ns.fishing, false, "pole off: fishing mode off")
    eq(Stub.binding(KEY), nil, "pole off: the key is given back")
    eq(ns.db.soundBackup, nil, "pole off: nothing left to put back")
    AllRestored("pole off")
    check(not KeepnetPanel:IsShown(), "pole off: the live panel is gone")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
