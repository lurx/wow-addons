-- Registers Leatherworking with the shared profession module in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewProfession({
    key = "leatherworking",
    title = L["Forever Leatherworking"],
    shortTitle = L["Leatherworking"],
    icon = "Interface\\Icons\\Trade_LeatherWorking",
    skillLine = 165,
    skillLines = { 165, 393 },   -- Skinning loads this module too
    order = 10,
    slash = "/lw",
    -- Basic leathers count as materials to skin or buy, not as things to craft first.
    notPrep = { [2318] = true, [2319] = true, [4234] = true, [4304] = true, [8170] = true },
    filters = { armor = { "leather", "mail" }, specs = { "Dragonscale", "Elemental", "Tribal" } },
}, ns)
