-- Engineering route: Wowhead WoW Forever Engineering leveling steps (Nov 2026).
-- Notes are written for this addon.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "wowhead" }

ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1, to = 30, spell = 3918 }, -- Rough Blasting Powder
        { from = 30, to = 50, spell = 3922 }, -- Handful of Copper Bolts
        { from = 50, to = 51, spell = 7430, fixed = 1, note = "e.spanner" }, -- Arclight Spanner
        { from = 51, to = 75, spell = 3923, note = "e.journeyman" }, -- Rough Copper Bomb
        { from = 75, to = 90, spell = 3929 }, -- Coarse Blasting Powder
        { from = 90, to = 100, spell = 3931 }, -- Coarse Dynamite
        { from = 100, to = 105, spell = 3973 }, -- Silver Contact
        { from = 105, to = 125, spell = 3938, note = "e.expert" }, -- Bronze Tube
        { from = 125, to = 135, spell = 3978 }, -- Standard Scope
        { from = 135, to = 150, spell = 3942 }, -- Whirring Bronze Gizmo
        { from = 150, to = 160, spell = 3953 }, -- Bronze Framework
        { from = 160, to = 175, spell = 3955 }, -- Explosive Sheep
        { from = 175, to = 194, spell = 12585 }, -- Solid Blasting Powder
        { from = 194, to = 195, spell = 12590, fixed = 1, note = "e.adjustor" }, -- Gyromatic Micro-Adjustor
        { from = 195, to = 200, spell = 12589, note = "e.artisan" }, -- Mithril Tube
        { from = 200, to = 215, spell = 12591 }, -- Unstable Trigger
        { from = 215, to = 238, spell = 12599 }, -- Mithril Casing
        { from = 238, to = 250, spell = 12619 }, -- Hi-Explosive Bomb
        { from = 250, to = 260, spell = 19788 }, -- Dense Blasting Powder
        { from = 260, to = 285, spell = 19791, note = "e.widget" }, -- Thorium Widget
        { from = 285, to = 300, spell = 19795, note = "e.tube" }, -- Thorium Tube
    },
}
