-- Shopping page: materials for the guide from the current skill, minus what you hold
-- and minus anything the route itself crafts along the way.
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI
FC.PageFactories = FC.PageFactories or {}
table.insert(FC.PageFactories, function(mod, ns)

local state = { scope = "rank" }

-- Steps covered by the chosen scope, with the number of crafts left in each.
local function stepsInScope(skill, max)
    local out = {}
    local current = mod:CurrentStepIndex(skill)
    if not current then return out end
    local guide = mod:Guide()
    for i = current, #guide do
        local step = guide[i]
        local within = state.scope == "guide"
            or (state.scope == "step" and i == current)
            or (state.scope == "rank" and step.from < math.max(max, 1))
        if within then
            local crafts = mod:StepCrafts(step, skill)
            if step.fixed and mod:FixedStepDone(step) then crafts = 0 end
            if crafts > 0 then table.insert(out, { step = step, crafts = crafts }) end
        end
    end
    return out
end

-- Returns buy rows { id, need, have, buy, price, source }, prep list from mod:Resolve,
-- total cost, and the names of items the route itself makes along the way.
function mod:ShoppingList(skill, max)
    local need, produced, order = {}, {}, {}
    for _, st in ipairs(stepsInScope(skill, max)) do
        local r = ns.recipes[st.step.spell]
        if r then
            for _, re in ipairs(r.reagents) do
                if not need[re[1]] then table.insert(order, re[1]) end
                need[re[1]] = (need[re[1]] or 0) + re[2] * st.crafts
            end
            if r.item then
                -- Items like Cured Light Hide made earlier in the route and used later.
                produced[r.item] = (produced[r.item] or 0) + (r.count or 1) * st.crafts
            end
        end
    end
    local needs, crafted = {}, {}
    for _, id in ipairs(order) do
        local fromRoute = math.min(produced[id] or 0, need[id])
        if fromRoute > 0 then table.insert(crafted, U.ItemName(id)) end
        if need[id] - fromRoute > 0 then table.insert(needs, { id, need[id] - fromRoute }) end
    end
    local items, preps = self:Resolve(needs)
    local rows, total = {}, 0
    for _, e in ipairs(items) do
        if not e.craft then
            local price, source = FC.Prices:Get(e.id)
            if e.short > 0 and price then total = total + e.short * price end
            table.insert(rows, { id = e.id, need = e.need, have = e.have, buy = e.short, price = price, source = source })
        end
    end
    return rows, total, crafted, preps, items
end

-- Tooltip line: how much of this item the shopping list (current scope) still needs.
local tipCache, tipTime = nil, 0
function mod:TooltipLines(itemID)
    local skill, max, has = self:Skill()
    if not has then return end
    if not tipCache or GetTime() - tipTime > 3 then
        local rows, _, _, preps = self:ShoppingList(skill, max)
        tipCache = {}
        for _, r in ipairs(rows) do tipCache[r.id] = { need = r.need, buy = r.buy } end
        for _, c in ipairs(preps) do tipCache[c.item] = { craft = c.crafts * (ns.recipes[c.spell].count or 1) } end
        tipTime = GetTime()
    end
    local e = tipCache[itemID]
    if not e then return end
    local scope = state.scope == "step" and L["This step"] or state.scope == "guide" and L["Whole guide"] or L["To rank cap"]
    if e.craft then
        return { string.format(L["%s shopping (%s): craft %d"], mod.shortTitle, scope, e.craft) }
    elseif e.buy > 0 then
        return { string.format(L["%s shopping (%s): need %d, buy %d"], mod.shortTitle, scope, e.need, e.buy) }
    end
    return { string.format(L["%s shopping (%s): need %d, you have enough"], mod.shortTitle, scope, e.need) }
end

local function render(canvas)
    local skill, max, has = mod:Skill()
    if not has then
        canvas:Text(string.format(L["%s is not learned on this character."], mod.shortTitle), "heading")
        return
    end
    canvas:Text(L["Shopping covers the guide from your current skill."], "small")
    local rows, total, crafted, preps, items = mod:ShoppingList(skill, max)
    local byId = {}
    for _, e in ipairs(items) do byId[e.id] = e end

    if #preps > 0 then
        canvas:Space(4)
        canvas:Text(U.Colorize(L["Prepare first"], unpack(S.accent)), "small")
        for i = #preps, 1, -1 do
            local c = preps[i]
            local e = byId[c.item]
            local status = c.known and U.Colorize(L["Known"], unpack(U.DIFF_COLORS.green))
                or U.Colorize(L["not known"], unpack(U.DIFF_COLORS.red))
            canvas:Row({
                icon = U.ItemIcon(c.item), height = 24, iconSize = 20, desaturate = not c.known,
                left = string.format(L["Craft %d× %s"], c.crafts * (ns.recipes[c.spell].count or 1), U.ItemName(c.item)),
                right = string.format("%s %d   ·   %s", L["Have"], e and e.have or 0, status),
                rightWidth = 220, rightFont = "body",
                onEnter = function(self) UI.ItemTooltip(self, c.item, { string.format(L["Made by %s"], mod.shortTitle) }) end,
            })
            if not c.known then
                for _, src in ipairs(mod:Sources(c.spell)) do
                    local hasPts = src.points and #src.points > 0
                    canvas:Row({ indent = 30, height = 18, leftFont = "small", left = src.text,
                        leftColor = hasPts and S.link or S.inkSoft,
                        onClick = hasPts and function() FC.Map:Show(src.points) end or nil })
                end
            end
        end
        canvas:Space(6)
    end

    -- Need | Have | Buy | Price | Source, each its own fixed-width column.
    local function cols(need, have, alts, buy, price, source, header)
        local f = header and "small" or nil
        local c = header and S.accent or nil
        return {
            { text = need, width = 44, font = f, color = c },
            { text = have, width = 44, font = f, color = c },
            { text = alts, width = 40, font = f, color = c or S.inkSoft },
            { text = buy, width = 44, font = f, color = c or (buy ~= "0" and S.accent or U.DIFF_COLORS.green) },
            { text = price, width = 96, font = f, color = c },
            { text = source, width = 76, justify = "LEFT", font = header and "small" or "tiny", color = c or S.inkSoft },
        }
    end
    local width = 44 * 3 + 40 + 96 + 76 + 8 * 6
    canvas:Row({ height = 20, left = U.Colorize(L["Materials"], unpack(S.accent)), leftFont = "small",
        cols = cols(L["Need"], L["Have"], L["Alts"], L["Buy"], L["Price"], L["Source"], true), rightWidth = width })
    local allHave = #preps == 0
    for i, row in ipairs(rows) do
        if row.buy > 0 then allHave = false end
        local alts = U.AltCount(row.id)
        local priceText = row.price and U.Money(row.buy > 0 and row.price * row.buy or row.price, true) or L["No price"]
        canvas:Row({
            icon = U.ItemIcon(row.id), height = 24, iconSize = 20,
            left = U.ItemName(row.id),
            cols = cols(tostring(row.need), tostring(row.have), alts > 0 and tostring(alts) or "–", tostring(row.buy), priceText, row.price and (row.source or "") or ""),
            rightWidth = width,
            bg = (i % 2 == 0) and S.rowAlt or nil,
            onEnter = function(self)
                local lines = {}
                if row.price then table.insert(lines, L["Price"] .. ": " .. U.Money(row.price) .. " (" .. (row.source or "") .. ")") end
                local altLines = FC.Inventory:AltLines(row.id)
                if #altLines > 0 then
                    table.insert(lines, L["On other characters"] .. ":")
                    for _, l in ipairs(altLines) do table.insert(lines, "  " .. l) end
                end
                UI.ItemTooltip(self, row.id, lines)
            end,
        })
    end
    -- Bought materials that some profession can make, and from what.
    local notes = {}
    for _, row in ipairs(rows) do
        local t = U.MadeFromText(row.id)
        if t then table.insert(notes, t) end
    end
    if #notes > 0 then
        canvas:Space(4)
        for _, t in ipairs(notes) do canvas:Text(t, "small", 4) end
    end
    canvas:Divider()
    if allHave then
        canvas:Text(U.Colorize(L["Everything you need is already in your bags or bank."], unpack(U.DIFF_COLORS.green)), "body")
    else
        canvas:Row({ height = 26, left = L["Estimated cost"], leftFont = "heading",
            right = U.Money(total), rightWidth = 220, rightColor = S.ink })
    end
    if #crafted > 0 then
        canvas:Text(string.format(L["Crafted along the way: %s"], table.concat(crafted, ", ")), "small")
    end
    canvas:Text(FC.Prices:Footnote(), "small")
end

local function setup(tb)
    local scope = UI.ButtonGroup(tb, {
        { value = "step", text = L["This step"] },
        { value = "rank", text = L["To rank cap"] },
        { value = "guide", text = L["Whole guide"] },
    }, function() return state.scope end, function(v) state.scope = v FC.Window:Refresh() end)
    scope:SetPoint("LEFT", 0, 0)
end

table.insert(mod.pages, { key = "shopping", title = L["Shopping"], render = render, setup = setup })
end)
