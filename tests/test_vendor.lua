-- Buying lures: when a vendor's window opens, the ticked ones of the five basic lures are
-- bought up to a number in the bags, and, as a choice of its own, every Aquadynamic Fish
-- Attractor the vendor has.
local T = {}

local BAUBLE, CRAWLERS, LENS, BRIGHT, WORM, ATTRACTOR = 6529, 6530, 6811, 6532, 7307, 6533
local BREAD = 4540

local function Said(text)
    for _, line in ipairs(Stub.chat) do
        if tostring(line):find(text, 1, true) then return true end
    end
    return false
end

local function Bought(id)
    local total = 0
    for _, purchase in ipairs(Stub.purchases) do
        if purchase.id == id then total = total + purchase.count end
    end
    return total
end

function T.before()
    Stub.items[LENS] = { "Aquadynamic Fish Lens", 1, 12, 0, 8, 0 }
    Stub.items[WORM] = { "Flesh Eating Worm", 1, 6, 0, 8, 0 }
    Stub.items[ATTRACTOR] = { "Aquadynamic Fish Attractor", 1, 62, 0, 8, 0 }
    Stub.items[BREAD] = { "Tough Hunk of Bread", 1, 1, 0, 5, 0 }
end

-- A fishing supplier: the three everyday lures without limit, two Attractors, and bread
local function Supplier()
    return {
        { id = BREAD, price = 25 },
        { id = BAUBLE, price = 50 },
        { id = CRAWLERS, price = 100 },
        { id = BRIGHT, price = 250 },
        { id = ATTRACTOR, price = 500, available = 2 },
    }
end

function T.run(ns)
    local Vendor = ns.Vendor
    Stub.bags = {}
    Stub.money = 100000
    Stub.login()
    local settings = ns.settings

    -- The five basic lures, and the one with a rule of its own
    eq(#Vendor.LURES, 5, "five basic lures")
    eq(Vendor.LURES[1].name, "Shiny Bauble", "Shiny Bauble")
    eq(Vendor.LURES[2].name, "Nightcrawlers", "Nightcrawlers")
    eq(Vendor.LURES[3].name, "Aquadynamic Fish Lens", "Aquadynamic Fish Lens")
    eq(Vendor.LURES[4].name, "Bright Baubles", "Bright Baubles")
    eq(Vendor.LURES[5].name, "Flesh Eating Worm", "Flesh Eating Worm")
    eq(Vendor.ATTRACTOR.name, "Aquadynamic Fish Attractor", "and the Aquadynamic Fish Attractor apart")

    -- Off until the player turns it on
    eq(settings.buyLures, false, "buying is off to begin with")
    eq(settings.buyAttractors, false, "and so is buying Attractors")
    eq(settings.buyLureCount, 20, "the number starts at 20")
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "a vendor's window opens: nothing is bought")
    eq(Stub.money, 100000, "and nothing spent")

    -- On, with nothing ticked: still nothing
    settings.buyLures = true
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "switched on with no lure ticked: nothing is bought")

    -- One lure ticked: bought up to the number, and only that lure
    settings.buyLureItems[BRIGHT] = true
    Stub.chat = {}
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 20, "the ticked lure is bought up to the number")
    eq(Bought(BAUBLE) + Bought(CRAWLERS) + Bought(ATTRACTOR) + Bought(BREAD), 0, "and nothing else")
    eq(Stub.money, 100000 - 20 * 250, "for its price")
    check(Said("Bought 20 Bright Baubles for"), "the player is told what and for how much")

    -- Enough in the bags already: nothing more
    Stub.purchases = {}
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "with that many in the bags nothing more is bought")
    -- A few used: topped up
    Stub.bags[BRIGHT] = 13
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 20, "seven used: seven bought")
    eq(Bought(BRIGHT), 7, "no more than that")

    -- Another number, and more than a stack of it
    settings.buyLureCount = 45
    settings.buyLureItems[BAUBLE] = true
    Stub.purchases = {}
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BAUBLE], 45, "a bigger number: that many, a stack at a time")
    eq(Stub.bags[BRIGHT], 45, "of each lure ticked")
    settings.buyLureCount = "nonsense"
    eq(Vendor.Count(), 20, "a number that isn't one is 20")
    settings.buyLureCount = 100000
    eq(Vendor.Count(), 200, "and there is a most")
    settings.buyLureCount = 20

    -- A lure the vendor has only a few of: those few
    Stub.purchases = {}
    settings.buyLureItems = { [LENS] = true, [WORM] = true }
    Stub.openMerchant({ { id = LENS, price = 300, available = 3 }, { id = BAUBLE, price = 50 } })
    eq(Stub.bags[LENS], 3, "a vendor with three of a ticked lure: three")
    eq(Bought(BAUBLE), 0, "a lure no longer ticked is left")
    eq(Bought(WORM), 0, "a ticked lure this vendor doesn't sell: nothing")

    -- Not enough money: what it pays for, and a word about it
    Stub.purchases = {}
    Stub.bags = {}
    Stub.money = 1100
    settings.buyLureItems = { [BRIGHT] = true }
    Stub.chat = {}
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 4, "money for four: four are bought")
    eq(Stub.money, 100, "and no more is spent than there is")
    check(Said("Not enough money for all the lures"), "the player is told")
    Stub.money = 100000

    -- Something that isn't sold for coins is left alone
    Stub.purchases = {}
    Stub.bags = {}
    Stub.openMerchant({ { id = BRIGHT, price = 250, extended = true } })
    eq(#Stub.purchases, 0, "a lure that isn't sold for coins is not bought")

    -- Sold several at a time: whole purchases
    Stub.openMerchant({ { id = BRIGHT, price = 250, batch = 5 } })
    eq(Stub.bags[BRIGHT], 20, "sold five at a time: four purchases for twenty")

    -- The Attractor: every one the vendor has, whatever the number, with the rest switched off
    settings.buyLures = false
    settings.buyAttractors = true
    Stub.purchases = {}
    Stub.bags = { [ATTRACTOR] = 30 }
    Stub.chat = {}
    Stub.openMerchant(Supplier())
    eq(Bought(ATTRACTOR), 2, "every Attractor the vendor has is bought")
    eq(Stub.bags[ATTRACTOR], 32, "however many are in the bags already")
    eq(Bought(BRIGHT) + Bought(BAUBLE), 0, "the other lures stay switched off")
    check(Said("Bought 2 Aquadynamic Fish Attractor for"), "the player is told")
    -- The vendor has none left
    Stub.purchases = {}
    Stub.openMerchant({ { id = ATTRACTOR, price = 500, available = 0 } })
    eq(#Stub.purchases, 0, "a vendor with none left: nothing")
    -- Both together
    settings.buyLures = true
    Stub.bags = {}
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 20, "both switched on: the ticked lure")
    eq(Stub.bags[ATTRACTOR], 2, "and the Attractors")
    -- Attractors switched off
    settings.buyAttractors = false
    Stub.purchases = {}
    Stub.bags = {}
    Stub.openMerchant(Supplier())
    eq(Bought(ATTRACTOR), 0, "Attractors switched off: left on the shelf")

    -- ------------------------------------------------------------ never far too many
    -- What is bought reaches the bags a moment later. Until then it counts as there: the
    -- vendor's window sent twice in a row buys nothing twice
    settings.buyLures, settings.buyAttractors = true, true
    settings.buyLureItems = { [BRIGHT] = true }
    Stub.purchases = {}
    Stub.bags = {}
    Stub.slowDelivery = true
    local shelf = Supplier()
    Stub.openMerchant(shelf)
    eq(Bought(BRIGHT), 20, "the lures are asked for")
    eq(Stub.bags[BRIGHT], nil, "and are not in the bags yet")
    Stub.fire("MERCHANT_SHOW")
    Stub.fire("MERCHANT_SHOW")
    eq(Bought(BRIGHT), 20, "the window sent again before they arrive: not bought again")
    eq(Bought(ATTRACTOR), 2, "nor the Attractors")
    Stub.deliver()
    Stub.fire("MERCHANT_SHOW")
    eq(Bought(BRIGHT), 20, "arrived: there are enough, nothing more")
    -- Some used later: topped up as ever
    Stub.bags[BRIGHT] = 15
    Stub.fire("MERCHANT_SHOW")
    Stub.deliver()
    eq(Stub.bags[BRIGHT], 20, "five used later: five bought")
    -- A purchase that never arrives is not waited for for ever
    Stub.bags[BRIGHT] = 10
    Stub.fire("MERCHANT_SHOW")
    Stub.undelivered = nil -- lost
    local before = Bought(BRIGHT)
    Stub.fire("MERCHANT_SHOW")
    eq(Bought(BRIGHT), before, "a purchase that hasn't arrived yet: still counted")
    Stub.advance(11)
    Stub.fire("MERCHANT_SHOW")
    eq(Bought(BRIGHT), before + 10, "ten seconds on with nothing arrived: bought again")
    Stub.deliver()
    Stub.slowDelivery = nil

    -- A lure standing twice in a vendor's list is bought once
    Stub.purchases = {}
    Stub.bags = {}
    Stub.advance(11)
    Stub.slowDelivery = true
    Stub.openMerchant({ { id = BRIGHT, price = 250 }, { id = BRIGHT, price = 250 } })
    eq(Bought(BRIGHT), 20, "a lure listed twice by one vendor: bought once")
    Stub.deliver()
    Stub.slowDelivery = nil

    -- The number can't be more than 200, whatever is typed
    settings.buyLureCount = 500
    Stub.purchases = {}
    Stub.bags = {}
    Stub.advance(11)
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 200, "500 asked for: 200 is the most there is")
    settings.buyLureCount = 20

    -- A vendor that says it has hundreds of Attractors: never more than twenty in a visit
    Stub.purchases = {}
    Stub.bags = {}
    Stub.advance(11)
    Stub.openMerchant({ { id = ATTRACTOR, price = 5, available = 500 } })
    eq(Bought(ATTRACTOR), 20, "a vendor claiming 500 Attractors: twenty are bought, no more")
    Stub.advance(11)
    Stub.purchases = {}
    Stub.bags = {}
    settings.buyAttractors = false

    -- With no more gold than the player set, nothing is bought at all
    eq(settings.buyLureFloor, 0, "no such limit to begin with")
    settings.buyLures, settings.buyAttractors = true, true
    settings.buyLureItems = { [BRIGHT] = true }
    settings.buyLureFloor = 10 -- gold
    Stub.purchases = {}
    Stub.bags = {}
    Stub.money = 100000 -- ten gold exactly
    Stub.chat = {}
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "exactly the gold that was set: nothing is bought")
    eq(Stub.money, 100000, "not the Attractors either")
    check(Said("No lures bought"), "and the player is told why")
    Stub.money = 99999
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "less than that: nothing")
    -- No word when there was nothing to buy anyway
    Stub.chat = {}
    Stub.openMerchant({ { id = BREAD, price = 25 } })
    check(not Said("No lures bought"), "a vendor with nothing wanted: no word about it")
    -- More than that: only what lies above it is spent
    Stub.money = 100001
    Stub.chat = {}
    Stub.openMerchant(Supplier())
    eq(#Stub.purchases, 0, "a copper more than is kept: not enough above it for one lure")
    check(Said("Not enough money above the 10"), "and the player is told the money above it didn't reach")
    Stub.money = 100000 + 3 * 250 + 100
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 3, "enough above it for three: three are bought")
    eq(Bought(ATTRACTOR), 0, "and no Attractor, which would take the money under what is kept")
    eq(Stub.money, 100100, "the gold that is kept is not touched")
    -- Plenty above it: everything, and still not under it
    Stub.purchases = {}
    Stub.bags = {}
    Stub.money = 200000
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 20, "plenty above it: the lures are bought")
    eq(Stub.bags[ATTRACTOR], 2, "and the Attractors")
    check(Stub.money >= 100000, "with the kept gold still there")
    -- Sold several at a time: no purchase that would go under it
    Stub.purchases = {}
    Stub.bags = {}
    Stub.money = 100000 + 2 * 5 * 250 + 1000
    settings.buyAttractors = false
    Stub.openMerchant({ { id = BRIGHT, price = 250, batch = 5 } })
    eq(Stub.bags[BRIGHT], 10, "sold five at a time, money above it for two purchases: two")
    eq(Stub.money, 101000, "not a third that would go under it")
    settings.buyAttractors = true
    settings.buyLureFloor = "nonsense"
    eq(Vendor.Floor(), 0, "a limit that isn't a number is none")
    settings.buyLureFloor = 0
    settings.buyAttractors = false
    Stub.money = 100000

    -- The Gear & food tab: the switch, the number, a tick box a lure, the Attractor's own
    settings.buyLures, settings.buyLureItems = true, { [CRAWLERS] = true }
    ns.UI.Show("gear")
    ns.UI.Refresh()
    local tab
    for _, frame in ipairs(Stub.frames) do
        if frame.buyLure then tab = frame end
    end
    check(tab ~= nil, "the Gear & food tab has the lure buying on it")
    eq(tab.buyLures:GetChecked(), true, "the switch shows it is on")
    eq(tab.buyLureCount:GetText(), "20", "the number to keep shows")
    eq(tab.buyLure.value, CRAWLERS, "the list shows the lure that is chosen")
    eq(tab.buyLure.label:GetText(), "Nightcrawlers", "by name")
    eq(tab.buyAttractors:GetChecked(), false, "the Attractor's box is its own")
    check(math.abs(tab.buyAttractors.label.__textColor[1] - ns.Widgets.COLORS.accent[1]) < 0.01
        and math.abs(tab.buyAttractors.label.__textColor[3] - ns.Widgets.COLORS.accent[3]) < 0.01,
        "and is written in the accent colour, to stand apart")
    -- One lure at a time: choosing another takes the first one's place
    tab.buyLure.onSelect(BRIGHT)
    eq(settings.buyLureItems[BRIGHT], true, "a lure chosen from the list is the lure to buy")
    eq(settings.buyLureItems[CRAWLERS], nil, "and the one before it no longer is")
    eq(Vendor.Chosen().name, "Bright Baubles", "one lure is chosen")
    eq(tab.buyLure.label:GetText(), "Bright Baubles", "and shown")
    Vendor.Choose(nil)
    ns.UI.Refresh()
    eq(Vendor.Chosen(), nil, "none chosen")
    eq(tab.buyLure.label:GetText(), "Choose a lure", "the list says to choose one")
    -- Several from before, when more than one could be ticked: the strongest shows
    settings.buyLureItems = { [BAUBLE] = true, [BRIGHT] = true }
    eq(Vendor.Chosen().name, "Bright Baubles", "of several ticked before, the strongest is the one shown")
    Vendor.Choose(CRAWLERS)
    ns.UI.Refresh()
    -- Typing a number
    tab.buyLureCount:SetText("35")
    tab.buyLureCount:GetScript("OnTextChanged")(tab.buyLureCount)
    eq(settings.buyLureCount, 35, "a number typed in is the number")
    tab.buyLureCount:SetText("")
    tab.buyLureCount:GetScript("OnTextChanged")(tab.buyLureCount)
    eq(settings.buyLureCount, 35, "an empty box changes nothing")
    eq(tab.buyLureFloor:GetText(), "0", "the gold limit shows")
    tab.buyLureFloor:SetText("250")
    tab.buyLureFloor:GetScript("OnTextChanged")(tab.buyLureFloor)
    eq(settings.buyLureFloor, 250, "gold typed in is the limit")
    -- Maintain, or a flat number every visit
    eq(tab.buyLureMaintain:GetChecked(), true, "Maintain is ticked to begin with")
    eq(tab.buyLureCountLabel:GetText(), "in my bags at all times", "and the number is what to keep")
    tab.buyLureMaintain:SetChecked(false)
    tab.buyLureMaintain:GetScript("OnClick")(tab.buyLureMaintain)
    eq(settings.buyLureFlat, true, "unticked: a flat number")
    eq(tab.buyLureCountLabel:GetText(), "at every vendor visit", "and the number says so")
    settings.buyLureCount, settings.buyLureFloor, settings.buyAttractors = 5, 0, false
    Vendor.Choose(BRIGHT)
    Stub.purchases = {}
    Stub.bags = { [BRIGHT] = 50 }
    Stub.money = 100000
    Stub.advance(11)
    Stub.openMerchant(Supplier())
    eq(Bought(BRIGHT), 5, "flat: that many are bought whatever is in the bags")
    Stub.openMerchant(Supplier())
    eq(Bought(BRIGHT), 10, "and again at the next visit")
    Stub.slowDelivery = true
    Stub.openMerchant(Supplier())
    Stub.fire("MERCHANT_SHOW")
    eq(Bought(BRIGHT), 15, "but the window sent twice in a row is one visit")
    Stub.deliver()
    Stub.slowDelivery = nil
    tab.buyLureMaintain:SetChecked(true)
    tab.buyLureMaintain:GetScript("OnClick")(tab.buyLureMaintain)
    eq(settings.buyLureFlat, false, "ticked again: maintain")
    Stub.openMerchant(Supplier())
    eq(Bought(BRIGHT), 15, "with more than the number in the bags, maintain buys nothing")
    -- Ticking the Attractor's box
    tab.buyAttractors:SetChecked(true)
    tab.buyAttractors:GetScript("OnClick")(tab.buyAttractors)
    eq(settings.buyAttractors, true, "and the Attractor's box its own setting")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
