-- A stand-in for the game, just enough of it to load Keepnet outside World of Warcraft and
-- walk it through a fishing session: frames that remember their scripts, game events, timers on
-- a clock the test moves by hand, game settings, key bindings, bags, loot and a fake Auctionator.
--
-- It models how the game behaves as far as is known. It is NOT the game: a pass here means the
-- addon's own logic holds together, not that the client agrees.
Stub = {
    now = 1000,            -- GetTime()
    epoch = 1795000000,    -- time()
    timers = {},
    frames = {},
    errors = {},           -- what the addon's error handler caught
    chat = {},
    missing = {},          -- undefined globals the addon read (old-client fallbacks, or typos)
    bindings = {},         -- owner -> { key -> binding }
    lockdown = false,      -- combat lock
    useKeyDown = true,     -- the game's "act on key down" setting
    zone = "Tanaris",
    subzone = "",
    mainHand = nil,
    bags = {},             -- itemID -> count
    channel = nil,
    casting = nil,
    enchantUntil = nil,
    loot = nil,
    fishingLoot = false,
    nextLoot = nil,
    addons = {},
    auction = {},          -- itemID -> copper
    auctionAge = {},
    used = {},             -- lures applied, in order
    equipped = {},         -- inventory slot -> itemID (the main hand is Stub.mainHand)
    auras = {},            -- buffs on the player
    usedItems = {},        -- food and buff items used, in order
    toys = {},             -- itemID -> true for toys the character has
    sounds = {},           -- sounds the addon played
    soundFiles = {},       -- sound files the addon played, by path
    files = {},            -- path -> true for sound files that exist
    missingKits = {},      -- sound kit number -> true for game sounds this client lacks
    sharedMedia = nil,     -- name -> path, when another addon has loaded LibSharedMedia
    class = "MAGE",
    uiScale = 0.64,        -- the interface's own scale
    looted = {},           -- loot slots the addon picked up
    confirmed = {},        -- "this item will bind" questions the addon answered
    mouseFocus = nil,      -- the frame under the mouse
    keepLootOpen = false,  -- the loot window stays open after a catch (auto-loot off)
    screen = {},           -- messages in the middle of the screen
    slotCooldown = {},     -- inventory slot -> time its use-effect is ready again
    skill = { 187, 225, 105 }, -- Fishing: trained, cap, temporary bonus
    SECRET = {},           -- a value the game hides from addons
    money = 50000,         -- the character's coins, in copper
    lootSource = nil,      -- the GUID the open loot comes from
    guidItems = {},        -- item GUID -> item ID
    guidSilent = false,    -- the game won't say which item a GUID is
    noLootSource = false,  -- the game won't say where loot comes from
    staleBags = false,     -- an opened item leaves the bags late (see Stub.open)
    owedBags = {},
}
ITEM_OPENABLE = "<Right Click to Open>"

local POLE = 6256
Stub.POLE = POLE

Stub.items = {
    -- name, quality, sell price, class, subclass, bind type, tooltip lines
    [POLE] = { "Fishing Pole", 1, 4, 2, 20, 0, { { leftText = "Fishing Pole" }, { leftText = "Two-Hand" } } },
    [6365] = { "Strong Fishing Pole", 1, 180, 2, 20, 0, { { leftText = "Strong Fishing Pole" }, { leftText = "Equip: Increased Fishing +5." } } },
    [6529] = { "Shiny Bauble", 1, 12, 0, 8, 0, { { leftText = "Use: When applied to your fishing pole, increases Fishing by 25 for 10 min." } } },
    [6530] = { "Nightcrawlers", 1, 25, 0, 8, 0, { { leftText = "Use: When applied to your fishing pole, increases Fishing by 50 for 10 min." } } },
    [6532] = { "Bright Baubles", 1, 62, 0, 8, 0, {
        { leftText = "Requires Fishing (100)", leftColor = { r = 1, g = 0.125, b = 0.125 } },
        { leftText = "Use: When applied to your fishing pole, increases Fishing by 75 for 10 min." },
    } },
    [13422] = { "Stonescale Eel", 1, 40, 7, 8, 0 },
    [13756] = { "Raw Summer Bass", 1, 5, 7, 8, 0 },
    [6303] = { "Raw Slitherskin Mackerel", 1, 1, 7, 8, 0 },
    [4500] = { "Tangled Fishing Line", 0, 33, 15, 0, 0 },    -- grey
    [19807] = { "Speckled Tastyfish", 1, 0, 12, 0, 1 },      -- binds when picked up, no vendor price
    [7973] = { "Big-mouth Clam", 1, 0, 15, 0, 0 },           -- nobody buys it
    [6292] = { "10 Pound Mud Snapper", 1, 60, 15, 0, 0 },     -- a trophy fish: white, like in the game
    [2000] = { "Shiny Green Thing", 2, 60, 15, 0, 0 },          -- green, on no list
    [8350] = { "The 1 Ring", 2, 250, 4, 0, 2 },
    [6307] = { "Message in a Bottle", 1, 0, 12, 0, 0 },
    [6355] = { "Sturdy Locked Chest", 1, 0, 15, 0, 0 },
    [21113] = { "Watertight Trunk", 1, 0, 15, 0, 0 },
    [286266] = { "Antonidas' Silver Coin", 0, 100, 15, 0, 0 },   -- grey, and a rarity
    -- Things that come out of opened catches. The clam (7973, above) has no tooltip of its own
    -- there; this one says it opens.
    [5523] = { "Small Barnacled Clam", 1, 3, 15, 0, 0, { { leftText = "Small Barnacled Clam" }, { leftText = "<Right Click to Open>" } } },
    [5503] = { "Clam Meat", 1, 4, 7, 8, 0 },
    [5498] = { "Small Lustrous Pearl", 2, 50, 7, 8, 0 },
    [3860] = { "Mithril Bar", 1, 250, 7, 8, 0 },
    [4338] = { "Mageweave Cloth", 1, 62, 7, 8, 0 },
    -- Clothing: the eighth field says where it goes
    [10000] = { "Plain Helm", 1, 50, 4, 4, 0, { { leftText = "Plain Helm" } }, { equipLoc = "INVTYPE_HEAD" } },
    [10001] = { "Plain Gloves", 1, 50, 4, 2, 0, { { leftText = "Plain Gloves" } }, { equipLoc = "INVTYPE_HAND" } },
    [19972] = { "Lucky Fishing Hat", 3, 0, 4, 1, 1, {
        { leftText = "Lucky Fishing Hat" }, { leftText = "Equip: Increased Fishing +5." },
    }, { equipLoc = "INVTYPE_HEAD" } },
    [19969] = { "Nat Pagle's Extreme Anglin' Boots", 3, 0, 4, 2, 1, {
        { leftText = "Nat Pagle's Extreme Anglin' Boots" }, { leftText = "Equip: Increased Fishing +5." },
    }, { equipLoc = "INVTYPE_FEET" } },
    [15405] = { "Shimmering Gloves", 2, 90, 4, 1, 0, {
        { leftText = "Shimmering Gloves" }, { leftText = "Fishing +2" },
    }, { equipLoc = "INVTYPE_HAND" } },
    [99001] = { "Master Angler's Cap", 4, 0, 4, 1, 1, {
        { leftText = "Master Angler's Cap" },
        { leftText = "Requires Fishing (300)", leftColor = { r = 1, g = 0.125, b = 0.125 } },
        { leftText = "Equip: Increased Fishing +20." },
    }, { equipLoc = "INVTYPE_HEAD" } },
    -- A hat whose use puts a lure on the pole; it has to be worn to be used
    [259846] = { "Wide-Brimmed Fishing Hat", 2, 0, 4, 1, 1, {
        { leftText = "Wide-Brimmed Fishing Hat" },
        { leftText = "Use: When applied to your fishing pole, increases Fishing by 25 for 10 min. (10 Min Cooldown)" },
    }, { equipLoc = "INVTYPE_HEAD", wornLure = true } },
    -- Food and buff items: the eighth field says what using them does
    [4594] = { "Rockscale Cod", 1, 6, 0, 5, 0, { { leftText = "Use: Restores 874 health over 27 sec. Must remain seated while eating. If you spend at least 10 seconds eating you will become well fed and gain 12 Fishing skill for 15 min." } },
        { use = { spell = 5004, name = "Well Fed", minutes = 15, eat = true, consume = true, text = "Fishing skill increased by 12." } } },
    [5476] = { "Fillet of Frenzy", 1, 2, 0, 5, 0, { { leftText = "Use: Restores 243 health over 21 sec. Must remain seated while eating. If you spend at least 10 seconds eating you will become well fed and gain 5 Fishing skill for 15 min." } },
        { use = { spell = 5005, name = "Well Fed", minutes = 15, eat = true, consume = true, text = "Fishing skill increased by 5." } } },
    [286732] = { "Shiny Silver Coin", 1, 0, 15, 0, 1, { { leftText = "Use: Increases your Fishing skill by 30 for 30 min." } },
        { use = { spell = 1321323, name = "Shiny Silver Coin", minutes = 30, consume = true, text = "Increases your Fishing skill by 30." } } },
    -- A toy: not in the bags, and its buff says nothing about fishing
    [276274] = { "Surfer Shoes", 2, 0, 15, 0, 1, { { leftText = "Use: Walk on water for 5 min." } },
        { use = { spell = 5200, name = "Surfing", minutes = 5, toy = true, text = "Walking on water." } } },
}

function Stub.link(id)
    return ("|cffffffff|Hitem:%d::::::::60:::::|h[%s]|h|r"):format(id, Stub.items[id][1])
end

-- ------------------------------------------------------------------------------------- clock
function GetTime() return Stub.now end
function time() return math.floor(Stub.epoch) end
date = os.date

C_Timer = {}
local function AddTimer(delay, fn, repeating)
    local timer = { at = Stub.now + delay, fn = fn, every = repeating and delay or nil }
    function timer:Cancel() self.cancelled = true end
    Stub.timers[#Stub.timers + 1] = timer
    return timer
end
function C_Timer.After(delay, fn) AddTimer(delay, fn) end
function C_Timer.NewTimer(delay, fn) return AddTimer(delay, fn) end
function C_Timer.NewTicker(delay, fn) return AddTimer(delay, fn, true) end

-- Moves the clock on, running every timer that falls due, in order
function Stub.advance(seconds)
    local target = Stub.now + seconds
    while true do
        local nextIndex
        for i, timer in ipairs(Stub.timers) do
            if not timer.cancelled and timer.at <= target
                and (not nextIndex or timer.at < Stub.timers[nextIndex].at) then
                nextIndex = i
            end
        end
        if not nextIndex then break end
        local timer = Stub.timers[nextIndex]
        Stub.epoch = Stub.epoch + (timer.at - Stub.now)
        Stub.now = timer.at
        if timer.every then
            timer.at = timer.at + timer.every
        else
            table.remove(Stub.timers, nextIndex)
        end
        timer.fn(timer)
    end
    Stub.epoch = Stub.epoch + (target - Stub.now)
    Stub.now = target
end

-- ------------------------------------------------------------------------------------ frames
-- Every widget method the addon calls must be named here: an unknown name is an error, which
-- catches a misspelt method.
local QUIET = {}
for name in ([[
    SetPoint ClearAllPoints SetAllPoints
    SetFrameStrata SetFrameLevel SetClampedToScreen SetMovable EnableMouse
    EnableMouseWheel RegisterForDrag RegisterForClicks StartMoving
    StopMovingOrSizing SetJustifyH SetWordWrap
    SetDesaturated SetCheckedTexture SetThumbTexture SetOrientation SetMinMaxValues SetValueStep
    SetObeyStepOnDrag SetHitRectInsets SetOwner AddLine SetHyperlink SetItemByID
    SetAutoFocus SetTextInsets SetMaxLetters ClearFocus SetPropagateKeyboardInput
    SetTexCoord SetBlendMode GenerateMenu
    SetShadowColor SetShadowOffset SetClipsChildren SetHighlightColor
]]):gmatch("%S+") do
    QUIET[name] = true
end

local Methods = {}
local MockMeta = {}
MockMeta.__index = function(_, key)
    local method = Methods[key]
    if method then return method end
    if QUIET[key] then return function() end end
    if type(key) == "string" and key:match("^%u") then
        error("unknown widget method: " .. key, 2)
    end
    return nil
end

local function Mock(kind, name, parent)
    local frame = setmetatable({
        __kind = kind, __name = name, __parent = parent, __scripts = {}, __events = {},
        __attrs = {}, __shown = true, __text = "",
    }, MockMeta)
    Stub.frames[#Stub.frames + 1] = frame
    return frame
end

function Methods:SetScript(name, fn) self.__scripts[name] = fn end
function Methods:GetScript(name) return self.__scripts[name] end
function Methods:RegisterEvent(event) self.__events[event] = true end
Methods.RegisterUnitEvent = Methods.RegisterEvent
function Methods:UnregisterEvent(event) self.__events[event] = nil end
-- The mouse is over one frame at most: the one a test names in Stub.mouseOver
function Methods:IsMouseOver() return Stub.mouseOver == self end
-- The interface root can't be hidden or shown once combat has locked the interface
local function RootLocked(frame, what)
    if frame == UIParent and Stub.lockdown then
        Stub.errors[#Stub.errors + 1] = "interface root " .. what .. " in combat"
        return true
    end
end
function Methods:Show()
    if RootLocked(self, "shown") then return end
    local was = self.__shown
    self.__shown = true
    if not was and self.__scripts.OnShow then self.__scripts.OnShow(self) end
end
function Methods:Hide()
    if RootLocked(self, "hidden") then return end
    local was = self.__shown
    self.__shown = false
    if was and self.__scripts.OnHide then self.__scripts.OnHide(self) end
end
function Methods:HookScript(name, fn)
    local old = self.__scripts[name]
    self.__scripts[name] = function(...)
        if old then old(...) end
        fn(...)
    end
end
function Methods:SetParent(parent) self.__parent = parent end
function Methods:GetParent() return self.__parent end
function Methods:SetAlpha(alpha) self.__alpha = alpha end
function Methods:GetAlpha() return self.__alpha or 1 end
function Methods:GetEffectiveScale() return self == UIParent and Stub.uiScale or 1 end
function Methods:GetWidth() return self.__width or (self == UIParent and 1600 or 200) end
function Methods:SetWidth(width) self.__width = width end
function Methods:GetFrameLevel() return 1 end
-- Whether the frame takes the mouse wheel: setting a wheel script turns it on, as in the game
function Methods:EnableMouseWheel(on) self.__wheel = on and true or false end
function Methods:EnableKeyboard(on) self.__keyboard = on end
function Methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Methods:IsShown() return self.__shown end
function Methods:SetText(text) self.__text = text end
function Methods:GetText() return self.__text end
function Methods:GetStringWidth() return #tostring(self.__text or "") * 6 end
function Methods:SetAttribute(key, value) self.__attrs[key] = value end
function Methods:GetAttribute(key) return self.__attrs[key] end
function Methods:SetChecked(checked) self.__checked = checked end
function Methods:GetChecked() return self.__checked end
function Methods:SetValue(value)
    self.__value = value
    if self.__scripts.OnValueChanged then self.__scripts.OnValueChanged(self, value, false) end
end
function Methods:GetValue() return self.__value end
function Methods:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
-- Every place a frame was put, in order: frame.__placed = { { point, relativeTo,
-- relativePoint, x, y }, ... }. (GetLeft and GetTop don't follow it: they are fixed.)
function Methods:SetPoint(...)
    self.__placed = self.__placed or {}
    self.__placed[#self.__placed + 1] = { ... }
end
function Methods:SetBackdropColor(r, g, b, a) self.__backdrop = { r, g, b, a } end
function Methods:SetBackdropBorderColor(r, g, b, a) self.__border = { r, g, b, a } end
function Methods:SetBackdrop(backdrop) self.__backdropFile = backdrop and backdrop.bgFile end
function Methods:SetColorTexture(r, g, b, a) self.__color = { r, g, b, a } end
-- What a text or a picture was last given, for the tests of the looks
function Methods:SetTextColor(r, g, b, a) self.__textColor = { r, g, b, a } end
function Methods:GetTextColor()
    local color = self.__textColor or { 1, 1, 1, 1 }
    return color[1], color[2], color[3], color[4]
end
function Methods:SetVertexColor(r, g, b, a) self.__vertex = { r, g, b, a } end
function Methods:SetTexture(texture) self.__texture = texture end
-- A texture that goes from one colour to another: { orientation, from, to }
function Methods:SetGradient(orientation, from, to) self.__gradient = { orientation, from, to } end
-- A font: the file it is drawn from, its size and its flags; and the font a text was given
function Methods:SetFont(file, size, flags) self.__font = { file, size, flags } end
function Methods:GetFont()
    local font = self.__font or {}
    return font[1], font[2], font[3]
end
function Methods:SetFontObject(font) self.__fontObject = font end
function Methods:SetScale(scale) self.__scale = scale end
function Methods:GetLeft() return 400 end
function Methods:GetTop() return 600 end
function Methods:GetBottom() return self.__bottom or 500 end
function Methods:SetHeight(height) self.__height = height end
function Methods:GetHeight() return self.__height or (self == UIParent and 900 or 40) end
function Methods:SetSize(width, height) self.__width, self.__height = width, height end
function Methods:GetName() return self.__name end
function Methods:CreateFontString() return Mock("FontString", nil, self) end
function Methods:CreateTexture() return Mock("Texture", nil, self) end
function Methods:AddMessage(text) Stub.chat[#Stub.chat + 1] = text end

-- The game's own frame templates that exist on this client, and the named parts each gives a
-- frame. A template that isn't listed makes CreateFrame fail, as in the game.
Stub.templates = {
    BackdropTemplate = {},
    SecureActionButtonTemplate = {},
    BasicFrameTemplateWithInset = { "TitleText", "CloseButton", "Bg", "InsetBg", "Inset" },
    UIPanelButtonTemplate = { "Text" },
    UICheckButtonTemplate = { "Text" },
    OptionsSliderTemplate = { "Low", "High", "Text" },
    InputBoxTemplate = {},
    WowStyle1DropdownTemplate = {},
    PanelTabButtonTemplate = { "Text" },
}
function DoesTemplateExist(template) return Stub.templates[template] ~= nil end

-- A font of an addon's own
function CreateFont(name)
    local font = Mock("Font", name)
    _G[name] = font
    return font
end
-- A colour as the game hands them about
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
-- The language of the client: a test names another in Stub.locale
function GetLocale() return Stub.locale or "enUS" end
-- The game's own fonts that the addon's texts are made in
for name, size in pairs({
    GameFontHighlightSmall = 10, GameFontNormalSmall = 10, GameFontDisableSmall = 10,
    GameFontNormal = 12, GameFontHighlight = 12, GameFontDisable = 12, GameFontNormalLarge = 16,
}) do
    local font = Mock("Font", name)
    font.__font = { "Fonts\\FRIZQT__.TTF", size, "" }
    -- White, the game's gold, or grey
    font.__textColor = name:find("Normal") and { 1, 0.82, 0, 1 } or name:find("Disable") and { 0.5, 0.5, 0.5, 1 } or { 1, 1, 1, 1 }
    _G[name] = font
end
-- A copy takes the colour of what it copies, as in the game
function Methods:CopyFontObject(source)
    if source and source.__textColor then
        self.__textColor = { source.__textColor[1], source.__textColor[2], source.__textColor[3], source.__textColor[4] }
    end
end

function CreateFrame(kind, name, parent, template)
    if template and not Stub.templates[template] then
        error("Couldn't find inherited node: " .. tostring(template))
    end
    local frame = Mock(kind, name, parent)
    frame.__template = template
    for _, part in ipairs(template and Stub.templates[template] or {}) do
        frame[part] = Mock("Region", nil, frame)
    end
    if name then _G[name] = frame end
    return frame
end

-- The game's menu for a drop-down: remembers how to build itself; a test opens it with
-- Stub.menu(dropdown), which returns the entries, each with a pick() to choose it
function Methods:SetupMenu(generator) self.__menu = generator end
function Methods:SetDefaultText(text) self.__defaultText = text end
function Methods:GetFontString()
    if not self.__fontString then self.__fontString = Mock("FontString", nil, self) end
    return self.__fontString
end
function Stub.menu(dropdown)
    local entries = {}
    local description = {}
    function description:SetScrollMode(height) entries.scroll = height end
    function description:CreateRadio(text, isSelected, setSelected, value)
        entries[#entries + 1] = {
            text = text, value = value, selected = isSelected(value) and true or false,
            pick = function() setSelected(value) end,
        }
    end
    dropdown.__menu(dropdown, description)
    return entries
end
Stub.selectedTabs = {}
function PanelTemplates_SelectTab(tab) Stub.selectedTabs[tab] = true end
function PanelTemplates_DeselectTab(tab) Stub.selectedTabs[tab] = nil end
function PanelTemplates_TabResize() end
Stub.reloads = 0
function ReloadUI() Stub.reloads = Stub.reloads + 1 end

-- Shown, and so is everything it sits in
function Stub.visible(frame)
    while frame do
        if not frame.__shown then return false end
        frame = frame.__parent
    end
    return true
end

function Stub.fire(event, ...)
    for _, frame in ipairs(Stub.frames) do
        if frame.__events[event] and frame.__scripts.OnEvent then
            frame.__scripts.OnEvent(frame, event, ...)
        end
    end
end

UIParent = Mock("Frame", "UIParent")
WorldFrame = Mock("Frame", "WorldFrame")
-- A little of the game's own interface, and another addon's bar that no list knows about
for _, name in ipairs({ "MinimapCluster", "PlayerFrame", "ChatFrame1", "MainMenuBar", "OtherAddonBar" }) do
    _G[name] = Mock("Frame", name, UIParent)
end
OtherAddonBarButton1 = Mock("Button", "OtherAddonBarButton1", OtherAddonBar)
-- An interface suite: one whole-screen container holding its bars
SuiteParent = Mock("Frame", "SuiteParent", UIParent)
SuiteParent.__width, SuiteParent.__height = 1600, 900
SuiteBar = Mock("Frame", "SuiteBar", SuiteParent)
SuiteBarButton3 = Mock("Button", "SuiteBarButton3", SuiteBar)
-- The game's own switch for the whole interface. Hiding is refused once combat has locked the
-- interface; showing is allowed even then, unless Stub.showBlockedInCombat says this client
-- differs.
function SetUIVisibility(visible)
    if Stub.lockdown and (not visible or Stub.showBlockedInCombat) then
        error("blocked in combat")
    end
    local was = UIParent.__shown
    UIParent.__shown = visible and true or false
    local script = UIParent.__scripts[visible and "OnShow" or "OnHide"]
    if was ~= UIParent.__shown and script then script(UIParent) end
end
function GetMouseFoci() return { Stub.mouseFocus } end
function LootSlot(slot) Stub.looted[#Stub.looted + 1] = slot end
function ConfirmLootSlot(slot) Stub.confirmed[#Stub.confirmed + 1] = slot end
GameTooltip = Mock("GameTooltip", "GameTooltip")
DEFAULT_CHAT_FRAME = Mock("Frame", "ChatFrame1")
UIErrorsFrame = { AddMessage = function(_, text) Stub.screen[#Stub.screen + 1] = text end }
UISpecialFrames = {}
SlashCmdList = {}
StaticPopupDialogs = {}
YES, NO = "Yes", "No"
NUM_BAG_SLOTS = 4
ITEM_QUALITY_COLORS = { [0] = { hex = "|cff9d9d9d" }, [1] = { hex = "|cffffffff" }, [2] = { hex = "|cff1eff00" } }

-- Answers Yes straight away
function StaticPopup_Show(which, _, _, data)
    Stub.popup = which
    StaticPopupDialogs[which].OnAccept(nil, data)
end

function geterrorhandler()
    return function(err) Stub.errors[#Stub.errors + 1] = tostring(err) end
end

function issecretvalue(value) return value == Stub.SECRET end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
-- The mouse: where a test puts it (in screen measure), and whether its left button is held
Stub.cursor = { 0, 0 }
Stub.mouseDown = false
function GetCursorPosition() return Stub.cursor[1], Stub.cursor[2] end
function IsMouseButtonDown() return Stub.mouseDown end
function GetCursorInfo() return nil end
function ClearCursor() end

-- ---------------------------------------------------------------------------- player and world
-- Who is playing. On the Forever client the realm has no name ("") and UnitName gives a
-- surname as its second value; a test that wants that sets Stub.realm and Stub.player.surname.
-- UnitGUID and UnitLevel are not defined here: a test about characters defines them itself.
Stub.player = { name = "Tester" }
Stub.realm = "Realm"
function UnitName() return Stub.player.name, Stub.player.surname end
function GetRealmName() return Stub.realm end
function GetRealZoneText() return Stub.zone end
function GetSubZoneText() return Stub.subzone end
function InCombatLockdown() return Stub.lockdown end
function UnitChannelInfo() return Stub.channel end
function UnitCastingInfo() return Stub.casting end
function GetInventoryItemID(_, slot)
    if slot == 16 then return Stub.mainHand end
    return Stub.equipped[slot]
end
function GetInventoryItemLink(unit, slot)
    local id = GetInventoryItemID(unit, slot)
    return id and Stub.link(id) or nil
end
function GetInventoryItemCooldown(_, slot)
    local ready = Stub.slotCooldown[slot]
    if ready and ready > Stub.now then return ready - 600, 600, 1 end
    return 0, 0, 1
end
function GetProfessions() return nil, nil, nil, 9 end
function GetProfessionInfo(index)
    if index == 9 then return "Fishing", 0, Stub.skill[1], Stub.skill[2], 0, 0, 356, Stub.skill[3] end
end
function PlayerHasToy(id) return Stub.toys[id] or false end
-- Both return whether the game will play it
function PlaySound(kit, channel)
    if Stub.missingKits[kit] then return false end
    Stub.sounds[#Stub.sounds + 1] = { kit = kit, channel = channel }
    return true, 1
end
function PlaySoundFile(path, channel)
    if not Stub.files[path] then return false end
    Stub.soundFiles[#Stub.soundFiles + 1] = { path = path, channel = channel }
    return true, 1
end
function UnitClass() return "Mage", Stub.class end
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
-- Another addon's LibSharedMedia, when Stub.sharedMedia (sounds: name -> path) or
-- Stub.sharedFonts (fonts: name -> path) is set. What asks to hear of newly shared media is
-- kept in Stub.mediaCallback.
function LibStub(name)
    if name ~= "LibSharedMedia-3.0" or not (Stub.sharedMedia or Stub.sharedFonts) then return nil end
    local function Of(kind)
        return (kind == "font" and Stub.sharedFonts or kind ~= "font" and Stub.sharedMedia) or {}
    end
    local media = {}
    function media:List(kind)
        local names = {}
        for key in pairs(Of(kind)) do names[#names + 1] = key end
        table.sort(names)
        return names
    end
    function media:Fetch(kind, key) return Of(kind)[key] end
    function media.RegisterCallback(_, event, fn)
        if event == "LibSharedMedia_Registered" then Stub.mediaCallback = fn end
    end
    return media
end
-- The colour picker: remembers what it was asked, so a test can pick or cancel
ColorPickerFrame = { picked = { 1, 1, 1 } }
function ColorPickerFrame:SetupColorPickerAndShow(info) self.info = info end
function ColorPickerFrame:GetColorRGB() return unpack(self.picked) end
SOUNDKIT = { RAID_WARNING = 8959 }
C_Secrets = { ShouldAurasBeSecret = function() return Stub.lockdown end }
function GetWeaponEnchantInfo()
    if Stub.enchantUntil and Stub.enchantUntil > Stub.now then
        return true, (Stub.enchantUntil - Stub.now) * 1000
    end
    return false
end

C_AddOns = { IsAddOnLoaded = function(name) return Stub.addons[name] or false end }
-- Lines of the addon's TOC file, by field name ("X-Keepnet-Build" = "dev" for a development copy)
Stub.metadata = {}
function C_AddOns.GetAddOnMetadata(_, field) return Stub.metadata[field] end

-- ------------------------------------------------------------------ chat channels, addon messages
-- Stub.gameChannels: the game's own channels the character is in (they join a while after
-- login in the real game; a test empties the list to model that). Stub.channels: the custom
-- channels joined, in order; their numbers follow the game's. Stub.sent: every addon message
-- sent, { prefix, text, kind, target }. Stub.chatLocked: the game holds chat back.
Stub.gameChannels = { "General", "Trade" }
Stub.channels = {}
Stub.hiddenChannels = {}
Stub.sent = {}
Stub.prefixes = {}
Stub.chatLocked = false
Stub.guild, Stub.group, Stub.raid = false, false, false
NUM_CHAT_WINDOWS = 10
C_ChatInfo = {}
function C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    Stub.prefixes[prefix] = true
    return true
end
function C_ChatInfo.InChatMessagingLockdown() return Stub.chatLocked end
function C_ChatInfo.SendAddonMessage(prefix, text, kind, target)
    if type(prefix) ~= "string" or #prefix > 16 then error("bad addon message prefix") end
    if type(text) ~= "string" or #text > 255 then error("bad addon message") end
    if Stub.chatLocked then return 9 end
    if kind == "CHANNEL" and (type(target) ~= "number" or target <= #Stub.gameChannels) then return 5 end
    Stub.sent[#Stub.sent + 1] = { prefix = prefix, text = text, kind = kind, target = target }
    return 0
end
function GetChannelList()
    local list = {}
    for index, name in ipairs(Stub.gameChannels) do
        list[#list + 1], list[#list + 2], list[#list + 3] = index, name, false
    end
    for index, name in ipairs(Stub.channels) do
        list[#list + 1], list[#list + 2], list[#list + 3] = #Stub.gameChannels + index, name, false
    end
    return unpack(list)
end
function GetChannelName(name)
    for index, joined in ipairs(Stub.channels) do
        if joined:lower() == tostring(name):lower() then return #Stub.gameChannels + index, joined, 0 end
    end
    return 0, nil, 0
end
function JoinTemporaryChannel(name)
    if GetChannelName(name) == 0 then Stub.channels[#Stub.channels + 1] = name end
end
function LeaveChannelByName(name)
    for index, joined in ipairs(Stub.channels) do
        if joined:lower() == tostring(name):lower() then table.remove(Stub.channels, index) end
    end
end
function RemoveChatWindowChannel(window, name) Stub.hiddenChannels[name] = (Stub.hiddenChannels[name] or 0) + 1 end
function IsInGuild() return Stub.guild end
function IsInGroup() return Stub.group or Stub.raid end
function IsInRaid() return Stub.raid end
C_Spell = { GetSpellName = function(id)
    if id == 7620 or id == 18248 then return "Fishing" end
    return "Spell " .. tostring(id)
end }

-- ------------------------------------------------------------------------------------- items
local function ItemID(item)
    if type(item) == "number" then return item end
    return tonumber(tostring(item):match("item:(%d+)"))
end

C_Item = {}
function C_Item.GetItemInfo(item)
    local id = ItemID(item)
    local info = id and Stub.items[id]
    if not info then return nil end
    -- name, link, quality, level, minLevel, type, subType, stack, equipLoc, icon, sellPrice,
    -- classID, subclassID, bindType
    return info[1], Stub.link(id), info[2], 1, 1, "", "", 20, "", 100000 + id, info[3], info[4], info[5], info[6]
end
function C_Item.GetItemInfoInstant(item)
    local id = ItemID(item)
    local info = id and Stub.items[id]
    if not info then return nil end
    return id, "", "", info[8] and info[8].equipLoc or "", 100000 + id, info[4], info[5]
end
-- Swaps a bag item into a slot; what was there goes to the bags
function C_Item.EquipItemByName(item, slot)
    local id = ItemID(item)
    if Stub.lockdown then
        Stub.errors[#Stub.errors + 1] = "clothing changed in combat"
        return
    end
    if not id or (Stub.bags[id] or 0) <= 0 then return end
    local previous = Stub.equipped[slot]
    Stub.bags[id] = Stub.bags[id] - 1
    if previous then Stub.bags[previous] = (Stub.bags[previous] or 0) + 1 end
    Stub.equipped[slot] = id
    Stub.fire("PLAYER_EQUIPMENT_CHANGED", slot, true)
    Stub.fire("BAG_UPDATE_DELAYED")
end
function C_Item.GetItemCount(item) return Stub.bags[ItemID(item)] or 0 end
function C_Item.GetItemIconByID(item) return 100000 + ItemID(item) end

C_Container = {}
local function BagList()
    local list = {}
    for id, count in pairs(Stub.bags) do
        if count > 0 then list[#list + 1] = id end
    end
    table.sort(list)
    return list
end
function C_Container.GetContainerNumSlots(bag) return bag == 0 and #BagList() or 0 end
function C_Container.GetContainerItemID(bag, slot) return bag == 0 and BagList()[slot] or nil end
function C_Container.GetContainerItemLink(bag, slot)
    local id = C_Container.GetContainerItemID(bag, slot)
    return id and Stub.link(id) or nil
end
function C_Container.GetItemCooldown() return 0, 0, 1 end

C_TooltipInfo = { GetItemByID = function(id)
    local info = Stub.items[id]
    return info and { lines = info[7] or {} } or nil
end }
function C_TooltipInfo.GetBagItem(bag, slot)
    return C_TooltipInfo.GetItemByID(C_Container.GetContainerItemID(bag, slot))
end
function C_TooltipInfo.GetInventoryItem(unit, slot)
    local id = GetInventoryItemID(unit, slot)
    return id and C_TooltipInfo.GetItemByID(id) or nil
end
function C_TooltipInfo.GetUnitBuffByAuraInstanceID(_, instance)
    for _, aura in ipairs(Stub.auras) do
        if aura.auraInstanceID == instance then
            return { lines = { { leftText = aura.name }, { leftText = aura.text } } }
        end
    end
end

-- Buffs: the ones that haven't run out
C_UnitAuras = {}
function C_UnitAuras.GetBuffDataByIndex(_, index)
    local n = 0
    for _, aura in ipairs(Stub.auras) do
        if aura.expirationTime > Stub.now then
            n = n + 1
            if n == index then return aura end
        end
    end
end
local nextAura = 0
function Stub.addAura(spellId, name, seconds, text)
    nextAura = nextAura + 1
    Stub.auras[#Stub.auras + 1] = { spellId = spellId, name = name, expirationTime = Stub.now + seconds,
        auraInstanceID = nextAura, text = text or "" }
    Stub.fire("UNIT_AURA", "player")
end
function Stub.removeAura(spellId)
    for i = #Stub.auras, 1, -1 do
        if Stub.auras[i].spellId == spellId then table.remove(Stub.auras, i) end
    end
    Stub.fire("UNIT_AURA", "player")
end

-- ------------------------------------------------------------------------------ game settings
Stub.cvars = {
    Sound_EnableAllSound = "1", Sound_EnableSFX = "0", Sound_MasterVolume = "0.6",
    Sound_SFXVolume = "0.3", Sound_EnableMusic = "0", Sound_MusicVolume = "0.4",
    Sound_EnableAmbience = "0", Sound_AmbienceVolume = "0.6", Sound_EnableDialog = "0",
    Sound_DialogVolume = "1", Sound_EnableErrorSpeech = "1", Sound_EnableEmoteSounds = "1",
    Sound_EnablePetSounds = "1", Sound_EnableSoundWhenGameIsInBG = "0",
    SoftTargetInteract = "0", SoftTargetInteractArc = "0", SoftTargetInteractRange = "10",
}
local SECURE = { SoftTargetInteract = true, SoftTargetInteractArc = true, SoftTargetInteractRange = true }

C_CVar = {}
function C_CVar.GetCVar(name) return Stub.cvars[name] end
function C_CVar.SetCVar(name, value)
    if Stub.cvars[name] == nil then return false end
    if SECURE[name] and Stub.lockdown then
        Stub.errors[#Stub.errors + 1] = "protected setting changed in combat: " .. name
        return false
    end
    Stub.cvars[name] = tostring(value)
    return true
end

-- ----------------------------------------------------------------------------------- bindings
local function Protected(what)
    if Stub.lockdown then
        Stub.errors[#Stub.errors + 1] = "protected call in combat: " .. what
        return true
    end
end
function SetOverrideBindingClick(owner, _, key, buttonName)
    if Protected("SetOverrideBindingClick") then return end
    Stub.bindings[owner] = Stub.bindings[owner] or {}
    Stub.bindings[owner][key] = { button = buttonName }
end
function SetOverrideBinding(owner, _, key, command)
    if Protected("SetOverrideBinding") then return end
    Stub.bindings[owner] = Stub.bindings[owner] or {}
    Stub.bindings[owner][key] = { command = command }
end
function ClearOverrideBindings(owner)
    if Protected("ClearOverrideBindings") then return end
    Stub.bindings[owner] = nil
end

-- What the key does now: { button = ... }, { command = ... } or nil
function Stub.binding(key)
    for _, keys in pairs(Stub.bindings) do
        if keys[key] then return keys[key] end
    end
end

-- --------------------------------------------------------------------------------------- loot
function IsFishingLoot() return Stub.fishingLoot end
function GetNumLootItems() return Stub.loot and #Stub.loot or 0 end
function GetLootSlotLink(slot)
    local drop = Stub.loot[slot]
    if drop.secret then return Stub.SECRET end
    if drop.money or drop.taken then return nil end
    return Stub.link(drop.id)
end
-- 0 an empty (taken) slot, 1 an item, 2 coins
Enum = { LootSlotType = { None = 0, Item = 1, Money = 2 } }
function GetLootSlotType(slot)
    local drop = Stub.loot and Stub.loot[slot]
    if not drop or drop.taken then return 0 end
    return drop.money and 2 or 1
end
function GetLootSlotInfo(slot)
    local drop = Stub.loot[slot]
    local info = Stub.items[drop.id]
    return 100000 + drop.id, info[1], drop.count or 1, nil, info[2]
end

-- ------------------------------------------------------------------------- what the player does
local FOOD_AURA = 433

local function CastFishing()
    if Stub.eating then
        Stub.eating = nil -- casting interrupts the meal: no buff
        Stub.removeAura(FOOD_AURA)
    end
    if Stub.channel then
        Stub.channel = nil
        Stub.fire("UNIT_SPELLCAST_CHANNEL_STOP", "player", "cast-guid", 7620)
    end
    Stub.channel = "Fishing"
    Stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 7620)
    Stub.fire("UNIT_SPELLCAST_CHANNEL_START", "player", "cast-guid", 7620)
    return "cast"
end
Stub.castFishing = CastFishing

local function UseLure(id)
    if (Stub.bags[id] or 0) <= 0 then return "no such item" end
    if Stub.lureFails then return "lure failed" end -- e.g. the player is moving
    Stub.bags[id] = Stub.bags[id] - 1
    Stub.used[#Stub.used + 1] = id
    Stub.enchantUntil = Stub.now + 600
    Stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 8087)
    Stub.fire("BAG_UPDATE_DELAYED")
    return "lure"
end

-- Food and buff items. Food gives its buff after ten seconds of uninterrupted eating.
-- asToy: used through the toy action; a toy can't be used any other way.
local function UseItem(id, asToy)
    local info = Stub.items[id]
    local use = info and info[8] and info[8].use
    if not use then return "no such item" end
    if use.toy then
        if not (asToy and Stub.toys[id]) then return "toy needs the toy action" end
    elseif asToy or (Stub.bags[id] or 0) <= 0 then
        return "no such item"
    end
    if Stub.useFails then return "use failed" end
    Stub.usedItems[#Stub.usedItems + 1] = id
    if use.consume then Stub.bags[id] = Stub.bags[id] - 1 end
    Stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 90000 + id)
    if use.consume then Stub.fire("BAG_UPDATE_DELAYED") end
    if use.eat then
        local meal = {}
        Stub.eating = meal
        Stub.addAura(FOOD_AURA, "Food", 30, "Restores health.")
        C_Timer.After(10, function()
            if Stub.eating ~= meal then return end
            Stub.eating = nil
            Stub.removeAura(use.spell)
            Stub.addAura(use.spell, use.name, use.minutes * 60, use.text)
        end)
    else
        Stub.removeAura(use.spell)
        Stub.addAura(use.spell, use.name, use.minutes * 60, use.text)
    end
    return "use:" .. id
end

-- A worn item whose use puts a lure on the pole ("/use 1" then "/use 16")
local function UseWornLure(slot)
    local id = Stub.equipped[slot]
    local info = id and Stub.items[id]
    if not (info and info[8] and info[8].wornLure) then return "nothing in that slot to use" end
    if (Stub.slotCooldown[slot] or 0) > Stub.now then return "on cooldown" end
    Stub.slotCooldown[slot] = Stub.now + 600
    Stub.used[#Stub.used + 1] = id
    Stub.enchantUntil = Stub.now + 600
    Stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 8087)
    return "lure"
end

-- What a click on a secure button does, from its attributes
local function SecureAction(button)
    local kind = button.__attrs.type
    if kind == "spell" then
        if button.__attrs.spell == "Fishing" then return CastFishing() end
        return "spell:" .. tostring(button.__attrs.spell)
    elseif kind == "macro" then
        local text = button.__attrs.macrotext or ""
        local id = tonumber(text:match("/use item:(%d+)"))
        if id and text:match("/use 16") then
            -- Using clothing from the bags puts it on instead of firing its effect
            local info = Stub.items[id]
            if info and info[8] and info[8].equipLoc then return "equipped instead of used" end
            return UseLure(id)
        end
        local slot = tonumber(text:match("^/use (%d+)\n/use 16"))
        if slot then return UseWornLure(slot) end
        if id then return UseItem(id) end
        return "macro?"
    elseif kind == "toy" then
        return UseItem(tonumber(button.__attrs.toy), true)
    end
    return nil
end

-- The line comes in. loot is a list of { id, count }, { secret = true }; nil for an empty hook.
function Stub.reel(loot)
    Stub.channel = nil
    Stub.fire("UNIT_SPELLCAST_CHANNEL_STOP", "player", "cast-guid", 7620)
    if loot then
        Stub.loot, Stub.fishingLoot = loot, true
        Stub.fire("LOOT_READY", true)
        Stub.fire("LOOT_OPENED", true)
        if not Stub.keepLootOpen then Stub.closeLoot() end
    end
end

function Stub.closeLoot()
    Stub.loot, Stub.fishingLoot = nil, false
    Stub.fire("LOOT_CLOSED")
end

-- Where the loot on screen comes from, as a GUID; nil when the game doesn't say
function GetLootSourceInfo()
    if Stub.noLootSource then return nil end
    return Stub.lootSource
end
function GetMoney() return Stub.money end
function C_Item.GetItemLinkByGUID(guid)
    local id = (not Stub.guidSilent) and Stub.guidItems[guid]
    return id and Stub.link(id) or nil
end

-- Opens an item in the bags the way the game does: a loot window that isn't fishing loot and
-- whose source is the item. contents is a list of { id, count } and { money = copper }.
-- Returns the window: window.take(slot, ...) takes those slots (all of them when none is
-- named), window.close() closes it with whatever is left inside. Once everything is taken the
-- item leaves the bags and the window closes by itself. Stub.staleBags delays the item
-- leaving the bags until Stub.flushBags() (the next window can open before that).
function Stub.open(itemID, contents)
    Stub.loot, Stub.fishingLoot = contents, false
    Stub.lootSource = "Item-4372-0-40000000" .. itemID
    Stub.guidItems[Stub.lootSource] = itemID
    -- Stub.lateSource: the game only says where the loot is from on the second event
    local quiet = Stub.noLootSource
    if Stub.lateSource then Stub.noLootSource = true end
    Stub.fire("LOOT_READY", true)
    Stub.noLootSource = quiet
    Stub.fire("LOOT_OPENED", true)
    if Stub.repeatLoot then Stub.fire("LOOT_READY", true) end
    local left = #contents
    local window = {}
    function window.close()
        if window.closed then return end
        window.closed = true
        Stub.loot, Stub.lootSource = nil, nil
        Stub.fire("LOOT_CLOSED")
    end
    function window.take(...)
        local slots = { ... }
        if #slots == 0 then
            for slot = 1, #contents do slots[slot] = slot end
        end
        for _, slot in ipairs(slots) do
            local drop = contents[slot]
            if drop and not drop.taken then
                drop.taken = true
                left = left - 1
                if drop.money then
                    Stub.money = Stub.money + drop.money
                else
                    Stub.bags[drop.id] = (Stub.bags[drop.id] or 0) + (drop.count or 1)
                end
                Stub.fire("LOOT_SLOT_CLEARED", slot)
            end
        end
        if left == 0 then
            if Stub.staleBags then
                Stub.owedBags[#Stub.owedBags + 1] = itemID
            else
                Stub.bags[itemID] = Stub.bags[itemID] - 1
            end
            Stub.fire("BAG_UPDATE_DELAYED")
            window.close()
        else
            Stub.fire("BAG_UPDATE_DELAYED")
        end
    end
    return window
end
function Stub.flushBags()
    for _, itemID in ipairs(Stub.owedBags) do
        Stub.bags[itemID] = Stub.bags[itemID] - 1
    end
    Stub.owedBags = {}
    Stub.fire("BAG_UPDATE_DELAYED")
end

local function Command(command)
    if command == "INTERACTTARGET" then
        if (tonumber(Stub.cvars.SoftTargetInteract) or 0) < 2 then return "interact key is off" end
        if Stub.channel == "Fishing" then
            Stub.reel(Stub.nextLoot)
            return "reel"
        end
        return "nothing to interact with"
    end
    return "command:" .. command
end

local function Click(buttonName, down)
    local button = _G[buttonName]
    if button.__scripts.PreClick then button.__scripts.PreClick(button, "LeftButton", down) end
    local result
    if (down and Stub.useKeyDown) or (not down and not Stub.useKeyDown) then
        result = SecureAction(button)
    end
    if button.__scripts.PostClick then button.__scripts.PostClick(button, "LeftButton", down) end
    return result
end

-- Presses and releases a key. Returns what happened: "cast", "lure", "reel", "nothing",
-- "unbound", ... The release goes to whatever the key is bound to by then.
function Stub.press(key)
    local binding = Stub.binding(key)
    if not binding then return "unbound" end
    local result
    if binding.command then
        result = Command(binding.command)
    else
        result = Click(binding.button, true)
    end
    local after = Stub.binding(key)
    if after and after.button then
        result = Click(after.button, false) or result
    end
    return result or "nothing"
end

function Stub.enterCombat()
    Stub.fire("PLAYER_REGEN_DISABLED")
    Stub.lockdown = true
end

function Stub.leaveCombat()
    Stub.lockdown = false
    Stub.fire("PLAYER_REGEN_ENABLED")
end

function Stub.equip(itemID)
    Stub.mainHand = itemID
    Stub.fire("PLAYER_EQUIPMENT_CHANGED", 16, itemID ~= nil)
    Stub.advance(0.5)
end

function Stub.login()
    Stub.fire("ADDON_LOADED", "Keepnet")
    Stub.fire("PLAYER_LOGIN")
    Stub.fire("PLAYER_ENTERING_WORLD", true, false)
    Stub.advance(1.1)
end

-- /reload: the addon logs out, the game throws away every frame, timer, binding and Lua
-- variable, keeps the saved data and the game settings, and loads the addon again.
-- Stub.loadAddon is supplied by run_tests.py. Returns the new addon table.
function Stub.reload()
    Stub.fire("PLAYER_LOGOUT")
    Stub.frames = { UIParent, GameTooltip, DEFAULT_CHAT_FRAME }
    UIParent.__scripts = {}
    KeepnetPicker = nil
    Stub.timers = {}
    Stub.bindings = {}
    KeepnetCastButton, KeepnetPanel, KeepnetWindow = nil, nil, nil
    local ns = Stub.loadAddon()
    Stub.login()
    return ns
end

-- ----------------------------------------------------------------------------- fake Auctionator
-- Checks its arguments the way the real one does
Auctionator = { API = { v1 = {} } }
local function Verify(caller, value, kind)
    if type(caller) ~= "string" or caller == "" then error("Auctionator: bad caller ID") end
    if type(value) ~= kind then error("Auctionator: bad argument") end
end
function Auctionator.API.v1.GetAuctionPriceByItemID(caller, id)
    Verify(caller, id, "number")
    return Stub.auction[id]
end
function Auctionator.API.v1.GetAuctionPriceByItemLink(caller, link)
    Verify(caller, link, "string")
    return Stub.auction[ItemID(link)]
end
function Auctionator.API.v1.GetVendorPriceByItemID(caller, id)
    Verify(caller, id, "number")
    local info = Stub.items[id]
    return info and info[3] or nil
end
function Auctionator.API.v1.GetAuctionAgeByItemID(caller, id)
    Verify(caller, id, "number")
    return Stub.auctionAge[id]
end

-- ------------------------------------------------------------------------------------ checks
Stub.passed, Stub.failed = 0, {}

function check(condition, message)
    if condition then
        Stub.passed = Stub.passed + 1
    else
        local where = debug.traceback("", 2):match("\n%s*([^\n]-:%d+)") or "?"
        Stub.failed[#Stub.failed + 1] = ("%s  (%s)"):format(message or "check failed", where)
    end
end

function eq(actual, expected, message)
    if actual == expected then
        Stub.passed = Stub.passed + 1
    else
        local where = debug.traceback("", 2):match("\n%s*([^\n]-:%d+)") or "?"
        Stub.failed[#Stub.failed + 1] = ("%s: expected %s, got %s  (%s)"):format(
            message or "eq", tostring(expected), tostring(actual), where)
    end
end

-- Record every undefined global the addon reads from here on
setmetatable(_G, { __index = function(_, key)
    Stub.missing[key] = true
    return nil
end })
