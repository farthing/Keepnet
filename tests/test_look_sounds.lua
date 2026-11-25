-- Looks, colours, accent colour, background opacity and panel size; the sound for each kind of rare
-- catch; the player's own sound files; sounds shared by other addons.
local T = {}

local KEY = "F"
local FOLDER = "Interface\\AddOns\\KeepnetSounds\\"

function T.before()
    -- As a Files.lua in the sounds folder would name them
    KeepnetSoundFiles = { "levelup.ogg", "..\\escape.ogg", "notes.txt" }
end

local function Close(a, b)
    return math.abs(a - b) < 0.001
end

function T.run(ns)
    local W, Alerts = ns.Widgets, ns.Alerts
    Stub.auction = { [13422] = 41800 }
    Stub.login()
    local settings = ns.settings
    settings.lureMode = "off"
    settings.gear = false
    Stub.equip(Stub.POLE)

    -- ------------------------------------------------------------------------- themes
    eq(settings.theme, "keepnet", "the default theme is Keepnet's own")
    eq(W.THEMES[1].name, "Keepnet", "listed first")
    eq(W.THEMES[2].name, "Keepnet rounded", "then the same with round corners")
    eq(W.THEMES[3].name, "Windows 95", "then the grey one")
    eq(W.THEMES[4].name, "Forever", "then the game's own look")

    -- Forever is another look altogether (the game's own windows and buttons): frames of the
    -- flat look are already on screen, so it can't be switched to in place
    eq(W.native, false, "the flat look is in use")
    settings.theme = "forever"
    W.ApplyTheme()
    eq(Stub.popup, "KEEPNET_RELOAD_FOR_THEME", "choosing Forever asks to reload the interface")
    eq(Stub.reloads, 1, "and reloads when the player agrees")
    eq(W.native, false, "until then the look on screen stays as it is")
    check(Close(W.COLORS.accent[1], 0.31), "with its own colours")
    eq(settings.theme, "forever", "the choice itself is kept for after the reload")
    settings.theme = "keepnet"
    W.ApplyTheme()
    eq(Stub.reloads, 1, "going back to a theme of the look on screen needs no reload")

    local accentTable, backgroundTable = W.COLORS.accent, W.COLORS.background
    -- Colours are a choice of their own, and change at once
    W.SetScheme(W.Theme("keepnet"), "ember")
    W.ApplyTheme()
    eq(Stub.reloads, 1, "other colours need no reload")
    check(Close(W.COLORS.accent[1], 1.00) and Close(W.COLORS.accent[2], 0.58), "other colours: their accent")
    check(Close(W.COLORS.background[1], 0.10), "other colours: their background")
    check(W.COLORS.accent == accentTable and W.COLORS.background == backgroundTable,
        "the colour tables are refilled, not replaced, so everything holding them follows")
    check(Close(KeepnetPanel.__backdrop[1], 0.10), "the live panel is repainted at once")
    eq(W.AccentHex(), "ff9338", "the accent as text colour")
    settings.schemes.keepnet = "no such colours"
    W.ApplyTheme()
    check(Close(W.COLORS.accent[1], 0.31), "unknown colours fall back to the look's first")
    settings.theme = "no such theme"
    W.ApplyTheme()
    check(Close(W.COLORS.accent[1], 0.31), "an unknown look falls back to the default")
    -- Each of Keepnet's colours used to be a theme: a saved one becomes the Keepnet look in
    -- those colours
    settings.theme, settings.schemes = "dusk", nil
    W.ApplyTheme()
    eq(settings.theme, "keepnet", "a colour saved as the theme: the look is Keepnet")
    eq(settings.schemes.keepnet, "dusk", "in those colours")
    check(Close(W.COLORS.accent[1], 0.74), "which are shown")
    eq(Stub.reloads, 1, "without a reload")
    settings.schemes = nil
    W.ApplyTheme()

    settings.accentMode = "class"
    W.ApplyTheme()
    check(Close(W.COLORS.accent[1], 0.25) and Close(W.COLORS.accent[3], 0.92), "the class colour as accent")
    Stub.class = "NOSUCHCLASS"
    W.ApplyTheme()
    check(Close(W.COLORS.accent[1], 0.31), "no class colour known: the theme's own")
    Stub.class = "MAGE"
    settings.accentMode = "custom"
    settings.accentColor = { 0.2, 0.4, 0.6 }
    W.ApplyTheme()
    check(Close(W.COLORS.accent[2], 0.4), "a colour of the player's own")

    -- ---------------------------------------------------------------------------- font
    -- Keepnet's own looks are written in Overpass: each of the game's fonts has a copy that
    -- is drawn from that file, and the texts are given the copy
    eq(settings.font, "overpass", "the default font is Overpass")
    local small, heading = KeepnetGameFontHighlightSmall, KeepnetGameFontNormal
    check(small ~= nil and heading ~= nil, "the game's fonts have copies of Keepnet's own")
    eq(KeepnetPanel.casts.__fontObject, small, "a text is given the copy")
    check(tostring(small.__font[1]):find("Media\\Overpass-Regular.ttf", 1, true), "drawn from the Overpass file")
    eq(small.__font[2], 10, "at the size the game's font has")
    check(tostring(heading.__font[1]):find("Media\\Overpass-SemiBold.ttf", 1, true), "a heading from the heavier one")
    eq(GameFontHighlightSmall.__font[1], "Fonts\\FRIZQT__.TTF", "the game's own font is not touched")
    eq(W.FontObject("NumberFontNormalSmall"), nil, "the small numbers on item pictures stay the game's")
    settings.font = "game"
    W.ApplyTheme()
    eq(small.__font[1], "Fonts\\FRIZQT__.TTF", "the game's own font chosen: every text follows at once")
    eq(heading.__font[1], "Fonts\\FRIZQT__.TTF", "headings too")
    settings.font = "overpass"
    W.ApplyTheme()
    check(tostring(small.__font[1]):find("Overpass", 1, true), "and back")
    -- A language the file has no letters for keeps the game's font
    Stub.locale = "koKR"
    W.ApplyTheme()
    eq(small.__font[1], "Fonts\\FRIZQT__.TTF", "Korean: the game's own font")
    Stub.locale = "ruRU"
    W.ApplyTheme()
    check(tostring(small.__font[1]):find("Overpass", 1, true), "Russian: Overpass has the letters")
    Stub.locale = nil
    settings.font = "no such font"
    W.ApplyTheme()
    check(tostring(small.__font[1]):find("Overpass", 1, true), "an unknown font is the default")
    settings.font = "overpass"

    -- Fonts other addons on this computer share are offered too
    eq(#W.FontChoices(), 2, "with nobody sharing fonts: Keepnet's two")
    Stub.sharedFonts = { ["Zebra Sans"] = "Interface\\AddOns\\Pack\\zebra.ttf", ["apple Serif"] = "Interface\\AddOns\\Pack\\apple.ttf" }
    local choices = W.FontChoices()
    eq(#choices, 4, "two shared fonts are added")
    eq(choices[1].name, "Overpass", "Keepnet's own first")
    eq(choices[2].name, "The game's own", "then the game's")
    eq(choices[3].name, "apple Serif", "then the shared ones, A to Z whatever their capitals")
    eq(choices[4].key, "shared:Zebra Sans", "each saved under the name it is shared by")
    settings.font = "shared:Zebra Sans"
    W.ApplyTheme()
    eq(small.__font[1], "Interface\\AddOns\\Pack\\zebra.ttf", "a shared font chosen: drawn from that addon's file")
    eq(heading.__font[1], "Interface\\AddOns\\Pack\\zebra.ttf", "headings from the same file")
    eq(small.__font[2], 10, "at the game font's size")
    eq(W.FontChoice(settings.font).name, "Zebra Sans", "and shown under its name")
    -- The addon that shared it is removed: the default takes its place, the choice is kept
    Stub.sharedFonts = { ["apple Serif"] = "Interface\\AddOns\\Pack\\apple.ttf" }
    W.ApplyTheme()
    check(tostring(small.__font[1]):find("Overpass", 1, true), "a shared font that is gone: the default")
    eq(W.FontChoice(settings.font).name, "Overpass", "which is what the list shows")
    eq(settings.font, "shared:Zebra Sans", "the choice itself is kept, for when it is back")
    -- An addon that loads after Keepnet shares it: taken up at once
    check(Stub.mediaCallback ~= nil, "Keepnet asks to hear of newly shared media")
    Stub.sharedFonts["Zebra Sans"] = "Interface\\AddOns\\Pack\\zebra.ttf"
    Stub.mediaCallback("LibSharedMedia_Registered", "font", "Some Other")
    check(tostring(small.__font[1]):find("Overpass", 1, true), "another font being shared changes nothing")
    Stub.mediaCallback("LibSharedMedia_Registered", "font", "Zebra Sans")
    eq(small.__font[1], "Interface\\AddOns\\Pack\\zebra.ttf", "the chosen one being shared is taken up")
    Stub.sharedFonts, Stub.mediaCallback = nil, nil
    settings.font = "overpass"
    W.ApplyTheme()

    -- The colour picker: dragging applies, Cancel puts the old colour back
    local seen
    W.PickColor(0.2, 0.4, 0.6, function(r, g, b) seen = { r, g, b } end)
    ColorPickerFrame.picked = { 0.9, 0.1, 0.1 }
    ColorPickerFrame.info.swatchFunc()
    check(seen and Close(seen[1], 0.9), "picking a colour hands it over")
    ColorPickerFrame.info.cancelFunc()
    check(Close(seen[1], 0.2), "Cancel hands the old colour back")

    -- ---------------------------------------------------------------- opacity and size
    settings.panelOpacity = 0.5
    settings.windowOpacity = 0.7
    settings.panelScale = 1.25
    W.ApplyTheme()
    ns.Fire("SETTINGS")
    check(Close(KeepnetPanel.__backdrop[4], 0.5), "the live panel's background at the chosen opacity")
    eq(KeepnetPanel.__scale, 1.25, "the live panel at the chosen size")
    ns.UI.Show("appearance")
    check(Close(KeepnetWindow.__backdrop[4], 0.7), "the window's background at its own opacity")
    settings.panelOpacity = 0
    W.ApplyTheme()
    eq(KeepnetPanel.__backdrop[4], 0, "the panel can be fully see-through")
    ns.UI.Show("alerts")
    ns.UI.Show("appearance")

    -- ------------------------------------------------------------------- file names
    eq(Alerts.ValidFileName("yatta.ogg"), "yatta.ogg", "a plain .ogg name")
    eq(Alerts.ValidFileName("  Level Up (2).MP3 "), "Level Up (2).MP3", "spaces round it are dropped; .mp3 is fine")
    eq(Alerts.ValidFileName("yatta.wav"), nil, "only .ogg and .mp3")
    eq(Alerts.ValidFileName("..\\secret.ogg"), nil, "no way out of the sounds folder")
    eq(Alerts.ValidFileName("sub/dir.ogg"), nil, "no folders")
    eq(Alerts.ValidFileName(""), nil, "not empty")
    eq(Alerts.ValidFileName(nil), nil, "not nothing")

    local files = Alerts.CustomFiles()
    eq(#files, 1, "of the folder's own list only the proper sound file name is taken")
    eq(files[1].name, "levelup.ogg", "its name")
    eq(files[1].listed, true, "marked as coming from the folder's list")
    eq(Alerts.AddCustom("yatta.ogg"), true, "adding a file by name")
    eq(Alerts.AddCustom("YATTA.OGG"), true, "adding it again is fine")
    eq(#settings.customSounds, 1, "and doesn't list it twice")
    eq(Alerts.AddCustom("yatta"), false, "a name without an ending is refused")
    eq(#Alerts.CustomFiles(), 2, "two files known")

    local function Has(key)
        for _, option in ipairs(Alerts.SoundOptions()) do
            if option.value == key then return option.text end
        end
    end
    eq(Has("kit:888"), "Level up", "the game's sounds are offered")
    local offered = Alerts.SoundOptions()
    eq(offered[1].value, "file:levelup.ogg", "the player's own sounds come first in the list")
    eq(offered[2].value, "file:yatta.ogg", "all of them")
    eq(offered[3].value, "kit:31578", "then the game's")
    eq(#offered, 2 + #Alerts.BUILTIN, "the two files and every game sound, nothing else")
    eq(Has("file:yatta.ogg"), "Yours: yatta.ogg", "and the player's own")
    eq(Has("file:levelup.ogg"), "Yours: levelup.ogg", "and the ones the folder lists")
    eq(Has("lsm:Bell"), nil, "no shared sounds without LibSharedMedia")
    Stub.sharedMedia = { Bell = "Interface\\AddOns\\Other\\bell.ogg", None = "none" }
    eq(Has("lsm:Bell"), "Shared: Bell", "another addon's shared sounds are offered")
    eq(Has("lsm:None"), nil, "but not the empty one")

    -- ----------------------------------------------------------------------- playing
    eq(Alerts.Play("kit:888"), true, "a game sound plays")
    eq(Stub.sounds[#Stub.sounds].channel, "Master", "on the master channel")
    Stub.missingKits[31578] = true
    eq(Alerts.Play("kit:31578"), false, "a sound this client lacks reports that")
    eq(Alerts.Play("file:yatta.ogg"), false, "a file that isn't there reports that")
    Stub.files[FOLDER .. "yatta.ogg"] = true
    eq(Alerts.Play("file:yatta.ogg"), true, "once the file is there it plays")
    eq(Stub.soundFiles[#Stub.soundFiles].path, FOLDER .. "yatta.ogg", "from the sounds folder")
    eq(Alerts.Play("file:..\\x.ogg"), false, "never from anywhere else")
    Stub.files["Interface\\AddOns\\Other\\bell.ogg"] = true
    eq(Alerts.Play("lsm:Bell"), true, "a shared sound plays")
    eq(Alerts.Play("nonsense"), false, "nonsense doesn't")

    -- --------------------------------------------------- a sound for each kind of catch
    settings.rareSounds.q2 = "file:yatta.ogg"
    settings.rareSounds.q3 = "kit:888"
    settings.rareSounds.q4 = "file:gone.ogg"
    settings.rareSounds.gold = "lsm:Bell"
    local function Catch(id)
        Stub.advance(2)
        Stub.press(KEY)
        Stub.nextLoot = { { id = id, count = 1 } }
        Stub.press(KEY)
    end
    local kits, played = #Stub.sounds, #Stub.soundFiles
    Catch(2000) -- green
    eq(Stub.soundFiles[#Stub.soundFiles].path, FOLDER .. "yatta.ogg", "a green catch plays the green sound")
    eq(#Stub.soundFiles, played + 1, "once")
    Catch(19972) -- blue
    eq(Stub.sounds[#Stub.sounds].kit, 888, "a blue catch plays the blue sound")
    Catch(99001) -- purple, set to a file that has gone
    eq(Stub.sounds[#Stub.sounds].kit, 8959, "a sound that can't play falls back to the raid warning")
    settings.rareQuality = 0
    settings.rareGold = 3
    Catch(13422) -- white, worth over 3 gold
    eq(Stub.soundFiles[#Stub.soundFiles].path, "Interface\\AddOns\\Other\\bell.ogg", "a worth-gold catch plays its own sound")
    -- ------------------------------------------------------- the list of fishing rarities
    local Rares = ns.Rares
    eq(Rares.Kind(6292), "trophy", "a trophy fish is on the list")
    eq(Rares.Kind(8350), "gear", "The 1 Ring is on the list")
    eq(Rares.Kind(6307), "quest", "Message in a Bottle is on the list")
    eq(Rares.Kind(6355), "chest", "a locked chest is on the list")
    eq(Rares.Kind(21113), "trunk", "a trunk is listed as a trunk")
    eq(Rares.Kind(286266), "coin", "a named coin is on the list")
    eq(Rares.Kind(21243), "bloated", "so are the bloated fish new to this client")
    eq(Rares.Kind(13422), nil, "an ordinary fish is not")
    eq(Rares.Kind(19807), nil, "nor the common tournament fish")
    check(Rares.Count() > 110, "the list holds every trophy fish, the coins and more")
    eq(settings.rareList.trophy, true, "trophy fish are announced unless turned off")
    eq(settings.rareList.chest, true, "so are the open-water chests")
    eq(settings.rareList.trunk, false, "trunks are not, unless turned on")

    settings.rareQuality, settings.rareGold = 0, 0 -- only the list is left to trigger an alert
    settings.rareSounds.list = "kit:8960"
    local said = #Stub.chat
    Catch(6292) -- a white trophy fish: quality alone would never find it
    check(Stub.chat[#Stub.chat]:find("trophy fish", 1, true), "a trophy fish is announced, and called one")
    eq(Stub.sounds[#Stub.sounds].kit, 8960, "with the sound chosen for fishing rarities")
    Catch(6307)
    check(Stub.chat[#Stub.chat]:find("quest catch", 1, true), "Message in a Bottle is announced")
    Catch(286266)
    check(Stub.chat[#Stub.chat]:find("named coin", 1, true), "a grey named coin is announced: quality would never find it")
    said = #Stub.chat
    Catch(21113)
    eq(#Stub.chat, said, "a trunk is quiet while that kind is off")
    settings.rareList.trunk = true
    Catch(21113)
    eq(#Stub.chat, said + 1, "and announced once it is on")
    settings.rareList.trophy = false
    said = #Stub.chat
    Catch(6292)
    eq(#Stub.chat, said, "a kind turned off is quiet")
    settings.rareList.trophy = true
    -- A listed rarity is the one announced even beside something worth more
    settings.rareGold = 3
    Stub.advance(2)
    Stub.press(KEY)
    Stub.nextLoot = { { id = 13422, count = 1 }, { id = 6292, count = 1 } }
    Stub.press(KEY)
    check(Stub.chat[#Stub.chat]:find("Mud Snapper", 1, true), "the listed rarity is the one announced, not the pricier fish beside it")
    eq(Stub.sounds[#Stub.sounds].kit, 8960, "with the rarity's sound")
    settings.rareGold = 3
    settings.rareQuality = 0

    settings.rareSound = false
    local before = #Stub.soundFiles
    Catch(13422)
    eq(#Stub.soundFiles, before, "sounds off: silent")
    check(#Stub.sounds >= kits, "(game sounds were counted)")

    Alerts.RemoveCustom("yatta.ogg")
    eq(#settings.customSounds, 0, "a file can be taken off the list again")
    eq(Alerts.SoundName("file:yatta.ogg"), "Yours: yatta.ogg (not found)", "a choice whose file is gone says so")

    -- Saved settings from before 0.3.0 get the new defaults
    eq(settings.rareSounds.gold, "lsm:Bell", "(the choice made above is kept)")
    ns = Stub.reload()
    eq(ns.settings.rareSounds.q2, "file:yatta.ogg", "sound choices survive a reload")
    check(Close(ns.Widgets.COLORS.accent[2], 0.4), "the accent survives a reload")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
