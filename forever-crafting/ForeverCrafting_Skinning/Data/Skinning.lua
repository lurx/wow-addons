-- Skinning data for WoW Forever.
-- Trainers, ranks and costs: Icy Veins WoW Forever database (NPC pages, Nov 2026).
-- Route (skill ranges, zones, mobs): wow-professions.com WoW Forever Skinning guide.
-- Mob levels and spawn hotspots: Icy Veins WoW Forever database (densest spawn clusters).
local _, ns = ...

-- Cost to train each rank, in copper.
ns.costs = { Apprentice = 10, Journeyman = 500, Expert = 5000, Artisan = 50000 }

-- rank = the highest rank the trainer teaches ("Apprentice" = junior trainer, up to 75).
ns.trainers = {
    { name = "Thuwd", rank = "Artisan", faction = "H", mapID = 1454, x = 0.632, y = 0.453 },
    { name = "Killian Hagey", rank = "Artisan", faction = "H", mapID = 1458, x = 0.702, y = 0.584 },
    { name = "Mooranta", rank = "Artisan", faction = "H", mapID = 1456, x = 0.448, y = 0.435 },
    { name = "Yonn Deepcut", rank = "Artisan", faction = "H", mapID = 1412, x = 0.450, y = 0.615 },
    { name = "Rand Rhobart", rank = "Artisan", faction = "H", mapID = 1420, x = 0.655, y = 0.600 },
    { name = "Dranh", rank = "Artisan", faction = "H", mapID = 1413, x = 0.451, y = 0.591 },
    { name = "Kulleg Stonehorn", rank = "Artisan", faction = "H", mapID = 1444, x = 0.745, y = 0.430 },
    { name = "Kagil", rank = "Apprentice", faction = "H", mapID = 1411, x = 0.408, y = 0.679 },
    { name = "Nawka Wildsong", rank = "Apprentice", faction = "H", mapID = 1412, x = 0.445, y = 0.768 },
    { name = "Margaret Weaver", rank = "Apprentice", faction = "H", mapID = 1420, x = 0.326, y = 0.657 },
    { name = "Maris Granger", rank = "Artisan", faction = "A", mapID = 1453, x = 0.721, y = 0.624 },
    { name = "Balthus Stoneflayer", rank = "Artisan", faction = "A", mapID = 1455, x = 0.395, y = 0.318 },
    { name = "Eladriel", rank = "Artisan", faction = "A", mapID = 1457, x = 0.642, y = 0.220 },
    { name = "Helene Peltskinner", rank = "Artisan", faction = "A", mapID = 1429, x = 0.473, y = 0.625 },
    { name = "Radnaal Maneweaver", rank = "Artisan", faction = "A", mapID = 1438, x = 0.421, y = 0.500 },
    { name = "Riley Peltskinner", rank = "Apprentice", faction = "A", mapID = 1429, x = 0.470, y = 0.399 },
    { name = "Brighid Stormflayer", rank = "Apprentice", faction = "A", mapID = 1426, x = 0.292, y = 0.677 },
    { name = "Terunne Bearshaper", rank = "Apprentice", faction = "A", mapID = 1438, x = 0.594, y = 0.387 },
    { name = "Ishlee Breezewhisper", rank = "Artisan", faction = "N", mapID = 2521, x = 0.596, y = 0.760 },
    { name = "Mendalass Tattermend", rank = "Artisan", faction = "N", mapID = 2521, x = 0.432, y = 0.455 },
}

-- Camping recipes for Skinning (Icy Veins WoW Forever database, Nov 2026).
-- spell = the recipe, to check whether you know it; source = where it comes from.
ns.camping = {
    { skill = 20, name = "Camp Chair", spell = 1229517, trainer = true, cost = 100 },
    { skill = 140, name = "Field Guide", spell = 1262985, blueprint = 273098,
      drops = { { "Lady Anacondra", "Wailing Caverns", 6.9 } } },
    { skill = 300, name = "Trapper's Workbench", spell = 1262982, blueprint = 273109,
      drops = { { "The Beast", "Upper Blackrock Spire", 3.1 }, { "Houndmaster Loksey", "Scarlet Monastery", 3.0 } } },
}

-- Route. faction: "A", "H" or "N" (both). alt = an alternative for the same range.
-- mobs = { name, npcID, minLevel, maxLevel }; pins = densest spawn spots { x, y } (0–100).
ns.steps = {
    { from = 1, to = 75, faction = "H", mapID = 1411, place = "Valley of Trials",
      mobs = { { "Mottled Boar", 3098, 1, 2 } }, pins = { { 44.2, 65.8 } }, note = "skin.start" },
    { from = 1, to = 75, faction = "A", mapID = 1429, place = "Northshire Valley",
      mobs = { { "Young Wolf", 299, 1, 1 }, { "Timber Wolf", 69, 1, 2 } }, pins = { { 48.9, 40.3 } }, note = "skin.start" },
    { from = 75, to = 150, faction = "N", mapID = 1413, place = "Raptor camp west of Northwatch Hold",
      mobs = { { "Sunscale Scytheclaw", 3256, 14, 18 }, { "Zhevra Charger", 3426, 16, 18 }, { "Ornery Plainstrider", 3245, 15, 17 } },
      pins = { { 53.6, 49.1 }, { 59.4, 33.7 } }, note = "skin.barrens" },
    { from = 75, to = 130, faction = "N", mapID = 1432, alt = true,
      mobs = { { "Elder Mountain Boar", 1192, 16, 17 }, { "Black Bear Patriarch", 1189, 15, 17 }, { "Loch Crocolisk", 1693, 13, 15 } },
      pins = { { 64.4, 38.5 }, { 75.9, 44.7 }, { 59.3, 25.1 } }, note = "skin.loch" },
    { from = 130, to = 150, faction = "N", mapID = 1437, alt = true, place = "Whelgar's Excavation Site",
      mobs = { { "Mottled Scytheclaw", 1022, 24, 26 }, { "Mottled Razormaw", 1023, 25, 27 } },
      pins = { { 34.4, 47.1 } }, note = "skin.wetlands" },
    { from = 150, to = 160, faction = "N", mapID = 1424, place = "In front of the cave",
      mobs = { { "Vicious Gray Bear", 2354, 21, 23 }, { "Starving Mountain Lion", 2384, 22, 24 } },
      pins = { { 49.8, 41.6 }, { 38.2, 38.4 } }, note = "skin.hillsbrad" },
    { from = 160, to = 225, faction = "N", mapID = 1424, place = "Foothill Caverns",
      mobs = { { "Cave Yeti", 2248, 28, 31 }, { "Ferocious Yeti", 2249, 30, 32 } },
      pins = { { 45.6, 31.3 } }, note = "skin.yetis" },
    { from = 150, to = 225, faction = "N", mapID = 1431, alt = true, place = "Rotting Orchard",
      mobs = { { "Nightbane Worgen", 898, 25, 27 }, { "Nightbane Shadow Weaver", 533, 26, 28 }, { "Nightbane Dark Runner", 205, 27, 29 } },
      pins = { { 64.0, 70.5 }, { 61.0, 30.5 }, { 63.5, 46.3 } }, note = "skin.duskwood" },
    { from = 225, to = 280, faction = "N", mapID = 1444, place = "Feral Scar Vale",
      mobs = { { "Feral Scar Yeti", 5292, 42, 44 }, { "Enraged Feral Scar", 5295, 44, 45 }, { "Hulking Feral Scar", 5293, 45, 46 } },
      pins = { { 53.3, 57.7 } }, note = "skin.feralas" },
    { from = 280, to = 300, faction = "N", mapID = 1449, place = "Western Un'Goro Crater",
      mobs = { { "Diemetradon", 9163, 50, 52 }, { "Elder Diemetradon", 9164, 53, 55 }, { "Frenzied Pterrordax", 9167, 51, 54 } },
      pins = { { 35.9, 33.3 }, { 34.9, 46.6 }, { 37.4, 69.1 } }, note = "skin.ungoro" },
}

-- Leathers, hides and scales shown on the Leathers page (zones come from FC.gathering).
ns.leathers = {
    { title = "Leather", items = { 2934, 2318, 2319, 4234, 4304, 8170 } },
    { title = "Hides", items = { 783, 4232, 4235, 8169, 8171 } },
    { title = "Scales and rare skins", items = { 7286, 7287, 7392, 6470, 6471, 7428, 8167, 8154, 8165, 15412, 15414, 15415, 15416, 15408 } },
}
