-- The line under the skill bar: the points of Fishing skill gained in the running session.
local T = {}

local KEY = "F"
local EEL = 13422

function T.run(ns)
    local Sessions, Skill = ns.Sessions, ns.Skill

    Stub.skill = { 187, 225, 0 }
    Stub.bags = {}
    Stub.login()
    Stub.equip(Stub.POLE)
    local panel = KeepnetPanel
    local function Line()
        panel:GetScript("OnUpdate")(panel, 1.5)
        return panel.gains:GetText()
    end
    eq(Line(), "Skill gains this session: 0", "no session yet: no gains")

    -- A point gained with no session running has nowhere to go
    Stub.skill[1] = 188
    Stub.fire("SKILL_LINES_CHANGED")
    eq(Sessions.Current(), nil, "a gain alone starts no session")
    eq(Line(), "Skill gains this session: 0", "and isn't counted")

    -- A catch that raises the skill: the game says so around the time the loot shows
    eq(Stub.press(KEY), "cast", "the line goes out")
    Stub.advance(12)
    Stub.skill[1] = 189
    Stub.fire("CHAT_MSG_SKILL", "Your skill in Fishing has increased to 189.")
    Stub.reel({ { EEL, 1 } })
    local session = Sessions.Current()
    eq(session.skillUps, 1, "the point goes to the running session")
    eq(Line(), "Skill gains this session: 1", "and shows under the skill bar")
    -- Both events for the one point: counted once
    Stub.fire("SKILL_LINES_CHANGED")
    eq(session.skillUps, 1, "the game's second event for the same point adds nothing")

    -- Neither event came: the next cast finds the rise
    Stub.advance(2)
    Stub.skill[1] = 191
    eq(Stub.press(KEY), "cast", "another cast")
    eq(session.skillUps, 3, "a rise no event told of is found at the next cast")
    Stub.advance(12)
    Stub.reel({ { EEL, 1 } })
    eq(Line(), "Skill gains this session: 3", "the line follows")

    -- A new rank from the trainer raises the cap, not the skill
    Stub.skill[2] = 300
    Stub.fire("SKILL_LINES_CHANGED")
    eq(session.skillUps, 3, "a higher cap is no gain")
    -- The skill reading lower (unlearned and learned again) is no gain, and sets the mark anew
    Stub.skill[1] = 1
    Stub.fire("SKILL_LINES_CHANGED")
    eq(session.skillUps, 3, "a lower skill takes nothing away")
    Stub.skill[1] = 2
    Stub.fire("SKILL_LINES_CHANGED")
    eq(session.skillUps, 4, "and the next point counts from there")

    -- The count belongs to its session: a new one starts at nothing, the old one keeps its own
    Stub.advance(2)
    ns.Core.NewSession()
    eq(Line(), "Skill gains this session: 0", "New session: the line starts again")
    eq(Sessions.Get(session.id).skillUps, 4, "the finished session keeps its gains")
    eq(Stub.press(KEY), "cast", "the first cast of the next session")
    Stub.advance(12)
    Stub.skill[1] = 3
    Stub.fire("SKILL_LINES_CHANGED")
    Stub.reel({ { EEL, 1 } })
    eq(Sessions.Current().skillUps, 1, "its first point")
    check(Sessions.Current().id ~= session.id, "(in the new session)")

    -- After a /reload the mark is set afresh: the skill as it stands is not a gain
    Stub.advance(2)
    ns = Stub.reload()
    Stub.equip(Stub.POLE)
    eq(ns.Sessions.Current().skillUps, 1, "a /reload keeps the count and adds nothing")
    eq(Skill ~= ns.Skill, true, "(the addon was loaded again)")
end

return T
