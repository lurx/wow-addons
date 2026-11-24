-- Registers Enchanting with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "enchanting",
    title = L["Forever Enchanting"],
    shortTitle = L["Enchanting"],
    icon = "Interface\\Icons\\Trade_Engraving",
    skillLine = 333,
    order = 30,
    slash = "/ench",
    filters = {},
}, ns)
