-- Keepnet: the character's Fishing skill, for the bar on the live panel, and the points it
-- gains, which are counted for the running session (session.skillUps).
local _, ns = ...
local Util = ns.Util

local Skill = {}
ns.Skill = Skill

local FISHING_SKILL_LINE = 356

local function Usable(value)
    return type(value) == "number" and not Util.Hidden(value)
end

local function Read()
    -- Fishing is the fourth profession slot (same lookup FishyWashy uses; see CREDITS.md)
    if GetProfessions and GetProfessionInfo then
        local _, _, _, fishing = GetProfessions()
        if fishing then
            local _, _, rank, max, _, _, _, modifier = GetProfessionInfo(fishing)
            if Usable(rank) and Usable(max) then
                return rank, max, Usable(modifier) and modifier or 0
            end
        end
    end
    local byLine = C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID
    if byLine then
        local info = byLine(FISHING_SKILL_LINE)
        if info and Usable(info.skillLevel) and Usable(info.maxSkillLevel) and info.maxSkillLevel > 0 then
            return info.skillLevel, info.maxSkillLevel, Usable(info.skillModifier) and info.skillModifier or 0
        end
    end
end

-- The trained skill, the most it can reach at the current rank, and the temporary bonus the
-- game reports on top (lure, gear); nil when the character hasn't learned Fishing
function Skill.Get()
    local ok, rank, max, bonus = pcall(Read)
    if ok and rank then
        return rank, max, bonus
    end
end

-- ---------------------------------------------------------------------------------------------
-- Skill gains
-- ---------------------------------------------------------------------------------------------
-- No event says in every language by how much Fishing went up, so the trained skill is
-- compared with what it was the last time it was read. The first reading after logging in
-- only sets the mark. Fishing skill only rises by fishing, so a rise found a little late (at
-- the next cast or tick) still belongs to the session.
local lastRank

function Skill.Check()
    local rank = Skill.Get()
    if not rank then return end
    local before = lastRank
    lastRank = rank
    if not before or rank <= before or not ns.db then return end
    if ns.Sessions.SkillGained(rank - before, ns.Core.Character()) then
        ns.Fire("SESSION")
    end
end

local events = CreateFrame("Frame")
-- The two events other addons on this client read the skill on (Mastercraft does on both).
-- An event name the client doesn't know is an error; skip it.
pcall(events.RegisterEvent, events, "CHAT_MSG_SKILL")
pcall(events.RegisterEvent, events, "SKILL_LINES_CHANGED")
events:SetScript("OnEvent", function() Skill.Check() end)
ns.On("WORLD", function() Skill.Check() end)
ns.On("CAST_START", function() Skill.Check() end)
ns.On("TICK", function() Skill.Check() end)
