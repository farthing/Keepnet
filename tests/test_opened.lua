-- Catches that are opened afterwards (a trunk, a clam): what comes out of them counts towards
-- the session the catch was made in.
local T = {}

local KEY = "F"
local EEL, TRUNK, CLAM, CHEST = 13422, 21113, 5523, 6355
local BAR, CLOTH, MEAT, PEARL = 3860, 4338, 5503, 5498

function T.run(ns)
    local Sessions, Core = ns.Sessions, ns.Core
    -- Eel, bar and pearl sell at auction; cloth and clam meat only to a vendor (62 and 4);
    -- the clam itself to a vendor for 3; the trunk has no price at all
    Stub.auction = { [EEL] = 41800, [BAR] = 30000, [PEARL] = 8000 }
    Stub.login()
    ns.settings.lureMode = "off"
    Stub.equip(Stub.POLE)

    -- A cast that catches this; the catch lands in the bags
    local function Catch(id, count)
        Stub.advance(2)
        Stub.press(KEY)
        Stub.nextLoot = { { id = id, count = count or 1 } }
        Stub.press(KEY)
        Stub.nextLoot = nil
        Stub.bags[id] = (Stub.bags[id] or 0) + (count or 1)
        Stub.fire("BAG_UPDATE_DELAYED")
    end
    local function Opened(session, id)
        return session.opened and session.opened[id] and session.opened[id].count or 0
    end
    local function Row(session, test)
        for _, row in ipairs((Core.Rows(session))) do
            if test(row) then return row end
        end
    end

    -- ------------------------------------------------- a trunk opened at the water
    Catch(EEL)
    Catch(TRUNK)
    Catch(CLAM, 3)
    local first = Sessions.Current()
    eq(first.catches, 3, "three catches in the session")
    local value, unpriced = Core.Value(first)
    eq(value, 41800 + 3 * 3, "before: the eel and the clams; the trunk has no price")
    eq(unpriced, 1, "and counts as an item without a price")

    local money = Stub.money
    local window = Stub.open(TRUNK, { { id = BAR, count = 2 }, { id = CLOTH, count = 3 }, { money = 1234 } })
    eq(Opened(first, BAR), 0, "nothing is counted while it is only being looked at")
    window.take()
    Stub.advance(1)
    eq(Stub.money, money + 1234, "(the coins went to the character)")
    eq(Opened(first, BAR), 2, "what came out of the trunk is in the session")
    eq(Opened(first, CLOTH), 3, "all of it")
    eq(first.money, 1234, "and so are the coins")
    eq(first.items[TRUNK].opened, 1, "the trunk is marked as opened")
    value, unpriced = Core.Value(first)
    eq(value, 41800 + 3 * 3 + 2 * 30000 + 3 * 62 + 1234, "the session's gold now holds the bars, the cloth and the coins")
    eq(unpriced, 0, "an opened trunk is no longer an item without a price")
    check(KeepnetPanel.buffs:GetText():find("Watertight Trunk opened", 1, true), "the live panel says it was counted")

    -- The catch itself stays what was on the hook
    eq(#Sessions.CatchList(first), 3, "the catch list is still the three things caught")
    eq(#Sessions.FindCatches("Mithril"), 0, "what came out of a trunk was not 'caught' in the zone")
    eq(first.catches, 3, "and the number of catches hasn't moved")

    -- The Session tab's rows
    local trunkRow = Row(first, function(row) return row.id == TRUNK end)
    eq(trunkRow.opened, 1, "the trunk's row says one was opened")
    eq(trunkRow.source, "opened", "and is priced as opened, not as 'no price'")
    eq(trunkRow.total, nil, "with nothing of its own in the total")
    local barRow = Row(first, function(row) return row.id == BAR end)
    eq(barRow.from, "opened", "the bars' row says where they came from")
    eq(barRow.total, 60000, "and is priced like anything else")
    local coins = Row(first, function(row) return row.money end)
    eq(coins and coins.total, 1234, "the coins have a row of their own")
    ns.SessionTab.View(first.id)
    check(ns.UI.IsShown(), "the Session tab shows it all")

    -- ------------------------------------------- things that must not be counted
    Stub.bags[CHEST] = 1 -- a chest that was never fished
    Stub.open(CHEST, { { id = BAR, count = 5 } }).take()
    Stub.advance(1)
    eq(Opened(first, BAR), 2, "a chest that wasn't fished is not counted")

    -- Loot from a corpse, with a fished clam still unopened in the bags
    local function Corpse()
        Stub.loot, Stub.fishingLoot = { { id = BAR, count = 1 } }, false
        Stub.lootSource = "Creature-0-4372-0-11-5432-0000000001"
        Stub.fire("LOOT_READY", true)
        Stub.fire("LOOT_OPENED", true)
        Stub.bags[BAR] = Stub.bags[BAR] + 1
        Stub.fire("LOOT_SLOT_CLEARED", 1)
        Stub.fire("BAG_UPDATE_DELAYED")
        Stub.loot, Stub.lootSource = nil, nil
        Stub.fire("LOOT_CLOSED")
        Stub.advance(1)
    end
    Corpse()
    eq(Opened(first, BAR), 2, "loot from a corpse is not counted")
    Stub.noLootSource = true
    Corpse()
    eq(Opened(first, BAR), 2, "nor when the game doesn't say where the loot is from")
    Stub.noLootSource = false

    -- A fishing catch is still a catch and nothing else
    Catch(EEL)
    eq(first.items[EEL].count, 2, "a catch still counts as a catch")
    eq(Opened(first, EEL), 0, "and not as something opened")

    -- ------------------------------------- opened later, after the session has ended
    Core.NewSession()
    Stub.equip(nil)
    eq(Sessions.Current(), nil, "the session is over and the pole is away")
    local kept = first.value
    eq(kept, 2 * 41800 + 3 * 3 + 2 * 30000 + 3 * 62 + 1234, "the finished session keeps its value")
    Stub.auction[EEL] = 10
    eq((Core.Value(first)), kept, "whatever prices do afterwards")

    Stub.open(CLAM, { { id = MEAT, count = 1 }, { id = PEARL, count = 1 } }).take()
    Stub.advance(1)
    eq(Opened(first, MEAT), 1, "a clam opened later goes to the session that caught it")
    eq(Opened(first, PEARL), 1, "with its pearl")
    eq(first.items[CLAM].opened, 1, "one of the three clams is opened")
    eq(first.value, kept + 4 + 8000 - 3, "its value moves by the meat and the pearl, less the clam that is gone")
    eq((Core.Value(first)), first.value, "and that is the value shown")

    -- The game won't say which item the loot is from: the clam that leaves the bags is it
    Stub.guidSilent = true
    Stub.open(CLAM, { { id = MEAT, count = 1 } }).take()
    Stub.advance(1)
    eq(first.items[CLAM].opened, 2, "an opened clam is found by its leaving the bags")
    eq(Opened(first, MEAT), 2, "and its meat counted")
    Stub.bags[CHEST] = 1
    Stub.open(CHEST, { { id = MEAT, count = 7 } }).take()
    -- (found by which catch leaves the bags, this only holds a moment after the window shut)
    Stub.advance(3)
    eq(Opened(first, MEAT), 2, "something that wasn't fished still isn't, that way either")
    Stub.guidSilent = false
    Stub.noLootSource = true
    Stub.open(CLAM, { { id = MEAT, count = 1 } }).take()
    Stub.advance(1)
    eq(first.items[CLAM].opened, 3, "the same when the game doesn't say where loot is from at all")
    eq(Opened(first, MEAT), 3, "its meat counted too")
    Stub.noLootSource = false
    Stub.bags[CLAM] = 1 -- a clam from somewhere else: every fished one has been opened
    Stub.open(CLAM, { { id = MEAT, count = 1 } }).take()
    Stub.advance(1)
    eq(Opened(first, MEAT), 3, "a clam beyond the ones that were fished is not counted")
    eq(first.items[CLAM].opened, 3, "and no more clams are marked than were caught")

    -- ------------------------------------------------ not everything taken out
    Stub.equip(Stub.POLE)
    Catch(TRUNK)
    local second = Sessions.Current()
    check(second ~= first, "a new session")
    window = Stub.open(TRUNK, { { id = BAR, count = 1 }, { id = CLOTH, count = 4 } })
    window.take(1)
    window.close()
    Stub.advance(1)
    eq(Opened(second, BAR), 1, "what was taken out is counted")
    eq(Opened(second, CLOTH), 0, "what was left inside is not")
    eq(second.items[TRUNK].opened, nil, "the trunk is still in the bags: not opened yet")
    eq(Opened(first, BAR), 2, "(the first session is untouched: this trunk is the second's)")
    Stub.advance(20)
    Stub.open(TRUNK, { { id = CLOTH, count = 4 } }).take()
    Stub.advance(1)
    eq(Opened(second, CLOTH), 4, "the rest, taken later, is counted then")
    eq(second.items[TRUNK].opened, 1, "and the trunk is opened")

    -- A long look before taking anything
    Catch(TRUNK)
    window = Stub.open(TRUNK, { { id = BAR, count = 1 } })
    Stub.advance(40)
    window.take()
    Stub.advance(1)
    eq(Opened(second, BAR), 2, "a trunk looked at for a long time still counts")
    eq(second.items[TRUNK].opened, 2, "both trunks opened")

    -- --------------------------------- clams opened one straight after another
    Catch(CLAM, 3)
    Stub.staleBags = true -- the bags lag behind: no clam has left them when the next opens
    for _ = 1, 3 do
        Stub.open(CLAM, { { id = MEAT, count = 1 }, { money = 100 } }).take()
    end
    Stub.staleBags = false
    Stub.flushBags()
    Stub.advance(1)
    eq(Opened(second, MEAT), 3, "three clams opened in a row: three lots of meat")
    eq(second.money, 300, "the coins of each, once")
    eq(second.items[CLAM].opened, 3, "three clams opened")
    eq(Opened(first, MEAT), 3, "all in the session that caught these three")

    -- ------------------- the game says late where the loot is from, and sends it twice
    Stub.lateSource, Stub.repeatLoot = true, true
    Catch(TRUNK)
    Stub.open(TRUNK, { { id = BAR, count = 1 }, { money = 50 } }).take()
    Stub.advance(1)
    eq(Opened(second, BAR), 3, "a source named only on the second event is still counted, once")
    eq(second.money, 350, "with its coins, once")
    eq(second.items[TRUNK].opened, 3, "and the trunk marked once")
    -- An unfished chest, named late, with a fished clam in the bags that is opened straight after
    Catch(CLAM)
    Stub.bags[CHEST] = 1
    Stub.open(CHEST, { { id = BAR, count = 6 } }).take()
    Stub.lateSource, Stub.repeatLoot = false, false
    Stub.open(CLAM, { { id = MEAT, count = 1 } }).take()
    Stub.advance(1)
    eq(Opened(second, BAR), 3, "a window the game names late as something unfished is dropped")
    eq(Opened(second, MEAT), 4, "and the clam opened right after it counts as itself")

    -- ------------------------------ taking a fished thing apart is not opening it
    local HAT, DUST = 19972, 5498
    Catch(HAT)
    Stub.open(HAT, { { id = DUST, count = 2 } }).take() -- disenchanted: loot from the item
    Stub.advance(1)
    eq(Opened(second, DUST), 0, "something worn that is disenchanted is not an opened catch")
    eq(second.items[HAT].opened, nil, "and is not marked as opened")

    -- ------------------------------------------ the sample sessions are left alone
    Catch(TRUNK)
    local bars = Opened(second, BAR)
    SlashCmdList.KEEPNET("demo")
    Stub.open(TRUNK, { { id = BAR, count = 9 } }).take()
    Stub.advance(1)
    SlashCmdList.KEEPNET("demo")
    eq(Opened(second, BAR), bars, "nothing is counted while the sample sessions show")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
