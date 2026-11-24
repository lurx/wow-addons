-- Which reagents can be crafted, and from what, across every profession the addon
-- has data for (Leatherworking, Tailoring, Enchanting so far), so it works even for
-- professions this character doesn't have. Generated; do not edit by hand.
-- [itemID] = { { prof, line = skill line, spell = recipe, skill = learn level, count, reagents = { { id, qty }, ... } }, ... }
local _, FC = ...
FC.madeFrom = FC.madeFrom or {}
local M = FC.madeFrom

M[2312] = { { prof = "Leatherworking", line = 165, spell = 2164, skill = 50, count = 1, reagents = { { 2318, 4 }, { 2320, 2 }, { 4231, 1 } } } } -- Fine Leather Gloves
M[2313] = { { prof = "Leatherworking", line = 165, spell = 2165, skill = 75, count = 1, reagents = { { 2319, 4 }, { 2320, 1 } } } } -- Medium Armor Kit
M[2318] = { { prof = "Leatherworking", line = 165, spell = 2881, skill = 1, count = 1, reagents = { { 2934, 3 } } } } -- Light Leather
M[2319] = { { prof = "Leatherworking", line = 165, spell = 20648, skill = 75, count = 1, reagents = { { 2318, 4 } } } } -- Medium Leather
M[2996] = { { prof = "Tailoring", line = 197, spell = 2963, skill = 1, count = 1, reagents = { { 2589, 2 } } } } -- Bolt of Linen Cloth
M[2997] = { { prof = "Tailoring", line = 197, spell = 2964, skill = 55, count = 1, reagents = { { 2592, 3 } } } } -- Bolt of Woolen Cloth
M[4231] = { { prof = "Leatherworking", line = 165, spell = 3816, skill = 30, count = 1, reagents = { { 783, 1 }, { 4289, 1 } } } } -- Cured Light Hide
M[4233] = { { prof = "Leatherworking", line = 165, spell = 3817, skill = 75, count = 1, reagents = { { 4232, 1 }, { 4289, 1 } } } } -- Cured Medium Hide
M[4234] = { { prof = "Leatherworking", line = 165, spell = 20649, skill = 125, count = 1, reagents = { { 2319, 5 } } } } -- Heavy Leather
M[4236] = { { prof = "Leatherworking", line = 165, spell = 3818, skill = 125, count = 1, reagents = { { 4235, 1 }, { 4289, 3 } } } } -- Cured Heavy Hide
M[4243] = { { prof = "Leatherworking", line = 165, spell = 3761, skill = 60, count = 1, reagents = { { 2318, 6 }, { 2320, 4 }, { 4231, 3 } } } } -- Fine Leather Tunic
M[4246] = { { prof = "Leatherworking", line = 165, spell = 3763, skill = 55, count = 1, reagents = { { 2318, 6 }, { 2320, 2 } } } } -- Fine Leather Belt
M[4253] = { { prof = "Leatherworking", line = 165, spell = 3770, skill = 110, count = 1, reagents = { { 2319, 4 }, { 2321, 2 }, { 3182, 2 }, { 3389, 2 }, { 4233, 2 } } } } -- Toughened Leather Gloves
M[4265] = { { prof = "Leatherworking", line = 165, spell = 3780, skill = 125, count = 1, reagents = { { 2321, 1 }, { 4234, 5 } } } } -- Heavy Armor Kit
M[4304] = { { prof = "Leatherworking", line = 165, spell = 20650, skill = 175, count = 1, reagents = { { 4234, 6 } } } } -- Thick Leather
M[4305] = { { prof = "Tailoring", line = 197, spell = 3839, skill = 100, count = 1, reagents = { { 4306, 4 } } } } -- Bolt of Silk Cloth
M[4320] = { { prof = "Tailoring", line = 197, spell = 3855, skill = 100, count = 1, reagents = { { 2319, 4 }, { 3182, 4 }, { 4305, 2 }, { 5500, 1 } } } } -- Spidersilk Boots
M[4339] = { { prof = "Tailoring", line = 197, spell = 3865, skill = 140, count = 1, reagents = { { 4338, 5 } } } } -- Bolt of Mageweave
M[8170] = { { prof = "Leatherworking", line = 165, spell = 22331, skill = 225, count = 1, reagents = { { 4304, 6 } } } } -- Rugged Leather
M[8172] = { { prof = "Leatherworking", line = 165, spell = 10482, skill = 175, count = 1, reagents = { { 8150, 1 }, { 8169, 1 } } } } -- Cured Thick Hide
M[8173] = { { prof = "Leatherworking", line = 165, spell = 10487, skill = 175, count = 1, reagents = { { 4291, 1 }, { 4304, 5 } } } } -- Thick Armor Kit
M[14044] = { { prof = "Tailoring", line = 197, spell = 18418, skill = 230, count = 1, reagents = { { 7078, 1 }, { 14048, 5 }, { 14341, 1 } } } } -- Cindercloth Cloak
M[14048] = { { prof = "Tailoring", line = 197, spell = 18401, skill = 205, count = 1, reagents = { { 14047, 5 } } } } -- Bolt of Runecloth
M[14342] = { { prof = "Tailoring", line = 197, spell = 18560, skill = 230, count = 1, reagents = { { 14256, 2 } } } } -- Mooncloth
M[15407] = { { prof = "Leatherworking", line = 165, spell = 19047, skill = 225, count = 2, reagents = { { 8171, 1 }, { 15409, 1 } } } } -- Cured Rugged Hide
M[15564] = { { prof = "Leatherworking", line = 165, spell = 19058, skill = 225, count = 1, reagents = { { 8170, 5 } } } } -- Rugged Armor Kit
M[18251] = { { prof = "Leatherworking", line = 165, spell = 22727, skill = 300, count = 1, reagents = { { 14341, 2 }, { 17012, 3 } } } } -- Core Armor Kit
M[213369] = { { prof = "Leatherworking", line = 165, spell = 435819, skill = 200, count = 1, reagents = { { 8172, 1 }, { 213370, 5 } } } } -- Faintly Glowing Leather
M[247786] = { { prof = "Enchanting", line = 333, spell = 1245320, skill = 1, count = 3, reagents = { { 10940, 1 } } } } -- Dust to Motes
