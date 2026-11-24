-- Where skinned materials come from, by zone (uiMapID, so names follow the game
-- language). Zone lists follow the Icy Veins WoW Forever skinning overview (Nov 2026).
-- [itemID] = { zones = { mapIDs }, places = { extra text }, creatures = "who to skin" }
local _, FC = ...
FC.gathering = {
    [2934] = { zones = { 1429, 1438, 2521 } },                                   -- Ruined Leather Scraps
    [2318] = { zones = { 1436, 1413, 1439, 1432 } },                             -- Light Leather
    [783]  = { zones = { 1436, 1413, 1439, 1432 } },                             -- Light Hide
    [2319] = { zones = { 1437, 1424, 1440, 1441 } },                             -- Medium Leather
    [4232] = { zones = { 1437, 1424, 1440, 1441 } },                             -- Medium Hide
    [4234] = { zones = { 1434, 1418, 1435, 1445 } },                             -- Heavy Leather
    [4235] = { zones = { 1434, 1418, 1435, 1445 } },                             -- Heavy Hide
    [4304] = { zones = { 1446, 1444, 1425, 1419 } },                             -- Thick Leather
    [8169] = { zones = { 1446, 1444, 1425, 1419 } },                             -- Thick Hide
    [8170] = { zones = { 1452, 1422, 1448, 1449 } },                             -- Rugged Leather
    [8171] = { zones = { 1452, 1422, 1448, 1449 } },                             -- Rugged Hide
    [7286] = { zones = { 1433 }, creatures = "Black whelps" },                   -- Black Whelp Scale
    [7287] = { zones = { 1437 }, creatures = "Red whelps" },                     -- Red Whelp Scale
    [6470] = { places = { "Wailing Caverns" }, creatures = "Deviate raptors and serpents" }, -- Deviate Scale
    [6471] = { places = { "Wailing Caverns" }, creatures = "Deviate raptors and serpents" }, -- Perfect Deviate Scale
    [7392] = { zones = { 1435 }, creatures = "Green whelps" },                   -- Green Whelp Scale
    [7428] = { zones = { 1434, 1435 }, creatures = "Shadowmaw and Shadow Panthers" }, -- Shadowcat Hide
    [8167] = { zones = { 1445, 1425, 1446 }, creatures = "Tortoises, snapjaws and surf gliders" }, -- Turtle Scale
    [8154] = { zones = { 1446 }, creatures = "Scorpids" },                       -- Scorpid Scale
    [8165] = { zones = { 1428, 1452 }, places = { "Sunken Temple" }, creatures = "Black dragonspawn and scalebanes" }, -- Worn Dragonscale
    [15412] = { zones = { 1435 }, places = { "Sunken Temple" }, creatures = "Green scalebanes and wyrmkin" }, -- Green Dragonscale
    [15414] = { zones = { 1437 }, places = { "Grim Batol" }, creatures = "Red dragonspawn and wyrmkin" }, -- Red Dragonscale
    [15415] = { zones = { 1452, 1447 }, creatures = "Blue dragonkin" },          -- Blue Dragonscale
    [15416] = { zones = { 1428 }, creatures = "Black and Flamescale dragonspawn" }, -- Black Dragonscale
    [15408] = { zones = { 1451, 1428 }, creatures = "Stonelash, Firetail and Venomtip scorpids" }, -- Heavy Scorpid Scale
    [15417] = { zones = { 1449 }, creatures = "Devilsaurs" },                    -- Devilsaur Leather
    [15419] = { zones = { 1452, 1448, 1422 }, creatures = "Shardtooth, Angerclaw and diseased bears" }, -- Warbear Leather
    [15422] = { zones = { 1452 }, creatures = "Frostsabers" },                   -- Frostsaber Leather
    [15423] = { zones = { 1452, 1447 }, creatures = "Chimaeras and Mistwing ravagers" }, -- Chimera Leather
}
