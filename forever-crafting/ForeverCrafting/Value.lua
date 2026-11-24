-- Experimental "Best value": what an item is worth sold to a vendor, sold on the
-- auction house (after the 5% cut), or disenchanted (expected value of the materials).
-- Disenchanting table for WoW Forever by required level (wow-professions.com/forever):
-- uncommon armor 75% dust / 20% essence / 5% shard, uncommon weapons 20 / 75 / 5,
-- rare items always a shard. Quantities are the middle of each range.
local _, FC = ...
local L = FC.L
local U = FC.Util
FC.Value = {}
local V = FC.Value

V.ICON = "Interface\\Icons\\Trade_Alchemy"

-- { maxRequiredLevel, dust, dustQty, essence, essenceQty, shard }
local TABLE = {
    { 10, 10940, 1.5, 10938, 1.5, nil },     -- Strange Dust, Lesser Magic Essence
    { 15, 10940, 2.5, 10939, 1.5, 10978 },   -- Strange Dust, Greater Magic Essence, Small Glimmering Shard
    { 20, 10940, 5.0, 10998, 1.5, 10978 },   -- Strange Dust, Lesser Astral Essence, Small Glimmering Shard
    { 25, 11083, 1.5, 11082, 1.5, 11084 },   -- Soul Dust, Greater Astral Essence, Large Glimmering Shard
    { 30, 11083, 3.5, 11134, 1.5, 11138 },   -- Soul Dust, Lesser Mystic Essence, Small Glowing Shard
    { 35, 11137, 1.5, 11135, 1.5, 11139 },   -- Vision Dust, Greater Mystic Essence, Large Glowing Shard
    { 40, 11137, 3.5, 11174, 1.5, 11177 },   -- Vision Dust, Lesser Nether Essence, Small Radiant Shard
    { 45, 11176, 1.5, 11175, 1.5, 11178 },   -- Dream Dust, Greater Nether Essence, Large Radiant Shard
    { 50, 11176, 3.5, 16202, 1.5, 14343 },   -- Dream Dust, Lesser Eternal Essence, Small Brilliant Shard
    { 55, 16204, 1.5, 16203, 1.5, 14344 },   -- Illusion Dust, Greater Eternal Essence, Large Brilliant Shard
    { 60, 16204, 3.5, 16203, 2.0, 14344 },   -- Illusion Dust, Greater Eternal Essence, Large Brilliant Shard
}

function V:Enabled()
    return FC.db and FC.db.experimentalValue
end

local function tier(reqLevel)
    reqLevel = math.max(reqLevel or 1, 1)
    for _, t in ipairs(TABLE) do
        if reqLevel <= t[1] then return t end
    end
end

-- Expected disenchant results: { { item, expectedCount } } or nil if it can't be disenchanted.
function V:Disenchant(itemID)
    local _, _, quality, _, reqLevel, _, _, _, _, _, _, classID = C_Item.GetItemInfo(itemID)
    if not quality or not (classID == 2 or classID == 4) then return nil end
    local t = tier(reqLevel)
    if not t then return nil end
    if quality == 2 then
        local weapon = classID == 2
        local out = {
            { t[2], (weapon and 0.20 or 0.75) * t[3] },
            { t[4], (weapon and 0.75 or 0.20) * t[5] },
        }
        if t[6] then table.insert(out, { t[6], 0.05 }) end
        return out
    elseif quality == 3 and t[6] then
        return { { t[6], 1 } }
    end
    return nil
end

-- Value of one item each way (copper). Returns nil while the item isn't cached.
-- { vendor, auction, disenchant, best = "vendor"|"auction"|"disenchant", bestValue }
function V:Get(itemID)
    local name, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemID)
    if not name then return nil end
    local r = {}
    if sellPrice and sellPrice > 0 then r.vendor = sellPrice end
    local ah = FC.Prices:AuctionPrice(itemID)
    if ah then r.auction = math.floor(ah * 0.95) end
    local parts = self:Disenchant(itemID)
    if parts then
        local total = 0
        for _, p in ipairs(parts) do
            local price = FC.Prices:AuctionPrice(p[1])
            if not price then total = nil break end
            total = total + price * p[2]
        end
        r.disenchant = total and math.floor(total) or nil
    end
    for _, key in ipairs({ "vendor", "auction", "disenchant" }) do
        if r[key] and (not r.bestValue or r[key] > r.bestValue) then
            r.best, r.bestValue = key, r[key]
        end
    end
    if not r.best then return nil end
    return r
end

local NAMES = { vendor = "Vendor", auction = "Auction", disenchant = "Disenchant" }

-- Two lines for a tooltip or the guide; nil when there's nothing to compare.
function V:Lines(itemID)
    if not self:Enabled() then return nil end
    local r = self:Get(itemID)
    if not r then return nil end
    local icon = "|T" .. self.ICON .. ":0|t "
    local head = icon .. L["Best value"] .. ": " .. L[NAMES[r.best]] .. " " .. (r.best == "disenchant" and "~" or "") .. U.Money(r.bestValue)
    local parts = {}
    for _, key in ipairs({ "vendor", "auction", "disenchant" }) do
        if r[key] then
            table.insert(parts, L[NAMES[key]] .. " " .. (key == "disenchant" and "~" or "") .. U.Money(r[key]))
        end
    end
    local detail = table.concat(parts, "  ·  ")
    if r.disenchant then detail = detail .. "  (" .. L["disenchanting needs an enchanter"] .. ")" end
    return { head, detail }
end
