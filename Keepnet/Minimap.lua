-- Keepnet: its button on the minimap, and what its entry in the minimap's addon menu does.
--
-- A left click opens or closes the window, a right click shows or hides the live panel, and
-- the button can be dragged round the minimap. Two settings, the character's own like every
-- other: minimapButton (shown or not) and minimapAngle (where on the edge: degrees, 0 at the
-- right, counted towards the top).
--
-- The button comes to be in one of two ways, decided once, at the first entry into the world
-- (by then every addon and every library an addon brings has been loaded):
--
--   * Through LibDBIcon, when another addon has loaded it together with LibDataBroker. The
--     button is then one of that library's, like most addons' buttons, which is what
--     minimap addons and button collectors know how to gather, skin and tidy away. Keepnet
--     also shows as a launcher on a broker bar (Titan Panel and the like).
--   * As a button of Keepnet's own otherwise, put together from the same pieces of the
--     game's art so that it looks like the others.
--
-- Keepnet brings neither library. Making the button through LibDBIcon when somebody else
-- brought it is what Mastercraft and Forever Dungeon Journal do on this client; the pieces a
-- minimap button is made of, and the names by which a minimap addon says what shape the
-- minimap has, are LibDBIcon's. Nothing was copied: see CREDITS.md.
local _, ns = ...
local Util = ns.Util

local Button = {}
ns.MinimapButton = Button

local NAME = "Keepnet"
Button.ICON = "Interface\\AddOns\\" .. ns.ADDON .. "\\Media\\Icon"
local DEFAULT_ANGLE = 190
local EDGE = 5 -- how far outside the minimap's edge the middle of the button sits
local ACTION = "|cff4fc3f7%s|r  %s"

-- ---------------------------------------------------------------------------------------------
-- What it does
-- ---------------------------------------------------------------------------------------------
local function Clicked(mouseButton)
    if mouseButton == "RightButton" then
        if ns.LivePanel then ns.LivePanel.Toggle() end
    elseif ns.UI then
        ns.UI.Toggle()
    end
end

-- The lines of its tooltip, on whichever tooltip shows them
local function Describe(tooltip, draggable)
    tooltip:AddLine("Keepnet  |cff9d9d9dv" .. ns.VERSION .. "|r")
    tooltip:AddLine(ACTION:format("Left click", "the window"), 0.85, 0.85, 0.85)
    tooltip:AddLine(ACTION:format("Right click", "the live panel"), 0.85, 0.85, 0.85)
    if draggable then tooltip:AddLine(ACTION:format("Drag", "move this button"), 0.85, 0.85, 0.85) end
end

-- ---------------------------------------------------------------------------------------------
-- Keepnet's own button
-- ---------------------------------------------------------------------------------------------
local button

-- A minimap addon says what shape it has given the minimap through a function they all
-- share, GetMinimapShape: "ROUND", "SQUARE", or which corners are still round:
-- "CORNER-TOPLEFT" (that one), "SIDE-LEFT" (both on that side), "TRICORNER-TOPLEFT" (all
-- but the one opposite). Without one the minimap is round.
local function RoundAt(right, top)
    local ok, shape = pcall(function() return GetMinimapShape and GetMinimapShape() end)
    if not ok or type(shape) ~= "string" or Util.Hidden(shape) then return true end
    if shape == "SQUARE" then return false end
    local kind, where = shape:match("^(%u+)%-(%u+)$")
    if not kind then return true end
    local vertical, horizontal = top and "TOP" or "BOTTOM", right and "RIGHT" or "LEFT"
    if kind == "CORNER" then
        return where == vertical .. horizontal
    elseif kind == "SIDE" then
        return where == vertical or where == horizontal
    elseif kind == "TRICORNER" then
        return where ~= (top and "BOTTOM" or "TOP") .. (right and "LEFT" or "RIGHT")
    end
    return true
end

-- Puts the button on the minimap's edge in the direction of its angle: on the circle where
-- the minimap is round there, on the side of the square where it isn't. A button that
-- something else has taken off the minimap (a collector's drawer) is left where it was put.
local function Place()
    if not button or button:GetParent() ~= Minimap then return end
    local angle = math.rad(tonumber(ns.settings.minimapAngle) or DEFAULT_ANGLE)
    local x, y = math.cos(angle), math.sin(angle)
    local halfWidth = (Minimap:GetWidth() or 140) / 2 + EDGE
    local halfHeight = (Minimap:GetHeight() or 140) / 2 + EDGE
    if not RoundAt(x >= 0, y > 0) then
        -- Out to the square's side: the longer of the two reaches all the way
        local longer = math.max(math.abs(x), math.abs(y))
        x, y = x / longer, y / longer
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * halfWidth, y * halfHeight)
end

-- While it is dragged: towards the mouse, as seen from the middle of the minimap
local function Follow()
    local middleX, middleY = Minimap:GetCenter()
    local mouseX, mouseY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not (middleX and middleY and mouseX and mouseY and scale and scale > 0) then return end
    ns.settings.minimapAngle = math.deg(math.atan2(mouseY / scale - middleY, mouseX / scale - middleX)) % 360
    Place()
end

local function Build()
    button = CreateFrame("Button", "KeepnetMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- The game's own pieces: a dark disc, the picture on it, and the ring round both
    local disc = button:CreateTexture(nil, "BACKGROUND")
    disc:SetSize(24, 24)
    disc:SetPoint("CENTER")
    disc:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18, 18)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture(Button.ICON)
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetSize(50, 50)
    ring:SetPoint("TOPLEFT")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton) Clicked(mouseButton) end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", Follow)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        if self:GetScript("OnUpdate") then return end -- being dragged
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        Describe(GameTooltip, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- A minimap addon gives the minimap another size after login: back onto its edge
    Minimap:HookScript("OnSizeChanged", Place)
end

-- ---------------------------------------------------------------------------------------------
-- The same through LibDBIcon
-- ---------------------------------------------------------------------------------------------
local broker -- Keepnet as LibDataBroker knows it
local icons  -- LibDBIcon, once the button is one of its own

-- LibDBIcon keeps a button's place and whether it is hidden in a table the addon hands it
-- (minimapPos, hide). Keepnet hands it this one, which holds nothing itself: reading and
-- writing those two goes straight to the settings, so the angle the library is given, and
-- the one it writes when its button is dragged, are always those of the character being
-- played, and nothing of the library's is saved. Whatever else the library notes in it
-- lasts until the next login or reload.
local applied = {} -- what was last passed on to the library: shown, angle
local other = {}
local place = setmetatable({}, {
    __index = function(_, key)
        local settings = ns.settings
        if key == "minimapPos" then return settings and tonumber(settings.minimapAngle) or DEFAULT_ANGLE end
        if key == "hide" then return not (settings and settings.minimapButton) end
        return other[key]
    end,
    __newindex = function(_, key, value)
        local settings = ns.settings
        if key == "minimapPos" then
            if settings and type(value) == "number" then
                settings.minimapAngle = value
                applied.angle = value -- the library moved its button there itself
            end
        elseif key == "hide" then
            if settings then settings.minimapButton = not value end
        else
            other[key] = value
        end
    end,
})

local function Library(name)
    if not LibStub then return nil end
    local ok, library = pcall(LibStub, name, true)
    return ok and type(library) == "table" and library or nil
end

local function ThroughLibrary()
    local data = Library("LibDataBroker-1.1")
    if not (data and data.NewDataObject) then return false end
    local ok, object = pcall(data.NewDataObject, data, NAME, {
        type = "launcher",
        label = NAME,
        text = NAME,
        icon = Button.ICON,
        OnClick = function(_, mouseButton) Clicked(mouseButton) end,
        OnTooltipShow = function(tooltip)
            if not (tooltip and tooltip.AddLine) then return end
            -- On a broker bar there is nothing to drag
            local owner = tooltip.GetOwner and tooltip:GetOwner()
            local name = owner and owner.GetName and owner:GetName()
            Describe(tooltip, type(name) == "string" and name:find("^LibDBIcon10_") ~= nil)
        end,
    })
    if not ok or type(object) ~= "table" then return false end
    broker = object
    local library = Library("LibDBIcon-1.0")
    if not (library and library.Register) then return false end
    if not pcall(library.Register, library, NAME, broker, place) then return false end
    icons = library
    return true
end

-- ---------------------------------------------------------------------------------------------
-- Shown or not, and where
-- ---------------------------------------------------------------------------------------------
-- The library is only told when what it was last told has changed: its button may by then
-- be in the keeping of a minimap addon, which a needless show or move would undo.
local function Sync()
    local settings = ns.settings
    if not settings then return end
    local shown = settings.minimapButton and true or false
    local angle = tonumber(settings.minimapAngle) or DEFAULT_ANGLE
    if icons then
        if shown ~= applied.shown then
            pcall(shown and icons.Show or icons.Hide, icons, NAME)
        elseif shown and angle ~= applied.angle and icons.Refresh then
            pcall(icons.Refresh, icons, NAME)
        end
    elseif button then
        if shown ~= applied.shown then button:SetShown(shown) end
        if angle ~= applied.angle then Place() end
    end
    applied.shown, applied.angle = shown, angle
end

local decided = false

local function Start()
    if not ns.settings or not Minimap then return end
    if not decided then
        decided = true
        if ThroughLibrary() then
            -- The library has shown or hidden its button, and put it at the angle
            applied.shown = ns.settings.minimapButton and true or false
            applied.angle = tonumber(ns.settings.minimapAngle) or DEFAULT_ANGLE
        else
            Build()
        end
    end
    Sync()
    -- Minimap addons reshape the minimap a moment after the world is entered
    if button then C_Timer.After(1, Place) end
end

-- /kn minimap: shown, or not
function Button.Toggle()
    ns.settings.minimapButton = not ns.settings.minimapButton
    ns.Fire("SETTINGS")
    if ns.UI then ns.UI.Refresh() end
    return ns.settings.minimapButton
end

-- (for the tests) "library", "own", or nil before the world was entered
function Button.Kind()
    return icons and "library" or button and "own" or nil
end

ns.On("WORLD", Start)
ns.On("SETTINGS", Sync)

-- ---------------------------------------------------------------------------------------------
-- The addon menu on the minimap (named in the TOC file as AddonCompartmentFunc and the two
-- beside it): the same clicks and the same lines
-- ---------------------------------------------------------------------------------------------
function Keepnet_OnAddonCompartmentClick(_, mouseButton)
    Clicked(mouseButton)
end

function Keepnet_OnAddonCompartmentEnter(_, entry)
    if not GameTooltip then return end
    GameTooltip:SetOwner(entry or UIParent, "ANCHOR_LEFT")
    Describe(GameTooltip, false)
    GameTooltip:Show()
end

function Keepnet_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end
