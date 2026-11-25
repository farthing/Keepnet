-- The update notice: copies of Keepnet tell each other their version over a hidden channel,
-- the guild and the group, and a copy that hears of a newer one from two different players
-- tells its player. See the top of Updates.lua for the rules these checks follow.
local T = {}

local PREFIX, CHANNEL = "Keepnet", "KeepersNet"

local function Count(list, text)
    local n = 0
    for _, line in ipairs(list) do
        if tostring(line):find(text, 1, true) then n = n + 1 end
    end
    return n
end

-- Addon messages sent since the last Clear(), optionally of one kind
local function Sent(kind)
    local n = 0
    for _, message in ipairs(Stub.sent) do
        if not kind or message.kind == kind then n = n + 1 end
    end
    return n
end

local function Clear()
    Stub.sent = {}
end

-- Another player's copy says its version
local function Hear(kind, sender, version, mark)
    Stub.fire("CHAT_MSG_ADDON", PREFIX, ("V1 %s %s"):format(version, mark or "abcd1234"), kind, sender)
end

-- A fresh login: the game forgets a temporary channel when the character leaves
local function Relog()
    Stub.channels = {}
    Clear()
    return Stub.reload()
end

function T.run(ns)
    local Updates = ns.Updates
    local mine = ns.VERSION

    -- ------------------------------------------------------------------------- versions
    eq(Updates.Compare("1.0.1", "1.0.0") > 0, true, "1.0.1 is newer than 1.0.0")
    eq(Updates.Compare("0.9.9", "1.0.0") < 0, true, "0.9.9 is older than 1.0.0")
    eq(Updates.Compare("1.10.0", "1.9.9") > 0, true, "numbers are compared as numbers, not as text")
    eq(Updates.Compare("1.0.0", "1.0.0"), 0, "the same version")
    eq(Updates.Parse("1.0"), nil, "two numbers are not a version")
    eq(Updates.Parse("1.0.0.1"), nil, "nor four")
    eq(Updates.Parse("v1.0.0"), nil, "nor anything with letters")
    eq(Updates.Parse("100.0.0"), nil, "nor a number out of bounds")
    eq(Updates.Parse("1.0.0 "), nil, "nor one with anything after it")
    eq(Updates.Parse(nil), nil, "nor nothing at all")

    -- ---------------------------------------------------------------------------- login
    Stub.login()
    eq(Stub.prefixes[PREFIX], true, "the prefix for the hidden messages is registered")
    eq(#Stub.channels, 0, "nothing is joined in the first seconds after login")
    eq(Sent(), 0, "and nothing is said")
    Stub.advance(12)
    eq(Stub.channels[1], CHANNEL, "then the channel is joined, after the game's own")
    eq(select(1, GetChannelName(CHANNEL)), 3, "so the game's channels keep their numbers")
    check((Stub.hiddenChannels[CHANNEL] or 0) >= 10, "it is taken off every chat window")
    eq(Sent(), 1, "the version is announced once")
    local first = Stub.sent[1]
    eq(first.kind, "CHANNEL", "on the channel")
    eq(first.target, 3, "by its number")
    eq(first.prefix, PREFIX, "under the prefix")
    local version, token = first.text:match("^V1 (%S+) (%x+)$")
    eq(version, mine, "the message carries this copy's version")
    check(token ~= nil and #token == 8, "and a mark of its own")
    Stub.advance(600)
    eq(Sent(), 1, "and not again: no guild, no group, nothing more to say")
    eq(Count(Stub.chat, "is out"), 0, "the player is told nothing")
    eq(Updates.Newest(), nil, "no newer version is known")

    -- ------------------------------------------------------------- what is heard and ignored
    Clear()
    Hear("CHANNEL", "Me", "9.9.9", token)
    eq(Updates.Newest(), nil, "its own message coming back is not somebody else's")
    Hear("CHANNEL", "Ann Weaver", mine)
    Stub.advance(10)
    eq(Sent(), 0, "the same version from another copy: nothing to answer")
    Stub.fire("CHAT_MSG_ADDON", "OtherAddon", "V1 9.9.9 abcd1234", "CHANNEL", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "1.0.5", "CHANNEL", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "V1 1.0 abcd1234", "CHANNEL", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "V1 1.0.5 abcd1234 and a great deal more besides", "CHANNEL", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "V1 1.0.5 abcd1234", "WHISPER", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, Stub.SECRET, "CHANNEL", "Ann Weaver")
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "V1 1.0.5 abcd1234", "CHANNEL", Stub.SECRET)
    Stub.fire("CHAT_MSG_ADDON", PREFIX, "V1 1.0.5 abcd1234", "CHANNEL", nil)
    eq(next(ns.db.updates.heard), nil, "another addon's, a malformed, a whispered, a hidden or a nameless message counts for nothing")
    Hear("CHANNEL", "Ann Weaver", "3.0.0")
    eq(next(ns.db.updates.heard), nil, "nor does a version too far ahead to be true")

    -- ------------------------------------------------------- an older copy is answered
    Hear("CHANNEL", "Old Timer", "0.9.9")
    eq(Sent(), 0, "an older copy is not answered at once")
    Stub.advance(6)
    eq(Sent("CHANNEL"), 1, "but within a few seconds, with this copy's version")
    -- Asked again straight away: the answer waits its turn, a message every ten seconds at most
    Clear()
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Stub.advance(4)
    eq(Sent(), 0, "a second answer so soon after the first is held back")
    Stub.advance(12)
    eq(Sent("CHANNEL"), 1, "and given when its turn comes")
    Stub.advance(20)
    -- Two others get there first: this copy keeps quiet
    Clear()
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Hear("CHANNEL", "Ann Weaver", mine)
    Hear("CHANNEL", "Ann Weaver", mine)
    Stub.advance(6)
    eq(Sent(), 1, "one other answer is not enough to stay silent, even said twice")
    Stub.advance(20)
    Clear()
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Hear("CHANNEL", "Ann Weaver", mine)
    Hear("CHANNEL", "Bob Reed", "1.0.3", "11112222")
    Stub.advance(6)
    eq(Sent(), 0, "two others answered first: one more would only be noise")
    eq(Updates.Newest(), nil, "one player announcing a newer version is not believed yet")
    eq(Count(Stub.chat, "is out"), 0, "and the player is not told")

    -- ----------------------------------------------- a newer version, from two players
    Hear("CHANNEL", "Bob Reed", "1.0.3", "33334444")
    eq(Updates.Newest(), nil, "the same player again is still one player")
    Hear("GUILD", "Cat Marsh", "1.0.2", "55556666")
    eq(Updates.Newest(), "1.0.2", "a second player: the newest version both vouch for is believed")
    eq(Count(Stub.chat, "Keepnet 1.0.2 is out (you have " .. mine .. ")"), 1, "and the player is told in chat")
    Hear("CHANNEL", "Cat Marsh", "1.0.2", "55556666")
    Hear("CHANNEL", "Dee Holt", "1.0.2", "77778888")
    eq(Count(Stub.chat, "is out"), 1, "once, however often it is heard")
    Hear("CHANNEL", "Cat Marsh", "1.0.3", "55556666")
    eq(Updates.Newest(), "1.0.3", "when two players are on a newer one still, that is the one")
    eq(Count(Stub.chat, "Keepnet 1.0.3 is out"), 1, "and the player hears of that too")
    Hear("CHANNEL", "Cat Marsh", "1.0.1", "55556666")
    eq(ns.db.updates.heard["Cat Marsh"].version, "1.0.3", "a player's newest claim is the one kept")
    check(Updates.Describe():find("Keepnet 1.0.3 is out", 1, true), "Settings says so as well")
    ns.UI.Show("settings")
    ns.UI.Refresh()

    -- On the live panel, the first time it is up: chat is out of sight with the interface hidden
    Stub.equip(Stub.POLE)
    Stub.advance(1.5)
    check(KeepnetPanel.buffs:GetText():find("Keepnet 1.0.3 is out", 1, true), "the live panel says it when the pole goes on")
    Stub.equip(nil)

    -- -------------------------------------------------------- remembered, for a while
    ns = Relog()
    Updates = ns.Updates
    eq(Updates.Newest(), "1.0.3", "what was heard is remembered at the next login")
    Stub.advance(12)
    eq(Count(Stub.chat, "Keepnet 1.0.3 is out"), 2, "and the player is told once more, after the login has settled")
    ns.db.updates.heard["Bob Reed"].at = time() - 8 * 86400
    eq(Updates.Newest(), "1.0.2", "a claim older than a week no longer counts")
    ns.db.updates.heard["Cat Marsh"].version = mine
    ns.db.updates.heard["Dee Holt"].version = "0.9.0"
    eq(Updates.Newest(), nil, "and one this copy has caught up with is forgotten")
    eq(next(ns.db.updates.heard), nil, "nothing is left of them")

    -- --------------------------------------------------- the game's channels come late
    Stub.gameChannels = {}
    ns = Relog()
    Updates = ns.Updates
    Stub.advance(40)
    eq(#Stub.channels, 0, "without the game's own channels in, Keepnet's is not joined: it would take their number")
    eq(Sent(), 0, "and nothing is said yet")
    Stub.gameChannels = { "General", "Trade" }
    Stub.advance(6)
    eq(Stub.channels[1], CHANNEL, "once they are in, it is")
    eq(Sent("CHANNEL"), 1, "and the version is announced")
    -- They never come (the player left them all): joined after a wait
    Stub.gameChannels = {}
    ns = Relog()
    Stub.advance(110)
    eq(#Stub.channels, 0, "still waiting for them after a minute or two")
    Stub.advance(20)
    eq(Stub.channels[1], CHANNEL, "but not for ever")
    eq(Sent("CHANNEL"), 1, "and the version is announced there")
    Stub.gameChannels = { "General", "Trade" }

    -- ----------------------------------------------------------------- guild and group
    Stub.guild = true
    ns = Relog()
    Stub.advance(12)
    eq(Sent("CHANNEL"), 1, "in a guild: the channel")
    eq(Sent("GUILD"), 1, "and the guild, once each")
    Clear()
    Stub.group = true
    Stub.fire("GROUP_ROSTER_UPDATE")
    eq(Sent("PARTY"), 1, "a party joined is told")
    Stub.fire("GROUP_ROSTER_UPDATE")
    Stub.advance(60)
    eq(Sent(), 1, "once, however the party changes")
    Stub.group = false
    Stub.fire("GROUP_ROSTER_UPDATE")
    Stub.raid = true
    Stub.fire("GROUP_ROSTER_UPDATE")
    eq(Sent("RAID"), 1, "a raid joined later is a new audience")
    Clear()
    Hear("RAID", "Old Timer", "0.9.9")
    Hear("GUILD", "Old Timer", "0.9.9")
    Stub.advance(20)
    eq(Sent("RAID"), 1, "an older copy in the raid is answered in the raid")
    eq(Sent("GUILD"), 1, "one in the guild, in the guild")
    eq(Sent("CHANNEL"), 0, "and not on the channel")
    Stub.guild, Stub.raid = false, false
    Stub.fire("GROUP_ROSTER_UPDATE")

    -- --------------------------------------------------- held back: combat and lockdown
    Clear()
    Stub.advance(20)
    Stub.enterCombat()
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Stub.advance(8)
    eq(Sent(), 0, "nothing is sent in combat")
    Stub.leaveCombat()
    Stub.chatLocked = true
    ns = Relog()
    Updates = ns.Updates
    Stub.advance(30)
    eq(#Stub.channels, 0, "while the game holds chat back the channel is not joined")
    eq(Sent(), 0, "and nothing is sent")
    Stub.chatLocked = false
    Stub.advance(6)
    eq(Stub.channels[1], CHANNEL, "when it lets go, the channel is joined")
    eq(Sent("CHANNEL"), 1, "and the version announced")

    -- ----------------------------------------------------------------------- the switch
    Clear()
    ns.settings.updates = false
    ns.Fire("SETTINGS")
    eq(#Stub.channels, 0, "turned off in Settings: Keepnet leaves the channel")
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Hear("CHANNEL", "Bob Reed", "1.0.3", "11112222")
    Hear("CHANNEL", "Cat Marsh", "1.0.3", "55556666")
    Stub.advance(30)
    eq(Sent(), 0, "says nothing")
    eq(Updates.Newest(), nil, "and listens to nothing")
    check(Updates.Describe():find("Off", 1, true), "Settings says it is off")
    ns.settings.updates = true
    ns.Fire("SETTINGS")
    eq(Stub.channels[1], CHANNEL, "turned on again: back in the channel")
    eq(Sent(), 0, "without saying again what was already said this session")

    -- -------------------------------------------------------------- a development copy
    Stub.metadata["X-Keepnet-Build"] = "dev"
    ns = Relog()
    Updates = ns.Updates
    Stub.advance(60)
    eq(Updates.IsDev(), true, "the copy tools\\install.ps1 makes knows it is a development copy")
    eq(Stub.channels[1], CHANNEL, "it joins the channel like any other")
    eq(Sent(), 0, "and never announces: its version may be one nobody can download")
    Hear("CHANNEL", "Old Timer", "0.9.9")
    Stub.advance(8)
    eq(Sent(), 0, "not even to an older copy")
    local before = Count(Stub.chat, "Keepnet 1.0.4 is out")
    Hear("CHANNEL", "Bob Reed", "1.0.4", "11112222")
    Hear("CHANNEL", "Cat Marsh", "1.0.4", "55556666")
    eq(Count(Stub.chat, "Keepnet 1.0.4 is out"), before + 1, "but it listens, and tells its player")
    check(Updates.Describe():find("1.0.4", 1, true), "in Settings too")
    Stub.metadata["X-Keepnet-Build"] = nil
end

return T
