-- Registers Herbalism with the shared gathering base in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewGatherer({
    key = "herbalism",
    title = L["Forever Herbalism"],
    shortTitle = L["Herbalism"],
    icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    nodeIcon = "Interface\\Icons\\INV_Misc_Flower_02",
    skillLine = 182,
    order = 16,
    slash = "/herb",
    nodesTitle = L["Herbs"],
}, ns)
