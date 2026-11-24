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
    button:SetSize(28, 28)
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

-- Sit just right of the rank bar (after its link button when there is one),
-- centred on the bar, so the button lines up however the window is skinned.
function PB.Place()
    if not button then return end
    button:ClearAllPoints()
    local page = ProfessionsFrame and ProfessionsFrame:IsShown() and ProfessionsFrame.CraftingPage
    local bar = page and page.RankBar
    if bar then
        local link = page.LinkButton
        local x = 6
        if link and link:IsShown() and link:GetRight() and bar:GetRight() then
            x = link:GetRight() - bar:GetRight() + 4
        end
        button:SetPoint("LEFT", bar, "RIGHT", x, 0)
    elseif ProfessionsFrame and ProfessionsFrame:IsShown() then
        button:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", -58, -26)
    else
        button:SetPoint("TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -40, -40)
    end
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
    PB.Place()
    button:Show()
end

FC:On("TRADE_SKILL_SHOW", function()
    PB:Update()
    -- The window finishes its layout a moment after it opens.
    C_Timer.After(0, function() PB.Place() end)
end)
