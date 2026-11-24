-- Registers Mining with the shared gathering base in Forever Crafting.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L

FC:NewGatherer({
    key = "mining",
    title = L["Forever Mining"],
    shortTitle = L["Mining"],
    icon = "Interface\\Icons\\Trade_Mining",
    nodeIcon = "Interface\\Icons\\INV_Ore_Copper_01",
    skillLine = 186,
    order = 17,
    slash = "/mine",
    nodesTitle = L["Ores"],
}, ns)
