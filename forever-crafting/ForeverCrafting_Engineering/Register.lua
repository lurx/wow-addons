-- Registers Engineering with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "engineering",
    title = L["Forever Engineering"],
    shortTitle = L["Engineering"],
    icon = "Interface\\Icons\\Trade_Engineering",
    skillLine = 202,
    order = 35,
    slash = "/eng",
    filters = {},
}, ns)
