-- Temporary world map pins. FC.Map:Show(points) marks one or more places, opens the
-- map on the first one, and clears the marks when the map closes.
-- point = { mapID = 1444, x = 0.744, y = 0.43, title = "Name", lines = { "..." } }
local _, FC = ...
local L = FC.L
FC.Map = { points = {} }
local M = FC.Map

ForeverCraftingPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ForeverCraftingPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1.0, 1.3)
end

function ForeverCraftingPinMixin:OnAcquired(point, x, y)
    self.point = point
    self:SetPosition(x, y)
end

function ForeverCraftingPinMixin:OnMouseEnter()
    local p = self.point
    if not p then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(p.title or "", 1, 0.82, 0)
    for _, line in ipairs(p.lines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
    GameTooltip:Show()
end

function ForeverCraftingPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

local Provider = CreateFromMixins(MapCanvasDataProviderMixin)

function Provider:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("ForeverCraftingPinTemplate")
end

-- Projects a point from its own zone map onto whatever map is being viewed
-- (zone, city, continent), so pins follow the map as the player zooms out.
local function project(point, viewMapID)
    if point.mapID == viewMapID then return point.x, point.y end
    local cont, world = C_Map.GetWorldPosFromMapPos(point.mapID, CreateVector2D(point.x, point.y))
    if not cont or not world then return end
    local pos = C_Map.GetMapPosFromWorldPos(cont, world, viewMapID)
    if not pos then return end
    local x, y = pos:GetXY()
    if x < 0 or x > 1 or y < 0 or y > 1 then return end
    return x, y
end

function Provider:RefreshAllData()
    self:RemoveAllData()
    local map = self:GetMap()
    local viewID = map:GetMapID()
    if not viewID then return end
    for _, p in ipairs(M.points) do
        local ok, x, y = pcall(project, p, viewID)
        if ok and x then map:AcquirePin("ForeverCraftingPinTemplate", p, x, y) end
    end
end

local provider
local function ensureProvider()
    if not WorldMapFrame and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_WorldMap") end
    if provider or not WorldMapFrame then return end
    provider = CreateFromMixins(Provider)
    WorldMapFrame:AddDataProvider(provider)
    WorldMapFrame:HookScript("OnHide", function() M:Clear() end)
end

function M:Clear()
    wipe(self.points)
    if provider and provider:GetMap() then provider:RemoveAllData() end
end

function M:Show(points)
    ensureProvider()
    wipe(self.points)
    for _, p in ipairs(M.Nearest(points)) do
        if p.mapID and p.x and p.y then table.insert(self.points, p) end
    end
    local first = self.points[1]
    if not first then return end
    -- Say where the waypoint goes, so you have it in words too.
    FC:Print(string.format(FC.L["Waypoint: %s, %s"], first.title or "", M.Describe(first))
        .. (#self.points > 1 and string.format(FC.L[" (nearest of %d)"], #self.points) or ""))
    if FC.db.setWaypoint and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(first.mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(first.mapID, first.x, first.y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end
    if not WorldMapFrame:IsShown() then
        if C_Map.OpenWorldMap then C_Map.OpenWorldMap(first.mapID) else ToggleWorldMap() end
    end
    -- Show the zone of the first point; if the points span zones, show their continent.
    local target = first.mapID
    for _, p in ipairs(self.points) do
        if p.mapID ~= first.mapID then
            local info = C_Map.GetMapInfo(first.mapID)
            while info and info.mapType and info.mapType > Enum.UIMapType.Continent and info.parentMapID and info.parentMapID > 0 do
                info = C_Map.GetMapInfo(info.parentMapID)
            end
            if info then target = info.mapID end
            break
        end
    end
    if M.OpenMapFocus(self.points) then
        if provider then provider:RefreshAllData() end
        return
    end
    WorldMapFrame:SetMapID(target)
    if provider then provider:RefreshAllData() end
end

-- OpenMap replaces the world map with one stitched map, and choosing a zone there zooms all
-- the way out. Use its API instead: glide to the pins, zoomed to fit them (or their zone).
function M.OpenMapFocus(points)
    local API = _G.OpenMapAPI
    if not (API and API.IsStitched and API.WorldFromMap and API.ShowWorld) then return false end
    local function focus()
        if not API.IsStitched() then return end
        local minU, minV, maxU, maxV
        local function add(u, v)
            if not u then return end
            minU, maxU = math.min(minU or u, u), math.max(maxU or u, u)
            minV, maxV = math.min(minV or v, v), math.max(maxV or v, v)
        end
        for _, p in ipairs(points) do add(API.WorldFromMap(p.mapID, p.x, p.y)) end
        if not minU then return end
        -- At least the size of the first pin's zone, so a single pin shows its surroundings.
        local first = points[1]
        local zu1, zv1 = API.WorldFromMap(first.mapID, 0, 0)
        local zu2, zv2 = API.WorldFromMap(first.mapID, 1, 1)
        local span = math.max(maxU - minU, maxV - minV)
        if zu1 and zu2 then span = math.max(span, math.abs(zu2 - zu1), math.abs(zv2 - zv1)) end
        span = span * 1.25
        local zoom = span > 0 and math.min(math.max(1 / span, 1), 200) or nil
        API.ShowWorld((minU + maxU) / 2, (minV + maxV) / 2, zoom)
    end
    -- Try now and again once the map has finished opening (it may switch to stitched then).
    C_Timer.After(0, focus)
    C_Timer.After(0.25, focus)
    return API.IsStitched()
end

-- The named area at a point ("Valley of Honor"), when the game knows it. Only areas
-- you have explored are reported, so this can be nil.
function M.SubArea(p)
    if not (C_MapExplorationInfo and C_MapExplorationInfo.GetExploredAreaIDsAtPosition and C_Map.GetAreaInfo) then return nil end
    local ok, ids = pcall(C_MapExplorationInfo.GetExploredAreaIDsAtPosition, p.mapID, CreateVector2D(p.x, p.y))
    if not ok or type(ids) ~= "table" or not ids[1] then return nil end
    local name = C_Map.GetAreaInfo(ids[1])
    if name and name ~= "" and name ~= FC.Util.ZoneName(p.mapID) then return name end
end

-- A one-line description of a point: "Valley of Honor, Orgrimmar 63.2, 45.3".
function M.Describe(p)
    local zone = FC.Util.ZoneName(p.mapID)
    local area = M.SubArea(p)
    if area then zone = area .. ", " .. zone end
    return string.format("%s %.1f, %.1f", zone, p.x * 100, p.y * 100)
end

-- Points sorted nearest first. Distance is measured in world coordinates, so trainers
-- in other zones of your continent compare properly; other continents come last.
local function worldPos(mapID, x, y)
    if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if ok and cont and pos then return cont, pos:GetXY() end
end

function M.Nearest(points)
    local here = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local pos = here and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(here, "player")
    local myCont, mx, my
    if pos then myCont, mx, my = worldPos(here, pos:GetXY()) end
    local list = {}
    for i, p in ipairs(points) do
        local d = 1e12 + i
        if myCont then
            local cont, x, y = worldPos(p.mapID, p.x, p.y)
            if cont == myCont then d = (x - mx) ^ 2 + (y - my) ^ 2 end
        elseif pos and p.mapID == here then
            -- No world coordinates in this client: at least sort your own zone first.
            local px, py = pos:GetXY()
            d = (p.x - px) ^ 2 + (p.y - py) ^ 2
        end
        table.insert(list, { p = p, d = d })
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for _, e in ipairs(list) do table.insert(out, e.p) end
    return out
end

-- For a list of trainer points: a short line naming the nearest one and where it is,
-- and tooltip lines listing every one with its place.
function M.TrainerSummary(points)
    local sorted = M.Nearest(points)
    local first = sorted[1]
    if not first then return "", {} end
    local line = FC.L["Nearest"] .. ": " .. (first.title or "") .. ", " .. M.Describe(first)
    if #sorted > 1 then line = line .. "   ·   " .. string.format(FC.L["%d more: hover for the list"], #sorted - 1) end
    local lines = {}
    for _, p in ipairs(sorted) do table.insert(lines, (p.title or "") .. ":  " .. M.Describe(p)) end
    table.insert(lines, " ")
    table.insert(lines, FC.L["Click to show on the world map."])
    return line, lines
end

-- Open the map on a zone without a pin (gathering routes name zones, not spots).
function M:ShowZone(mapID)
    if not mapID then return end
    ensureProvider()
    self:Clear()
    if not WorldMapFrame:IsShown() then
        if C_Map.OpenWorldMap then C_Map.OpenWorldMap(mapID) else ToggleWorldMap() end
    end
    local API = _G.OpenMapAPI
    if API and API.WorldFromMap and API.ShowWorld then
        local function focus()
            if not API.IsStitched() then return end
            local u1, v1 = API.WorldFromMap(mapID, 0, 0)
            local u2, v2 = API.WorldFromMap(mapID, 1, 1)
            if not u1 or not u2 then return end
            local span = math.max(math.abs(u2 - u1), math.abs(v2 - v1)) * 1.1
            API.ShowWorld((u1 + u2) / 2, (v1 + v2) / 2, span > 0 and math.max(1 / span, 1) or nil)
        end
        C_Timer.After(0, focus)
        C_Timer.After(0.25, focus)
        if API.IsStitched() then return end
    end
    WorldMapFrame:SetMapID(mapID)
    FC:Print(FC.Util.ZoneName(mapID))
end
