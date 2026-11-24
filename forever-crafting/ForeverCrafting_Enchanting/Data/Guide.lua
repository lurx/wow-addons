-- Enchanting routes. Skill ranges and recipe choices follow the Icy Veins and Wowhead
-- WoW Forever guides (Nov 2026); notes are written for this addon.
-- action = "disenchant" marks a step that levels by disenchanting instead of a recipe.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "cheapest", "wowhead", "icyveins" }

-- Icy Veins leveling guide, 1-225.
ns.routes.icyveins = {
    name = "Icy Veins",
    steps = {
        { from = 1,   to = 2,   spell = 7421,  note = "e.copperRod" },        -- Runed Copper Rod
        { from = 2,   to = 20,  spell = 7418,  note = "e.gear" },             -- Enchant Bracer - Inferior Stamina
        { from = 20,  to = 70,  spell = 7420,  note = "e.deflect" },          -- Enchant Chest - Inferior Stamina
        { from = 70,  to = 100, spell = 7457,  note = "e.journeyman" },       -- Enchant Bracer - Minor Stamina
        { from = 100, to = 129, spell = 7771 },                               -- Enchant Cloak - Minor Protection
        { from = 129, to = 130, spell = 7795,  note = "e.silverRod" },        -- Runed Silver Rod
        { from = 130, to = 159, spell = 13501, note = "e.expert" },           -- Enchant Bracer - Lesser Stamina
        { from = 159, to = 160, spell = 13628, note = "e.goldenRod" },        -- Runed Golden Rod
        { from = 160, to = 180, spell = 13637 },                              -- Enchant Boots - Lesser Agility
        { from = 180, to = 204, spell = 13661 },                              -- Enchant Bracer - Strength
        { from = 204, to = 205, spell = 13702, note = "e.truesilverRod" },    -- Runed Truesilver Rod
        { from = 205, to = 225, spell = 13746, note = { A = "e.cloak.A", H = "e.cloak.H" } }, -- Enchant Cloak - Greater Defense
    },
}

-- Wowhead "Tried & Tested in Forever", 1-300.
ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1,   to = 2,   spell = 7421,  note = "e.copperRod" },        -- Runed Copper Rod
        { from = 2,   to = 20,  action = "disenchant", note = "e.disenchant" },
        { from = 20,  to = 79,  spell = 14293 },                              -- Lesser Magic Wand
        { from = 79,  to = 90,  spell = 7426,  note = "e.journeyman" },       -- Enchant Chest - Minor Absorption
        { from = 90,  to = 100, spell = 7457 },                               -- Enchant Bracer - Minor Stamina
        { from = 100, to = 101, spell = 7795,  note = "e.silverRod" },        -- Runed Silver Rod
        { from = 101, to = 110, spell = 14807 },                              -- Greater Magic Wand
        { from = 110, to = 135, spell = 13419, note = { A = "e.dalria", H = "e.kulwia" } }, -- Enchant Cloak - Minor Agility
        { from = 135, to = 155, spell = 13501, note = "e.expert" },           -- Enchant Bracer - Lesser Stamina
        { from = 155, to = 156, spell = 13628, note = "e.goldenRod" },        -- Runed Golden Rod
        { from = 156, to = 185, spell = 13536, note = { A = "e.dalria", H = "e.kulwia" } }, -- Enchant Bracer - Lesser Strength
        { from = 185, to = 200, spell = 13661, note = "e.artisan" },          -- Enchant Bracer - Strength
        { from = 200, to = 201, spell = 13702, note = "e.truesilverRod" },    -- Runed Truesilver Rod
        { from = 201, to = 220, spell = 13661 },                              -- Enchant Bracer - Strength
        { from = 220, to = 225, spell = 13746 },                              -- Enchant Cloak - Greater Defense
        { from = 225, to = 230, spell = 13815 },                              -- Enchant Gloves - Agility
        { from = 230, to = 235, spell = 13836 },                              -- Enchant Boots - Stamina
        { from = 235, to = 250, spell = 13858 },                              -- Enchant Chest - Superior Stamina
        { from = 250, to = 265, spell = 25127, note = "e.lokhtos" },          -- Lesser Mana Oil
        { from = 265, to = 294, spell = 20017, note = { A = "e.mythrindir", H = "e.bartlett" } }, -- Enchant Shield - Greater Stamina
        { from = 294, to = 295, spell = 20051, note = "e.lorelae" },          -- Runed Arcanite Rod
        { from = 295, to = 300, spell = 20015 },                              -- Enchant Cloak - Superior Defense
    },
}

-- Cheapest overall (compared with Auctionator prices, Nov 2026): Icy Veins to 225,
-- then Wowhead's steps from 225 to 300.
ns.routes.cheapest = { name = "Cheapest", steps = {} }
for _, st in ipairs(ns.routes.icyveins.steps) do table.insert(ns.routes.cheapest.steps, st) end
for _, st in ipairs(ns.routes.wowhead.steps) do
    if st.to > 225 then
        local copy = {}
        for k, v in pairs(st) do copy[k] = v end
        copy.from = math.max(st.from, 225)
        table.insert(ns.routes.cheapest.steps, copy)
    end
end
