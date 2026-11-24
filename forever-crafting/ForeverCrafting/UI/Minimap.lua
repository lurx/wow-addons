-- A small self-contained minimap button (no libraries).
local _, FC = ...
local L = FC.L
FC.Minimap = {}
local MM = FC.Minimap

local button

local function position()
    local angle = math.rad(FC.db.minimap.angle or 215)
    local r = (Minimap:GetWidth() / 2) + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function create()
    button = CreateFrame("Button", "ForeverCraftingMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(FC.Style.media .. "Icon")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, b)
        if b == "RightButton" then FC.Window:Open(nil, "settings") else FC.Window:Toggle() end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            FC.db.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            position()
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Forever Crafting"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Left-click: open or close"], 1, 1, 1)
        GameTooltip:AddLine(L["Right-click: settings"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: move this button"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

function MM:Update()
    if not button then create() end
    if FC.db.minimap.hide then button:Hide() else position() button:Show() end
end

FC:On("LOGIN", function() MM:Update() end)
