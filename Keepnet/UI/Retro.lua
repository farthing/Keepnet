-- Keepnet: the "Windows 95" look. Every piece is drawn here from plain colour, the way that
-- interface was put together: a grey face with a two-line bevel (light above and to the left,
-- dark below and to the right) that stands out for windows and buttons and goes in for text
-- boxes, lists and tick boxes; a title bar in one colour; dark text; a selection that turns a
-- line the title bar's colour with light text. Nothing here is a picture file, and nothing is
-- taken from Windows: the tick, the cross, the arrow and the dots are small patterns written
-- out below, and the colours are the well-known numbers of its colour schemes (see CREDITS.md).
--
-- The building blocks in Widgets.lua ask for these pieces when this look is in use (W.retro):
--   Retro.Paint       the bevel and background of a skinned frame, by its kind
--   Retro.Dress       a text: this look's font, and colours that read on a light background
--   Retro.Caption     a title bar, with a title and a close box when wanted
--   Retro.Tab, Page   the window's tabs and the framed page under them
--   Retro.Tick, Thumb, Combo, Edit, Progress, Paper, Rule, Hover, Latch, Pressable, Glyph
--
-- One measure of the interface stands for one dot of that screen, so on a modern screen
-- everything is that many times larger, as it would be magnified.
local addonName, ns = ...
local W = ns.Widgets

local R = {}
ns.Retro = R

local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

-- ---------------------------------------------------------------------------------------------
-- Colour schemes. The names of the colours:
--   face       windows, buttons               paper       text boxes and lists
--   hilight    the brightest edge             text        text on the face and on paper
--   light      the edge beside it             title       the title bar, titleText on it
--   shadow     the darker edge                select      a chosen line, selectText on it
--   dark       the darkest edge
-- The numbers are those of that system's own schemes, under the names it gave them (the
-- "(VGA)", "(high color)" and "(large)" it added to some are left off).
-- ---------------------------------------------------------------------------------------------
local function Scheme(key, name, colors)
    local scheme = { key = key, name = name }
    for part, color in pairs(colors) do
        scheme[part] = { color[1] / 255, color[2] / 255, color[3] / 255 }
    end
    -- What the building blocks that know nothing of this look read
    scheme.background, scheme.header, scheme.button, scheme.buttonHover = scheme.face, scheme.face, scheme.face, scheme.face
    scheme.border = scheme.dark
    scheme.accent = scheme.select
    return scheme
end

R.SCHEMES = {
    Scheme("standard", "Windows Standard", {
        face = { 192, 192, 192 }, hilight = { 255, 255, 255 }, light = { 223, 223, 223 }, shadow = { 128, 128, 128 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 0, 0, 128 }, titleText = { 255, 255, 255 }, select = { 0, 0, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("brick", "Brick", {
        face = { 194, 191, 165 }, hilight = { 225, 224, 210 }, light = { 194, 191, 165 }, shadow = { 141, 137, 97 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 128, 0, 0 }, titleText = { 225, 224, 210 }, select = { 141, 137, 97 }, selectText = { 255, 255, 255 },
    }),
    Scheme("desert", "Desert", {
        face = { 213, 204, 187 }, hilight = { 234, 230, 221 }, light = { 213, 204, 187 }, shadow = { 162, 141, 104 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 0, 128, 128 }, titleText = { 255, 255, 255 }, select = { 0, 128, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("eggplant", "Eggplant", {
        face = { 144, 176, 168 }, hilight = { 200, 216, 216 }, light = { 144, 176, 168 }, shadow = { 88, 128, 120 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 88, 128, 120 }, titleText = { 255, 255, 255 }, select = { 88, 128, 120 }, selectText = { 255, 255, 255 },
    }),
    Scheme("lilac", "Lilac", {
        face = { 174, 168, 217 }, hilight = { 216, 213, 236 }, light = { 174, 168, 217 }, shadow = { 90, 78, 177 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 90, 78, 177 }, titleText = { 255, 255, 255 }, select = { 90, 78, 177 }, selectText = { 255, 255, 255 },
    }),
    Scheme("maple", "Maple", {
        face = { 230, 216, 174 }, hilight = { 242, 236, 215 }, light = { 230, 216, 174 }, shadow = { 198, 166, 70 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 198, 166, 70 }, titleText = { 255, 255, 255 }, select = { 198, 166, 70 }, selectText = { 0, 0, 0 },
    }),
    Scheme("marine", "Marine", {
        face = { 136, 192, 184 }, hilight = { 200, 224, 216 }, light = { 136, 192, 184 }, shadow = { 72, 144, 136 },
        dark = { 0, 0, 0 }, paper = { 200, 224, 216 }, text = { 0, 0, 0 },
        title = { 0, 0, 128 }, titleText = { 192, 192, 192 }, select = { 0, 0, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("plum", "Plum", {
        face = { 168, 152, 144 }, hilight = { 216, 208, 200 }, light = { 168, 152, 144 }, shadow = { 120, 96, 88 },
        dark = { 0, 0, 0 }, paper = { 216, 208, 200 }, text = { 0, 0, 0 },
        title = { 72, 64, 96 }, titleText = { 216, 208, 200 }, select = { 40, 72, 72 }, selectText = { 216, 208, 200 },
    }),
    Scheme("pumpkin", "Pumpkin", {
        face = { 236, 213, 157 }, hilight = { 245, 234, 207 }, light = { 236, 213, 157 }, shadow = { 215, 165, 47 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 215, 165, 47 }, titleText = { 255, 255, 255 }, select = { 128, 0, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("rainyday", "Rainy Day", {
        face = { 131, 153, 177 }, hilight = { 193, 204, 217 }, light = { 131, 153, 177 }, shadow = { 79, 101, 125 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 79, 101, 125 }, titleText = { 255, 255, 255 }, select = { 79, 101, 125 }, selectText = { 255, 255, 255 },
    }),
    Scheme("rose", "Rose", {
        face = { 207, 175, 183 }, hilight = { 231, 216, 220 }, light = { 207, 175, 183 }, shadow = { 159, 96, 112 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 159, 96, 112 }, titleText = { 255, 255, 255 }, select = { 159, 96, 112 }, selectText = { 255, 255, 255 },
    }),
    Scheme("slate", "Slate", {
        face = { 157, 185, 200 }, hilight = { 206, 220, 227 }, light = { 157, 185, 200 }, shadow = { 85, 128, 151 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 85, 128, 151 }, titleText = { 255, 255, 255 }, select = { 85, 128, 151 }, selectText = { 255, 255, 255 },
    }),
    Scheme("spruce", "Spruce", {
        face = { 162, 200, 169 }, hilight = { 208, 227, 211 }, light = { 162, 200, 169 }, shadow = { 89, 151, 100 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 89, 151, 100 }, titleText = { 255, 255, 255 }, select = { 89, 151, 100 }, selectText = { 255, 255, 255 },
    }),
    Scheme("storm", "Storm", {
        face = { 192, 192, 192 }, hilight = { 255, 255, 255 }, light = { 192, 192, 192 }, shadow = { 128, 128, 128 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 128, 0, 128 }, titleText = { 255, 255, 255 }, select = { 128, 0, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("teal", "Teal", {
        face = { 192, 192, 192 }, hilight = { 255, 255, 255 }, light = { 192, 192, 192 }, shadow = { 128, 128, 128 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 0, 128, 128 }, titleText = { 255, 255, 255 }, select = { 0, 128, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("wheat", "Wheat", {
        face = { 222, 222, 160 }, hilight = { 238, 238, 208 }, light = { 222, 222, 160 }, shadow = { 188, 188, 65 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 128, 128, 0 }, titleText = { 255, 255, 255 }, select = { 128, 128, 0 }, selectText = { 255, 255, 255 },
    }),
    Scheme("highcontrastblack", "High Contrast Black", {
        face = { 0, 0, 0 }, hilight = { 192, 192, 192 }, light = { 255, 255, 255 }, shadow = { 128, 128, 128 },
        dark = { 255, 255, 255 }, paper = { 0, 0, 0 }, text = { 255, 255, 255 },
        title = { 128, 0, 128 }, titleText = { 255, 255, 255 }, select = { 128, 0, 128 }, selectText = { 255, 255, 255 },
    }),
    Scheme("highcontrastwhite", "High Contrast White", {
        face = { 255, 255, 255 }, hilight = { 192, 192, 192 }, light = { 192, 192, 192 }, shadow = { 128, 128, 128 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 0, 0, 0 }, titleText = { 255, 255, 255 }, select = { 0, 0, 0 }, selectText = { 255, 255, 255 },
    }),
    Scheme("redwhiteandblue", "Red, White and Blue", {
        face = { 192, 192, 192 }, hilight = { 255, 255, 255 }, light = { 192, 192, 192 }, shadow = { 128, 128, 128 },
        dark = { 0, 0, 0 }, paper = { 255, 255, 255 }, text = { 0, 0, 0 },
        title = { 128, 0, 0 }, titleText = { 255, 255, 255 }, select = { 128, 0, 0 }, selectText = { 255, 255, 255 },
    }),
}

-- The colours in use: filled by Retro.Apply, never replaced
local C = {}
for part, color in pairs(R.SCHEMES[1]) do
    if type(color) == "table" then C[part] = { color[1], color[2], color[3] } end
end
R.COLORS = C
-- The look's entry in the list of looks gets its schemes here
W.Theme("win95").schemes = R.SCHEMES

local function Light(color)
    return color[1] * 0.299 + color[2] * 0.587 + color[3] * 0.114 > 0.5
end

-- 0 where a faint wash has to darken (a light face), 1 where it has to lighten
function R.Shade()
    return Light(C.face) and 0 or 1
end

-- ---------------------------------------------------------------------------------------------
-- Text. The game's texts are light, made for dark windows. On a light background each colour
-- is swapped for the nearest of the sixteen that screen had that still reads: white becomes
-- the scheme's text colour, grey a darker grey, and a bright colour its dark sister (green to
-- dark green, red to maroon, blue to navy ...).
-- ---------------------------------------------------------------------------------------------
-- plainIsText: the game's gold, which it uses for headings, counts as ordinary text
local function InkColor(r, g, b, plainIsText)
    local high, low = math.max(r, g, b), math.min(r, g, b)
    if high < 0.5 then return r, g, b end -- dark already
    if (high - low) / high < 0.25 then
        if high > 0.85 then return C.text[1], C.text[2], C.text[3] end
        return 0.5, 0.5, 0.5
    end
    if plainIsText and r > 0.9 and g > 0.7 and g < 0.9 and b < 0.2 then
        return C.text[1], C.text[2], C.text[3]
    end
    local cut = high * 0.6
    return r >= cut and 0.5 or 0, g >= cut and 0.5 or 0, b >= cut and 0.5 or 0
end
R.InkColor = InkColor

local function InkCode(alpha, red, green, blue)
    local r, g, b = InkColor(tonumber(red, 16) / 255, tonumber(green, 16) / 255, tonumber(blue, 16) / 255)
    local function Byte(value) return math.floor(value * 255 + 0.5) end
    return ("|c%s%02x%02x%02x"):format(alpha, Byte(r), Byte(g), Byte(b))
end

-- The colour codes inside a text, swapped the same way
local function Ink(text)
    if type(text) ~= "string" or not text:find("|c", 1, true) then return text end
    return (text:gsub("|c(%x%x)(%x%x)(%x%x)(%x%x)", InkCode))
end
R.Ink = Ink

-- The font: the nearest thing the game has until the look's own file is there. Each line is
-- tried in turn and the last one that works stays (a file that isn't there changes nothing).
-- Only for the languages the file has letters for; the others keep the game's own font.
local FONT_SIZE = 11
local LATIN = { enUS = true, enGB = true, deDE = true, frFR = true, esES = true, esMX = true, itIT = true, ptBR = true }
local font

function R.Font()
    if font then return font end
    font = CreateFont("KeepnetRetroFont")
    local files = { STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" }
    if LATIN[GetLocale and GetLocale() or "enUS"] then
        files[#files + 1] = "Fonts\\ARIALN.TTF"
        files[#files + 1] = MEDIA .. "W95FA.otf"
    end
    for _, file in ipairs(files) do
        pcall(font.SetFont, font, file, FONT_SIZE, "")
    end
    font:SetShadowOffset(0, 0)
    font:SetTextColor(C.text[1], C.text[2], C.text[3])
    return font
end

-- The game's fonts that stand for a heading: drawn bold here. That screen's bold was the
-- same letters drawn twice, one dot apart, and so is this one.
local BOLD = { GameFontNormal = true, GameFontNormalLarge = true }

-- What a text stands on decides its colour: "face" and "paper" take the scheme's text colour
-- and swapped colours, "title" and "select" their own light text and nothing else
local ON = { title = "titleText", select = "selectText" }

local texts = setmetatable({}, { __mode = "k" }) -- every dressed text, to colour again

local function Colour(self)
    local own = ON[self.keepnetSurface]
    local chosen = self.keepnetColor
    local r, g, b
    local swap = false
    if own then
        r, g, b = C[own][1], C[own][2], C[own][3]
    else
        swap = Light(C[self.keepnetSurface] or C.face)
        if not chosen then
            r, g, b = C.text[1], C.text[2], C.text[3]
        elseif swap then
            r, g, b = InkColor(chosen[1], chosen[2], chosen[3], true)
        else
            r, g, b = chosen[1], chosen[2], chosen[3]
        end
    end
    self.keepnetSetColor(self, r, g, b, chosen and chosen[4] or 1)
    local text = self.keepnetRaw
    if text ~= nil then
        self.keepnetSetText(self, swap and Ink(text) or text)
    end
    -- Bold only where the whole text is one colour: the second drawing has just the one
    if self.keepnetBold and not (type(text) == "string" and text:find("|c", 1, true)) then
        self:SetShadowColor(r, g, b, 1)
        self:SetShadowOffset(1, 0)
    else
        self:SetShadowOffset(0, 0)
    end
end

-- Gives a text this look. fontName is the game font it was asked for in.
function R.Dress(text, fontName)
    -- The small numbers on item pictures stay the game's: they are part of the picture
    if fontName and fontName:find("^NumberFont") then return end
    text:SetFontObject(R.Font())
    text.keepnetBold = BOLD[fontName] or false
    text.keepnetSurface = "face"
    text.keepnetSetText, text.keepnetSetColor = text.SetText, text.SetTextColor
    text.SetText = function(self, value)
        self.keepnetRaw = value
        Colour(self)
    end
    text.SetTextColor = function(self, r, g, b, a)
        self.keepnetColor = { r, g, b, a }
        Colour(self)
    end
    text.GetText = function(self) return self.keepnetRaw end
    -- "face", "paper", "title" or "select"
    text.SetSurface = function(self, surface)
        if self.keepnetSurface ~= surface then
            self.keepnetSurface = surface
            Colour(self)
        end
    end
    texts[text] = true
    Colour(text)
end

-- A text box: this look's font, and the selection in the scheme's colours
function R.Edit(box)
    box:SetFontObject(R.Font())
    box:SetTextColor(C.text[1], C.text[2], C.text[3])
    if box.SetHighlightColor then box:SetHighlightColor(C.select[1], C.select[2], C.select[3], 0.6) end
end

-- ---------------------------------------------------------------------------------------------
-- The bevel: two lines round a frame (or round a picture on it), each ring light on one side
-- and dark on the other. The dark sides take the corners, as they did.
-- ---------------------------------------------------------------------------------------------
local function Ring(frame, target, inset, layer)
    local ring = {}
    for _, side in ipairs({ "top", "left", "bottom", "right" }) do
        ring[side] = frame:CreateTexture(nil, layer or "BORDER")
    end
    ring.top:SetPoint("TOPLEFT", target, "TOPLEFT", inset, -inset)
    ring.top:SetPoint("TOPRIGHT", target, "TOPRIGHT", -inset - 1, -inset)
    ring.top:SetHeight(1)
    ring.left:SetPoint("TOPLEFT", target, "TOPLEFT", inset, -inset)
    ring.left:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", inset, inset + 1)
    ring.left:SetWidth(1)
    ring.bottom:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", inset, inset)
    ring.bottom:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -inset, inset)
    ring.bottom:SetHeight(1)
    ring.right:SetPoint("TOPRIGHT", target, "TOPRIGHT", -inset, -inset)
    ring.right:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -inset, inset)
    ring.right:SetWidth(1)
    return ring
end

-- Colours a ring: one colour above and to the left, one below and to the right; nil hides it
local function Tint(ring, upper, lower)
    for _, side in ipairs({ "top", "left", "bottom", "right" }) do
        local color = (side == "top" or side == "left") and upper or lower
        if color then
            ring[side]:SetColorTexture(color[1], color[2], color[3], 1)
            ring[side]:Show()
        else
            ring[side]:Hide()
        end
    end
end

-- Outer ring above-left and below-right, then the inner ring the same way
local STYLES = {
    window = { "light", "dark", "hilight", "shadow" }, -- a window, a menu
    button = { "hilight", "dark", "light", "shadow" }, -- a button, a column heading, a tab's page
    pressed = { "dark", "hilight", "shadow", "light" }, -- a button held down
    field = { "shadow", "hilight", "dark", "light" },  -- a text box, a list, a tick box
    thin = { "shadow", "hilight" },                    -- a progress bar
    list = { "dark", "dark" },                         -- a list that drops down
}

-- What each kind of frame gets: its bevel, and the colour behind it
local KINDS = {
    window = { "window", "face" }, menu = { "window", "face" },
    button = { "button", "face" }, header = { "button", "face" },
    field = { "field", "paper" }, slot = { "field", "face" },
    thin = { "thin", "face" }, list = { "list", "paper" },
    track = {}, -- a slider: its groove and handle are drawn by Retro.Thumb
}

local Art = {}
Art.__index = Art
local arts = {} -- those that no skinned frame owns, to colour again

-- target: what the bevel goes round, the frame itself when left out
function R.Art(frame, target, layer)
    local art = setmetatable({ frame = frame, alpha = 1 }, Art)
    target = target or frame
    art.fill = frame:CreateTexture(nil, "BACKGROUND")
    art.fill:SetAllPoints(target)
    art.outer = Ring(frame, target, 0, layer)
    art.inner = Ring(frame, target, 1, layer)
    return art
end

function Art:Repaint()
    local style = STYLES[(self.down or self.latched) and "pressed" or self.rest]
    Tint(self.outer, style and C[style[1]], style and C[style[2]])
    Tint(self.inner, style and style[3] and C[style[3]], style and style[4] and C[style[4]])
    local color = self.fillKey and C[self.fillKey]
    if color then
        self.fill:SetColorTexture(color[1], color[2], color[3], self.alpha)
        self.fill:Show()
    else
        self.fill:Hide()
    end
    if self.marked then
        Tint(self.mark, self.marked, self.marked)
    elseif self.mark then
        Tint(self.mark)
    end
end

-- What the screens call the frame's background colour. The colour is the kind's own here;
-- only how solid it is can be asked for.
function Art:Fill(_, _, _, alpha)
    if alpha then self.alpha = alpha end
    self:Repaint()
end

-- What the screens call the frame's border colour, which they change to point a frame out
-- (the chosen lure, a rare catch). Here that is a line just inside the bevel.
function Art:Edge(r, g, b, a)
    local border = W.COLORS.border
    local plain = a == 0 or not r
        or (math.abs(r - border[1]) + math.abs(g - border[2]) + math.abs(b - border[3]) < 0.01)
    if plain then
        self.marked = nil
    else
        self.mark = self.mark or Ring(self.frame, self.frame, 2, "ARTWORK")
        self.marked = { r, g, b }
    end
    self:Repaint()
end

-- A bevel that stands by itself: style is one of STYLES, fillKey a colour's name or nil
local function Loose(frame, target, style, fillKey, layer)
    local art = R.Art(frame, target, layer)
    art.rest, art.fillKey = style, fillKey
    arts[#arts + 1] = art
    art:Repaint()
    return art
end

-- Paints one skinned frame (an entry of Widgets.lua's list)
function R.Paint(entry, alpha)
    local art = entry.retro
    if not art then
        art = R.Art(entry.frame)
        entry.retro = art
        entry.frame:SetBackdrop(nil)
        local kind = entry.kind
        if not kind then
            if entry.group or entry.color == W.COLORS.background then
                kind = "window"
            elseif entry.color == W.COLORS.button then
                kind = "button"
            else
                kind = "field"
            end
        end
        local parts = KINDS[kind] or KINDS.button
        art.kind, art.rest, art.fillKey = kind, parts[1], parts[2]
    end
    entry.custom = art
    art.alpha = alpha or 1
    art:Repaint()
end

-- The art of a skinned frame, once it has been painted
local function ArtOf(frame)
    local entry = frame.keepnetSkin
    return entry and entry.retro
end

-- A button goes in while the mouse holds it, and what is on it moves down and right a dot
function R.Pressable(button)
    local function Set(down)
        local art = ArtOf(button)
        if not art or art.down == down then return end
        art.down = down
        art:Repaint()
        if button.keepnetNudge then button.keepnetNudge(down) end
    end
    button.keepnetNudge = function(down)
        button.label:ClearAllPoints()
        button.label:SetPoint("CENTER", down and 1 or 0, down and -1 or 0)
    end
    button:HookScript("OnMouseDown", function() Set(true) end)
    button:HookScript("OnMouseUp", function() Set(false) end)
    button:HookScript("OnHide", function() Set(false) end)
end

-- A button that stays in while something is switched on. latch:SetShown(true/false)
function R.Latch(button)
    local latch = {}
    function latch:SetShown(on)
        local art = ArtOf(button)
        if not art then return end
        art.latched = on and true or false
        art:Repaint()
    end
    return latch
end

-- ---------------------------------------------------------------------------------------------
-- The small pictures: each "#" is one dot
-- ---------------------------------------------------------------------------------------------
local GLYPHS = {
    check = { "......#", ".....##", "#...###", "##.###.", "#####..", ".###...", "..#...." },
    close = { "##....##", ".##..##.", "..####..", "...##...", "..####..", ".##..##.", "##....##" },
    down = { "#######", ".#####.", "..###..", "...#..." },
    dots = { "##.##.##", "##.##.##" },
}
local glyphs = {}

-- A frame showing one of them. glyph:SetInk(name) colours it with one of the scheme's colours.
function R.Glyph(parent, name, ink)
    local rows = GLYPHS[name]
    local glyph = CreateFrame("Frame", nil, parent)
    glyph:SetSize(#rows[1], #rows)
    glyph.parts = {}
    for y, row in ipairs(rows) do
        local x = 1
        while x <= #row do
            if row:sub(x, x) == "#" then
                local stop = x
                while row:sub(stop + 1, stop + 1) == "#" do stop = stop + 1 end
                local part = glyph:CreateTexture(nil, "OVERLAY")
                part:SetPoint("TOPLEFT", x - 1, -(y - 1))
                part:SetSize(stop - x + 1, 1)
                glyph.parts[#glyph.parts + 1] = part
                x = stop + 1
            else
                x = x + 1
            end
        end
    end
    function glyph:SetInk(key)
        self.ink = key
        local color = C[key] or C.text
        for _, part in ipairs(self.parts) do
            part:SetColorTexture(color[1], color[2], color[3], 1)
        end
    end
    -- It stands where a letter stood in the other looks, which the screens colour
    glyph.SetTextColor = function() end
    glyph:SetInk(ink or "text")
    glyphs[#glyphs + 1] = glyph
    return glyph
end

-- ---------------------------------------------------------------------------------------------
-- The title bar
-- ---------------------------------------------------------------------------------------------
local painters = {} -- everything else that has colours of its own: called when they change

local function Painted(fn)
    painters[#painters + 1] = fn
    fn()
end

-- A small button for a title bar, with one of the small pictures on it
function R.CaptionButton(parent, glyph, onClick)
    local button = W.Button(parent, "", 16, 14, onClick)
    local rows = GLYPHS[glyph]
    local x, y = math.floor((16 - #rows[1]) / 2), -math.floor((14 - #rows) / 2)
    button.glyph = R.Glyph(button, glyph)
    button.glyph:SetPoint("TOPLEFT", x, y)
    button.keepnetNudge = function(down)
        button.glyph:ClearAllPoints()
        button.glyph:SetPoint("TOPLEFT", x + (down and 1 or 0), y - (down and 1 or 0))
    end
    return button
end

-- The bar across the top of a window. title and onClose (a close box) can be left out: the
-- live panel writes its own texts on the bar. Returns the bar, to hang texts on.
function R.Caption(frame, title, onClose)
    local bar = frame:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", 3, -3)
    bar:SetPoint("TOPRIGHT", -3, -3)
    bar:SetHeight(18)
    Painted(function() bar:SetColorTexture(C.title[1], C.title[2], C.title[3], 1) end)
    if title then
        local text = W.Text(frame, "GameFontNormalLarge", title)
        text:SetSurface("title")
        text:SetPoint("LEFT", bar, "LEFT", 3, 0)
        frame.keepnetTitle = text
    end
    if onClose then
        local close = R.CaptionButton(frame, "close", onClose)
        close:SetPoint("TOPRIGHT", -5, -5)
        frame.keepnetClose = close
    end
    return bar
end

-- ---------------------------------------------------------------------------------------------
-- Tabs, and the framed page they belong to. The tabs stand in a row on the page's top edge;
-- the one in front is two dots taller and covers that edge under itself.
-- ---------------------------------------------------------------------------------------------
R.PAGE_TOP, R.PAGE_SIDE = -50, 8

function R.Page(window)
    local page = CreateFrame("Frame", nil, window)
    page:SetPoint("TOPLEFT", R.PAGE_SIDE, R.PAGE_TOP)
    page:SetPoint("BOTTOMRIGHT", -R.PAGE_SIDE, R.PAGE_SIDE)
    Loose(page, page, "button")
    return page
end

-- tab:Place(window, x) puts it at x along the page's top edge and returns the next tab's x
function R.Tab(parent, title, onClick)
    local tab = CreateFrame("Button", nil, parent)
    tab.retroTab = true
    tab.label = W.Text(tab, "GameFontHighlightSmall", title)
    tab.label:SetPoint("CENTER")
    local width = math.max(48, math.floor((tab.label:GetStringWidth() or 40) + 0.5) + 16)
    tab:SetSize(width, 20)

    local fill = tab:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 0)
    local function Line(layer) return tab:CreateTexture(nil, layer or "BORDER") end
    local left, top, corner = Line(), Line(), Line()
    left:SetPoint("TOPLEFT", 0, -2)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    top:SetPoint("TOPLEFT", 2, 0)
    top:SetPoint("TOPRIGHT", -2, 0)
    top:SetHeight(1)
    corner:SetPoint("TOPLEFT", 1, -1)
    corner:SetSize(1, 1)
    local right, rightInner, rightCorner = Line(), Line(), Line()
    right:SetPoint("TOPRIGHT", 0, -2)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    rightInner:SetPoint("TOPRIGHT", -1, -2)
    rightInner:SetPoint("BOTTOMRIGHT", -1, 0)
    rightInner:SetWidth(1)
    rightCorner:SetPoint("TOPRIGHT", -1, -1)
    rightCorner:SetSize(1, 1)
    Painted(function()
        local function Set(texture, color) texture:SetColorTexture(color[1], color[2], color[3], 1) end
        Set(fill, C.face)
        Set(left, C.hilight)
        Set(top, C.hilight)
        Set(corner, C.hilight)
        Set(right, C.dark)
        Set(rightCorner, C.dark)
        Set(rightInner, C.shadow)
    end)

    function tab:Place(window, x)
        self.window, self.x = window, x
        self:SetSelected(self.selected)
        return x + width
    end

    function tab:SetSelected(selected)
        self.selected = selected and true or false
        self:SetHeight(self.selected and 24 or 20)
        self.label:ClearAllPoints()
        self.label:SetPoint("CENTER", 0, self.selected and 1 or 0)
        if self.window then
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", self.window, "TOPLEFT", self.x, R.PAGE_TOP - (self.selected and 2 or 0))
            self:SetFrameLevel((self.window:GetFrameLevel() or 1) + (self.selected and 4 or 3))
        end
    end

    tab:SetScript("OnClick", onClick)
    return tab
end

-- ---------------------------------------------------------------------------------------------
-- The pieces of the smaller building blocks
-- ---------------------------------------------------------------------------------------------
-- A tick box: the tick is one of the small pictures
function R.Tick(check)
    check:SetSize(13, 13)
    local glyph = R.Glyph(check, "check")
    glyph:SetPoint("TOPLEFT", 3, -3)
    local set = check.SetChecked
    function check:keepnetSync()
        glyph:SetShown(self:GetChecked() and true or false)
    end
    check.SetChecked = function(self, value)
        set(self, value)
        self:keepnetSync()
    end
    check:keepnetSync()
end

-- A slider: a groove across the middle and a raised handle
function R.Thumb(slider)
    local lines = {}
    for i, key in ipairs({ "shadow", "dark", "hilight" }) do
        local line = slider:CreateTexture(nil, "BORDER")
        line:SetHeight(1)
        line:SetPoint("LEFT", 0, 2 - i)
        line:SetPoint("RIGHT", 0, 2 - i)
        lines[i] = { line, key }
    end
    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(9, 14)
    slider:SetThumbTexture(thumb)
    Painted(function()
        for _, entry in ipairs(lines) do
            local color = C[entry[2]]
            entry[1]:SetColorTexture(color[1], color[2], color[3], 1)
        end
        thumb:SetColorTexture(C.face[1], C.face[2], C.face[3], 1)
    end)
    Loose(slider, thumb, "button", nil, "OVERLAY")
end

-- A drop-down: a text box with a small button at its right end, an arrow on it
function R.Combo(dropdown)
    dropdown.label:SetSurface("paper")
    local box = CreateFrame("Frame", nil, dropdown)
    box:SetPoint("TOPRIGHT", -2, -2)
    box:SetPoint("BOTTOMRIGHT", -2, 2)
    box:SetWidth(16)
    Loose(box, box, "button", "face")
    local arrow = R.Glyph(box, "down")
    arrow:SetPoint("TOPLEFT", 4, -6)
end

-- A progress bar's filling and its text. Over the filling the text is light, beside it dark:
-- two texts, the light one cut off where the filling ends. Returns the filling (a frame: set
-- its width, show it, hide it) and the text (text:SetText).
function R.Progress(bar)
    local back = W.Text(bar, "GameFontHighlightSmall")
    back:SetPoint("CENTER")
    local fill = CreateFrame("Frame", nil, bar)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    if fill.SetClipsChildren then fill:SetClipsChildren(true) end
    local paint = fill:CreateTexture(nil, "BACKGROUND")
    paint:SetAllPoints()
    W.Accent(paint, 1)
    local front = W.Text(fill, "GameFontHighlightSmall")
    front:SetPoint("CENTER", bar, "CENTER")
    front:SetSurface("select")
    local text = {}
    function text:SetText(value)
        back:SetText(value)
        front:SetText(value)
    end
    return fill, text
end

-- The white sheet behind a table's rows, in a frame that goes in, column headings and all
function R.Paper(t, width, rowHeight, visible)
    local sheet = t:CreateTexture(nil, "BACKGROUND")
    sheet:SetPoint("TOPLEFT", -2, 2)
    sheet:SetPoint("BOTTOMRIGHT", t, "TOPLEFT", width + 2, -rowHeight * (visible + 1) - 2)
    sheet:SetColorTexture(0, 0, 0, 0)
    Loose(t, sheet, "field", "paper")
end

-- A dividing line: cut into the face, dark above and bright under it
function R.Rule(texture)
    local parent = texture:GetParent()
    local under = parent:CreateTexture(nil, "ARTWORK")
    under:SetHeight(1)
    under:SetPoint("TOPLEFT", texture, "BOTTOMLEFT")
    under:SetPoint("TOPRIGHT", texture, "BOTTOMRIGHT")
    Painted(function()
        texture:SetColorTexture(C.shadow[1], C.shadow[2], C.shadow[3], 1)
        under:SetColorTexture(C.hilight[1], C.hilight[2], C.hilight[3], 1)
    end)
    -- The bright line comes and goes with the dark one
    local show, hide = texture.Show, texture.Hide
    texture.Show = function(self)
        show(self)
        under:Show()
    end
    texture.Hide = function(self)
        hide(self)
        under:Hide()
    end
    texture.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end

-- A line of a list or a menu: under the mouse it turns the selection's colour and its texts
-- light. texts: the row's texts; rest: what they stand on otherwise ("face" or "paper");
-- mark: a square or small picture on the row that has to turn light with them.
-- row.keepnetCool() puts it back, for a list that is shown again.
function R.Hover(row, texts, rest, mark)
    local hot = row:CreateTexture(nil, "BACKGROUND")
    hot:SetAllPoints()
    W.Accent(hot, 1)
    hot:Hide()
    local function Set(on)
        hot:SetShown(on)
        for _, text in ipairs(texts) do
            text:SetSurface(on and "select" or rest)
        end
        if mark then
            local color = on and C.selectText or C.select
            mark:SetColorTexture(color[1], color[2], color[3], 1)
        end
    end
    for _, text in ipairs(texts) do text:SetSurface(rest) end
    row:HookScript("OnEnter", function() Set(true) end)
    row:HookScript("OnLeave", function() Set(false) end)
    row.keepnetCool = function() Set(false) end
end

-- ---------------------------------------------------------------------------------------------
-- The colours in use. accent: the player's own colour, when the theme's isn't wanted: it
-- becomes the title bar and the selection, as changing those two did on that screen.
-- ---------------------------------------------------------------------------------------------
function R.Apply(scheme, accent)
    for part, color in pairs(scheme) do
        if type(color) == "table" and C[part] then
            C[part][1], C[part][2], C[part][3] = color[1], color[2], color[3]
        end
    end
    if accent then
        local on = Light(accent) and { 0, 0, 0 } or { 1, 1, 1 }
        for _, part in ipairs({ "title", "select" }) do
            C[part][1], C[part][2], C[part][3] = accent[1], accent[2], accent[3]
        end
        for _, part in ipairs({ "titleText", "selectText" }) do
            C[part][1], C[part][2], C[part][3] = on[1], on[2], on[3]
        end
    end
    if font then font:SetTextColor(C.text[1], C.text[2], C.text[3]) end
    for _, art in ipairs(arts) do art:Repaint() end
    for _, glyph in ipairs(glyphs) do glyph:SetInk(glyph.ink) end
    for _, paint in ipairs(painters) do paint() end
    for text in pairs(texts) do Colour(text) end
end
