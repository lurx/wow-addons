-- Small shared helpers: money text, item info, difficulty colours, craft estimates.
local _, FC = ...
local L = FC.L
FC.Util = {}
local U = FC.Util

function U.Money(copper, short)
    if not copper then return L["No price"] end
    copper = math.floor(copper + 0.5)
    if GetCoinTextureString and not short then
        return GetCoinTextureString(copper)
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then return string.format("%dg %ds", g, s) end
    if s > 0 then return string.format("%ds %dc", s, c) end
    return string.format("%dc", c)
end

-- Item name/icon with graceful fallback while the client is still loading item data.
function U.ItemName(itemID, fallback)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then
        C_Item.RequestLoadItemDataByID(itemID)
        return fallback or ("item:" .. itemID)
    end
    return name
end

-- Item icon followed by its name, in the item's quality colour (ink for common items).
function U.ItemBracket(itemID)
    local text = string.format("|T%s:14:14:0:-1|t %s", tostring(U.ItemIcon(itemID)), U.ItemName(itemID))
    local r, g, b = U.ItemQualityColor(itemID)
    if r then return U.Colorize(text, r, g, b) end
    return text
end

-- "[Heavy Leather] can be crafted from 5× [Medium Leather] (Leatherworking)".
function U.MadeFromText(itemID)
    local list = FC.madeFrom and FC.madeFrom[itemID]
    if not list then return end
    local options = {}
    for _, m in ipairs(list) do
        local parts = {}
        for _, re in ipairs(m.reagents) do
            table.insert(parts, string.format("%d× %s", re[2], U.ItemBracket(re[1])))
        end
        local made = m.count and m.count > 1 and string.format(" (%s, ×%d)", FC.L[m.prof], m.count) or string.format(" (%s)", FC.L[m.prof])
        table.insert(options, table.concat(parts, ", ") .. made)
    end
    return string.format(FC.L["%s can be crafted from %s"], U.ItemBracket(itemID), table.concat(options, " " .. FC.L["or"] .. " "))
end

function U.ItemIcon(itemID)
    return C_Item.GetItemIconByID(itemID) or 134400
end

-- Item quality colours for text on parchment. The game's own colours are made for dark
-- tooltips (bright green, light blue) and wash out on a light page, so these are darker
-- shades of the same hues. Common and poor items use the normal ink.
local PARCHMENT_QUALITY = {
    [2] = { 0.10, 0.42, 0.04 },   -- uncommon: dark green
    [3] = { 0.02, 0.30, 0.62 },   -- rare: dark blue
    [4] = { 0.42, 0.13, 0.62 },   -- epic: dark purple
    [5] = { 0.70, 0.33, 0.00 },   -- legendary: dark orange
    [6] = { 0.55, 0.45, 0.15 },   -- artifact / heirloom: dark gold
    [7] = { 0.10, 0.45, 0.60 },
}
function U.ItemQualityColor(itemID)
    local q = C_Item.GetItemQualityByID(itemID)
    local c = q and PARCHMENT_QUALITY[q]
    if c then return c[1], c[2], c[3] end
end

function U.ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    return link
end

-- Bags + bank (and reagent bank where the client has one). When the game doesn't
-- report the bank (not visited this session), the last bank snapshot is used.
function U.Count(itemID)
    local withBank = C_Item.GetItemCount(itemID, true, false, true) or 0
    local bags = C_Item.GetItemCount(itemID, false) or 0
    if withBank == bags and FC.Inventory then
        local snap = FC.Inventory:MyBank(itemID)
        if snap and snap > 0 then return bags + snap end
    end
    return withBank
end

-- Count on this realm's other characters of the same faction.
function U.AltCount(itemID)
    return FC.Inventory and (FC.Inventory:OnAlts(itemID)) or 0
end

function U.SpellName(spellID, fallback)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID) or fallback
    end
    return (GetSpellInfo and GetSpellInfo(spellID)) or fallback
end

function U.ZoneName(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    return info and info.name or L["Unknown"]
end

-- Difficulty -------------------------------------------------------------------------
-- r = { o = learn skill, y = yellow, g = green, gr = gray }
-- Text colours, darkened so they read on parchment.
U.DIFF_COLORS = {
    orange = { 0.78, 0.30, 0.00 },
    yellow = { 0.60, 0.45, 0.00 },
    green  = { 0.13, 0.42, 0.06 },
    gray   = { 0.38, 0.36, 0.32 },
    red    = { 0.62, 0.06, 0.03 },
}
-- Fill colours for bars and pills.
U.DIFF_FILLS = {
    orange = { 0.86, 0.42, 0.08 },
    yellow = { 0.88, 0.70, 0.12 },
    green  = { 0.27, 0.56, 0.16 },
    gray   = { 0.56, 0.53, 0.48 },
    red    = { 0.66, 0.12, 0.08 },
}
U.DIFF_NAMES = { orange = "Orange", yellow = "Yellow", green = "Green", gray = "Gray", red = "Not learnable yet" }

function U.Difficulty(r, skill)
    if r.o and skill < r.o then return "red" end
    if r.y and skill < r.y then return "orange" end
    if r.g and skill < r.g then return "yellow" end
    if r.gr and skill < r.gr then return "green" end
    return "gray"
end

-- Chance of a skill point at a given skill (standard formula: certain while orange,
-- then falling linearly from yellow to zero at gray).
function U.SkillUpChance(r, skill)
    if r.o and skill < r.o then return 0 end
    if not r.y or not r.gr then return 1 end
    if skill < r.y then return 1 end
    if skill >= r.gr then return 0 end
    return (r.gr - skill) / (r.gr - r.y)
end

-- Expected crafts to go from `from` to `to` with this recipe. nil if it can't get there.
function U.ExpectedCrafts(r, from, to)
    local total = 0
    for s = from, to - 1 do
        local c = U.SkillUpChance(r, s)
        if c <= 0 then return nil end
        total = total + 1 / c
    end
    return math.ceil(total)
end

function U.Colorize(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

function U.Ink(text)
    local c = FC.Style and FC.Style.ink or { 0.24, 0.15, 0.07 }
    return U.Colorize(text, c[1], c[2], c[3])
end
