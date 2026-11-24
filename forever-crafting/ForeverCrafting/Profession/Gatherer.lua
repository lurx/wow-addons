-- Shared base for gathering professions that pick from nodes (Herbalism, Mining):
-- a Guide page (rank, trainers, where to gather for your skill) and a nodes page
-- (every herb or vein, the skill it needs, where it grows, what you hold).
--
-- A module calls FC:NewGatherer(def, ns) with
--   def = { key, title, shortTitle, icon, skillLine, order, slash, nodesTitle, nodeIcon }
--   ns.trainers = { { name, rank, faction, mapID, x, y }, ... }  (rank = highest taught)
--   ns.nodes    = { { name, skill = { min, yellow, green, gray }, items = { itemID, ... }, zones = { mapID, ... } } }
--   ns.steps    = { { from, to, faction, zones = { mapID, ... }, nodes = { name, ... }, note } }
--   ns.camping  = { { skill, name } } (optional), ns.tips = { stringKey, ... } (optional)
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI

local RANKS = {
    { key = "Apprentice", cap = 75, skill = 0, level = 0 },
    { key = "Journeyman", cap = 150, skill = 50, level = 10 },
    { key = "Expert", cap = 225, skill = 125, level = 20 },
    { key = "Artisan", cap = 300, skill = 200, level = 35 },
}
local function rankIndex(key)
    for i, r in ipairs(RANKS) do if r.key == key then return i end end
    return 1
end

function FC:NewGatherer(def, ns)
    local mod = {
        title = def.title, shortTitle = def.shortTitle, icon = def.icon,
        mainSkillLine = def.skillLine, skillLines = { def.skillLine },
        order = def.order or 50, pages = {}, data = ns,
    }

    function mod:Skill()
        local s = FC:GetSkill(def.skillLine)
        if not s then return 0, 0, false end
        return s.rank or 0, s.max or 0, true
    end

    function mod:Subtitle()
        local skill, max, has = self:Skill()
        if not has then return def.shortTitle end
        return string.format("%s %d / %d", def.shortTitle, skill, max)
    end

    function mod:NextRank()
        local _, max = self:Skill()
        for _, r in ipairs(RANKS) do
            if r.cap > max then return r end
        end
    end

    function mod:TrainersFor(rankKey)
        local want, out = rankIndex(rankKey), {}
        for _, t in ipairs(ns.trainers) do
            if rankIndex(t.rank) >= want and FC:ShowsFaction(t.faction) then table.insert(out, t) end
        end
        return out
    end

    function mod:TrainerPoints(list)
        local pts = {}
        for _, t in ipairs(list) do
            table.insert(pts, { mapID = t.mapID, x = t.x, y = t.y, title = t.name,
                lines = { def.shortTitle .. " " .. L["Trainer"] } })
        end
        return pts
    end

    local byName = {}
    for _, n in ipairs(ns.nodes) do byName[n.name] = n end
    mod.nodesByName = byName

    -- Difficulty of a node for your skill, using its four thresholds.
    function mod.NodeColor(node, skill)
        local s = node.skill
        if skill < s[1] then return U.DIFF_COLORS.red end
        if skill < s[2] then return U.DIFF_COLORS.orange end
        if skill < s[3] then return U.DIFF_COLORS.yellow end
        if skill < s[4] then return U.DIFF_COLORS.green end
        return U.DIFF_COLORS.gray
    end

    function mod:Steps()
        local out = {}
        for _, s in ipairs(ns.steps) do
            if FC:ShowsFaction(s.faction or "N") then table.insert(out, s) end
        end
        return out
    end

    function mod:CurrentStep(skill)
        for _, s in ipairs(self:Steps()) do
            if skill < s.to then return s end
        end
    end

    function mod:CandidateItems()
        local set = {}
        for _, n in ipairs(ns.nodes) do
            for _, id in ipairs(n.items) do set[id] = true end
        end
        return set
    end

    function mod:TooltipLines() return nil end

    -- Guide ---------------------------------------------------------------------------

    local showDone = false

    local function rankBlock(canvas, skill, max)
        local nextRank = mod:NextRank()
        if not nextRank then return end
        local level = UnitLevel("player") or 1
        local ready = skill >= nextRank.skill and level >= nextRank.level
        local text
        if ready and skill >= max then
            text = U.Colorize(string.format(L["You are at your rank cap. Train %s to keep gaining skill."], L[nextRank.key]), unpack(S.accent))
        elseif ready then
            text = U.Colorize(string.format(L["Ready to train %s now"], L[nextRank.key]), unpack(U.DIFF_COLORS.green))
        else
            text = string.format(L["Next rank: %s at skill %d (character level %d)"], L[nextRank.key], nextRank.skill, nextRank.level)
        end
        local points = mod:TrainerPoints(mod:TrainersFor(nextRank.key))
        local sub, lines = FC.Map.TrainerSummary(points)
        canvas:Row({
            icon = "Interface\\Icons\\INV_Misc_Book_11", height = 34, left = text, sub = sub,
            right = U.Colorize(L["Show on map"], unpack(S.link)), rightWidth = 110,
            bg = ready and { 0.4, 0.6, 0.2, 0.12 } or nil,
            onClick = function() FC.Map:Show(points) end,
            onEnter = function(self) UI.TextTooltip(self, L["Trainers"], lines) end,
        })
    end

    local function nodeText(step, skill)
        local parts = {}
        for _, name in ipairs(step.nodes) do
            local n = byName[name]
            if n then
                local c = mod.NodeColor(n, skill)
                local txt = string.format("%s (%d)", L[n.name], n.skill[1])
                table.insert(parts, U.Colorize(txt, unpack(c)))
            end
        end
        return table.concat(parts, ",  ")
    end

    local function zoneText(step)
        local names = {}
        for _, z in ipairs(step.zones) do table.insert(names, U.ZoneName(z)) end
        return table.concat(names, ", ")
    end

    local function stepCard(canvas, step, skill, isCurrent)
        local done = skill >= step.to
        canvas:Row({
            icon = def.nodeIcon or def.icon, height = isCurrent and 36 or 28,
            left = U.Colorize(string.format("%d–%d", step.from, step.to), unpack(S.inkSoft)) .. "   "
                .. U.Colorize(zoneText(step), unpack(done and S.inkSoft or S.ink)),
            leftFont = isCurrent and "heading" or "body",
            right = U.Colorize(L["Show zone"], unpack(S.link)), rightWidth = 110,
            bg = isCurrent and { 0.85, 0.65, 0.25, 0.18 } or nil,
            desaturate = done,
            onClick = function() FC.Map:ShowZone(step.zones[1]) end,
            onEnter = function(self) UI.TextTooltip(self, zoneText(step), { L["Click to open the zone map."] }) end,
        })
        canvas:Text(nodeText(step, skill), "small", 46)
        if step.note then
            local note = type(step.note) == "table" and (step.note[FC:GetFaction()] or step.note.N) or step.note
            if note then canvas:Text(U.Colorize(L["Tip"] .. ": ", unpack(S.accent)) .. L[note], "small", 46) end
        end
        canvas:Space(isCurrent and 8 or 4)
    end

    local function renderGuide(canvas)
        local skill, max, has = mod:Skill()
        if not has then
            canvas:Space(20)
            canvas:Text(string.format(L["%s is not learned on this character."], def.shortTitle), "heading", 0, { justify = "CENTER" })
            return
        end
        canvas:Text(string.format(L["Skill %d / %d"], skill, max), "heading")
        -- What you can gather now and what opens up next.
        local can, nextNode = {}, nil
        for _, n in ipairs(ns.nodes) do
            if skill >= n.skill[1] then
                if skill < n.skill[4] then table.insert(can, U.Colorize(L[n.name], unpack(mod.NodeColor(n, skill)))) end
            elseif not nextNode or n.skill[1] < nextNode.skill[1] then
                nextNode = n
            end
        end
        if can[1] then canvas:Text(L["Gives skill now"] .. ": " .. table.concat(can, ", "), "small") end
        if nextNode then
            canvas:Text(U.Colorize(string.format(L["Next: %s at %d"], L[nextNode.name], nextNode.skill[1]), unpack(S.inkSoft)), "small")
        end
        rankBlock(canvas, skill, max)
        for _, tip in ipairs(ns.tips or {}) do
            canvas:Text(U.Colorize(L[tip], unpack(S.inkSoft)), "small")
        end
        canvas:Divider()
        local current = mod:CurrentStep(skill)
        for _, c in ipairs(ns.camping or {}) do c.profName = def.shortTitle end
        -- Camping recipes you don't know yet, each shown once just before the first
        -- step that reaches its skill (so ones you can learn now sit at the top).
        local pending = ns.camping and FC.Camping.Pending(ns.camping, def.skillLine) or {}
        local shown = {}
        for _, step in ipairs(mod:Steps()) do
            if showDone or skill < step.to then
                for _, c in ipairs(pending) do
                    if c.skill < step.to and not shown[c] then
                        shown[c] = true
                        FC.Camping.Milestone(canvas, c, skill, def.skillLine)
                    end
                end
                stepCard(canvas, step, skill, step == current)
            end
        end
        if ns.camping then FC.Camping.List(canvas, ns.camping, skill, def.skillLine, def.shortTitle) end
    end

    local function setupGuide(tb)
        local check = UI.Check(tb, L["Show finished steps"], function() return showDone end,
            function(v) showDone = v FC.Window:Refresh(true) end)
        check:SetPoint("LEFT", 0, 0)
    end

    table.insert(mod.pages, { key = "guide", title = L["Guide"], render = renderGuide, setup = setupGuide })

    -- Nodes page ----------------------------------------------------------------------

    local function renderNodes(canvas)
        local skill = mod:Skill()
        for _, n in ipairs(ns.nodes) do
            local zones = {}
            for _, z in ipairs(n.zones) do table.insert(zones, U.ZoneName(z)) end
            local held, parts = 0, {}
            for _, id in ipairs(n.items) do
                local c = U.Count(id)
                held = held + c
                table.insert(parts, U.ItemName(id) .. (c > 0 and (" " .. c) or ""))
            end
            local s = n.skill
            canvas:Row({
                icon = U.ItemIcon(n.items[1]), height = 34,
                left = U.Colorize(L[n.name], unpack(mod.NodeColor(n, skill))) .. "   "
                    .. U.Colorize(string.format("%d / %d / %d / %d", s[1], s[2], s[3], s[4]), unpack(S.inkSoft)),
                sub = table.concat(zones, ", "),
                right = held > 0 and tostring(held) or U.Colorize("0", unpack(S.inkSoft)), rightWidth = 60,
                onEnter = function(self)
                    UI.TextTooltip(self, L[n.name], {
                        string.format(L["Gather from %d, skill-ups until %d"], s[1], s[4]),
                        table.concat(parts, ", "),
                        L["Click to open the zone map."],
                    })
                end,
                onClick = function() if n.zones[1] then FC.Map:ShowZone(n.zones[1]) end end,
            })
        end
        canvas:Space(6)
        canvas:Text(U.Colorize(L["Numbers are the skill to gather, then where it turns yellow, green and gray."], unpack(S.inkSoft)), "tiny")
    end

    table.insert(mod.pages, { key = "nodes", title = def.nodesTitle, render = renderNodes })

    FC:RegisterModule(def.key, mod)
    if def.slash then
        local name = "FOREVERCRAFTING_" .. def.key:upper()
        _G["SLASH_" .. name .. "1"] = def.slash
        SlashCmdList[name] = function() FC.Window:Toggle(def.key) end
    end
    return mod
end

-- Camping recipes for gathering professions (no Recipes tab there, so the guide shows them).
-- entry = { skill, name, spell, trainer = true, cost } or { skill, name, spell, blueprint, drops = { { boss, place, chance } } }
FC.Camping = {}
local C = FC.Camping

function C.Source(c)
    if c.trainer then
        return string.format(L["Any %s trainer, %s"], c.profName or "", U.Money(c.cost or 0))
    elseif c.drops then
        local parts = {}
        for _, d in ipairs(c.drops) do table.insert(parts, string.format(L["%s in %s (%.1f%%)"], d[1], d[2], d[3])) end
        return string.format(L["%s drops from %s"], U.ItemBracket(c.blueprint), table.concat(parts, L[" or "]))
    end
end

-- A card in the route for a camping recipe you don't know yet.
function C.Milestone(canvas, c, skill, skillLine)
    local ready = skill >= c.skill
    local state = ready and U.Colorize(L["Not learned yet"], unpack(S.accent))
        or U.Colorize(string.format(L["At %d"], c.skill), unpack(S.inkSoft))
    canvas:Row({
        icon = c.blueprint and U.ItemIcon(c.blueprint) or "Interface\\Icons\\INV_Misc_Wood_01", height = 30,
        left = U.Colorize(L["Camping"] .. ":  ", unpack(S.accent)) .. L[c.name] .. U.Colorize(string.format("  (%d)", c.skill), unpack(S.inkSoft)),
        sub = C.Source(c),
        right = state, rightWidth = 130,
        bg = ready and { 0.85, 0.65, 0.25, 0.10 } or nil,
        onEnter = c.blueprint and function(self) UI.ItemTooltip(self, c.blueprint) end or nil,
    })
    canvas:Space(4)
end

-- The list at the bottom of the guide: known, not learned yet, or not checked yet.
function C.List(canvas, entries, skill, skillLine, profName)
    canvas:Divider()
    canvas:Text(L["Camping"], "heading")
    local synced = FC:HasSynced(skillLine)
    for _, c in ipairs(entries) do
        local known = FC:IsKnown(skillLine, c.spell)
        local title = string.format(L["%s at %d"], L[c.name], c.skill)
        if known then
            title = U.Colorize(title .. "  " .. L["(known)"], unpack(U.DIFF_COLORS.green))
        elseif skill >= c.skill then
            title = title .. "  " .. U.Colorize(synced and L["(not learned yet)"]
                or string.format(L["(unknown: open your %s window once)"], profName), unpack(S.accent))
        end
        canvas:Text(title, "small", 12)
        if not known then canvas:Text(U.Colorize(C.Source(c) or "", unpack(S.inkSoft)), "tiny", 24) end
    end
end

-- Camping entries to show as cards in the route, keyed to the first step that reaches them.
function C.Pending(entries, skillLine)
    local out = {}
    if not FC:HasSynced(skillLine) then return out end
    for _, c in ipairs(entries) do
        if not FC:IsKnown(skillLine, c.spell) then table.insert(out, c) end
    end
    return out
end
