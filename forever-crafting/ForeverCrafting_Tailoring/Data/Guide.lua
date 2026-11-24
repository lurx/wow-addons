-- Tailoring routes. Skill ranges and recipe choices follow the Icy Veins and Wowhead
-- WoW Forever guides (Nov 2026); notes are written for this addon.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "cheapest", "wowhead", "icyveins" }

-- Icy Veins leveling guide, 1-225.
ns.routes.icyveins = {
    name = "Icy Veins",
    steps = {
        { from = 1,   to = 30,  spell = 2963,  note = "t.linenBolts" },       -- Bolt of Linen Cloth
        { from = 30,  to = 55,  spell = 8776,  note = "t.journeyman" },       -- Linen Belt
        { from = 55,  to = 80,  spell = 2964 },                               -- Bolt of Woolen Cloth
        { from = 80,  to = 100, spell = 2402 },                               -- Woolen Cape
        { from = 100, to = 120, spell = 3839,  note = "t.silkBolts" },        -- Bolt of Silk Cloth
        { from = 120, to = 135, spell = 8760,  note = { A = "t.expert.A", H = "t.expert.H" } }, -- Azure Silk Hood
        { from = 135, to = 140, spell = 3871 },                               -- Formal White Shirt
        { from = 140, to = 150, spell = 3865 },                               -- Bolt of Mageweave
        { from = 150, to = 170, spell = 8791 },                               -- Crimson Silk Vest
        { from = 170, to = 190, spell = 8799 },                               -- Crimson Silk Pantaloons
        { from = 190, to = 215, spell = 12053, note = { A = "t.artisan.A", H = "t.artisan.H" } }, -- Black Mageweave Gloves
        { from = 215, to = 215, spell = 3865,  fixed = 104, note = "t.bagBolts" }, -- Bolt of Mageweave x104
        { from = 215, to = 225, spell = 12065 },                              -- Mageweave Bag
    },
}

-- Wowhead "Tried & Tested in Forever", 1-300.
ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1,   to = 43,  spell = 2963,  note = "t.linenBolts" },       -- Bolt of Linen Cloth
        { from = 43,  to = 45,  spell = 2385 },                               -- Brown Linen Vest
        { from = 45,  to = 70,  spell = 8776,  note = "t.journeyman" },       -- Linen Belt
        { from = 70,  to = 75,  spell = 2397 },                               -- Reinforced Linen Cape
        { from = 75,  to = 81,  spell = 2964 },                               -- Bolt of Woolen Cloth
        { from = 81,  to = 100, spell = 2402 },                               -- Woolen Cape
        { from = 100, to = 110, spell = 3839 },                               -- Bolt of Silk Cloth
        { from = 110, to = 125, spell = 3848 },                               -- Double-stitched Woolen Shoulders
        { from = 125, to = 132, spell = 8760,  note = { A = "t.expert.A", H = "t.expert.H" } }, -- Azure Silk Hood
        { from = 132, to = 139, spell = 6690 },                               -- Lesser Wizard's Robe
        { from = 139, to = 140, spell = 3871 },                               -- Formal White Shirt
        { from = 140, to = 149, spell = 3865 },                               -- Bolt of Mageweave
        { from = 149, to = 160, spell = 8764 },                               -- Earthen Vest
        { from = 160, to = 170, spell = 8770 },                               -- Robe of Power
        { from = 170, to = 180, spell = 12048 },                              -- Black Mageweave Vest
        { from = 180, to = 190, spell = 12061 },                              -- Orange Mageweave Shirt
        { from = 190, to = 205, spell = 12053, note = { A = "t.artisan.A", H = "t.artisan.H" } }, -- Black Mageweave Gloves
        { from = 205, to = 214, spell = 18401 },                              -- Bolt of Runecloth
        { from = 214, to = 234, spell = 18402 },                              -- Runecloth Belt
        { from = 234, to = 250, spell = 18409, note = "t.pattern" },          -- Runecloth Cloak
        { from = 250, to = 260, spell = 18423, note = "t.pattern" },          -- Runecloth Boots
        { from = 260, to = 280, spell = 1257487, note = "t.pattern" },        -- Runecloth Cuffs
        { from = 280, to = 285, spell = 23662, note = "t.timbermaw" },        -- Wisdom of the Timbermaw
        { from = 285, to = 292, spell = 1297120, note = "t.pattern" },        -- Venomspew Gloves
        { from = 292, to = 299, spell = 1297121 },                            -- Venomspew Cord
        { from = 299, to = 300, spell = 1297122 },                            -- Venomspew Footpads
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
