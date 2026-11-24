-- Registers Tailoring with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "tailoring",
    title = L["Forever Tailoring"],
    shortTitle = L["Tailoring"],
    icon = "Interface\\Icons\\Trade_Tailoring",
    skillLine = 197,
    order = 20,
    slash = "/tail",
    filters = { armor = { "cloth" }, specs = { "Mooncloth", "Shadoweave", "Spellfire" } },
}, ns)
