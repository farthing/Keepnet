-- Keepnet: one key for fishing.
--   Line in:  the key clicks a hidden secure button, which eats fishing food, uses a buff
--             item, applies a lure or casts Fishing: the first of those that is needed.
--   Line out: the key is the game's own Interact key, which reels in without the mouse. The
--             game's "interact key" settings are turned on for that time and put back after.
-- One press does one thing: the game only lets a key press start a single action.
--
-- The method (override-bind the key to a secure button for casting, re-bind it to
-- INTERACTTARGET with SoftTargetInteract on while the Fishing channel runs) was learned from
-- FishyWashy by veiset and Forever Fishing by Hamish336; the wider interact arc and range come
-- from Luredon and Fishing Mode. Written from scratch; see CREDITS.md.
--
-- Bindings and the interact settings are protected: they can't be changed in combat. Combat
-- start still allows it for an instant, so everything is put back there and set up again when
-- combat ends.
local _, ns = ...
local Util, Fishing, Lures, Buffs = ns.Util, ns.Fishing, ns.Lures, ns.Buffs

local OneKey = {}
ns.OneKey = OneKey

local BUTTON_NAME = "KeepnetCastButton"

-- Game settings while the line is out: { name, the least it must be, what to set }.
-- SoftTargetInteract: 0 off, 1 gamepad, 2 keyboard and mouse, 3 both.
-- Arc 2 is all the way round; the bobber can land 20 yards out and to the side.
local INTERACT_CVARS = {
    { "SoftTargetInteract", 2, "3" },
    { "SoftTargetInteractArc", 2, "2" },
    { "SoftTargetInteractRange", 30, "30" },
}

-- No parent: the key must keep working while the game's interface is hidden (HideUI.lua)
local button = CreateFrame("Button", BUTTON_NAME, nil, "SecureActionButtonTemplate")
-- The game acts on key down or key up depending on a player setting; take both
button:RegisterForClicks("AnyUp", "AnyDown")
button:SetAttribute("type", "spell")

local owner = CreateFrame("Frame") -- owns the override bindings
local bound       -- "cast", "reel" or nil
local boundKey

-- A key press also sends "key up". With the game set to act on key up, the release of the
-- press that reeled in arrives after the key was re-bound to casting and would throw the line
-- straight back out. So a release with no press before it since the line came in is ignored.
-- (Not a timer: a timer would also swallow a quick deliberate second press.)
local sawPress = false

-- Decides what this press does. The decision is made on the press; its release keeps it (the
-- game acts on one or the other). Attributes can only change out of combat, which is also the
-- only time the key is bound.
button:SetScript("PreClick", function(self, _, down)
    if InCombatLockdown() then return end
    if down == false then
        if not sawPress then
            self:SetAttribute("type", nil) -- a stray release: nothing
        end
        sawPress = false
        return
    end
    sawPress = true
    if Lures.Casting() or Buffs.Waiting() then
        self:SetAttribute("type", nil) -- the lure is still going on, or eating: nothing
        return
    end
    -- In this order: food (ten seconds of eating), other buff items, the lure, the cast
    local item = Buffs.ToUse()
    local lure = not item and Lures.ToApply()
    if item then
        Buffs.Offered(item)
        if Util.IsToy(item) then
            -- A /use macro doesn't fire a learned toy; the toy action does
            self:SetAttribute("type", "toy")
            self:SetAttribute("toy", item)
        else
            self:SetAttribute("type", "macro")
            self:SetAttribute("macrotext", Buffs.UseMacro(item))
        end
    elseif lure then
        Lures.Offered()
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", Lures.ApplyMacro(lure))
    else
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", Fishing.Name())
    end
end)

-- ---------------------------------------------------------------------------------------------
-- The interact settings (shared with the bobber mark: SoftTarget.lua saves and restores them)
-- ---------------------------------------------------------------------------------------------
local function EnableInteract()
    ns.SoftTarget.Want("key", INTERACT_CVARS)
end

local function RestoreInteract()
    ns.SoftTarget.Release("key")
end

-- ---------------------------------------------------------------------------------------------
-- The key
-- ---------------------------------------------------------------------------------------------
-- Binds the key to match fishing mode, combat and the line. Called whenever one of them changes.
function OneKey.Update()
    if not ns.db or InCombatLockdown() then return end -- combat end calls this again
    local key = ns.settings.key
    local want
    if ns.fishing and not ns.inCombat and key and key ~= "" then
        want = Fishing.LineOut() and "reel" or "cast"
    end
    if want ~= "reel" then
        RestoreInteract()
    end
    if want == bound and key == boundKey then return end
    ClearOverrideBindings(owner)
    if want == "cast" then
        SetOverrideBindingClick(owner, true, key, BUTTON_NAME)
    elseif want == "reel" then
        EnableInteract()
        SetOverrideBinding(owner, true, key, "INTERACTTARGET")
    end
    bound, boundKey = want, key
end

-- What the key does right now: "cast", "reel" or nil
function OneKey.State()
    return bound
end

ns.On("MODE", OneKey.Update)
ns.On("COMBAT", OneKey.Update)
ns.On("SETTINGS", OneKey.Update)
ns.On("LINE", function(out)
    if not out then sawPress = false end
    OneKey.Update()
end)
-- A logout in combat can't touch the settings; the saved copy puts them back at next login
ns.On("LOGOUT", function()
    if InCombatLockdown() then return end
    ClearOverrideBindings(owner)
    bound, boundKey = nil, nil
    RestoreInteract()
end)
