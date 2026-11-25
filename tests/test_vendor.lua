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
    -- More than that: bought as usual
    Stub.money = 100001
    Stub.openMerchant(Supplier())
    eq(Stub.bags[BRIGHT], 20, "a copper more than was set: the lures are bought")
    eq(Stub.bags[ATTRACTOR], 2, "and the Attractors")
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
        if frame.buyLureChecks then tab = frame end
    end
    check(tab ~= nil, "the Gear & food tab has the lure buying on it")
    eq(#tab.buyLureChecks, 5, "a tick box for each of the five lures")
    eq(tab.buyLures:GetChecked(), true, "the switch shows it is on")
    eq(tab.buyLureCount:GetText(), "20", "the number shows")
    eq(tab.buyLureChecks[2]:GetChecked(), true, "the ticked lure is ticked")
    eq(tab.buyLureChecks[1]:GetChecked(), false, "the others are not")
    eq(tab.buyLureChecks[3].label:GetText(), "Aquadynamic Fish Lens", "each named")
    eq(tab.buyAttractors:GetChecked(), false, "the Attractor's box is its own")
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
    -- Ticking
    tab.buyLureChecks[4]:SetChecked(true)
    tab.buyLureChecks[4]:GetScript("OnClick")(tab.buyLureChecks[4])
    eq(settings.buyLureItems[BRIGHT], true, "ticking a lure's box ticks the lure")
    tab.buyAttractors:SetChecked(true)
    tab.buyAttractors:GetScript("OnClick")(tab.buyAttractors)
    eq(settings.buyAttractors, true, "and the Attractor's box its own setting")

    for _, err in ipairs(Stub.errors) do
        check(false, "error caught: " .. err)
    end
end

return T
