-- Keepnet: the "Keepnet rounded" look. The same flat panels and buttons as the Keepnet look,
-- with round corners. A frame's own backdrop can only be square, so a round one is put
-- together here from pieces: a quarter circle in each corner (Media\RoundFill*.tga, white, so
-- it takes any colour) with plain colour between them, and the border the same way from a
-- quarter ring (Media\RoundRing*.tga) and four lines. The pictures are Keepnet's own, made by
-- tools\make_art.py.
--
-- Big frames (the window, the live panel) get a corner 8 wide, everything else one 4 wide.
-- Column headings of a table stay square: they stand shoulder to shoulder.
local addonName, ns = ...
local W = ns.Widgets

local Round = {}
ns.Round = Round

local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local FILL = { [8] = MEDIA .. "RoundFill8.tga", [4] = MEDIA .. "RoundFill4.tga" }
local RING = { [8] = MEDIA .. "RoundRing8.tga", [4] = MEDIA .. "RoundRing4.tga" }

-- The pictures show the top left corner; the other three are the same picture turned over
local CORNERS = {
    TOPLEFT = { 0, 1, 0, 1 }, TOPRIGHT = { 1, 0, 0, 1 },
    BOTTOMLEFT = { 0, 1, 1, 0 }, BOTTOMRIGHT = { 1, 0, 1, 0 },
}

local Art = {}
Art.__index = Art

local function Corner(frame, layer, file, radius, point, coords)
    local texture = frame:CreateTexture(nil, layer)
    texture:SetTexture(file)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    texture:SetSize(radius, radius)
    texture:SetPoint(point)
    return texture
end

local function Band(frame, layer, point, x, y, otherPoint, otherX, otherY)
    local texture = frame:CreateTexture(nil, layer)
    texture:SetPoint(point, x, y)
    texture:SetPoint(otherPoint, otherX, otherY)
    return texture
end

local function Make(frame, radius)
    local art = setmetatable({ corners = {}, bands = {}, ringCorners = {}, ringLines = {} }, Art)
    for point, coords in pairs(CORNERS) do
        art.corners[#art.corners + 1] = Corner(frame, "BACKGROUND", FILL[radius], radius, point, coords)
        art.ringCorners[#art.ringCorners + 1] = Corner(frame, "BORDER", RING[radius], radius, point, coords)
    end
    -- The inside: a strip between the top corners, one between the bottom corners, and
    -- everything between those two
    local top = Band(frame, "BACKGROUND", "TOPLEFT", radius, 0, "TOPRIGHT", -radius, 0)
    top:SetHeight(radius)
    local bottom = Band(frame, "BACKGROUND", "BOTTOMLEFT", radius, 0, "BOTTOMRIGHT", -radius, 0)
    bottom:SetHeight(radius)
    local middle = Band(frame, "BACKGROUND", "TOPLEFT", 0, -radius, "BOTTOMRIGHT", 0, radius)
    art.bands = { top, bottom, middle }
    -- The border between the corners
    local lineTop = Band(frame, "BORDER", "TOPLEFT", radius, 0, "TOPRIGHT", -radius, 0)
    lineTop:SetHeight(1)
    local lineBottom = Band(frame, "BORDER", "BOTTOMLEFT", radius, 0, "BOTTOMRIGHT", -radius, 0)
    lineBottom:SetHeight(1)
    local lineLeft = Band(frame, "BORDER", "TOPLEFT", 0, -radius, "BOTTOMLEFT", 0, radius)
    lineLeft:SetWidth(1)
    local lineRight = Band(frame, "BORDER", "TOPRIGHT", 0, -radius, "BOTTOMRIGHT", 0, radius)
    lineRight:SetWidth(1)
    art.ringLines = { lineTop, lineBottom, lineLeft, lineRight }
    return art
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
        art = Make(entry.frame, entry.group and 8 or 4)
        entry.round = art
        entry.frame:SetBackdrop(nil)
    end
    entry.custom = art
    art:Fill(color[1], color[2], color[3], alpha)
    local border = W.COLORS.border
    art:Edge(border[1], border[2], border[3], border[4] or 1)
end
