-- Adds Forever Crafting lines to item tooltips: where a material is skinned (zones,
-- not single mobs), which profession can make it and from what, and what the open
-- profession module needs of it.
local _, FC = ...
local L = FC.L
local U = FC.Util

local GOLD = { 0.95, 0.78, 0.35 }
local TEXT = { 0.92, 0.88, 0.78 }

local function zoneList(g)
    local names = {}
    for _, id in ipairs(g.zones or {}) do table.insert(names, U.ZoneName(id)) end
    for _, p in ipairs(g.places or {}) do table.insert(names, L[p]) end
    return table.concat(names, ", ")
end

local function plainItem(id)
    return string.format("|T%s:0|t %s", tostring(U.ItemIcon(id)), U.ItemName(id))
end

local function addLines(tt, itemID)
    if not (FC.db and FC.db.tooltips) or not itemID then return end
    local lines = {}
    local g = FC.gathering and FC.gathering[itemID]
    if g then
        table.insert(lines, { L["Skinned in"] .. ": " .. zoneList(g) })
        if g.creatures then table.insert(lines, { L["From"] .. ": " .. L[g.creatures] }) end
    end
    for _, m in ipairs(FC.madeFrom and FC.madeFrom[itemID] or {}) do
        local parts = {}
        for _, re in ipairs(m.reagents) do table.insert(parts, string.format("%d× %s", re[2], plainItem(re[1]))) end
        local text = string.format("%s (%d): %s", L[m.prof], m.skill or 1, table.concat(parts, ", "))
        if FC:GetSkill(m.line) then
            text = text .. "  " .. (FC:IsKnown(m.line, m.spell) and U.Colorize(L["Known"], 0.3, 0.9, 0.3)
                or U.Colorize(L["not known"], 1, 0.4, 0.4))
        end
        table.insert(lines, { L["Made with"] .. " " .. text })
    end
    for _, key in ipairs(FC.moduleOrder) do
        local mod = FC.modules[key]
        if mod.TooltipLines then
            local ok, extra = pcall(mod.TooltipLines, mod, itemID)
            if ok and extra then for _, l in ipairs(extra) do table.insert(lines, { l }) end end
        end
    end
    local value = FC.Value:Lines(itemID)
    if value then
        table.insert(lines, { value[1] })
        table.insert(lines, { value[2], small = true })
    end
    if #lines == 0 then return end
    tt:AddLine(L["Forever Crafting"], GOLD[1], GOLD[2], GOLD[3])
    for _, l in ipairs(lines) do
        if l.small then tt:AddLine(l[1], 0.7, 0.7, 0.7, true) else tt:AddLine(l[1], TEXT[1], TEXT[2], TEXT[3], true) end
    end
    tt:Show()
end

local function itemFromData(data)
    local id = data and data.id
    if type(id) == "number" then return id end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
        if tt ~= GameTooltip and tt ~= ItemRefTooltip then return end
        local ok, id = pcall(itemFromData, data)
        if ok and id then addLines(tt, id) end
    end)
else
    local function onItem(tt)
        local _, link = tt:GetItem()
        local id = link and tonumber(link:match("item:(%d+)"))
        addLines(tt, id)
    end
    GameTooltip:HookScript("OnTooltipSetItem", onItem)
    ItemRefTooltip:HookScript("OnTooltipSetItem", onItem)
end
