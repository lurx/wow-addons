-- Leatherworking routes. Each step: from/to skill, the recipe's spell ID, an optional
-- note key (or { A = key, H = key } for faction-specific advice), and `fixed` for a
-- batch made at one skill. Notes are written for this addon.
-- Past a route's end the guide page suggests recipes from live data.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "cheapest", "wowhead", "icyveins" }

-- Wowhead "Tried & Tested in Forever", 1-300 (Nov 2026).
ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1,   to = 30,  spell = 2881,  note = "wh.scraps" },        -- Light Leather
        { from = 30,  to = 45,  spell = 2152 },                             -- Light Armor Kit
        { from = 45,  to = 55,  spell = 3816 },                             -- Cured Light Hide
        { from = 55,  to = 85,  spell = 3756,  note = "guide.gloves" },     -- Embossed Leather Gloves
        { from = 85,  to = 100, spell = 3763,  note = "wh.belts" },         -- Fine Leather Belt
        { from = 100, to = 115, spell = 7135 },                             -- Dark Leather Pants
        { from = 115, to = 118, spell = 2167 },                             -- Gray Leather Boots
        { from = 118, to = 125, spell = 3766,  note = "guide.darkBelt" },   -- Dark Leather Belt
        { from = 125, to = 135, spell = 3818,  note = { A = "guide.heavy.A", H = "guide.heavy.H" } }, -- Cured Heavy Hide
        { from = 135, to = 143, spell = 3766 },                             -- Dark Leather Belt
        { from = 143, to = 145, spell = 3818,  note = "wh.curedHeavy" },    -- Cured Heavy Hide
        { from = 145, to = 155, spell = 3770,  note = "wh.toughened" },     -- Toughened Leather Gloves
        { from = 155, to = 160, spell = 7151 },                             -- Barbaric Shoulders
        { from = 160, to = 180, spell = 3778,  note = "wh.gemBelt" },       -- Gem-studded Leather Belt
        { from = 180, to = 185, spell = 7151 },                             -- Barbaric Shoulders
        { from = 185, to = 190, spell = 3778 },                             -- Gem-studded Leather Belt
        { from = 190, to = 200, spell = 7156,  note = "wh.artisan" },       -- Guardian Gloves
        { from = 200, to = 210, spell = 10487 },                            -- Thick Armor Kit
        { from = 210, to = 225, spell = 10548, note = { A = "guide.headband.A", H = "guide.headband.H" } }, -- Nightscape Pants
        { from = 225, to = 230, spell = 19047, note = "wh.rugged" },        -- Cured Rugged Hide
        { from = 230, to = 240, spell = 10548 },                            -- Nightscape Pants
        { from = 240, to = 255, spell = 19049, note = { A = "wh.wicked.A", H = "wh.wicked.H" } }, -- Wicked Leather Gauntlets
        { from = 255, to = 260, spell = 19048, note = "wh.scorpid" },       -- Heavy Scorpid Bracers
        { from = 260, to = 270, spell = 19049 },                            -- Wicked Leather Gauntlets
        { from = 270, to = 300, spell = 19088 },                            -- Heavy Scorpid Helm
    },
}

-- Icy Veins leveling guide, 1-225 (Nov 2026).
ns.routes.icyveins = {
    name = "Icy Veins",
    steps = {
        { from = 1,   to = 30,  spell = 2152,  note = "guide.scraps" },          -- Light Armor Kit
        { from = 30,  to = 55,  spell = 3816,  note = "guide.curedLight" },      -- Cured Light Hide
        { from = 55,  to = 75,  spell = 3756,  note = "guide.gloves" },          -- Embossed Leather Gloves
        { from = 75,  to = 80,  spell = 20648, note = "guide.medium" },          -- Medium Leather
        { from = 80,  to = 90,  spell = 3817,  note = "guide.curedMedium" },     -- Cured Medium Hide
        { from = 90,  to = 100, spell = 3763,  note = "guide.fineBelt" },        -- Fine Leather Belt
        { from = 100, to = 115, spell = 9068,  note = "guide.pants" },           -- Light Leather Pants
        { from = 115, to = 125, spell = 3766,  note = "guide.darkBelt" },        -- Dark Leather Belt
        { from = 125, to = 130, spell = 20649, note = { A = "guide.heavy.A", H = "guide.heavy.H" } },           -- Heavy Leather
        { from = 130, to = 130, spell = 3818,  fixed = 20, note = "guide.curedHeavy" }, -- Cured Heavy Hide x20
        { from = 130, to = 155, spell = 3780,  note = "guide.heavyKit" },        -- Heavy Armor Kit
        { from = 155, to = 165, spell = 7151,  note = "guide.shoulders" },       -- Barbaric Shoulders
        { from = 165, to = 175, spell = 7156,  note = "guide.gauntlets" },       -- Guardian Gloves
        { from = 175, to = 195, spell = 10487, note = "guide.thickKit" },        -- Thick Armor Kit
        { from = 195, to = 210, spell = 10507, note = { A = "guide.headband.A", H = "guide.headband.H" } },        -- Nightscape Headband
        { from = 210, to = 225, spell = 10548, note = "guide.pants2" },          -- Nightscape Pants
    },
}

-- Cheapest overall (compared with Auctionator prices, Nov 2026): Icy Veins to 225,
-- then Wowhead's steps from 225 to 300.
ns.routes.cheapest = { name = "Cheapest", steps = {} }
for _, st in ipairs(ns.routes.icyveins.steps) do table.insert(ns.routes.cheapest.steps, st) end
for _, st in ipairs(ns.routes.wowhead.steps) do
    if st.from >= 225 then table.insert(ns.routes.cheapest.steps, st) end
end
