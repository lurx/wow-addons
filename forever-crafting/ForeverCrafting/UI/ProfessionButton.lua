-- A button on the Blizzard profession window that opens the matching module.
local _, FC = ...
FC.ProfessionButton = {}
local PB = FC.ProfessionButton

local button

local function currentLine()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return end
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    return info and info.professionID
end

local function create()
    local host = ProfessionsFrame or TradeSkillFrame
    if not host then return end
    button = CreateFrame("Button", nil, host)
    button:SetSize(30, 30)
    if ProfessionsFrame and host == ProfessionsFrame then
        button:SetPoint("TOPRIGHT", host, "TOPRIGHT", -58, -26)
    else
        button:SetPoint("TOPRIGHT", host, "TOPRIGHT", -40, -40)
    end
    button:SetFrameStrata("HIGH")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    button.icon = icon
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.2)
    button:SetScript("OnClick", function(self)
        if self.mod then FC.Window:Toggle(self.mod.key) end
    end)
    button:SetScript("OnEnter", function(self)
        if not self.mod then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(self.mod.title, 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

function PB:Update()
    if not FC.db.showProfessionButton then
        if button then button:Hide() end
        return
    end
    local mod = FC:GetModuleForSkillLine(currentLine() or 0)
    if not mod then
        if button then button:Hide() end
        return
    end
    if not button then create() end
    if not button then return end
    button.mod = mod
    button.icon:SetTexture(mod.icon)
    button:Show()
end

FC:On("TRADE_SKILL_SHOW", function() PB:Update() end)
