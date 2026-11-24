-- Shared profession module: data access, recipe sources, prep breakdown and guide maths.
-- A profession addon supplies its data table (ns) and calls FC:NewProfession(def, ns).
--   def = { key, title, shortTitle, icon, skillLine, skillLines, order, notPrep = { [itemID] = true },
--           slash = "/lw", filters = { armor = {...}, specs = {...} } }
local _, FC = ...
local L = FC.L
local U = FC.Util
FC.PageFactories = FC.PageFactories or {}

function FC:NewProfession(def, ns)
local SKILL_MAIN = def.skillLine
local NOT_PREP = def.notPrep or {}
local mod = {
    title = def.title,
    shortTitle = def.shortTitle,
    icon = def.icon,
    mainSkillLine = SKILL_MAIN,
    skillLines = def.skillLines or { SKILL_MAIN },
    order = def.order or 50,
    filters = def.filters or {},
    pages = {},
    expanded = {},
    state = {},
    ns = ns,
    data = ns,
}
ns.mod = mod

-- Ranks ----------------------------------------------------------------------------
ns.ranks = {
    { key = "Apprentice", cap = 75, skill = 0, level = 0 },
    { key = "Journeyman", cap = 150, skill = 50, level = 10 },
    { key = "Expert", cap = 225, skill = 125, level = 20 },
    { key = "Artisan", cap = 300, skill = 200, level = 35 },
}

function mod:Skill()
    local s = FC:GetSkill(SKILL_MAIN)
    if not s then return 0, 0, false end
    return s.rank or 0, s.max or 0, true
end

function mod:Subtitle()
    local parts = {}
    for _, line in ipairs(self.skillLines) do
        local sk = FC:GetSkill(line)
        if sk then table.insert(parts, string.format("%s %d / %d", sk.name or "", sk.rank, sk.max)) end
    end
    return table.concat(parts, "   ·   ")
end

-- The rank the player needs next, or nil at Artisan.
function mod:NextRank()
    local _, max = self:Skill()
    for _, r in ipairs(ns.ranks) do
        if r.cap > max then return r end
    end
end

function mod:TrainersFor(rankKey)
    local wanted = {}
    local rankIndex = 1
    for i, r in ipairs(ns.ranks) do if r.key == rankKey then rankIndex = i end end
    for _, t in ipairs(ns.trainers) do
        local tIndex = 1
        for i, r in ipairs(ns.ranks) do if r.key == t.rank then tIndex = i end end
        -- exact = only that rank (a cookbook vendor, a quest giver), never lower ones.
        local fits = t.exact and tIndex == rankIndex or (not t.exact and tIndex >= rankIndex)
        if fits and FC:ShowsFaction(t.faction) then
            table.insert(wanted, t)
        end
    end
    return wanted
end

function mod:TrainerPoints(list)
    local pts = {}
    for _, t in ipairs(list) do
        table.insert(pts, { mapID = t.mapID, x = t.x, y = t.y, title = t.name,
            lines = { L[t.rank] .. " " .. L["Trainer"], FC.Map.Describe(t) } })
    end
    return pts
end

-- Guide notes can be one key, or { A = key, H = key } for faction-specific advice.
-- Returns a list of display strings for the current faction setting.
function mod:NoteLines(note)
    if type(note) ~= "table" then return { L[note] } end
    local lines = {}
    if FC:GetFaction() == "Both" then
        if note.A then table.insert(lines, L["Alliance"] .. ": " .. L[note.A]) end
        if note.H then table.insert(lines, L["Horde"] .. ": " .. L[note.H]) end
    else
        local key = note[FC:GetFaction():sub(1, 1)]
        if key then table.insert(lines, L[key]) end
    end
    return lines
end

-- Recipes ----------------------------------------------------------------------------

function mod:HasRecipe(spellID)
    return ns.recipes[spellID] ~= nil
end

function mod:IsKnown(spellID)
    return FC:IsKnown(SKILL_MAIN, spellID)
end

function mod:RecipeName(spellID)
    local r = ns.recipes[spellID]
    if r and r.item then
        local n = C_Item.GetItemNameByID(r.item)
        if n then return n end
        C_Item.RequestLoadItemDataByID(r.item)
    end
    return U.SpellName(spellID, r and r.name or ("spell:" .. spellID))
end

function mod:RecipeIcon(spellID)
    local r = ns.recipes[spellID]
    if r and r.item then return U.ItemIcon(r.item) end
    local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    return tex or (r and r.icon) or self.icon
end

-- Thresholds in the table shape FC.Util expects.
function mod:Levels(spellID)
    local r = ns.recipes[spellID]
    return r and r.lv
end

-- Price of one craft's reagents (nil if any reagent has no price and isn't craftable).
function mod:CraftCost(spellID, depth)
    depth = depth or 0
    local r = ns.recipes[spellID]
    if not r or depth > 6 then return end
    local total = 0
    for _, re in ipairs(r.reagents) do
        local p = FC.Prices:Get(re[1])
        if not p then
            local sub = ns.byItem[re[1]]
            p = sub and self:CraftCost(sub, depth + 1)
            if p then p = p / math.max(ns.recipes[sub].count or 1, 1) end
        end
        if not p then return nil end
        total = total + p * re[2]
    end
    return total
end

-- Preparation ----------------------------------------------------------------------
-- Some reagents are themselves crafts of this profession (Cured Medium Hide, Bolt of
-- Silk Cloth, a runed rod). Those get broken down into what they're made from, except
-- items the profession lists in notPrep (basic leathers you'd rather skin or buy).

function mod:PrepRecipe(itemID)
    if NOT_PREP[itemID] then return end
    local sid = ns.byItem[itemID]
    local r = sid and ns.recipes[sid]
    if not r or not (r.trainer or r.starter or (r.patterns and #r.patterns > 0)) then return end
    return sid
end

-- Works out how to cover a list of needs ({ { itemID, qty }, ... }) from what you hold:
-- prep items you're short of are crafted, their reagents added in turn.
-- Returns:
--   items  = ordered { id, need, have, short, craft = crafts or nil, spell = prep recipe or nil, top = bool }
--   crafts = ordered { item, spell, crafts, make, known }
function mod:Resolve(needs)
    local avail, items, byId, crafts, craftById = {}, {}, {}, {}, {}
    local function holding(id)
        if avail[id] == nil then avail[id] = U.Count(id) end
        return avail[id]
    end
    local function entry(id, top)
        local e = byId[id]
        if not e then
            e = { id = id, need = 0, have = 0, short = 0, top = top }
            byId[id] = e
            table.insert(items, e)
        end
        if top then e.top = true end
        return e
    end
    local function want(id, qty, depth, top)
        local e = entry(id, top)
        local h = holding(id)
        local use = math.min(h, qty)
        avail[id] = h - use
        e.need = e.need + qty
        e.have = e.have + use
        local missing = qty - use
        if missing <= 0 then return end
        local sid = depth < 5 and self:PrepRecipe(id)
        if sid then
            local r = ns.recipes[sid]
            local n = math.ceil(missing / math.max(r.count or 1, 1))
            e.spell = sid
            e.craft = (e.craft or 0) + n
            local c = craftById[id]
            if not c then
                c = { item = id, spell = sid, crafts = 0, make = 0, known = self:IsKnown(sid) }
                craftById[id] = c
                table.insert(crafts, c)
            end
            c.crafts = c.crafts + n
            c.make = c.make + missing
            for _, re in ipairs(r.reagents) do want(re[1], re[2] * n, depth + 1, false) end
        else
            e.short = e.short + missing
        end
    end
    for _, nd in ipairs(needs) do want(nd[1], nd[2], 0, true) end
    return items, crafts
end

-- Where a recipe comes from, as a list of entries:
-- { kind = "trainer"|"vendor"|"drop"|"quest"|"starter", text = "...", points = {...}, rare = bool }
function mod:Sources(spellID)
    local r = ns.recipes[spellID]
    local out = {}
    if not r then return out end
    if r.starter then
        table.insert(out, { kind = "starter", text = L["Starting recipe"] })
    end
    if r.trainer then
        local rank = "Apprentice"
        for _, rk in ipairs(ns.ranks) do if r.lv.o and r.lv.o >= rk.skill then rank = rk.key end end
        local list = self:TrainersFor(rank)
        table.insert(out, {
            kind = "trainer",
            text = string.format(L["Any %s trainer"], self.shortTitle) .. (r.trainerCost and r.trainerCost > 0 and ("  " .. U.Money(r.trainerCost)) or ""),
            points = self:TrainerPoints(list),
        })
    end
    for _, pid in ipairs(r.patterns or {}) do
        local p = ns.patterns[pid]
        if p then
            for _, v in ipairs(p.vendors or {}) do
                local npc = ns.npcs[v[1]]
                if npc and FC:ShowsFaction(npc.f) then
                    local line = npc.name .. " – " .. (npc.mapID and U.ZoneName(npc.mapID) or (npc.zone or ""))
                    if v[2] and v[2] > 0 then line = line .. "  " .. U.Money(v[2]) end
                    if v[3] then line = line .. "  (" .. L["Limited stock"] .. ")" end
                    table.insert(out, { kind = "vendor", text = line, npc = v[1],
                        points = npc.mapID and { { mapID = npc.mapID, x = npc.x, y = npc.y, title = npc.name, lines = { L["Vendor"], U.ItemName(pid, p.name) } } } })
                end
            end
            for i, d in ipairs(p.drops or {}) do
                if i > 4 then break end
                local npc = ns.npcs[d[1]]
                local name = npc and npc.name or d[3] or ("NPC " .. d[1])
                local line = name .. (npc and npc.mapID and (" – " .. U.ZoneName(npc.mapID)) or (d[4] and (" – " .. d[4]) or ""))
                if d[2] then line = line .. "  " .. string.format(L["%s chance"], d[2]) end
                table.insert(out, { kind = "drop", text = line, rare = true,
                    points = npc and npc.mapID and { { mapID = npc.mapID, x = npc.x, y = npc.y, title = name, lines = { L["Drop"] } } } })
            end
            for _, q in ipairs(p.quests or {}) do
                table.insert(out, { kind = "quest", text = q[2] or ("Quest " .. q[1]) })
            end
            if not (p.vendors and #p.vendors > 0) and not (p.drops and #p.drops > 0) and not (p.quests and #p.quests > 0) then
                table.insert(out, { kind = "pattern", text = U.ItemName(pid, p.name) })
            end
        end
    end
    return out
end

function mod:IsRare(spellID)
    local r = ns.recipes[spellID]
    if not r or r.trainer or r.starter then return false end
    for _, pid in ipairs(r.patterns or {}) do
        local p = ns.patterns[pid]
        if p and p.vendors and #p.vendors > 0 then return false end
    end
    return r.patterns and #r.patterns > 0
end

function mod:HasSource(spellID)
    local r = ns.recipes[spellID]
    return r and (r.starter or r.trainer or (r.patterns and #r.patterns > 0)) and true or false
end

-- Guide maths ----------------------------------------------------------------------------

function mod:RouteKey()
    local routes = FC.db.routes or {}
    local key = routes[self.key]
    if not ns.routes[key] then key = ns.routeOrder[1] end
    return key
end

function mod:SetRoute(key)
    FC.db.routes = FC.db.routes or {}
    FC.db.routes[self.key] = key
end

function mod:Guide()
    return ns.routes[self:RouteKey()].steps
end

-- Crafts needed for a guide step from the current skill (0 when finished).
function mod:StepCrafts(step, skill)
    if step.action then return 0 end
    local r = ns.recipes[step.spell]
    if not r then return 0 end
    if step.fixed then
        if skill > step.to then return 0 end
        return step.fixed
    end
    if skill >= step.to then return 0 end
    local from = math.max(skill, step.from)
    return U.ExpectedCrafts(r.lv, from, step.to) or step.estimate or 0
end

-- What a step makes that later steps use as a reagent: keep it instead of selling.
-- Returns { { item, count, step, index }, ... } in route order.
function mod:KeepFor(index, skill)
    local steps = self:Guide()
    local step = steps[index]
    local r = step and step.spell and ns.recipes[step.spell]
    if not (r and r.item) then return {} end
    local out = {}
    for j = index + 1, #steps do
        local later = steps[j]
        local lr = later.spell and ns.recipes[later.spell]
        if lr then
            for _, re in ipairs(lr.reagents) do
                if re[1] == r.item then
                    local crafts = later.fixed or self:StepCrafts(later, skill)
                    if crafts > 0 then
                        table.insert(out, { item = r.item, count = re[2] * crafts, step = later, index = j })
                    end
                end
            end
        end
    end
    return out
end

function mod:CurrentStepIndex(skill)
    for i, step in ipairs(self:Guide()) do
        if step.fixed then
            if skill <= step.to and not self:FixedStepDone(step) then return i end
        elseif skill < step.to then
            return i
        end
    end
end

-- A fixed-count step ("make 20 at 130") counts as done once the skill has moved past it
-- or the player already holds the batch.
function mod:FixedStepDone(step)
    local skill = self:Skill()
    if skill > step.to then return true end
    local r = ns.recipes[step.spell]
    return r and r.item and U.Count(r.item) >= step.fixed
end

-- Best recipes for the current skill when the guide has no step (or as alternatives).
function mod:Suggestions(skill, limit)
    local list = {}
    local level = UnitLevel("player")
    for id, r in pairs(ns.recipes) do
        local chance = U.SkillUpChance(r.lv, skill)
        local obtainable = self:IsKnown(id) or r.trainer or r.starter
        if not obtainable then
            for _, pid in ipairs(r.patterns or {}) do
                local p = ns.patterns[pid]
                if p and p.vendors and #p.vendors > 0 then obtainable = true end
            end
        end
        if chance > 0 and obtainable and r.lv.o and r.lv.o <= skill and not r.spec then
            local cost = self:CraftCost(id)
            table.insert(list, { spell = id, chance = chance, cost = cost, known = self:IsKnown(id) })
        end
    end
    table.sort(list, function(a, b)
        if (a.chance >= 0.99) ~= (b.chance >= 0.99) then return a.chance >= 0.99 end
        local ca = a.cost and a.cost / a.chance or math.huge
        local cb = b.cost and b.cost / b.chance or math.huge
        if ca ~= cb then return ca < cb end
        return a.chance > b.chance
    end)
    local out = {}
    for i = 1, math.min(limit or 5, #list) do out[i] = list[i] end
    return out
end

-- Craft bar ------------------------------------------------------------------------------

-- How many of a recipe the bags alone can make (crafting can't use the bank).
function mod:CanMake(spellID)
    local r = ns.recipes[spellID]
    if not r or #r.reagents == 0 then return 0 end
    local n = math.huge
    for _, re in ipairs(r.reagents) do
        n = math.min(n, math.floor((C_Item.GetItemCount(re[1], false) or 0) / re[2]))
    end
    return n == math.huge and 0 or n
end

-- The next thing to craft for the guide: a prep item first (deepest first), then the
-- step's recipe. Returns { spell, want, canMake, label, step, blocked = reason }.
function mod:NextCraft()
    local skill, max, has = self:Skill()
    if not has then return nil end
    local guide = self:Guide()
    local idx = self:CurrentStepIndex(skill)
    local step = idx and guide[idx]
    if not step then return nil end
    if step.action then return { action = step.action, step = step } end
    local r = ns.recipes[step.spell]
    if not r then return nil end
    local want
    if step.fixed then
        want = math.max(step.fixed - (r.item and U.Count(r.item) or 0), 0)
    else
        want = self:StepCrafts(step, skill)
    end
    if want <= 0 then want = 1 end
    -- Rank cap: crafting doesn't stop by itself at the cap, so only plan the crafts that
    -- still give skill now, and stop at the cap until the next rank is trained.
    local capped
    local nextRank = max > 0 and max < 300 and self:NextRank() or nil
    if not step.fixed and nextRank and step.to > max then
        if skill >= max then
            return { spell = step.spell, want = want, canMake = 0, label = "step", step = step, index = idx,
                blocked = "train", rank = nextRank }
        end
        local toCap = U.ExpectedCrafts(r.lv, skill, max)
        if toCap then want = math.max(1, math.min(want, math.ceil(toCap))) end
        capped = { max = max, rank = nextRank }
    end
    -- Anything to prepare first? Resolve lists preps outermost-first; craft the deepest.
    local needs = {}
    for _, re in ipairs(r.reagents) do table.insert(needs, { re[1], re[2] * want }) end
    local _, preps = self:Resolve(needs)
    for i = #preps, 1, -1 do
        local c = preps[i]
        if not c.known then
            return { spell = c.spell, want = c.crafts, canMake = 0, label = "prepare", step = step, blocked = "learn" }
        end
        local can = self:CanMake(c.spell)
        if can > 0 then
            return { spell = c.spell, want = c.crafts, canMake = can, label = "prepare", step = step }
        end
    end
    if not self:IsKnown(step.spell) then
        return { spell = step.spell, want = want, canMake = 0, label = "step", step = step, blocked = "learn" }
    end
    local stepCan = self:CanMake(step.spell)
    if stepCan == 0 and #preps > 0 then
        -- Nothing can be made yet: point at the first thing to prepare, so its missing
        -- materials are what the bar shows.
        local c = preps[#preps]
        return { spell = c.spell, want = c.crafts, canMake = 0, label = "prepare", step = step, blocked = "mats" }
    end
    return { spell = step.spell, want = want, canMake = stepCan, label = "step", step = step, index = idx,
        blocked = stepCan == 0 and "mats" or nil, capped = capped }
end

-- How many of each item you hold that the rest of the guide (from your current skill)
-- will use, including what prepared materials need. { [itemID] = count }
function mod:Earmarked()
    local skill, _, has = self:Skill()
    local out = {}
    if not has then return out end
    local steps = self:Guide()
    local idx = self:CurrentStepIndex(skill)
    if not idx then return out end
    local needs = {}
    for i = idx, #steps do
        local step = steps[i]
        local r = not step.action and ns.recipes[step.spell]
        if r then
            local crafts
            if step.fixed then
                crafts = math.max(step.fixed - (r.item and U.Count(r.item) or 0), 0)
            else
                crafts = self:StepCrafts(step, skill)
            end
            if crafts > 0 then
                for _, re in ipairs(r.reagents) do table.insert(needs, { re[1], re[2] * crafts }) end
            end
        end
    end
    local items = self:Resolve(needs)
    for _, e in ipairs(items) do
        if e.have > 0 then out[e.id] = (out[e.id] or 0) + e.have end
    end
    -- Tools recipes need (enchanting rods): keep one of each you hold.
    local toolNames = {}
    for _, r in pairs(ns.recipes) do
        if r.tool then
            for name in r.tool:gmatch("[^,]+") do toolNames[strtrim(name)] = true end
        end
    end
    for _, r in pairs(ns.recipes) do
        if r.item and toolNames[r.name] and U.Count(r.item) > 0 then
            out[r.item] = math.max(out[r.item] or 0, 1)
        end
    end
    return out
end

-- Every material and product this profession deals with (for the Leftovers page).
function mod:CandidateItems()
    local set = {}
    for _, r in pairs(ns.recipes) do
        if r.item then set[r.item] = true end
        for _, re in ipairs(r.reagents) do
            if FC.IsOwnMaterial(re[1], self.mainSkillLine) then set[re[1]] = true end
        end
    end
    return set
end

-- Reagents of a recipe you're short of in your bags for `count` crafts: { { id, short, inBank } }.
function mod:MissingInBags(spellID, count)
    local r = ns.recipes[spellID]
    local out = {}
    if not r then return out end
    for _, re in ipairs(r.reagents) do
        local bags = C_Item.GetItemCount(re[1], false) or 0
        local need = re[2] * math.max(count, 1)
        if bags < need then
            table.insert(out, { id = re[1], short = need - bags, inBank = math.max(U.Count(re[1]) - bags, 0) })
        end
    end
    return out
end

-- Items the AH scan should price: guide materials plus reagents of known recipes.
function mod:GetTrackedItems()
    local set, list = {}, {}
    local function add(id)
        if not set[id] then set[id] = true table.insert(list, id) end
    end
    for _, step in ipairs(self:Guide()) do
        local r = ns.recipes[step.spell]
        if r then for _, re in ipairs(r.reagents) do add(re[1]) end end
    end
    for id, r in pairs(ns.recipes) do
        if self:IsKnown(id) then for _, re in ipairs(r.reagents) do add(re[1]) end end
    end
    return list
end

-- Registration -------------------------------------------------------------------------

mod.key = def.key
for _, factory in ipairs(FC.PageFactories) do factory(mod, ns) end
FC.Prices:RegisterVendorItems(ns.vendorItems or {})
FC:RegisterModule(def.key, mod)

if def.slash then
    local name = "FOREVERCRAFTING_" .. def.key:upper()
    _G["SLASH_" .. name .. "1"] = def.slash
    SlashCmdList[name] = function() FC.Window:Toggle(def.key) end
end
return mod
end
