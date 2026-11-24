-- Cooking routes. Skill ranges and recipe choices follow the Wowhead WoW Forever Cooking
-- guide and the wow-professions.com WoW Forever Cooking guide (Nov 2026); rank unlocks
-- (Expert Cookbook, Clamlette Surprise) follow Icy Veins. Notes are written for this addon.
local _, ns = ...
ns.routes = {}
ns.routeOrder = { "cheapest", "wowhead", "wowprof" }

-- Wowhead "Cooking Leveling Steps 1-300": fish all the way.
ns.routes.wowhead = {
    name = "Wowhead",
    steps = {
        { from = 1,   to = 50,  spell = 7751,  note = "c.smallfish" },            -- Brilliant Smallfish
        { from = 50,  to = 100, spell = 7753,  note = "c.journeyman" },           -- Longjaw Mud Snapper
        { from = 100, to = 175, spell = 7755,  note = { A = "c.expert.A", H = "c.expert.H" } },               -- Bristle Whisker Catfish
        { from = 175, to = 225, spell = 20916 },                                  -- Mithril Headed Trout
        { from = 225, to = 275, spell = 18238, note = "c.artisan" },              -- Spotted Yellowtail
        { from = 275, to = 300, spell = 18246, note = "c.mightfish" },            -- Mightfish Steak
    },
}

-- wow-professions.com WoW Forever Cooking guide.
ns.routes.wowprof = {
    name = "Wow-Professions",
    steps = {
        { from = 1,   to = 50,  spell = 7751,  note = "c.smallfish" },            -- Brilliant Smallfish
        { from = 50,  to = 100, spell = 7753,  note = "c.journeyman" },           -- Longjaw Mud Snapper
        { from = 100, to = 150, spell = 7755,  note = { A = "c.expert.A", H = "c.expert.H" } },               -- Bristle Whisker Catfish
        { from = 150, to = 175, spell = 6500,  note = "c.clams" },                -- Goblin Deviled Clams
        { from = 175, to = 225, spell = 15855, note = "c.raptor" },               -- Roast Raptor
        { from = 225, to = 285, spell = 18238, note = "c.artisan" },              -- Spotted Yellowtail
        { from = 285, to = 300, spell = 18243, note = "c.nightfin" },             -- Nightfin Soup
    },
}

-- Cheapest, from your Auctionator prices (Nov 2026): Wowhead's fish to 225 (catfish and
-- trout beat clams and Raptor Flesh), then Spotted Yellowtail and Nightfin Soup instead of
-- Mightfish Steak (Large Raw Mightfish was about 70s each). Under 2g of materials in all.
ns.routes.cheapest = {
    name = "Cheapest",
    steps = {
        { from = 1,   to = 50,  spell = 7751,  note = "c.smallfish" },            -- Brilliant Smallfish
        { from = 50,  to = 100, spell = 7753,  note = "c.journeyman" },           -- Longjaw Mud Snapper
        { from = 100, to = 175, spell = 7755,  note = { A = "c.expert.A", H = "c.expert.H" } },               -- Bristle Whisker Catfish
        { from = 175, to = 225, spell = 20916 },                                  -- Mithril Headed Trout
        { from = 225, to = 285, spell = 18238, note = "c.artisan" },              -- Spotted Yellowtail
        { from = 285, to = 300, spell = 18243, note = "c.nightfin" },             -- Nightfin Soup
    },
}
