-- Alchemy routes. Wowhead WoW Forever Alchemy leveling steps and the wow-professions.com
-- WoW Forever Alchemy guide (Nov 2026). Notes are written for this addon.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "cheapest", "wowhead", "wowprof" }

ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1,   to = 12,  spell = 1245250 },                     -- Elixir of Minor Force
        { from = 12,  to = 55,  spell = 7183 },                        -- Elixir of Minor Defense
        { from = 55,  to = 65,  spell = 2331, note = "a.journeyman" }, -- Minor Mana Potion
        { from = 65,  to = 90,  spell = 2334 },                        -- Elixir of Minor Fortitude
        { from = 90,  to = 120, spell = 3171 },                        -- Elixir of Wisdom
        { from = 120, to = 160, spell = 3173, note = "a.expert" },     -- Lesser Mana Potion
        { from = 160, to = 195, spell = 3452 },                        -- Mana Potion
        { from = 195, to = 205, spell = 11449, note = "a.artisan" },   -- Elixir of Agility
        { from = 205, to = 225, spell = 11448 },                       -- Greater Mana Potion
        { from = 225, to = 226, spell = 11459, fixed = 1, note = "a.philo" }, -- Philosopher's Stone
        { from = 226, to = 240, spell = 11448 },                       -- Greater Mana Potion
        { from = 240, to = 260, spell = 11460 },                       -- Draught of Detect Undead
        { from = 260, to = 270, spell = 17553, note = "a.supermana" }, -- Superior Mana Potion
        { from = 270, to = 300, spell = 1231583, note = "a.discolored" }, -- Major Discolored Healing Potion
    },
}

ns.routes.wowprof = {
    name = "Wow-Professions",
    steps = {
        { from = 1,   to = 10,  spell = 1245250 },                     -- Elixir of Minor Force
        { from = 10,  to = 55,  spell = 7183 },                        -- Elixir of Minor Defense
        { from = 55,  to = 65,  spell = 2331, note = "a.journeyman" }, -- Minor Mana Potion
        { from = 65,  to = 90,  spell = 2334 },                        -- Elixir of Minor Fortitude
        { from = 90,  to = 120, spell = 3171 },                        -- Elixir of Wisdom
        { from = 120, to = 130, spell = 3173 },                        -- Lesser Mana Potion
        { from = 130, to = 150, spell = 7837, note = "a.fireoil" },    -- Fire Oil
        { from = 150, to = 165, spell = 7845, note = "a.expert" },     -- Elixir of Fire Power
        { from = 165, to = 195, spell = 3452 },                        -- Mana Potion
        { from = 195, to = 235, spell = 7259, note = "a.nature" },     -- Nature Protection Potion
        { from = 235, to = 250, spell = 11465 },                       -- Elixir of Greater Intellect
        { from = 250, to = 260, spell = 17551, note = "a.stonescale" },-- Stonescale Oil
        { from = 260, to = 265, spell = 11465 },                       -- Elixir of Greater Intellect
        { from = 265, to = 300, spell = 17554, note = "a.defense" },   -- Elixir of Greater Defense
    },
}

-- Cheapest, from your Auctionator prices (Nov 2026): the wow-professions.com route came to
-- about 25g of materials against about 47g for Wowhead's (Plaguebloom and Murloc Eyes for the
-- last 30 points, and Goldthorn/Khadgar's Whisker mana potions, cost more than oils).
ns.routes.cheapest = { name = "Cheapest", steps = ns.routes.wowprof.steps }
