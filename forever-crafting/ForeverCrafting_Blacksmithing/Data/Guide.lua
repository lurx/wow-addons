-- Blacksmithing route: Wowhead WoW Forever Blacksmithing leveling steps (Nov 2026).
-- Notes are written for this addon.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "wowhead" }

ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1, to = 30, spell = 2660 }, -- Rough Sharpening Stone
        { from = 30, to = 65, spell = 3320, note = "b.journeyman" }, -- Rough Grinding Stone
        { from = 65, to = 75, spell = 2661 }, -- Copper Chain Belt
        { from = 75, to = 80, spell = 19666 }, -- Silver Skeleton Key
        { from = 80, to = 90, spell = 2668 }, -- Rough Bronze Leggings
        { from = 90, to = 100, spell = 2666 }, -- Runed Copper Belt
        { from = 100, to = 105, spell = 2674 }, -- Heavy Sharpening Stone
        { from = 105, to = 110, spell = 2666 }, -- Runed Copper Belt
        { from = 110, to = 125, spell = 2668, note = "b.expert" }, -- Rough Bronze Leggings
        { from = 125, to = 129, spell = 8768 }, -- Iron Buckle
        { from = 129, to = 140, spell = 9985 }, -- Bronze Warhammer
        { from = 140, to = 147, spell = 2672 }, -- Patterned Bronze Bracers
        { from = 147, to = 155, spell = 3501 }, -- Green Iron Bracers
        { from = 155, to = 165, spell = 3506 }, -- Green Iron Leggings
        { from = 165, to = 183, spell = 3501 }, -- Green Iron Bracers
        { from = 183, to = 190, spell = 9928 }, -- Heavy Mithril Gauntlet
        { from = 190, to = 200, spell = 7223, note = "b.artisan" }, -- Golden Scale Bracers
        { from = 200, to = 205, spell = 9928 }, -- Heavy Mithril Gauntlet
        { from = 205, to = 210, spell = 9931 }, -- Mithril Plate Pants
        { from = 210, to = 215, spell = 9928 }, -- Heavy Mithril Gauntlet
        { from = 215, to = 225, spell = 9959 }, -- Heavy Mithril Breastplate
        { from = 225, to = 235, spell = 16640 }, -- Dense Weightstone
        { from = 235, to = 240, spell = 9961 }, -- Mithril Coif
        { from = 240, to = 246, spell = 9968 }, -- Heavy Mithril Boots
        { from = 246, to = 250, spell = 10001 }, -- Big Black Mace
        { from = 250, to = 257, spell = 19669 }, -- Arcanite Skeleton Key
        { from = 257, to = 270, spell = 10013, note = "b.ebon" }, -- Ebon Shiv
        { from = 270, to = 275, spell = 1252365, note = "b.dirk" }, -- Bold Dirk
        { from = 275, to = 279, spell = 16969, note = "b.handaxe" }, -- Ornate Thorium Handaxe
        { from = 279, to = 300, spell = 1252365 }, -- Bold Dirk
    },
}
