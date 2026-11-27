-- Keepnet: the game's soft-target settings, shared by the parts of Keepnet that need them while
-- the line is out. The fishing key (OneKey.lua) needs the interact target, so the key reels in
-- without the mouse; the bobber mark (BobberMark.lua) needs that too, plus the settings that
-- give the bobber a nameplate.
--
-- Each part says what it wants with SoftTarget.Want(who, list) and lets go with
-- SoftTarget.Release(who). A setting is only ever raised (never lowered below the player's own
-- value), the player's value is saved before the first change (in KeepnetDB, so a crash is
-- undone at the next login), and it goes back once nothing in Keepnet wants it any more.
--
-- The interact settings are protected: they can't be changed in combat (combat start still
-- allows it for an instant, which is when the callers let go). The icon and nameplate settings
-- are not protected. The pattern (back up the player's value before the first change, put back
-- only once nothing needs it) was there before for the key alone; it moved here for 1.1.6.
local _, ns = ...
local Util = ns.Util

local SoftTarget = {}
ns.SoftTarget = SoftTarget

-- who -> { { name, the least it must be, what to set }, ... }
local wants = {}

local function Wanted()
    local names = {}
    for _, list in pairs(wants) do
        for _, entry in ipairs(list) do names[entry[1]] = true end
    end
    return names
end

-- Puts back every saved setting that nothing wants now
local function RestoreUnwanted()
    local backup = ns.db and ns.db.interactBackup
    if not backup then return end
    local names = Wanted()
    for name, value in pairs(backup) do
        if not names[name] then
            Util.SetCVar(name, value)
            -- Kept for a later try if the game refused (in combat); gone once it is back
            local now = Util.GetCVar(name)
            if now == nil or now == value or (tonumber(now) and tonumber(now) == tonumber(value)) then
                backup[name] = nil
            end
        end
    end
    if next(backup) == nil then ns.db.interactBackup = nil end
end

-- Raises the settings in `list` for `who` (again, every time: the game can put some back by
-- itself, e.g. the icon setting at entering the world).
function SoftTarget.Want(who, list)
    if not ns.db then return end
    wants[who] = list
    local backup = ns.db.interactBackup or {}
    for _, entry in ipairs(list) do
        local name, least, wanted = entry[1], entry[2], entry[3]
        local current = Util.GetCVar(name)
        if current ~= nil and (tonumber(current) or 0) < least then
            if backup[name] == nil then backup[name] = current end
            -- Saved before the change, so a crash can still be undone at next login
            ns.db.interactBackup = backup
            Util.SetCVar(name, wanted)
        end
    end
end

function SoftTarget.Release(who)
    wants[who] = nil
    RestoreUnwanted()
end

-- Everything back, whoever wanted it (logout)
function SoftTarget.ReleaseAll()
    wants = {}
    RestoreUnwanted()
end

-- (for the tests)
function SoftTarget.Wants(who)
    return wants[who] ~= nil
end
