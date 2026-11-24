-- Skinning module: where to skin for your skill, rank and trainers, and the leathers
-- you'll get. A gathering profession, so it has its own pages instead of the
-- recipe-based Guide / Recipes / Shopping pages.
local _, ns = ...
local FC = ForeverCrafting
local L = FC.L
local U = FC.Util
local S = FC.Style
local UI = FC.UI

local SKILL = 393
local RANKS = {
    { key = "Apprentice", cap = 75, skill = 0, level = 0 },
    { key = "Journeyman", cap = 150, skill = 50, level = 10 },
    { key = "Expert", cap = 225, skill = 125, level = 20 },
    { key = "Artisan", cap = 300, skill = 200, level = 35 },
}

local mod = {
    title = L["Forever Skinning"],
    shortTitle = L["Skinning"],
    icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    mainSkillLine = SKILL,
    skillLines = { SKILL },
    order = 15,
    pages = {},
    data = ns,
}

function mod:Skill()
    local s = FC:GetSkill(SKILL)
    if not s then return 0, 0, false end
    return s.rank or 0, s.max or 0, true
end

function mod:Subtitle()
    local skill, max, has = self:Skill()
    if not has then return L["Skinning"] end
    return string.format("%s %d / %d", L["Skinning"], skill, max)
end

-- Skinning needed for a beast of a level: 1 up to level 10, then 10 per level to 19
-- (level 11 = 10, 15 = 50), then 5 × level.
function mod.Required(level)
    if level <= 10 then return 1 end
    if level < 20 then return (level - 10) * 10 end
    return level * 5
end

-- Highest beast level this skill can skin.
function mod.MaxLevel(skill)
    local lvl = 0
    for l = 1, 63 do
        if mod.Required(l) <= skill then lvl = l else break end
    end
    return lvl
end

function mod:NextRank()
    local _, max = self:Skill()
    for _, r in ipairs(RANKS) do
        if r.cap > max then return r end
    end
end

local function rankIndex(key)
    for i, r in ipairs(RANKS) do if r.key == key then return i end end
    return 1
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
            lines = { L["Skinning"] .. " " .. L["Trainer"], FC.Map.Describe(t) } })
    end
    return pts
end

function mod:StepPoints(step)
    local pts = {}
    local names = {}
    for _, m in ipairs(step.mobs) do table.insert(names, m[1]) end
    for _, p in ipairs(step.pins) do
        table.insert(pts, { mapID = step.mapID, x = p[1] / 100, y = p[2] / 100,
            title = step.place and L[step.place] or U.ZoneName(step.mapID),
            lines = { table.concat(names, ", ") } })
    end
    return pts
end

-- Steps for the current faction setting, main route first, alternatives marked.
function mod:Steps()
    local out = {}
    for _, s in ipairs(ns.steps) do
        if FC:ShowsFaction(s.faction) then table.insert(out, s) end
    end
    return out
end

-- The main-route step for this skill (alternatives that cover it are listed beside it).
function mod:CurrentStep(skill)
    for _, s in ipairs(self:Steps()) do
        if not s.alt and skill < s.to then return s end
    end
end

-- Skinned materials, for the Leftovers page.
function mod:CandidateItems()
    local set = {}
    for _, group in ipairs(ns.leathers) do
        for _, id in ipairs(group.items) do set[id] = true end
    end
    return set
end

-- Tooltip lines for skinned items: nothing extra (the core tooltip already lists zones).
function mod:TooltipLines() return nil end

------------------------------------------------------------------------------------
-- Guide page
------------------------------------------------------------------------------------

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
    local trainers = mod:TrainersFor(nextRank.key)
    local points = mod:TrainerPoints(trainers)
    local sub, lines = FC.Map.TrainerSummary(points)
    local cost = ns.costs[nextRank.key]
    if cost then table.insert(lines, 1, string.format(L["Costs %s"], U.Money(cost))) end
    canvas:Row({
        icon = "Interface\\Icons\\INV_Misc_Book_11", height = 34, left = text,
        sub = sub,
        right = U.Colorize(L["Show on map"], unpack(S.link)), rightWidth = 110,
        bg = ready and { 0.4, 0.6, 0.2, 0.12 } or nil,
        onClick = function() FC.Map:Show(points) end,
        onEnter = function(self) UI.TextTooltip(self, L["Trainers"], lines) end,
    })
end

local function mobText(step, skill)
    local parts = {}
    for _, m in ipairs(step.mobs) do
        local lv = m[3] == m[4] and tostring(m[3]) or (m[3] .. "–" .. m[4])
        local need = mod.Required(m[3])
        local txt = string.format("%s (%s, %s)", m[1],
            string.format(L["level %s"], lv), string.format(L["needs %d"], need))
        if skill < need then txt = U.Colorize(txt, unpack(U.DIFF_COLORS.red)) end
        table.insert(parts, txt)
    end
    return table.concat(parts, ",  ")
end

local function stepCard(canvas, step, skill, isCurrent, isAlt)
    local range = string.format("%d–%d", step.from, step.to)
    local where = U.ZoneName(step.mapID)
    if step.place then where = where .. ": " .. L[step.place] end
    local prefix = isAlt and (U.Colorize(L["Or"] .. "  ", unpack(S.inkSoft))) or ""
    local done = skill >= step.to
    canvas:Row({
        icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", height = isCurrent and 36 or 28,
        indent = isAlt and 24 or 0,
        left = prefix .. U.Colorize(range, unpack(S.inkSoft)) .. "   " .. U.Colorize(where, unpack(done and S.inkSoft or S.ink)),
        leftFont = isCurrent and "heading" or "body",
        right = U.Colorize(L["Show spawns on map"], unpack(S.link)), rightWidth = 150,
        bg = isCurrent and { 0.85, 0.65, 0.25, 0.18 } or nil,
        desaturate = done,
        onClick = function() FC.Map:Show(mod:StepPoints(step)) end,
        onEnter = function(self) UI.TextTooltip(self, where, { L["Click to show where they spawn."] }) end,
    })
    local indent = isAlt and 70 or 46
    canvas:Text(mobText(step, skill), "small", indent)
    if step.note then
        canvas:Text(U.Colorize(L["Tip"] .. ": ", unpack(S.accent)) .. L[step.note], "small", indent)
    end
    canvas:Space(isCurrent and 8 or 4)
end

local function renderGuide(canvas)
    local skill, max, has = mod:Skill()
    if not has then
        canvas:Space(20)
        canvas:Text(string.format(L["%s is not learned on this character."], L["Skinning"]), "heading", 0, { justify = "CENTER" })
        return
    end
    canvas:Text(string.format(L["Skill %d / %d"], skill, max), "heading")
    local maxLevel = mod.MaxLevel(skill)
    canvas:Text(string.format(L["You can skin beasts up to level %d."], maxLevel)
        .. "  " .. U.Colorize(string.format(L["Level %d needs Skinning %d."], maxLevel + 1, mod.Required(maxLevel + 1)), unpack(S.inkSoft)), "small")
    rankBlock(canvas, skill, max)
    canvas:Text(U.Colorize(L["Keep a Skinning Knife in your bags. It doesn't need to be equipped."], unpack(S.inkSoft)), "small")
    canvas:Divider()

    local current = mod:CurrentStep(skill)
    for _, c in ipairs(ns.camping) do c.profName = L["Skinning"] end
    -- Camping recipes you don't know yet, shown just before the first step that reaches them.
    local pending, shown = FC.Camping.Pending(ns.camping, SKILL), {}
    for _, step in ipairs(mod:Steps()) do
        local done = skill >= step.to
        if showDone or not done then
            for _, c in ipairs(pending) do
                if c.skill < step.to and not shown[c] then
                    shown[c] = true
                    FC.Camping.Milestone(canvas, c, skill, SKILL)
                end
            end
            stepCard(canvas, step, skill, step == current, step.alt)
        end
    end

    FC.Camping.List(canvas, ns.camping, skill, SKILL, L["Skinning"])
end

local function setupGuide(tb)
    local check = UI.Check(tb, L["Show finished steps"], function() return showDone end,
        function(v) showDone = v FC.Window:Refresh(true) end)
    check:SetPoint("LEFT", 0, 0)
end

table.insert(mod.pages, { key = "guide", title = L["Guide"], render = renderGuide, setup = setupGuide })

------------------------------------------------------------------------------------
-- Leathers page: what you hold of each skinned material and where it comes from.
------------------------------------------------------------------------------------

local function zonesOf(id)
    local g = FC.gathering and FC.gathering[id]
    if not g then return nil end
    local names = {}
    for _, z in ipairs(g.zones or {}) do table.insert(names, U.ZoneName(z)) end
    for _, p in ipairs(g.places or {}) do table.insert(names, L[p]) end
    local txt = table.concat(names, ", ")
    if g.creatures then txt = txt .. "  ·  " .. L[g.creatures] end
    return txt
end

local function renderLeathers(canvas)
    for _, group in ipairs(ns.leathers) do
        canvas:Text(L[group.title], "heading")
        for _, id in ipairs(group.items) do
            local have = U.Count(id)
            local alts = U.AltCount(id)
            local right = have > 0 and tostring(have) or U.Colorize("0", unpack(S.inkSoft))
            if alts > 0 then right = right .. U.Colorize(string.format("  +%d", alts), unpack(S.inkSoft)) end
            canvas:Row({
                icon = U.ItemIcon(id), height = 34,
                left = U.ItemName(id),
                sub = zonesOf(id),
                right = right, rightWidth = 90,
                onClick = function(_, button)
                    if IsModifiedClick("CHATLINK") then ChatEdit_InsertLink(U.ItemLink(id)) end
                end,
                onEnter = function(self) UI.ItemTooltip(self, id) end,
            })
        end
        canvas:Space(6)
    end
end

table.insert(mod.pages, { key = "leathers", title = L["Leathers"], render = renderLeathers })

FC:RegisterModule("skinning", mod)

SLASH_FOREVERCRAFTING_SKINNING1 = "/skin"
SlashCmdList.FOREVERCRAFTING_SKINNING = function() FC.Window:Toggle("skinning") end
