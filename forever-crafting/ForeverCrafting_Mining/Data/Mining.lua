-- Mining data for WoW Forever. Trainers, ranks, nodes, skill thresholds and zones: Icy Veins
-- (guide + database, Nov 2026). Route: wow-professions.com WoW Forever Mining guide.
local _, ns = ...

ns.trainers = {
    { name = "Kelsey Fargo", rank = "Apprentice", faction = "A", mapID = 1429, x = 0.472, y = 0.323 },
    { name = "Sally Swiftwrench", rank = "Apprentice", faction = "A", mapID = 1426, x = 0.289, y = 0.678 },
    { name = "Fanorran Stilloak", rank = "Apprentice", faction = "A", mapID = 1438, x = 0.582, y = 0.415 },
    { name = "Geofram Bouldertoe", rank = "Artisan", faction = "A", mapID = 1455, x = 0.500, y = 0.271 },
    { name = "Gelman Stonehand", rank = "Artisan", faction = "A", mapID = 1453, x = 0.634, y = 0.350 },
    { name = "Yarr Hammerstone", rank = "Artisan", faction = "A", mapID = 1426, x = 0.500, y = 0.503 },
    { name = "Dank Drizzlecut", rank = "Artisan", faction = "A", mapID = 1426, x = 0.693, y = 0.554 },
    { name = "Brock Stoneseeker", rank = "Artisan", faction = "A", mapID = 1432, x = 0.371, y = 0.478 },
    { name = "Kurdram Stonehammer", rank = "Artisan", faction = "A", mapID = 1439, x = 0.382, y = 0.410 },
    { name = "Matt Johnson", rank = "Artisan", faction = "A", mapID = 1431, x = 0.741, y = 0.496 },
    { name = "Norzsh", rank = "Apprentice", faction = "H", mapID = 1411, x = 0.406, y = 0.681 },
    { name = "Vartha Rockmane", rank = "Apprentice", faction = "H", mapID = 1412, x = 0.443, y = 0.783 },
    { name = "Walter Mason", rank = "Apprentice", faction = "H", mapID = 1420, x = 0.323, y = 0.657 },
    { name = "Makaru", rank = "Artisan", faction = "H", mapID = 1454, x = 0.731, y = 0.264 },
    { name = "Brek Stonehoof", rank = "Artisan", faction = "H", mapID = 1456, x = 0.347, y = 0.569 },
    { name = "Brom Killian", rank = "Artisan", faction = "H", mapID = 1458, x = 0.565, y = 0.376 },
    { name = "Johan Focht", rank = "Artisan", faction = "H", mapID = 1421, x = 0.434, y = 0.405 },
    { name = "Messana Crestwind", rank = "Artisan", faction = "N", mapID = 2521, x = 0.448, y = 0.445 },
    { name = "Halavuul Cragwind", rank = "Artisan", faction = "N", mapID = 2521, x = 0.654, y = 0.804 },
    { name = "Pikkle", rank = "Artisan", faction = "N", mapID = 1446, x = 0.511, y = 0.281 },
    { name = "Grungle", rank = "Artisan", faction = "N", mapID = 2548, x = 0.777, y = 0.519 },
}

ns.nodes = {
    { name = "Copper Vein", skill = { 1, 25, 50, 100 }, items = { 2770, 2835 }, zones = { 2521, 1412, 1413, 1426, 1429, 1420, 1411 } },
    { name = "Tin Vein", skill = { 65, 90, 115, 165 }, items = { 2771, 2836 }, zones = { 1440, 1413, 1433, 1432, 1424, 1437, 2548 } },
    { name = "Silver Vein", skill = { 75, 100, 125, 175 }, items = { 2775 }, zones = { 1417, 1441, 1413, 1424, 1434, 1433, 2548 } },
    { name = "Iron Deposit", skill = { 125, 150, 175, 225 }, items = { 2772, 2838 }, zones = { 1417, 1443, 1434, 1441, 1416, 1418, 2548 } },
    { name = "Gold Vein", skill = { 155, 180, 205, 255 }, items = { 2776 }, zones = { 1417, 1418, 1434, 1446, 1425, 1441 } },
    { name = "Mithril Deposit", skill = { 175, 200, 225, 275 }, items = { 3858, 7912 }, zones = { 1425, 1446, 1447, 1443, 1418, 1427 } },
    { name = "Truesilver Deposit", skill = { 230, 255, 280, 330 }, items = { 7911 }, zones = { 1452, 1425, 1428, 1423, 1449, 1447 } },
    { name = "Dark Iron Deposit", skill = { 230, 255, 280, 330 }, items = { 11370 }, zones = { 1428, 1427 } },
    { name = "Small Thorium Vein", skill = { 245, 270, 295, 345 }, items = { 10620, 12365 }, zones = { 1449, 1451, 1428, 1452, 1422, 1423 } },
    { name = "Rich Thorium Vein", skill = { 275, 300, 325, 375 }, items = { 10620, 12365 }, zones = { 1452, 1423, 1447, 1428, 1449, 1422 } },
}

ns.steps = {
    { from = 1, to = 65, faction = "H", zones = { 1411, 1412, 1420 }, nodes = { "Copper Vein" }, note = "mine.start" },
    { from = 1, to = 65, faction = "A", zones = { 1429, 1426, 1438 }, nodes = { "Copper Vein" }, note = "mine.start" },
    { from = 1, to = 65, faction = "N", zones = { 2521 }, nodes = { "Copper Vein" }, note = "mine.zephras" },
    { from = 65, to = 125, faction = "A", zones = { 1437, 1436, 1413 }, nodes = { "Copper Vein", "Tin Vein", "Silver Vein" }, note = "mine.journeyman" },
    { from = 65, to = 125, faction = "H", zones = { 1421, 1424, 1413 }, nodes = { "Copper Vein", "Tin Vein", "Silver Vein" }, note = "mine.journeyman" },
    { from = 125, to = 175, faction = "N", zones = { 1441, 1417, 1443 }, nodes = { "Iron Deposit", "Gold Vein", "Silver Vein" }, note = "mine.expert" },
    { from = 175, to = 245, faction = "N", zones = { 1425, 1446 }, nodes = { "Mithril Deposit", "Truesilver Deposit", "Gold Vein" }, note = "mine.artisan" },
    { from = 245, to = 275, faction = "N", zones = { 1449, 1448, 1419 }, nodes = { "Small Thorium Vein", "Mithril Deposit", "Truesilver Deposit" } },
    { from = 275, to = 300, faction = "N", zones = { 1449, 1452, 1428, 1423 }, nodes = { "Rich Thorium Vein", "Small Thorium Vein" }, note = "mine.end" },
}
ns.tips = { "mine.tip.pick", "mine.tip.tracking", "mine.tip.smelt" }

-- Camping recipes (Icy Veins WoW Forever database, Nov 2026).
ns.camping = {
    { skill = 20, name = "Lodestone", spell = 1230161, trainer = true, cost = 100 },
    { skill = 140, name = "Rock Garden", spell = 1262975, blueprint = 273097,
      drops = { { "Relic Guardian", "Excavation Site: Wetlands", 6.6 } } },
    { skill = 300, name = "Molten Foundry", spell = 1263071, blueprint = 273122,
      drops = { { "Ambassador Flamelash", "Blackrock Depths", 3.5 } } },
}
