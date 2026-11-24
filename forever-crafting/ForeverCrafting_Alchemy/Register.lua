-- Registers Alchemy with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "alchemy",
    title = L["Forever Alchemy"],
    shortTitle = L["Alchemy"],
    icon = "Interface\\Icons\\Trade_Alchemy",
    skillLine = 171,
    order = 25,
    slash = "/alch",
    filters = {},
}, ns)
