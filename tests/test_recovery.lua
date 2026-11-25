-- The game crashed while fishing: the game settings are still on the fishing values, and the
-- saved data still holds the player's own. The next login, without the pole, must put them back.
-- Also: logging in with the line state unknown, and with no Auctionator at all.
local T = {}

function T.before()
    -- As the settings file would be after a crash mid-cast
    Stub.cvars.Sound_EnableSFX = "1"
    Stub.cvars.Sound_MasterVolume = "1"
    Stub.cvars.Sound_SFXVolume = "1"
    Stub.cvars.Sound_MusicVolume = "0"
    Stub.cvars.Sound_EnableErrorSpeech = "0"
    Stub.cvars.SoftTargetInteract = "3"
    Stub.cvars.SoftTargetInteractRange = "30"
    KeepnetDB = {
        settings = { key = "SPACE", sessionGap = 45 },
        soundBackup = {
            Sound_EnableSFX = "0", Sound_MasterVolume = "0.6", Sound_SFXVolume = "0.3",
            Sound_MusicVolume = "0.4", Sound_EnableErrorSpeech = "1",
        },
        interactBackup = { SoftTargetInteract = "0", SoftTargetInteractRange = "10" },
    }
    Auctionator = nil
end

function T.run(ns)
    Stub.login()
    eq(ns.fishing, false, "no pole after the crash")
    eq(Stub.cvars.Sound_EnableSFX, "0", "sound effects switch put back")
    eq(Stub.cvars.Sound_MasterVolume, "0.6", "master volume put back")
    eq(Stub.cvars.Sound_SFXVolume, "0.3", "effects volume put back")
    eq(Stub.cvars.Sound_MusicVolume, "0.4", "music volume put back")
    eq(Stub.cvars.Sound_EnableErrorSpeech, "1", "error speech put back")
    eq(Stub.cvars.SoftTargetInteract, "0", "interact key put back")
    eq(Stub.cvars.SoftTargetInteractRange, "10", "interact range put back")
    eq(ns.db.soundBackup, nil, "sound backup cleared")
    eq(ns.db.interactBackup, nil, "interact backup cleared")

    -- Saved settings are kept and missing ones get their defaults
    eq(ns.settings.key, "SPACE", "the saved key is kept")
    eq(ns.settings.sessionGap, 45, "the saved session gap is kept")
    eq(ns.settings.lureMode, "auto", "a missing setting gets its default")
    eq(ns.settings.zoneSplit, true, "another default")

    -- Fishing without Auctionator: vendor prices only, nothing breaks
    Stub.equip(Stub.POLE)
    eq(Stub.binding("SPACE").button, "KeepnetCastButton", "the saved key casts")
    eq(Stub.press("SPACE"), "cast", "no lures in the bags: the first press casts")
    Stub.nextLoot = { { id = 13422, count = 2 } }
    eq(Stub.press("SPACE"), "reel", "reel in")
    local session = ns.Sessions.Current()
    eq(session.value, 2 * 40, "without Auctionator the catch counts at the vendor price")
    ns.UI.Show("session")
    ns.UI.Show("settings")

    -- Logging out in combat can't touch protected settings; they wait in the saved data
    eq(Stub.press("SPACE"), "cast", "cast")
    Stub.lockdown = true
    Stub.fire("PLAYER_LOGOUT")
    eq(Stub.cvars.Sound_MasterVolume, "0.6", "logout in combat: sound is put back (not protected)")
    check(ns.db.interactBackup ~= nil, "logout in combat: the interact settings wait for the next login")
    Stub.lockdown = false

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
