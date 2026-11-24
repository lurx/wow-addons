-- Registers Cooking with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "cooking",
    title = L["Forever Cooking"],
    shortTitle = L["Cooking"],
    icon = "Interface\\Icons\\INV_Misc_Food_15",
    skillLine = 185,
    order = 40,
    slash = "/cook",
    filters = {},
}, ns)
