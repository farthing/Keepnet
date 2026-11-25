-- Keepnet: the fishing sound profile. While fishing mode is on, sound effects (the splash)
-- are at full volume and music, ambience and dialog are off, so the bite is easy to hear.
--
-- The player's own values are written to the saved data BEFORE anything is changed, and put
-- back when fishing mode ends, on logout, and at the next login if the game crashed in between.
--
-- Which settings to change follows Classic Fishing Companion and Fishing Buddy; saving the
-- originals first and applying twice follows Classic Fishing Companion's notes. See CREDITS.md.
--
-- Limit: the splash is an ordinary sound effect. Game settings can't separate it from spells,
-- creatures or other anglers' bobbers.
local _, ns = ...
local Util = ns.Util

local Sound = {}
ns.Sound = Sound

-- In this order: turn sound on before setting volumes
local function Profile()
    return {
        { "Sound_EnableAllSound", "1" },
        { "Sound_EnableSFX", "1" },
        { "Sound_MasterVolume", tostring(ns.settings.masterVolume or 1) },
        { "Sound_SFXVolume", "1" },
        { "Sound_EnableMusic", "0" },
        { "Sound_MusicVolume", "0" },
        { "Sound_EnableAmbience", "0" },
        { "Sound_AmbienceVolume", "0" },
        { "Sound_EnableDialog", "0" },
        { "Sound_DialogVolume", "0" },
        { "Sound_EnableErrorSpeech", "0" },
        { "Sound_EnableEmoteSounds", "0" },
        { "Sound_EnablePetSounds", "0" },
        -- The splash must be heard with another window in front
        { "Sound_EnableSoundWhenGameIsInBG", "1" },
    }
end

function Sound.IsApplied()
    return ns.db.soundBackup ~= nil
end

local function Set(profile)
    for _, entry in ipairs(profile) do
        Util.SetCVar(entry[1], entry[2])
    end
end

function Sound.Restore()
    local backup = ns.db.soundBackup
    if not backup then return end
    -- Volumes first, so nothing is heard at the wrong level while the switches flip back
    for name, value in pairs(backup) do
        if name:find("Volume", 1, true) then Util.SetCVar(name, value) end
    end
    for name, value in pairs(backup) do
        if not name:find("Volume", 1, true) then Util.SetCVar(name, value) end
    end
    ns.db.soundBackup = nil
end

function Sound.Apply()
    if not ns.settings.sound then
        Sound.Restore()
        return
    end
    local profile = Profile()
    local backup = ns.db.soundBackup or {}
    for _, entry in ipairs(profile) do
        local name = entry[1]
        if backup[name] == nil then
            local current = Util.GetCVar(name)
            if current ~= nil then backup[name] = current end
        end
    end
    -- Saved before the first change: a crash from here on can still be undone at next login
    ns.db.soundBackup = backup
    Set(profile)
    -- Turning sound on restarts the sound system, which can drop a value set in the same
    -- frame, so set them once more on the next frame
    C_Timer.After(0, function()
        if ns.fishing and ns.settings.sound and ns.db.soundBackup then
            Set(Profile())
        end
    end)
end

ns.On("MODE", function(on)
    if on then
        Sound.Apply()
    else
        Sound.Restore()
    end
end)

ns.On("SETTINGS", function()
    if ns.fishing then Sound.Apply() end
end)

-- The game writes its settings file on logout: make sure it writes the player's own values
ns.On("LOGOUT", Sound.Restore)
