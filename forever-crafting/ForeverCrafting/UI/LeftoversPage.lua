-- Leftovers: crafting materials, crafted items and spare profession tools in your bags
-- and bank that your guides no longer need, with what each is worth sold to a vendor,
-- on the auction house, or disenchanted. Information only: nothing is sold for you.
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI

FC.SharedPages = FC.SharedPages or {}

-- Profession tools: keep one if you have the profession, none if you don't.
local TOOLS = {
    [7005] = 393,   -- Skinning Knife (Skinning)
    [2901] = 186,   -- Mining Pick (Mining)
    [5956] = 164,   -- Blacksmith Hammer (Blacksmithing)
    [6219] = 202,   -- Arclight Spanner (Engineering)
    [10498] = 202,  -- Gyromatic Micro-Adjustor (Engineering)
}

-- Trade goods that belong to a profession: [subclassID] = skill lines that use them.
-- A recipe's reagent only counts as a leftover when you have one of those professions,
-- so a leatherworker doesn't see herbs, cloth or ore that one odd pattern happens to use.
local OWNERS = {
    [5] = { 197 },            -- Cloth: Tailoring
    [6] = { 165, 393 },       -- Leather: Leatherworking, Skinning
    [7] = { 186, 164, 202 },  -- Metal & Stone: Mining, Blacksmithing, Engineering
    [8] = { 185 },            -- Cooking
    [9] = { 182, 171 },       -- Herb: Herbalism, Alchemy
    [12] = { 333 },           -- Enchanting
}

-- Whether a recipe reagent is a material of one of your professions. Potions, food and
-- drink are never leftovers as reagents: you use them. (A module still lists the things
-- its own recipes make, so an alchemist sees spare potions.)
function FC.IsOwnMaterial(id)
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
    if not classID then return true end
    if classID == 0 then return false end
    local owners = classID == 7 and OWNERS[subclassID]
    if not owners then return true end
    for _, line in ipairs(owners) do
        if FC:GetSkill(line) then return true end
    end
    return false
end

local function collect()
    local candidates, earmarked = {}, {}
    for _, key in ipairs(FC.moduleOrder) do
        local mod = FC.modules[key]
        if mod.CandidateItems then
            for id in pairs(mod:CandidateItems()) do candidates[id] = true end
        end
        if mod.Earmarked then
            for id, n in pairs(mod:Earmarked()) do earmarked[id] = (earmarked[id] or 0) + n end
        end
    end
    for id in pairs(FC.gathering or {}) do candidates[id] = true end
    for id in pairs(TOOLS) do candidates[id] = true end

    local rows = {}
    for id in pairs(candidates) do
        local total = U.Count(id)
        if total > 0 then
            local keep = earmarked[id] or 0
            if TOOLS[id] then keep = FC:GetSkill(TOOLS[id]) and 1 or 0 end
            local spare = total - keep
            if spare > 0 then
                local bags = C_Item.GetItemCount(id, false) or 0
                local v = FC.Value:Get(id)
                table.insert(rows, {
                    id = id, spare = spare, bags = math.min(bags, total), bank = math.max(total - bags, 0),
                    tool = TOOLS[id] ~= nil, v = v,
                    worth = v and v.bestValue and v.bestValue * spare or -1,
                })
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.worth ~= b.worth then return a.worth > b.worth end
        return U.ItemName(a.id) < U.ItemName(b.id)
    end)
    return rows
end

local NAMES = { vendor = "Vendor", auction = "Auction", disenchant = "Disenchant" }

local function cols(spare, vendor, auction, de, best, header)
    local f = header and "small" or nil
    local c = header and S.accent or nil
    return {
        { text = spare, width = 44, font = f, color = c },
        { text = vendor, width = 84, font = f, color = c },
        { text = auction, width = 84, font = f, color = c },
        { text = de, width = 88, font = f, color = c },
        { text = best, width = 72, justify = "LEFT", font = header and "small" or "tiny", color = c or U.DIFF_COLORS.green },
    }
end
local WIDTH = 44 + 84 + 84 + 88 + 72 + 8 * 5

local function money(v, spare, approx)
    if not v then return U.Colorize("–", unpack(S.inkSoft)) end
    return (approx and "~" or "") .. U.Money(v * spare, true)
end

local function render(canvas)
    canvas:Text(L["Leftovers"], "heading")
    canvas:Text(L["Crafting materials, crafted items and spare tools in your bags and bank that your guides no longer need, and what they're worth. Nothing is sold or listed for you."], "small")
    if FC.Inventory:MyBank(2318) == nil and not FC.Inventory:HasSyndicator() then
        canvas:Text(U.Colorize(L["Visit your bank once so leftovers there are counted too."], unpack(S.accent)), "small")
    end
    canvas:Space(4)

    local rows = collect()
    if #rows == 0 then
        canvas:Space(16)
        canvas:Text(L["Nothing left over. Everything you hold is still needed by your guides."], "body", 0, { justify = "CENTER" })
        return
    end

    canvas:Row({ height = 20, left = U.Colorize(L["Item"], unpack(S.accent)), leftFont = "small",
        cols = cols(L["Spare"], L["Vendor"], L["Auction"], "|T" .. FC.Value.ICON .. ":0|t " .. L["Disenchant"], L["Best"], true),
        rightWidth = WIDTH })

    local sum, anyDE = 0, false
    for i, row in ipairs(rows) do
        local v = row.v or {}
        if v.disenchant then anyDE = true end
        if row.worth > 0 then sum = sum + row.worth end
        local where = {}
        if row.bags > 0 then table.insert(where, string.format(L["bags %d"], row.bags)) end
        if row.bank > 0 then table.insert(where, string.format(L["bank %d"], row.bank)) end
        local sub = table.concat(where, "  ·  ")
        if row.tool then sub = sub .. "  ·  " .. L["spare tool"] end
        canvas:Row({
            icon = U.ItemIcon(row.id), height = 32, iconSize = 24,
            left = U.ItemName(row.id), sub = sub,
            cols = cols(tostring(row.spare), money(v.vendor, row.spare), money(v.auction, row.spare),
                money(v.disenchant, row.spare, true), v.best and L[NAMES[v.best]] or ""),
            rightWidth = WIDTH,
            bg = (i % 2 == 0) and S.rowAlt or nil,
            onClick = function(_, button)
                if IsModifiedClick("CHATLINK") then ChatEdit_InsertLink(U.ItemLink(row.id)) end
            end,
            onEnter = function(self)
                local lines = {}
                if v.vendor then table.insert(lines, L["Vendor"] .. ": " .. U.Money(v.vendor) .. " " .. L["each"]) end
                if v.auction then table.insert(lines, L["Auction"] .. ": " .. U.Money(v.auction) .. " " .. L["each, after the 5% cut"]) end
                if v.disenchant then table.insert(lines, L["Disenchant"] .. ": ~" .. U.Money(v.disenchant) .. " " .. L["each, on average"]) end
                UI.ItemTooltip(self, row.id, lines)
            end,
        })
    end

    canvas:Space(4)
    canvas:Row({ height = 22, left = U.Colorize(L["Worth about, each sold the best way"], unpack(S.accent)),
        right = U.Money(sum, true), rightWidth = 140 })
    canvas:Space(6)
    canvas:Text(U.Colorize(FC.Prices:Footnote(), unpack(S.inkSoft)), "tiny")
    if anyDE then
        canvas:Text(U.Colorize(L["Disenchant values are averages (experimental) and need an enchanter."], unpack(S.inkSoft)), "tiny")
    end
end

table.insert(FC.SharedPages, { key = "leftovers", title = L["Leftovers"], render = render })
