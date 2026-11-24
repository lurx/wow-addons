-- Guide page: the 1-300 route with live progress, materials and where to learn each step.
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI
FC.PageFactories = FC.PageFactories or {}
table.insert(FC.PageFactories, function(mod, ns)

local showDone = false

local function diffColor(spellID, skill)
    local r = ns.recipes[spellID]
    if not r then return S.ink end
    local d = U.Difficulty(r.lv, skill)
    return U.DIFF_COLORS[d] or S.ink
end

local CHECK = " |TInterface\\RaidFrame\\ReadyCheck-Ready:11|t"
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:11|t "

-- "10× Cured Medium Hide (2), craft 8" style text for one material.
local function itemText(e, qty)
    local name = U.ItemName(e.id)
    local txt = string.format("%d× %s", qty, name)
    if e.craft then
        return txt .. U.Colorize(string.format(" (%d)", e.have), unpack(S.inkSoft))
            .. U.Colorize(" · " .. string.format(L["craft %d"], e.craft), unpack(S.accent))
    end
    -- Part of it is in the bank: say how much, so you know to fetch it.
    local bags = C_Item.GetItemCount(e.id, false) or 0
    local inBank = math.max((e.have or 0) - bags, 0)
    local bankNote = ""
    if inBank > 0 and bags < qty then
        bankNote = U.Colorize(" " .. string.format(L["(%d/%d in bank)"], math.min(inBank, qty), qty), unpack(S.accent))
    end
    if e.short <= 0 then
        return U.Colorize(txt, unpack(U.DIFF_COLORS.green)) .. bankNote .. CHECK
    end
    if bankNote ~= "" then
        local alts = U.AltCount(e.id)
        return txt .. bankNote .. (alts > 0 and U.Colorize(" " .. string.format(L["+%d on alts"], alts), unpack(S.inkSoft)) or "")
    end
    local alts = U.AltCount(e.id)
    local extra = {}
    if e.have > 0 then table.insert(extra, tostring(e.have)) end
    if alts > 0 then table.insert(extra, string.format(L["+%d on alts"], alts)) end
    if #extra > 0 then
        return txt .. U.Colorize(" (" .. table.concat(extra, ", ") .. ")", unpack(S.inkSoft))
    end
    return txt
end

-- Lines describing the materials for `crafts` of a recipe, including anything
-- that has to be prepared first and whether you know how to make it.
local function materialsLines(spellID, crafts)
    local r = ns.recipes[spellID]
    if not r or crafts <= 0 then return {} end
    local needs = {}
    for _, re in ipairs(r.reagents) do table.insert(needs, { re[1], re[2] * crafts }) end
    local items, preps = mod:Resolve(needs)
    local byId = {}
    for _, e in ipairs(items) do byId[e.id] = e end
    local top = {}
    for _, nd in ipairs(needs) do table.insert(top, itemText(byId[nd[1]], nd[2])) end
    local lines = { { text = table.concat(top, ",  ") } }
    -- Deepest preparation first, in the order you'd actually craft.
    for i = #preps, 1, -1 do
        local c = preps[i]
        local pr = ns.recipes[c.spell]
        local parts = {}
        for _, re in ipairs(pr.reagents) do
            table.insert(parts, itemText(byId[re[1]], re[2] * c.crafts))
        end
        local head = (c.known and "" or CROSS) .. string.format(L["Prepare %d× %s"], c.crafts * (pr.count or 1), U.ItemName(c.item))
        if not c.known then head = U.Colorize(head .. " (" .. L["not known"] .. ")", unpack(U.DIFF_COLORS.red)) end
        table.insert(lines, { text = head .. ":  " .. table.concat(parts, ",  "), spell = c.spell, known = c.known })
    end
    return lines
end

local function rankBlock(canvas, skill, max)
    local level = UnitLevel("player")
    local nextRank = mod:NextRank()
    if not nextRank then return end
    local ready = skill >= nextRank.skill and level >= nextRank.level
    local text
    if ready and skill >= max then
        text = U.Colorize(string.format(L["You are at your rank cap. Train %s to keep gaining skill."], L[nextRank.key]), unpack(S.accent))
    elseif ready then
        text = U.Colorize(string.format(L["Ready to train %s now"], L[nextRank.key]), unpack(U.DIFF_COLORS.green))
    else
        text = string.format(L["Next rank: %s at skill %d (character level %d)"], L[nextRank.key], nextRank.skill, nextRank.level)
    end
    local trainers = mod:TrainersFor(nextRank.key)
    local points = mod:TrainerPoints(trainers)
    local sub, lines = FC.Map.TrainerSummary(points)
    canvas:Row({
        icon = "Interface\\Icons\\INV_Misc_Book_11", height = 34, left = text,
        sub = sub,
        right = U.Colorize(L["Show on map"], unpack(S.link)), rightWidth = 110,
        bg = ready and { 0.4, 0.6, 0.2, 0.12 } or nil,
        onClick = function() FC.Map:Show(points) end,
        onEnter = function(self) UI.TextTooltip(self, L["Trainers"], lines) end,
    })
end

local function sourceLines(canvas, spellID)
    for _, src in ipairs(mod:Sources(spellID)) do
        local hasPts = src.points and #src.points > 0
        canvas:Row({
            indent = 46, height = 18,
            left = (src.kind == "trainer" and L["Trainer"] or src.kind == "vendor" and L["Vendor"] or src.kind == "drop" and L["Drop"]
                or src.kind == "quest" and L["Quest"] or L["Pattern"]) .. ":  " .. src.text,
            leftFont = "small", leftColor = hasPts and S.link or S.inkSoft,
            onClick = hasPts and function() FC.Map:Show(src.points) end or nil,
            onEnter = hasPts and function(self) UI.TextTooltip(self, L["Show on map"], { L["Click to show on the world map."] }) end or nil,
        })
    end
end

-- Steps that aren't a recipe (e.g. "disenchant green items until 20").
local ACTIONS = {
    disenchant = { icon = 132853, text = "Disenchant uncommon (green) or better items" },
}

local function actionCard(canvas, step, isCurrent)
    local a = ACTIONS[step.action] or { icon = 134400, text = step.action }
    canvas:Row({
        icon = a.icon, height = isCurrent and 36 or 28,
        left = U.Colorize(string.format("%d–%d", step.from, step.to), unpack(S.inkSoft)) .. "   " .. L[a.text],
        leftFont = isCurrent and "heading" or "body",
        bg = isCurrent and { 0.85, 0.65, 0.25, 0.18 } or nil,
    })
    if step.note then
        for _, line in ipairs(mod:NoteLines(step.note)) do
            canvas:Text(U.Colorize(L["Tip"] .. ": ", unpack(S.accent)) .. line, "small", 46)
        end
    end
    canvas:Space(isCurrent and 8 or 4)
end

local function stepCard(canvas, i, step, skill, isCurrent)
    if step.action then return actionCard(canvas, step, isCurrent) end
    local r = ns.recipes[step.spell]
    if not r then return end
    local crafts = mod:StepCrafts(step, skill)
    local known = mod:IsKnown(step.spell)
    local range = step.fixed and string.format("%d", step.to) or string.format("%d–%d", step.from, step.to)
    local right
    if step.fixed then
        right = string.format(L["Make %d"], step.fixed)
    elseif crafts > 0 then
        right = string.format(L["about %d crafts"], crafts)
    end
    canvas:Row({
        icon = mod:RecipeIcon(step.spell), height = isCurrent and 36 or 28,
        left = U.Colorize(range, unpack(S.inkSoft)) .. "   " .. U.Colorize(mod:RecipeName(step.spell), unpack(diffColor(step.spell, skill))),
        leftFont = isCurrent and "heading" or "body",
        right = right, rightWidth = 130,
        bg = isCurrent and { 0.85, 0.65, 0.25, 0.18 } or nil,
        desaturate = not known,
        onClick = function(_, button)
            if IsModifiedClick("CHATLINK") and r.item then
                ChatEdit_InsertLink(U.ItemLink(r.item))
            end
        end,
        onEnter = function(self)
            UI.RecipeTooltip(self, r.item, step.spell, r.item and { L["Shift-click to link the item."] } or nil)
        end,
    })
    for _, line in ipairs(materialsLines(step.spell, step.fixed or crafts)) do
        canvas:Text(line.text, "small", line.spell and 58 or 46)
        if line.spell and not line.known then sourceLines(canvas, line.spell) end
    end
    if step.note then
        for _, line in ipairs(mod:NoteLines(step.note)) do
            canvas:Text(U.Colorize(L["Tip"] .. ": ", unpack(S.accent)) .. line, "small", 46)
        end
    end
    local keep = mod:KeepFor(i, skill)
    for _, k in ipairs(keep) do
        local range = k.step.fixed and string.format("%d", k.step.to) or string.format("%d–%d", k.step.from, k.step.to)
        canvas:Text(U.Colorize(L["Keep"] .. ": ", unpack(S.accent)) .. string.format(L["%d× %s for %s (%s)"],
            k.count, U.ItemBracket(k.item), mod:RecipeName(k.step.spell), range), "small", 46)
    end
    -- Experimental: what the leftovers are worth (only for results no later step uses).
    if not keep[1] and r.item then
        local value = FC.Value:Lines(r.item)
        if value then
            canvas:Text(value[1], "small", 46)
            canvas:Text(U.Colorize(value[2], unpack(S.inkSoft)), "tiny", 58)
        end
    end
    if not known then
        canvas:Text(U.Colorize(L["You don't know this recipe yet."], unpack(U.DIFF_COLORS.red)), "small", 46)
        sourceLines(canvas, step.spell)
    end
    canvas:Space(isCurrent and 8 or 4)
end

local function suggestions(canvas, skill)
    canvas:Text(L["Suggested"], "heading")
    canvas:Text(L["No verified route for this range yet. These are the best recipes you can use right now."], "small")
    canvas:Space(4)
    for _, s in ipairs(mod:Suggestions(skill, 6)) do
        canvas:Row({
            icon = mod:RecipeIcon(s.spell), height = 36, desaturate = not s.known,
            left = U.Colorize(mod:RecipeName(s.spell), unpack(diffColor(s.spell, skill))),
            sub = s.cost and string.format(L["Cost per craft: %s"], U.Money(s.cost)) or nil,
            skill = { lv = ns.recipes[s.spell].lv, skill = skill, known = s.known }, rightWidth = 185,
            onEnter = function(self)
                local r = ns.recipes[s.spell]
                UI.RecipeTooltip(self, r.item, s.spell)
            end,
        })
        for _, line in ipairs(materialsLines(s.spell, 1)) do
            canvas:Text(line.text, "small", line.spell and 58 or 46)
        end
        if not s.known then sourceLines(canvas, s.spell) end
        canvas:Space(4)
    end
end

local function render(canvas)
    local skill, max, has = mod:Skill()
    if not has then
        canvas:Space(20)
        canvas:Text(string.format(L["%s is not learned on this character."], mod.shortTitle), "heading", 0, { justify = "CENTER" })
        return
    end
    canvas:Text(string.format(L["Skill %d / %d"], skill, max), "heading")
    rankBlock(canvas, skill, max)
    if not FC:HasSynced(mod.mainSkillLine) then
        canvas:Text(U.Colorize(L["Open your profession window once so Forever Crafting can read which recipes you know."], unpack(S.accent)), "small")
    end
    canvas:Divider()

    local current = mod:CurrentStepIndex(skill)
    local guide = mod:Guide()
    for i, step in ipairs(guide) do
        local done = (current == nil) or i < current
        if step.fixed and mod:FixedStepDone(step) then done = true end
        if done then
            if showDone then
                local label = step.action and L[(ACTIONS[step.action] or {}).text or step.action] or mod:RecipeName(step.spell)
                canvas:Row({
                    icon = step.action and (ACTIONS[step.action] or {}).icon or mod:RecipeIcon(step.spell), height = 20, desaturate = true,
                    left = U.Colorize((step.fixed and step.to or (step.from .. "–" .. step.to)) .. "   " .. label .. "   |TInterface\\RaidFrame\\ReadyCheck-Ready:11|t", unpack(U.DIFF_COLORS.gray)),
                    leftFont = "small",
                })
            end
        else
            stepCard(canvas, i, step, skill, i == current)
            if i == current then canvas:Divider() end
        end
    end
    local last = guide[#guide]
    if skill >= (last and last.to or 0) or current == nil then
        canvas:Divider()
        suggestions(canvas, skill)
    end
end

local function setup(tb)
    local check = UI.Check(tb, L["Show finished steps"], function() return showDone end,
        function(v) showDone = v FC.Window:Refresh(true) end)
    check:SetPoint("LEFT", 0, 0)

    local label = tb:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(S.fonts.small)
    label:SetText(L["Route"])
    local choices = {}
    for _, key in ipairs(ns.routeOrder) do table.insert(choices, { value = key, text = L[ns.routes[key].name] }) end
    local route = UI.ButtonGroup(tb, choices, function() return mod:RouteKey() end,
        function(v) mod:SetRoute(v) FC.Window:Refresh() end)
    route:SetPoint("RIGHT", tb, "RIGHT", 0, 0)
    label:SetPoint("RIGHT", route, "LEFT", -8, 0)
end

table.insert(mod.pages, { key = "guide", title = L["Guide"], render = render, setup = setup })
end)
