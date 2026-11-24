-- Registers Blacksmithing with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "blacksmithing",
    title = L["Forever Blacksmithing"],
    shortTitle = L["Blacksmithing"],
    icon = "Interface\\Icons\\Trade_BlackSmithing",
    skillLine = 164,
    order = 30,
    slash = "/bs",
    filters = { armor = { "plate", "mail" } },
}, ns)
