-- Keepnet: the building blocks of the screens: flat panels and buttons, a tick box, a slider,
-- a drop-down list, a text box and the sortable table, and the look and colours they are
-- drawn in. Built from plain frames so they don't depend on game templates that differ
-- between client versions.
--   "THEME"  the colours changed; screens redraw what they coloured themselves
local addonName, ns = ...
local Util = ns.Util

local W = {}
ns.Widgets = W

local FLAT = "Interface\\Buttons\\WHITE8x8"
local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

-- ---------------------------------------------------------------------------------------------
-- Looks and colours. The player chooses a look (W.THEMES; the setting is still called
-- "theme") and, for the looks that have more than one, a set of colours (the look's
-- "schemes"). The first of each is the default.
--
-- A look is drawn in one of four ways:
--   flat    (the default) plain coloured frames with thin borders, all drawn by Keepnet;
--   round   (round = true) the same with round corners (UI\Round.lua);
--   retro   (retro = true) grey bevelled windows with dark text (UI\Retro.lua);
--   native  (native = true) everything made from the game's own templates and art.
-- Going from one way of drawing to another rebuilds every frame, which needs the interface
-- reloaded; the player is asked. Colours change at once.
-- A set of colours is six of them: background, header, button, buttonHover, border, accent.
-- Looks that share a "family" share the player's choice of colours. A look without schemes
-- carries its own six colours.
-- A native look names the game art for the pieces that have no template: "art" for the live
-- panel, "smallArt" for bars and item slots; its colours only tint that art.
-- A native look may also name an interface suite in "adopt": every piece is then handed to
-- that suite to paint (UI\Adopt.lua, which needs an adapter for the suite).
-- ---------------------------------------------------------------------------------------------
-- The game's tooltip frame, for the pieces of a native theme that have no template of their own
local NATIVE_ART = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local NATIVE_SMALL_ART = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- Keepnet's own colours. All dark, since the text is the game's own light fonts.
W.SCHEMES = {
    {
        -- blue-black, a cyan accent
        key = "keepnet", name = "Keepnet",
        background = { 0.06, 0.07, 0.09 }, header = { 0.13, 0.15, 0.19 }, button = { 0.17, 0.20, 0.25 },
        buttonHover = { 0.24, 0.29, 0.36 }, border = { 0, 0, 0 }, accent = { 0.31, 0.76, 0.97 },
    },
    {
        key = "slate", name = "Slate",
        background = { 0.10, 0.10, 0.11 }, header = { 0.17, 0.17, 0.19 }, button = { 0.23, 0.23, 0.26 },
        buttonHover = { 0.32, 0.32, 0.36 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
    },
    {
        key = "forest", name = "Forest",
        background = { 0.05, 0.08, 0.06 }, header = { 0.10, 0.17, 0.12 }, button = { 0.14, 0.23, 0.16 },
        buttonHover = { 0.20, 0.33, 0.23 }, border = { 0, 0, 0 }, accent = { 0.52, 0.88, 0.45 },
    },
    {
        key = "ember", name = "Ember",
        background = { 0.10, 0.06, 0.05 }, header = { 0.20, 0.12, 0.09 }, button = { 0.27, 0.16, 0.12 },
        buttonHover = { 0.38, 0.23, 0.16 }, border = { 0, 0, 0 }, accent = { 1.00, 0.58, 0.22 },
    },
    {
        key = "dusk", name = "Dusk",
        background = { 0.06, 0.05, 0.10 }, header = { 0.13, 0.11, 0.21 }, button = { 0.18, 0.15, 0.29 },
        buttonHover = { 0.26, 0.22, 0.41 }, border = { 0, 0, 0 }, accent = { 0.74, 0.58, 1.00 },
    },
    {
        key = "black", name = "Plain black",
        background = { 0, 0, 0 }, header = { 0.10, 0.10, 0.10 }, button = { 0.17, 0.17, 0.17 },
        buttonHover = { 0.28, 0.28, 0.28 }, border = { 0.30, 0.30, 0.30 }, accent = { 1, 1, 1 },
    },
}

W.THEMES = {
    -- Keepnet's own look: flat
    { key = "keepnet", name = "Keepnet", family = "keepnet", schemes = W.SCHEMES },
    -- The same with round corners (UI\Round.lua)
    { key = "rounded", name = "Keepnet rounded", round = true, family = "keepnet", schemes = W.SCHEMES },
    {
        -- Grey bevelled windows, a title bar, dark text (UI\Retro.lua, which adds its colour
        -- schemes to this entry; the colours here are only what stands in before it has)
        key = "win95", name = "Windows 95", retro = true, family = "win95",
        background = { 0.75, 0.75, 0.75 }, header = { 0.75, 0.75, 0.75 }, button = { 0.75, 0.75, 0.75 },
        buttonHover = { 0.75, 0.75, 0.75 }, border = { 0, 0, 0 }, accent = { 0, 0, 0.5 },
    },
    {
        -- The game's own look. native = true: every window, button, tick box, slider, text box,
        -- drop-down and tab is made from the client's own templates (UI\Native.lua), so it
        -- looks like whatever this client ships. The colours below only tint the few pieces
        -- that have no template of their own: the live panel, bars and item slots, which are
        -- drawn with the game's tooltip frame.
        key = "forever", name = "Forever", native = true,
        background = { 0.05, 0.05, 0.08 }, header = { 0.10, 0.09, 0.08 }, button = { 0.08, 0.08, 0.08 },
        buttonHover = { 0.20, 0.20, 0.20 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
        art = NATIVE_ART, smallArt = NATIVE_SMALL_ART,
        artBorder = { 0.8, 0.8, 0.8 },
    },
    {
        -- EllesmereUI: built like Forever, then every piece is handed to EllesmereUI to paint
        -- (UI\\Adopt.lua). The accent is that suite's own. Without EllesmereUI installed it is the
        -- Forever look.
        key = "ellesmereui", name = "EllesmereUI", native = true, adopt = "EllesmereUI",
        background = { 0.05, 0.05, 0.08 }, header = { 0.10, 0.10, 0.11 }, button = { 0.08, 0.08, 0.08 },
        buttonHover = { 0.20, 0.20, 0.20 }, border = { 0, 0, 0 }, accent = { 1.00, 0.82, 0.00 },
        art = NATIVE_ART, smallArt = NATIVE_SMALL_ART, artBorder = { 0.8, 0.8, 0.8 },
    },
}

-- The colours in use. These tables are filled by W.ApplyTheme and never replaced, so anything
-- holding one of them sees a new theme at once.
W.COLORS = {
    background = { 0.06, 0.07, 0.09, 1 },
    border = { 0, 0, 0, 1 },
    header = { 0.13, 0.15, 0.19, 1 },
    button = { 0.17, 0.20, 0.25, 1 },
    buttonHover = { 0.24, 0.29, 0.36, 1 },
    accent = { 0.31, 0.76, 0.97 },
}

-- How see-through the background of each kind of top-level frame is: "window" and "panel"
W.opacity = { window = 0.94, panel = 0.94 }

local skinned = {} -- every frame given a backdrop: { frame, color, group }
local accents = {} -- every texture drawn in the accent colour: { texture, alpha }

local FLAT_BACKDROP = { bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 }
local activeTheme -- set by W.ApplyTheme

local function Paint(entry)
    if entry.frame.keepnetAdopted then
        -- The player's interface suite paints this one (UI\Adopt.lua)
        entry.frame:SetBackdropColor(0, 0, 0, 0)
        entry.frame:SetBackdropBorderColor(0, 0, 0, 0)
        return
    end
    local color = entry.color
    local alpha = entry.group and W.opacity[entry.group] or 1
    -- The looks that draw a frame themselves, in place of its backdrop
    if W.retro and ns.Retro then
        ns.Retro.Paint(entry, alpha)
        return
    end
    if W.round and ns.Round and ns.Round.Wants(entry) then
        ns.Round.Paint(entry, color, alpha)
        return
    end
    -- A theme with frame art: the big frames (those with a group) take "art", the small
    -- pieces "smallArt"
    local art
    if activeTheme then
        art = entry.group and activeTheme.art or (not entry.group and activeTheme.smallArt) or nil
    end
    local backdrop = art or FLAT_BACKDROP
    if entry.backdrop ~= backdrop then
        entry.frame:SetBackdrop(backdrop)
        entry.backdrop = backdrop
    end
    entry.frame:SetBackdropColor(color[1], color[2], color[3], alpha)
    if art then
        local tint = activeTheme.artBorder or W.COLORS.border
        entry.frame:SetBackdropBorderColor(tint[1], tint[2], tint[3], W.COLORS.border[4] or 1)
    else
        entry.frame:SetBackdropBorderColor(unpack(W.COLORS.border))
    end
end

-- The border colour a frame goes back to after being highlighted
function W.BorderColor(group)
    local art = activeTheme and (group and activeTheme.art or (not group and activeTheme.smallArt))
    local tint = art and activeTheme.artBorder or W.COLORS.border
    return tint[1], tint[2], tint[3], W.COLORS.border[4] or 1
end

-- Gives a frame a background in one of the W.COLORS and a border. group is "window" or "panel"
-- for a big frame: its background follows that opacity setting and takes the theme's frame
-- art, when the theme has any. kind says what the frame is, for the looks that draw each
-- kind differently: "button", "header" (a column heading), "field" (a text box, a tick box),
-- "list", "menu", "slot" (an item), "thin" (a bar), "track" (a slider). Left out, it follows
-- from the colour.
--
-- Whatever draws the frame, the screens go on colouring it with SetBackdropColor and
-- SetBackdropBorderColor: where a look draws the frame itself, those two reach its drawing.
function W.Skin(frame, color, group, kind)
    local entry = { frame = frame, color = color or W.COLORS.background, group = group, kind = kind }
    local fill, edge = frame.SetBackdropColor, frame.SetBackdropBorderColor
    frame.SetBackdropColor = function(self, r, g, b, a)
        if entry.custom then entry.custom:Fill(r, g, b, a) else fill(self, r, g, b, a) end
    end
    frame.SetBackdropBorderColor = function(self, r, g, b, a)
        if entry.custom then entry.custom:Edge(r, g, b, a) else edge(self, r, g, b, a) end
    end
    frame.keepnetSkin = entry
    skinned[#skinned + 1] = entry
    W.built = true
    Paint(entry)
end

-- A thin dividing line
function W.Rule(texture)
    if W.retro and ns.Retro then
        ns.Retro.Rule(texture)
    else
        texture:SetColorTexture(1, 1, 1, 0.12)
    end
end

-- A faint wash over what is under it: the line the mouse is on, a scroll track. Light on the
-- dark looks, dark on a light one.
function W.Faint(texture, alpha)
    local shade = (W.retro and ns.Retro) and ns.Retro.Shade() or 1
    texture:SetColorTexture(shade, shade, shade, alpha)
end

-- ---------------------------------------------------------------------------------------------
-- The font of Keepnet's own looks (the flat one and the rounded one): Overpass, unless the
-- player would rather have the game's own. The other looks have theirs: the game's, the
-- suite's, the retro look's.
--
-- Every text is made in one of the game's fonts (W.Text), which decides its size and colour.
-- For each of those Keepnet keeps a copy of its own (W.FontObject) and gives the texts that
-- copy; changing the font is changing the file the copies are drawn from, so every text
-- follows at once. A file is only used for the languages it has letters for, and a file that
-- isn't there leaves the game's font in place.
--
-- Besides its own, Keepnet offers every font another addon on this computer shares through
-- LibSharedMedia (interface suites and font packs do): W.FontChoices. Such a font stays in
-- the addon that brought it; Keepnet only asks the library where the file is. Its choice is
-- saved as "shared:" and the name it is shared under. When that addon is gone the default
-- takes its place, and when it loads after Keepnet the font is taken up as soon as it is
-- shared.
-- ---------------------------------------------------------------------------------------------
local WESTERN = {
    enUS = true, enGB = true, deDE = true, frFR = true, esES = true, esMX = true, itIT = true,
    ptBR = true, ruRU = true,
}

-- The first is the default
W.FONTS = {
    {
        key = "overpass", name = "Overpass",
        regular = MEDIA .. "Overpass-Regular.ttf", bold = MEDIA .. "Overpass-SemiBold.ttf",
        locales = WESTERN,
    },
    { key = "game", name = "The game's own" },
}

function W.Font(key)
    for _, font in ipairs(W.FONTS) do
        if font.key == key then return font end
    end
    return W.FONTS[1]
end

local SHARED = "shared:"

local function SharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

-- The file of a font another addon shares, by the name it is shared under; nil when nobody
-- shares it (now)
local function SharedFont(name)
    local media = SharedMedia()
    if not media then return nil end
    local ok, file = pcall(media.Fetch, media, "font", name, true)
    if ok and type(file) == "string" and file ~= "" then return file end
end

-- The name a saved choice was shared under, or nil for one of Keepnet's own
local function SharedName(key)
    if type(key) == "string" and key:sub(1, #SHARED) == SHARED then return key:sub(#SHARED + 1) end
end

-- Everything there is to choose from: Keepnet's own, then what other addons share, A to Z:
-- { { key, name } }
function W.FontChoices()
    local list = {}
    for _, font in ipairs(W.FONTS) do
        list[#list + 1] = { key = font.key, name = font.name }
    end
    local media = SharedMedia()
    if media then
        -- (the library lists only the fonts that have this language's letters)
        local ok, names = pcall(media.List, media, "font")
        if ok and type(names) == "table" then
            local shared = {}
            for _, name in ipairs(names) do
                if type(name) == "string" and SharedFont(name) then shared[#shared + 1] = name end
            end
            table.sort(shared, function(a, b) return a:lower() < b:lower() end)
            for _, name in ipairs(shared) do
                list[#list + 1] = { key = SHARED .. name, name = name }
            end
        end
    end
    return list
end

-- The choice in use, as the list shows it: { key, name }. A shared font that is gone is the
-- default.
function W.FontChoice(key)
    local name = SharedName(key)
    if name and SharedFont(name) then return { key = key, name = name } end
    local font = W.Font(key)
    return { key = font.key, name = font.name }
end

-- The files a choice is drawn from, for ordinary text and for headings; nothing for the
-- game's own
local function FontFiles(key)
    local name = SharedName(key)
    if name then
        local file = SharedFont(name)
        if file then return file, file end
        key = nil
    end
    local font = W.Font(key)
    if font.regular and font.locales[GetLocale and GetLocale() or "enUS"] then
        return font.regular, font.bold
    end
end

-- The game's fonts that stand for a heading: these get the heavier file
local HEADING_FONTS = { GameFontNormal = true, GameFontNormalLarge = true }

local fonts = {} -- by the game font's name: { object, file, size, flags, heading }, or false

local function SetFontFile(entry)
    local regular, heading = FontFiles(ns.settings and ns.settings.font)
    -- The game's own first: it stays when the file asked for next isn't there
    entry.object:SetFont(entry.file, entry.size, entry.flags)
    if regular then
        pcall(entry.object.SetFont, entry.object, entry.heading and heading or regular, entry.size, entry.flags)
    end
end

local function RefreshFonts()
    for _, entry in pairs(fonts) do
        if entry then SetFontFile(entry) end
    end
end

-- A font shared by an addon that loads after Keepnet: taken up when it is shared
local watching = false
local function WatchSharedFonts()
    if watching then return end
    local media = SharedMedia()
    if not media or type(media.RegisterCallback) ~= "function" then return end
    watching = true
    pcall(media.RegisterCallback, W, "LibSharedMedia_Registered", function(_, kind, name)
        if kind == "font" and SharedName(ns.settings and ns.settings.font) == name then RefreshFonts() end
    end)
end

-- Keepnet's copy of one of the game's fonts, or nil where the game's own is to be used as it
-- is: in the other looks, for the small numbers on item pictures, and where the game has no
-- font of that name
function W.FontObject(name)
    if W.native or W.retro then return nil end
    local entry = fonts[name]
    if entry == nil then
        entry = false
        local source = _G[name]
        if CreateFont and type(source) == "table" and source.GetFont and not name:find("^NumberFont") then
            local file, size, flags = source:GetFont()
            if file and size then
                local object = CreateFont("Keepnet" .. name)
                object:CopyFontObject(source)
                entry = { object = object, file = file, size = size, flags = flags or "", heading = HEADING_FONTS[name] }
                SetFontFile(entry)
            end
        end
        fonts[name] = entry
    end
    return entry and entry.object or nil
end

-- A bar's filling in the accent colour: flat, or the game's status bar art in a native theme
local BAR_ART = "Interface\\TargetingFrame\\UI-StatusBar"
function W.BarFill(texture, alpha)
    if not W.native then
        W.Accent(texture, alpha)
        return
    end
    local accent = W.COLORS.accent
    texture:SetTexture(BAR_ART)
    texture:SetVertexColor(accent[1], accent[2], accent[3], alpha or 1)
    accents[#accents + 1] = { texture = texture, alpha = alpha or 1, vertex = true }
end

-- Colours a texture in the accent colour, now and whenever the theme changes
function W.Accent(texture, alpha)
    local accent = W.COLORS.accent
    texture:SetColorTexture(accent[1], accent[2], accent[3], alpha or 1)
    accents[#accents + 1] = { texture = texture, alpha = alpha or 1 }
end

-- The accent colour as "rrggbb", for colouring text
function W.AccentHex()
    local accent = W.COLORS.accent
    return ("%02x%02x%02x"):format(accent[1] * 255, accent[2] * 255, accent[3] * 255)
end

function W.Theme(key)
    for _, theme in ipairs(W.THEMES) do
        if theme.key == key then return theme end
    end
    return W.THEMES[1]
end

-- The set of colours a look is shown in: the player's choice for its family, or its first.
-- A look without schemes is its own.
function W.Scheme(theme)
    local schemes = theme.schemes
    if not schemes then return theme end
    local chosen = ns.settings and ns.settings.schemes and ns.settings.schemes[theme.family]
    for _, scheme in ipairs(schemes) do
        if scheme.key == chosen then return scheme end
    end
    return schemes[1]
end

-- Chooses a look's colours (for every look of its family). W.ApplyTheme shows them.
function W.SetScheme(theme, key)
    if not theme.schemes or not ns.settings then return end
    ns.settings.schemes = ns.settings.schemes or {}
    ns.settings.schemes[theme.family] = key
end

-- Before looks and colours were two choices, each of Keepnet's colours was a theme
local OLD_COLOUR_THEMES = { slate = true, forest = true, ember = true, dusk = true, black = true }

local function Migrate(settings)
    if OLD_COLOUR_THEMES[settings.theme] then
        settings.schemes = settings.schemes or {}
        settings.schemes.keepnet = settings.theme
        settings.theme = "keepnet"
    elseif settings.theme == "elvui" then
        -- There was an ElvUI look. It was the Forever look unless that suite was installed,
        -- and it was never tried against the suite; it is gone.
        settings.theme = "forever"
    end
end

-- The character's class colour, or nil
local function ClassColor()
    local _, class = UnitClass("player")
    local color = class and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
    if color and color.r then return { color.r, color.g, color.b } end
end

-- Takes the theme, accent and opacity from the settings and recolours everything on screen
StaticPopupDialogs["KEEPNET_RELOAD_FOR_THEME"] = {
    text = "Keepnet has to reload the interface to change to this look.",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function W.ApplyTheme()
    local settings = ns.settings or {}
    Migrate(settings)
    local theme = W.Theme(settings.theme)
    -- How the look is drawn
    local look = (theme.native and "native") or (theme.retro and "retro") or (theme.round and "round") or "flat"
    local adopting = theme.adopt or false -- the suite's name
    if W.look == nil or not W.built then
        -- Nothing is on screen yet: the look is free to choose
        W.look, W.adopting = look, adopting
        W.native, W.retro, W.round = look == "native", look == "retro", look == "round"
    elseif look ~= W.look or adopting ~= W.adopting then
        -- Frames of the other look are already built. The choice is saved and takes effect
        -- at the next reload; until then everything stays as it is.
        StaticPopup_Show("KEEPNET_RELOAD_FOR_THEME")
        return
    end
    activeTheme = theme
    local scheme = W.Scheme(theme)
    for _, name in ipairs({ "background", "header", "button", "buttonHover", "border" }) do
        local from, to = scheme[name], W.COLORS[name]
        to[1], to[2], to[3], to[4] = from[1], from[2], from[3], 1
    end
    -- (the border's fourth number is set below: borders can be turned off)
    local accent = scheme.accent
    local own = nil -- the player's own accent, when the look's isn't wanted
    if adopting and ns.Adopt then
        accent = ns.Adopt.Accent() or accent
    end
    if settings.accentMode == "class" then
        own = ClassColor()
    elseif settings.accentMode == "custom" and settings.accentColor then
        own = settings.accentColor
    end
    accent = own or accent
    if W.retro and ns.Retro then ns.Retro.Apply(scheme, own) end
    RefreshFonts()
    WatchSharedFonts()
    W.COLORS.accent[1], W.COLORS.accent[2], W.COLORS.accent[3] = accent[1], accent[2], accent[3]
    W.COLORS.border[4] = (settings.borders == false) and 0 or 1
    W.opacity.window = settings.windowOpacity or 0.94
    W.opacity.panel = settings.panelOpacity or 0.94
    for _, entry in ipairs(skinned) do
        Paint(entry)
    end
    for _, entry in ipairs(accents) do
        if entry.vertex then
            entry.texture:SetVertexColor(accent[1], accent[2], accent[3], entry.alpha)
        else
            entry.texture:SetColorTexture(accent[1], accent[2], accent[3], entry.alpha)
        end
    end
    ns.Fire("THEME")
end

ns.On("INIT", W.ApplyTheme)

-- Opens the game's colour picker. onChange(r, g, b) is called as the player drags, and with
-- the old colour again on Cancel.
function W.PickColor(r, g, b, onChange)
    local function Picked()
        onChange(ColorPickerFrame:GetColorRGB())
    end
    local function Cancelled()
        onChange(r, g, b)
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = false, swatchFunc = Picked, cancelFunc = Cancelled,
        })
    else
        -- Clients before the picker was reworked
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func = Picked
        ColorPickerFrame.cancelFunc = Cancelled
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

function W.Panel(name, parent, width, height, group)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    W.Skin(frame, W.COLORS.background, group)
    if group == "panel" and ns.Adopt then
        ns.Adopt.Apply("panel", frame)
    end
    return frame
end

function W.Text(parent, font, text)
    local fontString = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    if W.retro and ns.Retro then
        ns.Retro.Dress(fontString, font or "GameFontHighlightSmall")
    else
        local own = W.FontObject(font or "GameFontHighlightSmall")
        if own then fontString:SetFontObject(own) end
    end
    fontString:SetText(text or "")
    if ns.Adopt then ns.Adopt.Apply("text", fontString) end
    return fontString
end

-- A flat button. button.label is its text. kind: see W.Skin (a drop-down is a button that
-- looks like a text box in one of the looks).
local function MakeButton(parent, text, width, height, onClick, kind)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 22)
    W.Skin(button, W.COLORS.button, nil, kind)
    button.label = W.Text(button, "GameFontHighlightSmall", text)
    button.label:SetPoint("CENTER")
    button:SetScript("OnEnter", function(self)
        -- (a button of the retro look doesn't light up under the mouse: it goes in when held)
        if not W.retro then self:SetBackdropColor(unpack(W.COLORS.buttonHover)) end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        if not W.retro then self:SetBackdropColor(unpack(W.COLORS.button)) end
        GameTooltip:Hide()
    end)
    if W.retro and ns.Retro and kind ~= "field" then ns.Retro.Pressable(button) end
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

function W.Button(parent, text, width, height, onClick)
    return MakeButton(parent, text, width, height, onClick)
end

-- A tab of the window. tab:SetSelected(true/false) marks it as the one showing.
function W.Tab(parent, name, title, onClick)
    if W.retro and ns.Retro then return ns.Retro.Tab(parent, title, onClick) end
    local tab = W.Button(parent, title, 100, 22, onClick)
    tab.line = tab:CreateTexture(nil, "OVERLAY")
    tab.line:SetHeight(2)
    -- (clear of the round corners, where there are any)
    tab.line:SetPoint("BOTTOMLEFT", W.round and 4 or 0, 0)
    tab.line:SetPoint("BOTTOMRIGHT", W.round and -4 or 0, 0)
    W.Accent(tab.line)
    function tab:SetSelected(selected)
        if selected then
            self.label:SetTextColor(unpack(W.COLORS.accent))
        else
            self.label:SetTextColor(1, 1, 1)
        end
        self.line:SetShown(selected and true or false)
    end
    return tab
end

-- A column heading of a table. header.label is its text.
function W.Header(parent, title, width, height, right)
    local header = CreateFrame("Button", nil, parent, "BackdropTemplate")
    header:SetSize(width, height)
    W.Skin(header, W.COLORS.header, nil, "header")
    header.label = W.Text(header, "GameFontNormalSmall", title)
    header.label:SetPoint(right and "RIGHT" or "LEFT", right and -6 or 6, 0)
    return header
end

-- A tick box with its text to the right. onChange(checked) is called when the player clicks.
function W.Check(parent, text, onChange)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetSize(16, 16)
    W.Skin(check, W.COLORS.button, nil, "field")
    if W.retro and ns.Retro then
        ns.Retro.Tick(check)
    else
        local tick = check:CreateTexture(nil, "OVERLAY")
        tick:SetPoint("TOPLEFT", 3, -3)
        tick:SetPoint("BOTTOMRIGHT", -3, 3)
        W.Accent(tick)
        check:SetCheckedTexture(tick)
    end
    check.label = W.Text(check, "GameFontHighlightSmall", text)
    check.label:SetPoint("LEFT", check, "RIGHT", 6, 0)
    -- Clicking the text ticks the box too
    check:SetHitRectInsets(0, -(check.label:GetStringWidth() or 0) - 8, 0, 0)
    check:SetScript("OnClick", function(self)
        if self.keepnetSync then self:keepnetSync() end
        if onChange then onChange(self:GetChecked() and true or false) end
    end)
    return check
end

-- A horizontal slider. onChange(value) is called while the player drags.
function W.Slider(parent, width, low, high, step, onChange)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetSize(width, 14)
    slider:SetOrientation("HORIZONTAL")
    W.Skin(slider, W.COLORS.header, nil, "track")
    if W.retro and ns.Retro then
        ns.Retro.Thumb(slider)
    else
        local thumb = slider:CreateTexture(nil, "OVERLAY")
        thumb:SetSize(10, 14)
        W.Accent(thumb)
        slider:SetThumbTexture(thumb)
    end
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider.value = W.Text(slider, "GameFontHighlightSmall")
    slider.value:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    slider:SetScript("OnValueChanged", function(self, value, userInput)
        -- Snap by hand as well: older clients don't hold to the step while dragging
        value = math.floor(value / step + 0.5) * step
        if self.silent then return end
        if onChange then onChange(value, userInput) end
    end)
    -- Sets the position without calling onChange
    function slider:Set(value)
        self.silent = true
        self:SetValue(value)
        self.silent = false
    end
    return slider
end

-- A one-line text box. onEnter(text) is called when the player presses Enter, and
-- onChange(text), when given, on every change the player types.
function W.EditBox(parent, width, onEnter, onChange)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 20)
    W.Skin(box, W.COLORS.header, nil, "field")
    if W.retro and ns.Retro then
        ns.Retro.Edit(box)
    else
        box:SetFontObject(W.FontObject("GameFontHighlightSmall") or "GameFontHighlightSmall")
    end
    box:SetAutoFocus(false)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetMaxLetters(64)
    box:SetScript("OnEnterPressed", function(self)
        if onEnter then onEnter(self:GetText()) end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if onChange then
        box:SetScript("OnTextChanged", function(self) onChange(self:GetText() or "") end)
    end
    return box
end

-- ---------------------------------------------------------------------------------------------
-- Drop-down list. One list frame is shared by every drop-down.
-- ---------------------------------------------------------------------------------------------
local POPUP_ROWS = 14
local POPUP_ROW_HEIGHT = 18
local POPUP_MORE_HEIGHT = 16 -- the line under a long list that says it scrolls
local popup

local function PopupRefresh()
    local options = popup.options
    for i, row in ipairs(popup.rows) do
        local option = options[i + popup.offset]
        if option then
            row.option = option
            row.label:SetText(option.text)
            if option.value == popup.owner.value then
                row.label:SetTextColor(unpack(W.COLORS.accent))
            else
                row.label:SetTextColor(1, 1, 1)
            end
            if row.keepnetCool then row.keepnetCool() end
            row:Show()
        else
            row:Hide()
        end
    end
    -- A list longer than fits says so, and how much is out of sight each way
    local above = popup.offset
    local below = math.max(0, #options - POPUP_ROWS - popup.offset)
    if #options > POPUP_ROWS then
        local parts = {}
        if above > 0 then parts[#parts + 1] = above .. " above" end
        if below > 0 then parts[#parts + 1] = below .. " more below" end
        popup.more:SetText(table.concat(parts, ", ") .. ": mouse wheel")
        popup.more:Show()
    else
        popup.more:Hide()
    end
end

local function PopupCreate()
    -- Catches a click anywhere else and closes the list
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()

    popup = CreateFrame("Frame", nil, catcher, "BackdropTemplate")
    W.Skin(popup, W.COLORS.header, nil, "list")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup.catcher = catcher
    popup.rows = {}
    popup.offset = 0
    catcher:SetScript("OnClick", function() catcher:Hide() end)
    for i = 1, POPUP_ROWS do
        local row = CreateFrame("Button", nil, popup)
        row:SetHeight(POPUP_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 1, -1 - (i - 1) * POPUP_ROW_HEIGHT)
        row:SetPoint("RIGHT", -1, 0)
        row.label = W.Text(row, "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", 6, 0)
        if W.retro and ns.Retro then
            ns.Retro.Hover(row, { row.label }, "paper")
        else
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.12)
        end
        row:SetScript("OnClick", function(self)
            local dropdown = popup.owner
            catcher:Hide()
            dropdown:Set(self.option.value, self.option.text)
            if dropdown.onSelect then dropdown.onSelect(self.option.value) end
        end)
        popup.rows[i] = row
    end
    popup.more = W.Text(popup, "GameFontDisableSmall")
    popup.more:SetPoint("BOTTOMLEFT", 6, 3)
    popup.more:SetTextColor(unpack(W.COLORS.accent))
    popup:EnableMouseWheel(true)
    popup:SetScript("OnMouseWheel", function(_, delta)
        local most = math.max(0, #popup.options - POPUP_ROWS)
        popup.offset = math.max(0, math.min(most, popup.offset - delta))
        PopupRefresh()
    end)
end

-- getOptions() returns { { value = ..., text = "..." }, ... }; onSelect(value) is called when
-- the player picks one. dropdown:Set(value, text) shows a choice without calling onSelect.
function W.Dropdown(parent, width, getOptions, onSelect)
    local retro = W.retro and ns.Retro
    local dropdown = retro and MakeButton(parent, "", width, 20, nil, "field") or W.Button(parent, "", width, 20)
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", 6, 0)
    dropdown.label:SetPoint("RIGHT", retro and -20 or -18, 0)
    dropdown.label:SetJustifyH("LEFT")
    dropdown.label:SetWordWrap(false)
    if retro then
        retro.Combo(dropdown)
    else
        local arrow = W.Text(dropdown, "GameFontHighlightSmall", "v")
        arrow:SetPoint("RIGHT", -6, 0)
        arrow:SetTextColor(unpack(W.COLORS.accent))
        ns.On("THEME", function() arrow:SetTextColor(unpack(W.COLORS.accent)) end)
    end
    dropdown.onSelect = onSelect

    function dropdown:Set(value, text)
        self.value = value
        self.label:SetText(text or tostring(value))
    end

    dropdown:SetScript("OnClick", function(self)
        if not popup then PopupCreate() end
        if popup.catcher:IsShown() and popup.owner == self then
            popup.catcher:Hide()
            return
        end
        popup.owner = self
        popup.options = getOptions()
        popup.offset = 0
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
        popup:SetSize(width, math.min(#popup.options, POPUP_ROWS) * POPUP_ROW_HEIGHT + 2
            + (#popup.options > POPUP_ROWS and POPUP_MORE_HEIGHT or 0))
        PopupRefresh()
        popup.catcher:Show()
    end)
    return dropdown
end

-- ---------------------------------------------------------------------------------------------
-- A button that is only a picture (the cog on the live panel). It has no frame of its own in
-- any look: it is dimmed until the mouse is on it. button.tooltip is shown when set.
-- ---------------------------------------------------------------------------------------------
function W.IconButton(parent, texture, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture(texture)
    button.icon:SetAlpha(0.65)
    button:SetScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.icon:SetAlpha(0.65)
        GameTooltip:Hide()
    end)
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

-- ---------------------------------------------------------------------------------------------
-- Menu: a list of choices that opens under the frame that was clicked (above it when there is
-- no room below). Unlike the drop-down's list it can have headings, and any number of its
-- entries can be marked as the ones in use.
--   menu:Open(anchor, entries), menu:Close(), menu:IsOpen(), menu:IsOpenAt(anchor),
--   menu:SetMenuWidth(width) for the next time it opens
--   entries: { { title = "Head" }, { note = "Nothing to choose from" },
--              { text = ..., right = ..., icon = ..., checked = ..., dim = ..., onClick = fn }, ... }
-- A click on an entry closes the menu and calls its onClick; a click anywhere else closes it.
--
-- It is built the way the drop-down's list above is, which is known to draw properly in the
-- game: a frame of its own under a click catcher that covers the screen, both in the topmost
-- layer. (The first version was a child of the live panel and came out see-through there.)
-- The catcher sits under whatever the clicked frame's window sits under, so the menu also
-- shows when that window has been lifted out of the game's interface, and the menu takes the
-- clicked frame's scale. Its background is a plain filled texture as well as the theme's
-- frame, so it is solid whatever the theme draws.
-- ---------------------------------------------------------------------------------------------
local MENU_ROW = 16

function W.Menu(width)
    -- Catches a click anywhere else and closes the menu
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()

    local menu = CreateFrame("Frame", nil, catcher, "BackdropTemplate")
    menu:SetSize(width, MENU_ROW)
    W.Skin(menu, W.COLORS.header, nil, "menu")
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:EnableMouse(true)
    menu.catcher = catcher
    menu.rows = {}

    -- The solid background, under the theme's frame
    local fill = menu:CreateTexture(nil, "BACKGROUND", nil, -8)
    local function PaintFill()
        -- (inside the frame's border: thicker in the game's art, and clear of round corners)
        local inset = (W.native or W.round) and 3 or (W.retro and 2 or 1)
        local color = W.COLORS.header
        fill:ClearAllPoints()
        fill:SetPoint("TOPLEFT", inset, -inset)
        fill:SetPoint("BOTTOMRIGHT", -inset, inset)
        fill:SetColorTexture(color[1], color[2], color[3], 1)
    end
    PaintFill()
    ns.On("THEME", PaintFill)

    local function Row(index)
        local row = menu.rows[index]
        if row then return row end
        row = CreateFrame("Button", nil, menu)
        row:SetHeight(MENU_ROW)
        row:SetPoint("TOPLEFT", 1, -3 - (index - 1) * MENU_ROW)
        row:SetPoint("TOPRIGHT", -1, -3 - (index - 1) * MENU_ROW)
        if not (W.retro and ns.Retro) then
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.12)
        end
        -- The mark of an entry in use
        row.mark = row:CreateTexture(nil, "ARTWORK")
        row.mark:SetSize(5, 5)
        row.mark:SetPoint("LEFT", 6, 0)
        W.Accent(row.mark)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(MENU_ROW - 3, MENU_ROW - 3)
        row.icon:SetPoint("LEFT", 16, 0)
        row.right = W.Text(row, "GameFontHighlightSmall")
        row.right:SetPoint("RIGHT", -6, 0)
        row.right:SetJustifyH("RIGHT")
        row.label = W.Text(row, "GameFontHighlightSmall")
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)
        if W.retro and ns.Retro then
            ns.Retro.Hover(row, { row.label, row.right }, "face", row.mark)
        end
        row:SetScript("OnClick", function(self)
            local entry = self.entry
            if not entry or not entry.onClick then return end
            menu:Close()
            entry.onClick()
        end)
        menu.rows[index] = row
        return row
    end

    -- What the clicked frame's window sits under: the game's interface, or the world frame
    -- when the window has been lifted out of the interface
    local function HomeOf(frame)
        local parent = frame:GetParent()
        while parent and parent ~= UIParent and parent ~= WorldFrame do
            parent = parent:GetParent()
        end
        return parent or UIParent
    end

    function menu:Open(anchor, entries)
        self.anchor = anchor
        local home = HomeOf(anchor)
        if catcher:GetParent() ~= home then
            catcher:SetParent(home)
            catcher:ClearAllPoints()
            catcher:SetAllPoints(home)
        end
        -- A new parent hands down its own layer: back to the top
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        -- The same size on screen as the frame it opens from
        local outer = home:GetEffectiveScale() or 1
        local scale = (anchor:GetEffectiveScale() or 1) / (outer ~= 0 and outer or 1)
        self:SetScale(scale > 0 and scale or 1)

        for index, entry in ipairs(entries) do
            local row = Row(index)
            row.entry = entry
            local heading = entry.title or entry.note
            local left = heading and 6 or 16
            row.mark:SetShown(entry.checked and true or false)
            if entry.icon and not heading then
                row.icon:SetTexture(entry.icon)
                row.icon:SetDesaturated(entry.dim and true or false)
                row.icon:Show()
                left = left + MENU_ROW
            else
                row.icon:Hide()
            end
            row.right:SetText(entry.right and ("|cff9d9d9d" .. entry.right .. "|r") or "")
            -- The text gets what the figures on the right leave it
            local taken = entry.right and ((row.right:GetStringWidth() or 0) + 12) or 6
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", left, 0)
            row.label:SetWidth(math.max(20, width - 2 - left - taken))
            row.label:SetText(heading or entry.text or "")
            if entry.title then
                row.label:SetTextColor(1, 0.82, 0)
            elseif entry.note or entry.dim then
                row.label:SetTextColor(0.62, 0.62, 0.62)
            elseif entry.checked then
                row.label:SetTextColor(unpack(W.COLORS.accent))
            else
                row.label:SetTextColor(1, 1, 1)
            end
            -- Headings and notes are not for clicking, and don't light up
            row:EnableMouse(entry.onClick ~= nil)
            if row.keepnetCool then row.keepnetCool() end
            row:Show()
        end
        for index = #entries + 1, #self.rows do
            self.rows[index]:Hide()
        end
        local height = #entries * MENU_ROW + 6
        self:SetSize(width, height)
        self:ClearAllPoints()
        -- Under the clicked frame, or above it when the screen ends first
        local bottom = anchor:GetBottom()
        if bottom and bottom * (anchor:GetEffectiveScale() or 1) < (height + 4) * (self:GetEffectiveScale() or 1) then
            self:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 1)
        else
            self:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
        end
        catcher:Show()
    end

    function menu:Close()
        self.anchor = nil
        catcher:Hide()
    end

    -- A new width, used from the next time the menu opens (an open one is closed)
    function menu:SetMenuWidth(newWidth)
        if newWidth == width then return end
        width = newWidth
        self:Close()
    end

    function menu:IsOpen()
        return catcher:IsShown() and true or false
    end

    function menu:IsOpenAt(anchor)
        return self:IsOpen() and self.anchor == anchor
    end

    catcher:SetScript("OnClick", function() menu:Close() end)
    return menu
end

-- ---------------------------------------------------------------------------------------------
-- Sortable table.
--   columns: { { title, width, align ("LEFT"/"RIGHT"), text = function(row), value =
--              function(row) for sorting (defaults to text), desc = true to sort high-to-low
--              on the first click, icon = function(row) for a picture before the text } }
--   options: rows (how many are visible), sort (column number; 0 to show the rows in the
--            order they are given until a heading is clicked), desc, id = function(row) for
--            keeping the selection, onSelect(row), onOpen(row) on a double-click,
--            onEnter(row, frame), onLeave()
-- Click a heading to sort by it; click it again to turn the order round. The mouse wheel
-- scrolls.
-- ---------------------------------------------------------------------------------------------
local ROW_HEIGHT = 18

function W.Table(parent, columns, options)
    options = options or {}
    local visible = options.rows or 12
    local width = 0
    for _, column in ipairs(columns) do
        width = width + column.width
    end

    local t = CreateFrame("Frame", nil, parent)
    t:SetSize(width, ROW_HEIGHT * (visible + 2))
    t.columns = columns
    t.data = {}
    t.offset = 0
    t.sortIndex = options.sort or 1
    t.sortDesc = options.desc or false
    t.headers = {}
    t.rows = {}

    local x = 0
    for i, column in ipairs(columns) do
        local header = W.Header(t, column.title, column.width, ROW_HEIGHT, column.align == "RIGHT")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetScript("OnClick", function()
            if t.sortIndex == i then
                t.sortDesc = not t.sortDesc
            else
                t.sortIndex = i
                t.sortDesc = column.desc or false
            end
            t:Sort()
        end)
        t.headers[i] = header
        x = x + column.width
    end

    -- The retro look's lists are white sheets set into the window
    local retro = W.retro and ns.Retro
    if retro then retro.Paper(t, width, ROW_HEIGHT, visible) end

    for r = 1, visible do
        local row = CreateFrame("Button", nil, t)
        row:SetSize(width, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -ROW_HEIGHT * r)
        if r % 2 == 0 and not retro then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.04)
        end
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        W.Faint(highlight, 0.08)
        row.selected = row:CreateTexture(nil, "BORDER")
        row.selected:SetAllPoints()
        -- (the retro look's chosen line is solid, with light text on it)
        W.Accent(row.selected, retro and 1 or 0.25)
        row.selected:Hide()
        row.cells, row.icons = {}, {}
        local cx = 0
        for i, column in ipairs(columns) do
            local left = cx + 6
            if column.icon then
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
                icon:SetPoint("LEFT", cx + 4, 0)
                row.icons[i] = icon
                left = cx + ROW_HEIGHT + 4
            end
            local cell = W.Text(row, "GameFontHighlightSmall")
            cell:SetPoint("LEFT", left, 0)
            cell:SetWidth(cx + column.width - 6 - left)
            cell:SetJustifyH(column.align or "LEFT")
            cell:SetWordWrap(false)
            if retro then cell:SetSurface("paper") end
            row.cells[i] = cell
            cx = cx + column.width
        end
        row:SetScript("OnClick", function(self)
            if not self.data then return end
            if options.id then
                t.selectedId = options.id(self.data)
                t:Refresh()
            end
            if options.onSelect then options.onSelect(self.data) end
        end)
        row:SetScript("OnDoubleClick", function(self)
            if self.data and options.onOpen then options.onOpen(self.data) end
        end)
        row:SetScript("OnEnter", function(self)
            if self.data and options.onEnter then options.onEnter(self.data, self) end
        end)
        row:SetScript("OnLeave", function()
            if options.onLeave then options.onLeave() end
        end)
        t.rows[r] = row
    end

    t.footer = W.Text(t, "GameFontDisableSmall")
    t.footer:SetPoint("TOPRIGHT", 0, -ROW_HEIGHT * (visible + 1) - 3)
    t.empty = W.Text(t, "GameFontDisable", options.emptyText or "Nothing here yet.")
    t.empty:SetPoint("TOP", 0, -ROW_HEIGHT * 3)
    if retro then t.empty:SetSurface("paper") end

    function t:Refresh()
        local data = self.data
        local most = math.max(0, #data - visible)
        if self.offset > most then self.offset = most end
        for i, header in ipairs(self.headers) do
            local title = columns[i].title
            if i == self.sortIndex then
                header.label:SetText(title .. (self.sortDesc and " v" or " ^"))
                header.label:SetTextColor(unpack(W.COLORS.accent))
            else
                header.label:SetText(title)
                header.label:SetTextColor(1, 0.82, 0)
            end
        end
        for r, row in ipairs(self.rows) do
            local entry = data[r + self.offset]
            row.data = entry
            if entry then
                local chosen = options.id and self.selectedId ~= nil and options.id(entry) == self.selectedId
                for i, column in ipairs(columns) do
                    if retro then row.cells[i]:SetSurface(chosen and "select" or "paper") end
                    row.cells[i]:SetText(column.text(entry) or "")
                    if row.icons[i] then
                        row.icons[i]:SetTexture(column.icon(entry))
                    end
                end
                row.selected:SetShown(chosen and true or false)
                row:Show()
            else
                row:Hide()
            end
        end
        if #data > visible then
            self.footer:SetText(("%d-%d of %d  (mouse wheel scrolls)"):format(
                self.offset + 1, math.min(#data, self.offset + visible), #data))
        else
            self.footer:SetText("")
        end
        self.empty:SetShown(#data == 0)
    end

    -- Rows of equal value keep the order they were given in
    function t:Sort()
        local column = columns[self.sortIndex]
        if column then
            Util.Sort(self.data, column.value or column.text, self.sortDesc)
        end
        self:Refresh()
    end

    -- Shows these rows, keeping the sort order, the scroll position and the selection
    function t:SetData(rows)
        self.data = rows
        self:Sort()
    end

    -- The selected row, or nil
    function t:Selected()
        if not options.id or self.selectedId == nil then return nil end
        for _, entry in ipairs(self.data) do
            if options.id(entry) == self.selectedId then return entry end
        end
    end

    t:EnableMouseWheel(true)
    t:SetScript("OnMouseWheel", function(self, delta)
        local most = math.max(0, #self.data - visible)
        self.offset = math.max(0, math.min(most, self.offset - delta * 3))
        self:Refresh()
    end)

    return t
end

-- A square button showing an item: its icon, how many there are, and the item's tooltip with
-- button.hint under it. button:SetItem(itemID, count, dimmed, chosen); nil hides the button.
function W.ItemButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    W.Skin(button, W.COLORS.button, nil, "slot")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count = W.Text(button, "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", -1, 1)

    function button:SetItem(itemID, count, dimmed, chosen)
        self.itemID = itemID
        if not itemID then
            self:Hide()
            return
        end
        self.icon:SetTexture(Util.ItemIcon(itemID))
        self.icon:SetDesaturated(dimmed and true or false)
        self.count:SetText((count and count > 1) and count or "")
        self:SetBackdropBorderColor(unpack(chosen and W.COLORS.accent or W.COLORS.border))
        self:Show()
    end

    button:SetScript("OnClick", function(self)
        if onClick and self.itemID then onClick(self.itemID, self) end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(self.itemID)
        else
            GameTooltip:SetHyperlink("item:" .. self.itemID)
        end
        if self.hint then GameTooltip:AddLine(self.hint, 0.6, 0.6, 0.6, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

-- Item names in their quality colour
function W.QualityText(text, quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color and color.hex then
        return color.hex .. text .. "|r"
    end
    return text
end
