-- Herbalism data for WoW Forever. Trainers, ranks, nodes, skill thresholds and zones: Icy Veins
-- (guide + database, Nov 2026). Route: wow-professions.com WoW Forever Herbalism guide.
local _, ns = ...

ns.trainers = {
    { name = "Nancy Songflower", rank = "Apprentice", faction = "A", mapID = 1429, x = 0.524, y = 0.439 },
    { name = "Emrys Flintbeard", rank = "Apprentice", faction = "A", mapID = 1426, x = 0.289, y = 0.666 },
    { name = "Eleyna Duskbreeze", rank = "Apprentice", faction = "A", mapID = 1438, x = 0.598, y = 0.414 },
    { name = "Firodren Mooncaller", rank = "Artisan", faction = "A", mapID = 1457, x = 0.480, y = 0.684 },
    { name = "Reyna Stonebranch", rank = "Artisan", faction = "A", mapID = 1455, x = 0.562, y = 0.600 },
    { name = "Tannysa", rank = "Artisan", faction = "A", mapID = 1453, x = 0.490, y = 0.882 },
    { name = "Shylamiir", rank = "Artisan", faction = "A", mapID = 1453, x = 0.314, y = 0.629 },
    { name = "Malorne Bladeleaf", rank = "Artisan", faction = "A", mapID = 1438, x = 0.577, y = 0.606 },
    { name = "Herbalist Pomeroy", rank = "Artisan", faction = "A", mapID = 1429, x = 0.399, y = 0.484 },
    { name = "Kali Healtouch", rank = "Artisan", faction = "A", mapID = 1432, x = 0.365, y = 0.484 },
    { name = "Alma Jainrose", rank = "Artisan", faction = "A", mapID = 1433, x = 0.165, y = 0.457 },
    { name = "Cylania Rootstalker", rank = "Artisan", faction = "A", mapID = 1440, x = 0.507, y = 0.671 },
    { name = "Telurinon Moonshadow", rank = "Artisan", faction = "A", mapID = 1437, x = 0.085, y = 0.566 },
    { name = "Brant Jasperbloom", rank = "Artisan", faction = "A", mapID = 1445, x = 0.640, y = 0.476 },
    { name = "Edward Egan", rank = "Artisan", faction = "A", mapID = 1416, x = 0.184, y = 0.632 },
    { name = "Halassa Fernbreeze", rank = "Artisan", faction = "N", mapID = 2521, x = 0.430, y = 0.435 },
    { name = "Syriel Nightrain", rank = "Artisan", faction = "N", mapID = 2521, x = 0.579, y = 0.755 },
    { name = "Flora Silverwind", rank = "Artisan", faction = "N", mapID = 1434, x = 0.277, y = 0.778 },
    { name = "Malvor", rank = "Artisan", faction = "N", mapID = 1450, x = 0.455, y = 0.470 },
    { name = "Zor'la", rank = "Apprentice", faction = "H", mapID = 1411, x = 0.427, y = 0.674 },
    { name = "Garan Sunstrider", rank = "Apprentice", faction = "H", mapID = 1412, x = 0.442, y = 0.779 },
    { name = "Florence Nightshade", rank = "Apprentice", faction = "H", mapID = 1420, x = 0.324, y = 0.652 },
    { name = "Jandi", rank = "Artisan", faction = "H", mapID = 1454, x = 0.555, y = 0.397 },
    { name = "Komin Winterhoof", rank = "Artisan", faction = "H", mapID = 1456, x = 0.505, y = 0.400 },
    { name = "Martha Alliestar", rank = "Artisan", faction = "H", mapID = 1458, x = 0.542, y = 0.489 },
    { name = "Mishiki", rank = "Artisan", faction = "H", mapID = 1411, x = 0.555, y = 0.750 },
    { name = "Faruza", rank = "Artisan", faction = "H", mapID = 1420, x = 0.598, y = 0.521 },
    { name = "Aranae Venomblood", rank = "Artisan", faction = "H", mapID = 1416, x = 0.616, y = 0.807 },
    { name = "Angrun", rank = "Artisan", faction = "H", mapID = 1434, x = 0.322, y = 0.275 },
    { name = "Ruw", rank = "Artisan", faction = "H", mapID = 1444, x = 0.760, y = 0.434 },
}

ns.nodes = {
    { name = "Peacebloom", skill = { 1, 25, 50, 100 }, items = { 2447 }, zones = { 1412, 1420, 2521, 1438, 1411, 1413, 1426, 1429 } },
    { name = "Silverleaf", skill = { 1, 25, 50, 100 }, items = { 765 }, zones = { 1412, 1420, 1429, 1438, 2521, 1426, 1413, 1411 } },
    { name = "Earthroot", skill = { 15, 40, 65, 115 }, items = { 2449 }, zones = { 1412, 1413, 1420, 1438, 1426, 1429, 1411, 2521 } },
    { name = "Mageroyal", skill = { 50, 75, 100, 150 }, items = { 785 }, zones = { 1413, 1421, 1432, 1436, 1433 } },
    { name = "Briarthorn", skill = { 70, 95, 120, 170 }, items = { 2450 }, zones = { 1413, 1431, 1421, 1433, 1436 } },
    { name = "Stranglekelp", skill = { 85, 110, 135, 185 }, items = { 3820 }, zones = { 1437, 1434, 1440, 1443, 1436 } },
    { name = "Bruiseweed", skill = { 100, 125, 150, 200 }, items = { 2453 }, zones = { 1442, 1413, 1440, 1431, 1433 } },
    { name = "Wild Steelbloom", skill = { 115, 140, 165, 215 }, items = { 3355 }, zones = { 1434, 1442, 1417, 1437, 1441 } },
    { name = "Grave Moss", skill = { 120, 145, 170, 220 }, items = { 3369 }, zones = { 1443, 1431 } },
    { name = "Kingsblood", skill = { 125, 150, 175, 225 }, items = { 3356 }, zones = { 1434, 1437, 1424, 1440, 1442 } },
    { name = "Liferoot", skill = { 150, 175, 200, 250 }, items = { 3357 }, zones = { 1445, 1434, 1435, 1437, 1416, 1443 } },
    { name = "Fadeleaf", skill = { 160, 185, 210, 260 }, items = { 3818 }, zones = { 1445, 1434, 1417, 1416, 1435 } },
    { name = "Goldthorn", skill = { 170, 195, 220, 270 }, items = { 3821 }, zones = { 1434, 1444, 1417, 1445, 1435 } },
    { name = "Khadgar's Whisker", skill = { 185, 210, 235, 285 }, items = { 3358 }, zones = { 1434, 1444, 1417, 1445, 1435 } },
    { name = "Wintersbite", skill = { 195, 220, 245, 295 }, items = { 3819 }, zones = { 1416 } },
    { name = "Firebloom", skill = { 205, 230, 255, 305 }, items = { 4625 }, zones = { 1446, 1427, 1419, 1418 } },
    { name = "Purple Lotus", skill = { 210, 235, 260, 310 }, items = { 8831 }, zones = { 1447, 1425, 1444, 1446, 1434 } },
    { name = "Arthas' Tears", skill = { 220, 245, 270, 320 }, items = { 8836 }, zones = { 1423, 1422, 1448 } },
    { name = "Sungrass", skill = { 230, 255, 280, 330 }, items = { 8838 }, zones = { 1444, 1447, 1425, 1449, 1422 } },
    { name = "Blindweed", skill = { 235, 260, 285, 335 }, items = { 8839 }, zones = { 1435, 1449 } },
    { name = "Ghost Mushroom", skill = { 245, 270, 295, 345 }, items = { 8845 }, zones = { 1425 } },
    { name = "Gromsblood", skill = { 250, 275, 300, 350 }, items = { 8846 }, zones = { 1448, 1419, 1443 } },
    { name = "Golden Sansam", skill = { 260, 285, 310, 360 }, items = { 13464 }, zones = { 1447, 1449, 1423, 1448, 1428 } },
    { name = "Dreamfoil", skill = { 270, 295, 320, 370 }, items = { 13463 }, zones = { 1447, 1423, 1449, 1448, 1428, 1451, 1422 } },
    { name = "Mountain Silversage", skill = { 280, 305, 330, 380 }, items = { 13465 }, zones = { 1452, 1423, 1447, 1449, 1428 } },
    { name = "Plaguebloom", skill = { 285, 310, 335, 385 }, items = { 13466 }, zones = { 1423, 1422, 1448 } },
    { name = "Icecap", skill = { 290, 315, 340, 390 }, items = { 13467 }, zones = { 1452 } },
    { name = "Black Lotus", skill = { 300, 325, 350, 400 }, items = { 13468 }, zones = { 1428, 1451, 1452, 1423 } },
}

ns.steps = {
    { from = 1, to = 70, faction = "H", zones = { 1411, 1412, 1420 }, nodes = { "Peacebloom", "Silverleaf", "Earthroot" }, note = "herb.start" },
    { from = 1, to = 70, faction = "A", zones = { 1429, 1426, 1438 }, nodes = { "Peacebloom", "Silverleaf", "Earthroot" }, note = "herb.start" },
    { from = 1, to = 70, faction = "N", zones = { 2521 }, nodes = { "Peacebloom", "Silverleaf", "Earthroot" }, note = "herb.zephras" },
    { from = 70, to = 115, faction = "N", zones = { 1421, 1432, 1439 }, nodes = { "Mageroyal", "Briarthorn", "Stranglekelp" }, note = "herb.journeyman" },
    { from = 115, to = 170, faction = "N", zones = { 1424, 1442 }, nodes = { "Bruiseweed", "Wild Steelbloom", "Stranglekelp", "Kingsblood", "Liferoot" }, note = "herb.expert" },
    { from = 170, to = 205, faction = "N", zones = { 1434, 1417 }, nodes = { "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn", "Khadgar's Whisker" } },
    { from = 205, to = 230, faction = "N", zones = { 1446, 1427 }, nodes = { "Purple Lotus", "Firebloom" }, note = "herb.artisan" },
    { from = 230, to = 270, faction = "N", zones = { 1425 }, nodes = { "Sungrass", "Purple Lotus", "Golden Sansam", "Ghost Mushroom" }, note = "herb.hinterlands" },
    { from = 270, to = 300, faction = "N", zones = { 1448 }, nodes = { "Sungrass", "Gromsblood", "Golden Sansam", "Dreamfoil", "Mountain Silversage", "Plaguebloom" } },
}
ns.tips = { "herb.tip.tracking", "herb.tip.tea" }

-- Camping recipes (Icy Veins WoW Forever database, Nov 2026).
ns.camping = {
    { skill = 20, name = "Incense Candle", spell = 1229705, trainer = true, cost = 100 },
    { skill = 140, name = "Greenhouse", spell = 1262980, blueprint = 273106,
      drops = { { "Shadetooth", "Excavation Site: Wetlands", 6.7 } } },
    { skill = 300, name = "Seed Hybridizer", spell = 1263070, blueprint = 273120,
      drops = { { "Tendris Warpwood", "Dire Maul", 3.9 } } },
}
