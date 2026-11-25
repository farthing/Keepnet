-- Keepnet: says so when a catch is a rare one: a sound, a line in the middle of the screen,
-- a line in chat and a highlight on the live panel.
--
-- What counts as rare, any of:
--   - the item is on the list of fishing rarities (Rares.lua): trophy fish, The 1 Ring, Message
--     in a Bottle and the like, which item quality doesn't find since most are ordinary white
--     items. The player ticks which kinds of them to hear about;
--   - the item is of at least a chosen quality (green, blue, purple);
--   - the item is worth at least a chosen amount of gold each.
--
-- The sound is the player's choice too, one for each kind of rare catch: a sound from the game,
-- one of the player's own files, or one that another addon shares through LibSharedMedia.
--
-- The player's own files go in  Interface\AddOns\KeepnetSounds\  (.ogg or .mp3). That folder
-- is outside Keepnet's own, so an update of the addon never deletes them. The game can't list
-- a folder, so each file is named once in the Alerts tab, or the folder carries a Files.lua
-- that names them (tools\install.ps1 writes one). The game only sees a new file after a
-- restart.
local _, ns = ...
local Util, Prices, Rares = ns.Util, ns.Prices, ns.Rares

local Alerts = {}
ns.Alerts = Alerts

local SOUND_FOLDER = "Interface\\AddOns\\KeepnetSounds\\"
local FALLBACK = "kit:8959"

-- Sounds from the game, by sound kit number
Alerts.BUILTIN = {
    { key = "kit:31578", text = "Loot toast" },
    { key = "kit:888", text = "Level up" },
    { key = "kit:8959", text = "Raid warning" },
    { key = "kit:8960", text = "Ready check" },
    { key = "kit:878", text = "Quest complete" },
    { key = "kit:5274", text = "Auction house opens" },
    { key = "kit:120", text = "Coins" },
    { key = "kit:63971", text = "Legendary loot toast" },
    { key = "kit:23404", text = "Quest pop-up" },
    { key = "kit:12867", text = "Alarm clock" },
    { key = "kit:3081", text = "Whisper" },
    { key = "kit:416", text = "Murloc" },
}

-- The kinds of rare catch that each have their own sound
Alerts.KINDS = {
    { key = "list", text = "Fishing rarity" },
    { key = "q2", text = "Green catch" },
    { key = "q3", text = "Blue catch" },
    { key = "q4", text = "Purple catch" },
    { key = "gold", text = "Worth-gold catch" },
}

local function SharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

-- ---------------------------------------------------------------------------------------------
-- The player's own sound files
-- ---------------------------------------------------------------------------------------------
-- A plain file name ending in .ogg or .mp3: no folders, so it can only name a file in the
-- sounds folder. Returns the tidied name, or nil.
function Alerts.ValidFileName(name)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$")
    if name == "" or name:find("[\\/:*?\"<>|]") or name:find("..", 1, true) then return nil end
    local lower = name:lower()
    if not (lower:match("%.ogg$") or lower:match("%.mp3$")) then return nil end
    return name
end

-- Every file known: named by a Files.lua in the sounds folder, or added in the Alerts tab.
-- { { name, listed = true when it comes from Files.lua } }, A to Z
function Alerts.CustomFiles()
    local seen, list = {}, {}
    local function Add(name, listed)
        name = Alerts.ValidFileName(name)
        if name and not seen[name:lower()] then
            seen[name:lower()] = true
            list[#list + 1] = { name = name, listed = listed }
        end
    end
    if type(KeepnetSoundFiles) == "table" then
        for _, name in ipairs(KeepnetSoundFiles) do Add(name, true) end
    end
    for _, name in ipairs(ns.settings.customSounds or {}) do Add(name, false) end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

function Alerts.AddCustom(name)
    name = Alerts.ValidFileName(name)
    if not name then return false end
    for _, file in ipairs(Alerts.CustomFiles()) do
        if file.name:lower() == name:lower() then return true end
    end
    table.insert(ns.settings.customSounds, name)
    ns.Fire("SETTINGS")
    return true
end

function Alerts.RemoveCustom(name)
    local list = ns.settings.customSounds
    for i = #list, 1, -1 do
        if list[i]:lower() == name:lower() then table.remove(list, i) end
    end
    ns.Fire("SETTINGS")
end

-- ---------------------------------------------------------------------------------------------
-- Choosing and playing
-- ---------------------------------------------------------------------------------------------
-- Everything the sound drop-downs offer: { { value = key, text } }
function Alerts.SoundOptions()
    local options = {}
    -- The player's own first: they are what the player came to pick
    for _, file in ipairs(Alerts.CustomFiles()) do
        options[#options + 1] = { value = "file:" .. file.name, text = "Yours: " .. file.name }
    end
    for _, sound in ipairs(Alerts.BUILTIN) do
        options[#options + 1] = { value = sound.key, text = sound.text }
    end
    local media = SharedMedia()
    if media then
        local names = media:List("sound") or {}
        for _, name in ipairs(names) do
            if name ~= "None" then
                options[#options + 1] = { value = "lsm:" .. name, text = "Shared: " .. name }
            end
        end
    end
    return options
end

-- The name a choice is shown by
function Alerts.SoundName(key)
    for _, option in ipairs(Alerts.SoundOptions()) do
        if option.value == key then return option.text end
    end
    local kind, rest = tostring(key):match("^(%a+):(.+)$")
    if kind == "file" then return "Yours: " .. rest .. " (not found)" end
    return tostring(key)
end

-- Plays a choice on the master channel, so it is heard whatever the effects volume is.
-- Returns true when the game says it will play.
function Alerts.Play(key)
    local kind, rest = tostring(key):match("^(%a+):(.+)$")
    local ok, willPlay = false, false
    if kind == "kit" and PlaySound then
        ok, willPlay = pcall(PlaySound, tonumber(rest), "Master")
    elseif kind == "file" and PlaySoundFile then
        local name = Alerts.ValidFileName(rest)
        if name then
            ok, willPlay = pcall(PlaySoundFile, SOUND_FOLDER .. name, "Master")
        end
    elseif kind == "lsm" and PlaySoundFile then
        local media = SharedMedia()
        local path = media and media:Fetch("sound", rest, true)
        if path then
            ok, willPlay = pcall(PlaySoundFile, path, "Master")
        end
    end
    return (ok and willPlay) and true or false
end

-- Why a catch counts as rare, or nil: "list" (a listed fishing rarity of a kind the player
-- wants to hear about), "quality" or "gold"
function Alerts.Reason(item, unitPrice)
    local settings = ns.settings
    local kind = Rares.Kind(item.id)
    if kind and settings.rareList[kind] then
        return "list"
    end
    local quality = settings.rareQuality or 0
    if quality > 0 and item.quality and item.quality >= quality then
        return "quality"
    end
    local gold = settings.rareGold or 0
    if gold > 0 and unitPrice and unitPrice >= gold * 10000 then
        return "gold"
    end
end

-- Which of the player's sound choices a rare catch gets
function Alerts.KindOf(item, reason)
    if reason == "list" then return "list" end
    if reason == "gold" then return "gold" end
    local quality = item.quality or 2
    if quality >= 4 then return "q4" end
    if quality == 3 then return "q3" end
    return "q2"
end

-- Called after every catch, once the session has it and it has been priced
ns.On("CATCH", function(loot, session)
    -- The one to announce: a listed rarity before anything else, then the most valuable
    local best, bestPrice, bestReason
    for _, drop in ipairs(loot or {}) do
        local item = drop.id and session.items[drop.id]
        if item then
            local price = Prices.Unit(item, ns.settings)
            local reason = Alerts.Reason(item, price)
            if reason then
                local better = not best
                    or (reason == "list" and bestReason ~= "list")
                    or ((reason == "list") == (bestReason == "list") and (price or 0) > (bestPrice or 0))
                if better then best, bestPrice, bestReason = item, price, reason end
            end
        end
    end
    if not best then return end
    local name = best.link or best.name or "something"
    local what = bestReason == "list" and (", " .. Rares.Label(Rares.Kind(best.id))) or ""
    local worth = bestPrice and ("  (" .. Util.Money(bestPrice) .. " each)") or ""
    Util.Print("Rare catch: " .. name .. what .. worth)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("Rare catch: " .. (best.name or Util.LinkName(best.link) or "?"), 0.31, 0.76, 0.97)
    end
    if ns.settings.rareSound then
        local choice = ns.settings.rareSounds[Alerts.KindOf(best, bestReason)]
        -- A sound this client doesn't have, or a file that has gone: still make a noise
        if not Alerts.Play(choice) then Alerts.Play(FALLBACK) end
    end
    ns.Fire("RARE", best, bestPrice)
end)
