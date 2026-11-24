-- Recipes page: every recipe of the profession, learned or not, with sources and reagents.
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI
FC.PageFactories = FC.PageFactories or {}
table.insert(FC.PageFactories, function(mod, ns)

local state = { filter = "all", search = "", hideUnsourced = true, source = "any", slot = "any", armor = "any", spec = "any" }

-- What kind of item a recipe makes, from the game's own item data (works uncached).
local SLOT_BY_EQUIP = {
    INVTYPE_HEAD = "head", INVTYPE_SHOULDER = "shoulder", INVTYPE_CHEST = "chest", INVTYPE_ROBE = "chest",
    INVTYPE_HAND = "hands", INVTYPE_WAIST = "waist", INVTYPE_LEGS = "legs", INVTYPE_FEET = "feet",
    INVTYPE_WRIST = "wrist", INVTYPE_CLOAK = "back", INVTYPE_BAG = "bags", INVTYPE_QUIVER = "bags",
    INVTYPE_BODY = "shirt", INVTYPE_SHIELD = "shield", INVTYPE_WEAPON = "weapon", INVTYPE_2HWEAPON = "weapon",
    INVTYPE_WEAPONMAINHAND = "weapon", INVTYPE_WEAPONOFFHAND = "weapon", INVTYPE_HOLDABLE = "weapon",
    INVTYPE_RANGED = "weapon", INVTYPE_RANGEDRIGHT = "weapon", INVTYPE_WAND = "weapon",
}
-- Enchants make no item; their slot is in the name ("Enchant Boots - Minor Speed").
local SLOT_BY_ENCHANT = { Boots = "feet", Bracer = "wrist", Chest = "chest", Cloak = "back", Gloves = "hands",
    Shield = "shield", Weapon = "weapon", ["2H Weapon"] = "weapon" }
local itemKind = {}
local function kindOf(itemID)
    local k = itemKind[itemID]
    if k then return k end
    local _, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    k = { slot = "other", armor = nil }
    if equipLoc and SLOT_BY_EQUIP[equipLoc] then k.slot = SLOT_BY_EQUIP[equipLoc]
    elseif classID == 1 or classID == 11 then k.slot = "bags"
    elseif classID == 0 then k.slot = "kits"
    elseif classID == 7 then k.slot = "materials" end
    if classID == 2 then k.slot = "weapon" end
    if classID == 4 and k.slot ~= "back" then
        k.armor = (subClassID == 1 and "cloth") or (subClassID == 2 and "leather") or (subClassID == 3 and "mail") or nil
    end
    if classID then itemKind[itemID] = k end
    return k
end

local function sourceMatch(id)
    if state.source == "any" then return true end
    for _, src in ipairs(mod:Sources(id)) do
        local kind = src.kind
        if kind == "quest" or kind == "pattern" then kind = "other" end
        if kind == state.source then return true end
    end
    return false
end
local sorted

local function sortedRecipes()
    if sorted then return sorted end
    sorted = {}
    for id in pairs(ns.recipes) do table.insert(sorted, id) end
    table.sort(sorted, function(a, b)
        local ra, rb = ns.recipes[a], ns.recipes[b]
        local la, lb = ra.lv.o or ra.lv.y or 0, rb.lv.o or rb.lv.y or 0
        if la ~= lb then return la < lb end
        return (ra.name or "") < (rb.name or "")
    end)
    return sorted
end

-- Exact thresholds for the tooltip, in bright tooltip colours.
local TIP = { orange = { 1, 0.5, 0.25 }, yellow = { 1, 1, 0 }, green = { 0.25, 0.75, 0.25 }, gray = { 0.6, 0.6, 0.6 } }
local function levelsText(lv)
    local function c(v, key) return v and U.Colorize(L[U.DIFF_NAMES[key]] .. " " .. v, unpack(TIP[key])) or nil end
    local parts = {}
    for _, k in ipairs({ { lv.o, "orange" }, { lv.y, "yellow" }, { lv.g, "green" }, { lv.gr, "gray" } }) do
        local t = c(k[1], k[2])
        if t then table.insert(parts, t) end
    end
    return table.concat(parts, "  ")
end

local function sourceSummary(id)
    local r = ns.recipes[id]
    local kinds = {}
    for _, src in ipairs(mod:Sources(id)) do
        local k = src.kind == "trainer" and L["Trainer"] or src.kind == "vendor" and L["Vendor"] or src.kind == "drop" and L["Drop"]
            or src.kind == "quest" and L["Quest"] or src.kind == "starter" and L["Starting recipe"] or L["Pattern"]
        if not kinds[k] then kinds[k] = true table.insert(kinds, k) end
    end
    local txt = #kinds > 0 and table.concat(kinds, ", ") or L["Source not recorded yet"]
    if r.spec then txt = txt .. "  ·  " .. string.format(L["Specialization: %s"], r.spec) end
    if r.tool then txt = txt .. "  ·  " .. string.format(L["Requires %s"], r.tool) end
    return txt
end

local function matches(id)
    local r = ns.recipes[id]
    local known = mod:IsKnown(id)
    if state.filter == "learned" and not known then return false end
    if state.filter == "missing" and known then return false end
    if state.hideUnsourced and not known and not mod:HasSource(id) then return false end
    if state.spec ~= "any" and (r.spec or "none") ~= state.spec then return false end
    if state.slot ~= "any" or state.armor ~= "any" then
        local k
        if r.item then
            k = kindOf(r.item)
        else
            local what = (r.name or ""):match("^Enchant ([%w ]-) %-")
            k = { slot = what and SLOT_BY_ENCHANT[what] or "other" }
        end
        if state.slot ~= "any" and k.slot ~= state.slot then return false end
        if state.armor ~= "any" and k.armor ~= state.armor then return false end
    end
    if not sourceMatch(id) then return false end
    if state.search ~= "" then
        local name = mod:RecipeName(id):lower()
        if not name:find(state.search, 1, true) then return false end
    end
    return true
end

local function expandedDetails(canvas, id, skill)
    local r = ns.recipes[id]
    canvas:Text(L["Reagents"], "small", 40, { color = S.accent })
    for _, re in ipairs(r.reagents) do
        local have = U.Count(re[1])
        local prep = mod:PrepRecipe(re[1])
        local sub
        if prep then
            sub = string.format(L["Made by %s"], mod.shortTitle) .. " · " .. (mod:IsKnown(prep)
                and U.Colorize(L["Known"], unpack(U.DIFF_COLORS.green))
                or U.Colorize(L["not known"], unpack(U.DIFF_COLORS.red)))
        end
        canvas:Row({
            indent = 40, height = 20, icon = U.ItemIcon(re[1]), iconSize = 16, sub = sub,
            left = string.format("%d× %s", re[2], U.ItemName(re[1])),
            right = string.format("%s %d", L["Have"], have) .. (U.AltCount(re[1]) > 0
                and U.Colorize(string.format("  " .. L["+%d on alts"], U.AltCount(re[1])), unpack(S.inkSoft)) or ""),
            rightWidth = 170,
            rightColor = have >= re[2] and U.DIFF_COLORS.green or S.inkSoft,
            onEnter = function(self) UI.ItemTooltip(self, re[1], FC.Inventory:AltLines(re[1])) end,
        })
    end
    local cost = mod:CraftCost(id)
    if cost then canvas:Text(string.format(L["Cost per craft: %s"], U.Money(cost)), "small", 40) end
    canvas:Text(L["Sources"], "small", 40, { color = S.accent })
    local sources = mod:Sources(id)
    if #sources == 0 then canvas:Text(L["Source not recorded yet"], "small", 52) end
    for _, src in ipairs(sources) do
        local hasPts = src.points and #src.points > 0
        canvas:Row({
            indent = 46, height = 18, leftFont = "small",
            left = src.text, leftColor = hasPts and S.link or S.inkSoft,
            onClick = hasPts and function() FC.Map:Show(src.points) end or nil,
            onEnter = hasPts and function(self) UI.TextTooltip(self, L["Show on map"], { L["Click to show on the world map."] }) end or nil,
        })
    end
    canvas:Space(6)
end

local function render(canvas)
    local skill = mod:Skill()
    local list = sortedRecipes()
    local shown, learned, total = 0, 0, 0
    for _, id in ipairs(list) do
        if mod:HasSource(id) or mod:IsKnown(id) then
            total = total + 1
            if mod:IsKnown(id) then learned = learned + 1 end
        end
    end
    canvas:Text(string.format(L["%d of %d recipes learned"], learned, total), "small")
    if not FC:HasSynced(mod.mainSkillLine) then
        canvas:Text(U.Colorize(L["Open your profession window once so Forever Crafting can read which recipes you know."], unpack(S.accent)), "small")
    end
    canvas:Space(4)

    for _, id in ipairs(list) do
        if matches(id) then
            shown = shown + 1
            local r = ns.recipes[id]
            local known = mod:IsKnown(id)
            local color = known and U.DIFF_COLORS[U.Difficulty(r.lv, skill)] or S.inkSoft
            local name = mod:RecipeName(id)
            if mod:IsRare(id) then name = name .. "  " .. "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12|t" .. U.Colorize(L["Rare"], 0.75, 0.55, 0.1) end
            canvas:Row({
                icon = mod:RecipeIcon(id), height = 36, desaturate = not known,
                ring = mod:IsRare(id) and "Interface\\Common\\WhiteIconFrame" or nil,
                left = U.Colorize(name, unpack(color)),
                sub = sourceSummary(id),
                skill = { lv = r.lv, skill = skill, known = known }, rightWidth = 185,
                bg = (shown % 2 == 0) and S.rowAlt or nil,
                onClick = function(_, button)
                    if IsModifiedClick("CHATLINK") and r.item then
                        ChatEdit_InsertLink(U.ItemLink(r.item))
                        return
                    end
                    mod.expanded[id] = not mod.expanded[id]
                    FC.Window:Refresh(true)
                end,
                onEnter = function(self)
                    UI.RecipeTooltip(self, r.item, id, { levelsText(r.lv), L["Click to show sources."],
                        r.item and L["Shift-click to link the item."] or nil })
                end,
            })
            if mod.expanded[id] then expandedDetails(canvas, id, skill) end
        end
    end
    canvas:Divider()
    canvas:Text(FC.Prices:Footnote(), "small")
end

local function setup(tb)
    local filter = UI.ButtonGroup(tb, {
        { value = "all", text = L["All"] },
        { value = "learned", text = L["Learned"] },
        { value = "missing", text = L["Missing"] },
    }, function() return state.filter end, function(v) state.filter = v FC.Window:Refresh() end)
    filter:SetPoint("LEFT", 0, 0)

    filter:ClearAllPoints()
    filter:SetPoint("TOPLEFT", 0, -2)
    local search = UI.Search(tb, 180, function(text)
        state.search = text:lower()
        FC.Window:Refresh()
    end)
    search:SetPoint("LEFT", filter, "RIGHT", 16, 0)

    local check = UI.Check(tb, L["Hide recipes with no known source"], function() return state.hideUnsourced end,
        function(v) state.hideUnsourced = v FC.Window:Refresh() end)
    check:SetPoint("LEFT", search, "RIGHT", 14, 0)

    -- Second row: dropdown filters.
    local function refresh() FC.Window:Refresh() end
    local source = UI.Dropdown(tb, L["Source"], {
        { value = "any", text = L["Any"] }, { value = "trainer", text = L["Trainer"] },
        { value = "vendor", text = L["Vendor"] }, { value = "drop", text = L["Drop"] },
        { value = "starter", text = L["Starting recipe"] }, { value = "other", text = L["Quest or other"] },
    }, function() return state.source end, function(v) state.source = v refresh() end, 150)
    source:SetPoint("TOPLEFT", filter, "BOTTOMLEFT", 0, -6)

    local slot = UI.Dropdown(tb, L["Type"], {
        { value = "any", text = L["Any"] }, { value = "head", text = L["Head"] }, { value = "shoulder", text = L["Shoulder"] },
        { value = "chest", text = L["Chest"] }, { value = "back", text = L["Back"] }, { value = "wrist", text = L["Wrist"] },
        { value = "hands", text = L["Hands"] }, { value = "waist", text = L["Waist"] }, { value = "legs", text = L["Legs"] },
        { value = "feet", text = L["Feet"] }, { value = "shirt", text = L["Shirt"] }, { value = "weapon", text = L["Weapon"] },
        { value = "shield", text = L["Shield"] }, { value = "kits", text = L["Kits and consumables"] },
        { value = "bags", text = L["Bags and quivers"] }, { value = "materials", text = L["Materials"] }, { value = "other", text = L["Other"] },
    }, function() return state.slot end, function(v) state.slot = v refresh() end, 150)
    slot:SetPoint("LEFT", source, "RIGHT", 6, 0)

    -- Armor and specialization choices come from the profession (none for Enchanting).
    local last = slot
    local armor, spec
    if mod.filters.armor then
        local choices = { { value = "any", text = L["Any"] } }
        for _, a in ipairs(mod.filters.armor) do table.insert(choices, { value = a, text = L[a:sub(1, 1):upper() .. a:sub(2)] }) end
        armor = UI.Dropdown(tb, L["Armor"], choices, function() return state.armor end, function(v) state.armor = v refresh() end, 130)
        armor:SetPoint("LEFT", last, "RIGHT", 6, 0)
        last = armor
    end
    if mod.filters.specs then
        local choices = { { value = "any", text = L["Any"] }, { value = "none", text = L["None"] } }
        for _, sp in ipairs(mod.filters.specs) do table.insert(choices, { value = sp, text = L[sp] }) end
        spec = UI.Dropdown(tb, L["Spec"], choices, function() return state.spec end, function(v) state.spec = v refresh() end, 140)
        spec:SetPoint("LEFT", last, "RIGHT", 6, 0)
        last = spec
    end

    local clear = UI.Button(tb, L["Clear"], 60, 22)
    clear:SetPoint("LEFT", last, "RIGHT", 6, 0)
    clear:SetScript("OnClick", function()
        state.source, state.slot, state.armor, state.spec = "any", "any", "any", "any"
        for _, d in ipairs({ source, slot, armor, spec }) do if d then d:Refresh() end end
        refresh()
    end)
end

table.insert(mod.pages, { key = "recipes", title = L["Recipes"], render = render, setup = setup, toolbarHeight = 54 })
end)
