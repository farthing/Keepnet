-- Keepnet: the looks with round corners: "Keepnet rounded" (the flat panels and buttons of the
-- Keepnet look, rounded) and "Glass" (the same shapes made to look like panes of dark glass).
--
-- A frame's own backdrop can only be square, so a round one is put together here from pieces:
-- a quarter circle in each corner (Media\RoundFill*.tga, white, so it takes any colour) with
-- plain colour between them, and the border the same way from a quarter ring
-- (Media\RoundRing*.tga) and four lines. Big frames (the window, the live panel) get a corner
-- 8 wide, everything else one 4 wide. Column headings of a table stay square: they stand
-- shoulder to shoulder.
--
-- Glass adds, to the same pieces:
--   a body you can see through, as dense as the colours in use say (and the player's own
--     setting for the window and the live panel);
--   a rim of light in place of the border: bright along the top, fading down the sides,
--     faint along the bottom;
--   a wash of light over the top of panes and buttons, fading downwards;
--   a soft shadow round the window and the live panel (Media\GlassShadow8.tga), so their
--     edge holds against a bright scene.
-- The game cannot blur what is behind a frame, so this glass is clear, not frosted. How glass
-- is made of such layers here was learnt from LibGlass (see CREDITS.md); the drawing and the
-- pictures are Keepnet's own, made by tools\make_art.py.
local addonName, ns = ...
local W = ns.Widgets

local Round = {}
ns.Round = Round

local FLAT = "Interface\\Buttons\\WHITE8x8"
local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local FILL = { [8] = MEDIA .. "RoundFill8.tga", [4] = MEDIA .. "RoundFill4.tga" }
local RING = { [8] = MEDIA .. "RoundRing8.tga", [4] = MEDIA .. "RoundRing4.tga" }
local SHADOW = MEDIA .. "GlassShadow8.tga"

-- The pictures show the top left corner; the other three are the same picture turned over
local CORNERS = {
    TOPLEFT = { 0, 1, 0, 1 }, TOPRIGHT = { 1, 0, 0, 1 },
    BOTTOMLEFT = { 0, 1, 1, 0 }, BOTTOMRIGHT = { 1, 0, 1, 0 },
}

-- Glass: how strong each part of the rim is, how strong the wash, how far the shadow
-- reaches beyond the frame (the shadow picture is that much and the corner across), and how
-- dark it is
local RIM_TOP, RIM_BOTTOM = 0.55, 0.12
local WASH = 0.10
local SHADOW_REACH, SHADOW_ALPHA = 12, 0.85
-- The kinds of piece that hold other text and so must be dense: a menu, a list that drops down
local DENSE = { menu = 0.93, list = 0.93 }
-- The kinds that get the wash of light: panes and buttons, not what is set into them
local NO_WASH = { field = true, thin = true, track = true, slot = true, menu = true, list = true }

local Art = {}
Art.__index = Art

local function Corner(frame, layer, level, file, size, point, coords, x, y)
    local texture = frame:CreateTexture(nil, layer, nil, level)
    texture:SetTexture(file)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    texture:SetSize(size, size)
    texture:SetPoint(point, x or 0, y or 0)
    return texture
end

local function Band(frame, layer, level, point, x, y, otherPoint, otherX, otherY)
    local texture = frame:CreateTexture(nil, layer, nil, level)
    texture:SetPoint(point, x, y)
    texture:SetPoint(otherPoint, otherX, otherY)
    return texture
end

-- A texture that goes from one see-through to another, bottom to top. (On this client such
-- a texture ignores SetAlpha: how see-through it is has to be in its two colours.)
local function Gradient(texture, r, g, b, bottom, top)
    if texture.SetGradient and CreateColor then
        texture:SetTexture(FLAT)
        texture:SetGradient("VERTICAL", CreateColor(r, g, b, bottom), CreateColor(r, g, b, top))
    else
        texture:SetColorTexture(r, g, b, (bottom + top) / 2)
    end
end

local function Make(frame, radius)
    local art = setmetatable({ corners = {}, bands = {}, ringCorners = {}, ringLines = {} }, Art)
    for point, coords in pairs(CORNERS) do
        art.corners[#art.corners + 1] = Corner(frame, "BACKGROUND", 0, FILL[radius], radius, point, coords)
        local ring = Corner(frame, "BORDER", 0, RING[radius], radius, point, coords)
        ring.top = point == "TOPLEFT" or point == "TOPRIGHT"
        art.ringCorners[#art.ringCorners + 1] = ring
    end
    -- The inside: a strip between the top corners, one between the bottom corners, and
    -- everything between those two
    local top = Band(frame, "BACKGROUND", 0, "TOPLEFT", radius, 0, "TOPRIGHT", -radius, 0)
    top:SetHeight(radius)
    local bottom = Band(frame, "BACKGROUND", 0, "BOTTOMLEFT", radius, 0, "BOTTOMRIGHT", -radius, 0)
    bottom:SetHeight(radius)
    local middle = Band(frame, "BACKGROUND", 0, "TOPLEFT", 0, -radius, "BOTTOMRIGHT", 0, radius)
    art.bands = { top, bottom, middle }
    -- The border between the corners
    art.lineTop = Band(frame, "BORDER", 0, "TOPLEFT", radius, 0, "TOPRIGHT", -radius, 0)
    art.lineTop:SetHeight(1)
    art.lineBottom = Band(frame, "BORDER", 0, "BOTTOMLEFT", radius, 0, "BOTTOMRIGHT", -radius, 0)
    art.lineBottom:SetHeight(1)
    art.lineLeft = Band(frame, "BORDER", 0, "TOPLEFT", 0, -radius, "BOTTOMLEFT", 0, radius)
    art.lineLeft:SetWidth(1)
    art.lineRight = Band(frame, "BORDER", 0, "TOPRIGHT", 0, -radius, "BOTTOMRIGHT", 0, radius)
    art.lineRight:SetWidth(1)
    art.ringLines = { art.lineTop, art.lineBottom, art.lineLeft, art.lineRight }
    return art
end

-- Glass: the wash of light over the top of a pane, as deep as it is given
local function AddWash(art, frame, radius, depth)
    for _, point in ipairs({ "TOPLEFT", "TOPRIGHT" }) do
        local corner = Corner(frame, "BACKGROUND", 2, FILL[radius], radius, point, CORNERS[point])
        corner:SetVertexColor(1, 1, 1, WASH)
    end
    local strip = Band(frame, "BACKGROUND", 2, "TOPLEFT", radius, 0, "TOPRIGHT", -radius, 0)
    strip:SetHeight(radius)
    strip:SetColorTexture(1, 1, 1, WASH)
    local fade = Band(frame, "BACKGROUND", 2, "TOPLEFT", 0, -radius, "TOPRIGHT", 0, -radius)
    fade:SetHeight(depth)
    Gradient(fade, 1, 1, 1, 0, WASH)
    art.wash = fade
end

-- Glass: the soft shadow round a big frame. The picture is the top left corner of it: the
-- part beyond the frame's own corner, with nothing where the frame is. Its last column and
-- last row are the shadow of a straight edge, which the four sides are drawn from.
local function AddShadow(art, frame, radius)
    local reach = SHADOW_REACH
    local size = reach + radius
    local edge = reach / size -- how much of the picture lies beyond the frame
    local last = 1 - 1 / 64   -- the picture's last column or row
    art.shadow = {}
    local function Keep(texture)
        texture:SetVertexColor(0, 0, 0, SHADOW_ALPHA)
        art.shadow[#art.shadow + 1] = texture
        return texture
    end
    local offsets = {
        TOPLEFT = { -reach, reach }, TOPRIGHT = { reach, reach },
        BOTTOMLEFT = { -reach, -reach }, BOTTOMRIGHT = { reach, -reach },
    }
    for point, coords in pairs(CORNERS) do
        Keep(Corner(frame, "BACKGROUND", -8, SHADOW, size, point, coords, offsets[point][1], offsets[point][2]))
    end
    -- Each side lies outside the frame, between two corners
    local function Side(left, right, top, bottom)
        local texture = Keep(frame:CreateTexture(nil, "BACKGROUND", nil, -8))
        texture:SetTexture(SHADOW)
        texture:SetTexCoord(left, right, top, bottom)
        return texture
    end
    local top = Side(last, 1, 0, edge)
    top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", radius, 0)
    top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -radius, 0)
    top:SetHeight(reach)
    local bottom = Side(last, 1, edge, 0)
    bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", radius, 0)
    bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -radius, 0)
    bottom:SetHeight(reach)
    local left = Side(0, edge, last, 1)
    left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, -radius)
    left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, radius)
    left:SetWidth(reach)
    local right = Side(edge, 0, last, 1)
    right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -radius)
    right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, radius)
    right:SetWidth(reach)
end

-- What the screens call the frame's background colour
function Art:Fill(r, g, b, a)
    a = a or 1
    for _, texture in ipairs(self.corners) do texture:SetVertexColor(r, g, b, a) end
    for _, texture in ipairs(self.bands) do texture:SetColorTexture(r, g, b, a) end
end

-- What the screens call the frame's border colour
function Art:Edge(r, g, b, a)
    a = a or 1
    if self.glass then
        local border = W.COLORS.border
        if math.abs(r - border[1]) + math.abs(g - border[2]) + math.abs(b - border[3]) < 0.01 then
            -- The usual border: the rim of light, bright along the top and fading downwards
            local top, bottom = RIM_TOP * a * self.rim, RIM_BOTTOM * a * self.rim
            for _, texture in ipairs(self.ringCorners) do
                texture:SetVertexColor(r, g, b, texture.top and top or bottom)
            end
            self.lineTop:SetColorTexture(r, g, b, top)
            self.lineBottom:SetColorTexture(r, g, b, bottom)
            Gradient(self.lineLeft, r, g, b, bottom, top)
            Gradient(self.lineRight, r, g, b, bottom, top)
            return
        end
        -- A colour of its own points the frame out (the chosen lure, a rare catch): all round
        self.lineLeft:SetTexture(FLAT)
        self.lineRight:SetTexture(FLAT)
        self.lineLeft:SetVertexColor(1, 1, 1, 1)
        self.lineRight:SetVertexColor(1, 1, 1, 1)
    end
    for _, texture in ipairs(self.ringCorners) do texture:SetVertexColor(r, g, b, a) end
    for _, texture in ipairs(self.ringLines) do texture:SetColorTexture(r, g, b, a) end
end

-- Whether this piece is drawn round: everything but a table's column headings
function Round.Wants(entry)
    return entry.kind ~= "header"
end

-- Paints one skinned frame (an entry of Widgets.lua's list) in the colour and with the
-- see-through it is given
function Round.Paint(entry, color, alpha)
    local art = entry.round
    if not art then
        local radius = entry.group and 8 or 4
        art = Make(entry.frame, radius)
        entry.round = art
        entry.frame:SetBackdrop(nil)
        if W.glass then
            art.glass = true
            -- The rim is fainter on the small pieces, so a screen full of them stays calm
            art.rim = entry.group and 1 or 0.6
            if entry.group then AddShadow(art, entry.frame, radius) end
            if not NO_WASH[entry.kind] then AddWash(art, entry.frame, radius, entry.group and 46 or 7) end
        end
    end
    entry.custom = art
    if W.glass and DENSE[entry.kind] then
        -- A menu or a list lies over other text: nearly solid, in the pane's colour
        local pane = W.COLORS.background
        art:Fill(pane[1], pane[2], pane[3], DENSE[entry.kind])
    else
        art:Fill(color[1], color[2], color[3], alpha)
    end
    local border = W.COLORS.border
    art:Edge(border[1], border[2], border[3], border[4] or 1)
end
