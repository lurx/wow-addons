-- Forever Crafting core: saved data, profession detection and module loading.
local ADDON, FC = ...
_G.ForeverCrafting = FC
local L = FC.L

FC.name = ADDON
FC.version = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "dev"
FC.modules = {}        -- key -> module
FC.moduleOrder = {}    -- ordered keys
FC.skills = {}         -- skillLineID -> { name, rank, max, modifier, icon }
FC.callbacks = {}      -- event name -> { fn, ... } (internal messages)

local DB_DEFAULTS = {
    minimap = { hide = false, angle = 215 },
    window = { scale = 1 },
    showProfessionButton = true,
    setWaypoint = true,
    skillDisplay = "bar",
    tooltips = true,
    craftBar = true,        -- show the craft bar
    experimentalValue = false, -- experimental: "Best value" (vendor / auction / disenchant)
    craftBarPoint = nil,        -- add Forever Crafting lines to item tooltips   -- "bar", "text" or "both"
    faction = "auto",
    forceScanButton = false,
    prices = {},        -- [itemID] = { p = copper, t = time } from our own AH scan
    vendorPrices = {},  -- [itemID] = copper, learned from merchants
}
local CHAR_DEFAULTS = {
    known = {},         -- [skillLineID] = { [recipeSpellID] = true }
    synced = {},        -- [skillLineID] = time of last profession-window read
}

local function applyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            applyDefaults(dst[k], v)
        end
    end
end

-- Messages -------------------------------------------------------------------

function FC:On(msg, fn)
    self.callbacks[msg] = self.callbacks[msg] or {}
    table.insert(self.callbacks[msg], fn)
end

function FC:Fire(msg, ...)
    local list = self.callbacks[msg]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, ...)
        if not ok then geterrorhandler()(err) end
    end
end

function FC:Print(...)
    print("|cffd8a657Forever Crafting:|r", ...)
end

-- Faction --------------------------------------------------------------------

-- The faction shown in guides: "Alliance", "Horde" or "Both". Auto follows the character.
function FC:GetFaction()
    local f = self.db and self.db.faction or "auto"
    if f == "Alliance" or f == "Horde" or f == "Both" then return f end
    return (UnitFactionGroup("player")) or "Alliance"
end

-- Whether something for faction code "A", "H" or "N" (neutral) should be shown.
function FC:ShowsFaction(code)
    if not code or code == "N" then return true end
    local f = self:GetFaction()
    return f == "Both" or f:sub(1, 1) == code
end

-- Profession detection ---------------------------------------------------------

-- WoW Forever's GetProfessionInfo reports its own IDs (8167, 8175, ...) instead of the
-- classic skill lines the data uses, so each profession is identified by, in order:
-- a mapping learned while its window was open, the reported ID itself, its English
-- name, or its icon (which doesn't depend on the game language).
local KNOWN_LINES = { [129] = true, [164] = true, [165] = true, [171] = true, [182] = true, [185] = true,
    [186] = true, [197] = true, [202] = true, [333] = true, [356] = true, [393] = true }
local LINE_BY_NAME = { ["Alchemy"] = 171, ["Blacksmithing"] = 164, ["Cooking"] = 185, ["Enchanting"] = 333,
    ["Engineering"] = 202, ["First Aid"] = 129, ["Fishing"] = 356, ["Herbalism"] = 182,
    ["Leatherworking"] = 165, ["Mining"] = 186, ["Skinning"] = 393, ["Tailoring"] = 197 }
local LINE_BY_ICON = { [136240] = 171, [136241] = 164, [136243] = 202, [136244] = 333, [136245] = 356,
    [136246] = 182, [136247] = 165, [136248] = 186, [136249] = 197, [134366] = 393, [133971] = 185 }

local function resolveLine(name, icon, reported)
    local map = FC.db and FC.db.reportedLines
    if map then
        if reported and map[reported] then return map[reported] end
        if name and map[name] then return map[name] end
    end
    if reported and KNOWN_LINES[reported] then return reported end
    return (name and LINE_BY_NAME[name]) or (icon and LINE_BY_ICON[icon])
end

-- Reads every profession the character has into FC.skills, keyed by skill line.
function FC:ScanSkills()
    wipe(self.skills)
    self.reportedByLine = self.reportedByLine or {}
    if GetProfessions and GetProfessionInfo then
        local list = { GetProfessions() }
        for i = 1, 6 do
            local idx = list[i]
            if idx then
                local name, icon, rank, maxRank, _, spellOffset, reported, modifier = GetProfessionInfo(idx)
                local line = resolveLine(name, icon, reported)
                if line then
                    self.skills[line] = { name = name, icon = icon, rank = rank or 0, max = maxRank or 0, modifier = modifier or 0,
                        reported = reported, spellOffset = spellOffset }
                end
            end
        end
    end
    -- Fallback for clients that only expose the classic skill list.
    if next(self.skills) == nil and GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
            local line = name and not isHeader and resolveLine(name)
            if line then
                self.skills[line] = { name = name, rank = rank or 0, max = maxRank or 0, modifier = modifier or 0 }
            end
        end
    end
    self:Fire("SKILLS_UPDATED")
end

-- While a profession window is open its base info carries the classic skill line;
-- remember which name/reported ID that belongs to, for any game language.
function FC:LearnOpenProfession(base)
    if not (base and base.professionID and KNOWN_LINES[base.professionID] and base.professionName) then return end
    self.db.reportedLines = self.db.reportedLines or {}
    self.db.reportedLines[base.professionName] = base.professionID
    if GetProfessions and GetProfessionInfo then
        for _, idx in pairs({ GetProfessions() }) do
            local name, _, _, _, _, _, reported = GetProfessionInfo(idx)
            if name == base.professionName and reported then
                self.db.reportedLines[reported] = base.professionID
            end
        end
    end
end

function FC:GetSkill(skillLine)
    return self.skills[skillLine]
end

-- Module loading ---------------------------------------------------------------

-- Each module is a LoadOnDemand addon with "## X-ForeverCrafting-SkillLines: 165,393".
-- It loads only when the character has at least one of those skill lines.
function FC:LoadModules()
    if not C_AddOns or not C_AddOns.GetNumAddOns then return end
    local player = UnitName("player")
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        local lines = name and C_AddOns.GetAddOnMetadata(name, "X-ForeverCrafting-SkillLines")
        if lines and not C_AddOns.IsAddOnLoaded(name) then
            local wanted = false
            for id in lines:gmatch("%d+") do
                if self.skills[tonumber(id)] then wanted = true end
            end
            local enabled = C_AddOns.GetAddOnEnableState(name, player) ~= 0
            if wanted and enabled and C_AddOns.IsAddOnLoadOnDemand(name) then
                local ok, reason = C_AddOns.LoadAddOn(name)
                if not ok then self:Print(name, reason or "") end
            end
        end
    end
end

-- Called by each module file once it is loaded.
function FC:RegisterModule(key, mod)
    mod.key = key
    self.modules[key] = mod
    table.insert(self.moduleOrder, key)
    table.sort(self.moduleOrder, function(a, b) return (self.modules[a].order or 99) < (self.modules[b].order or 99) end)
    if mod.OnRegister then mod:OnRegister() end
    self:Fire("MODULE_REGISTERED", key)
end

function FC:GetModuleForSkillLine(skillLine)
    for _, key in ipairs(self.moduleOrder) do
        local mod = self.modules[key]
        if mod.mainSkillLine == skillLine then return mod end
    end
end

-- Known recipes ------------------------------------------------------------------

function FC:IsKnown(skillLine, spellID)
    local known = self.char.known[skillLine]
    if known and known[spellID] then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    return false
end

function FC:HasSynced(skillLine)
    return self.char.synced[skillLine] ~= nil
end

-- Reads every learned recipe while the profession window is open.
function FC:ReadOpenProfession()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return end
    if C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked() then return end
    if C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild() then return end
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    self:LearnOpenProfession(info)
    local line = info and info.professionID
    if not line or not KNOWN_LINES[line] then return end
    local ids = C_TradeSkillUI.GetAllRecipeIDs()
    if not ids or #ids == 0 then return end
    local known = self.char.known[line] or {}
    self.char.known[line] = known
    for _, id in ipairs(ids) do
        local r = C_TradeSkillUI.GetRecipeInfo(id)
        if r and r.learned then known[id] = true end
    end
    self.char.synced[line] = time()
    self:ScanSkills()
    self:Fire("RECIPES_UPDATED", line)
end

-- Events ---------------------------------------------------------------------------

local ev = CreateFrame("Frame")
FC.eventFrame = ev
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")

local readPending = false
local function queueRead()
    if readPending then return end
    readPending = true
    C_Timer.After(0.3, function()
        readPending = false
        FC:ReadOpenProfession()
    end)
end

ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        ForeverCraftingDB = ForeverCraftingDB or {}
        ForeverCraftingCharDB = ForeverCraftingCharDB or {}
        applyDefaults(ForeverCraftingDB, DB_DEFAULTS)
        applyDefaults(ForeverCraftingCharDB, CHAR_DEFAULTS)
        FC.db = ForeverCraftingDB
        FC.char = ForeverCraftingCharDB
        FC:Fire("DB_READY")
    elseif event == "PLAYER_LOGIN" then
        FC:ScanSkills()
        FC:LoadModules()
        for _, e in ipairs({ "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
            "NEW_RECIPE_LEARNED", "BAG_UPDATE_DELAYED", "MERCHANT_SHOW", "TRADE_SKILL_CLOSE",
            "GET_ITEM_INFO_RECEIVED" }) do
            pcall(ev.RegisterEvent, ev, e)
        end
        FC:Fire("LOGIN")
    elseif event == "SKILL_LINES_CHANGED" then
        FC:ScanSkills()
        FC:LoadModules()
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then
        queueRead()
        FC:Fire("TRADE_SKILL_SHOW")
    elseif event == "TRADE_SKILL_CLOSE" then
        FC:Fire("TRADE_SKILL_CLOSE")
    elseif event == "NEW_RECIPE_LEARNED" then
        if arg1 then
            for _, key in ipairs(FC.moduleOrder) do
                local mod = FC.modules[key]
                if mod.HasRecipe and mod:HasRecipe(arg1) then
                    FC.char.known[mod.mainSkillLine] = FC.char.known[mod.mainSkillLine] or {}
                    FC.char.known[mod.mainSkillLine][arg1] = true
                end
            end
        end
        queueRead()
        FC:Fire("RECIPES_UPDATED")
    elseif event == "BAG_UPDATE_DELAYED" then
        FC:Fire("BAGS_UPDATED")
    elseif event == "MERCHANT_SHOW" then
        FC.Prices:ReadMerchant()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- Item names arrive in bursts; repaint once after the burst.
        if not FC.itemTimer then
            FC.itemTimer = C_Timer.NewTimer(0.5, function()
                FC.itemTimer = nil
                FC:Fire("BAGS_UPDATED")
            end)
        end
    end
end)

-- Slash commands ---------------------------------------------------------------------

SLASH_FOREVERCRAFTING1 = "/fc"
SLASH_FOREVERCRAFTING2 = "/forevercrafting"
SlashCmdList.FOREVERCRAFTING = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "bar" then
        FC.db.craftBar = not FC.db.craftBar
        FC.CraftBar:Update()
    elseif msg == "debug" then
        FC.db.debugBar = not FC.db.debugBar
        print("Forever Crafting bar debug: " .. (FC.db.debugBar and "on" or "off"))
    elseif msg == "settings" or msg == "options" then
        FC.Window:Open(nil, "settings")
    elseif msg == "help" then
        FC:Print(L["Commands: /fc, /fc settings, /fc bar"])
    else
        FC.Window:Toggle()
    end
end

function ForeverCrafting_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then
        FC.Window:Open(nil, "settings")
    else
        FC.Window:Toggle()
    end
end

-- Support link (Ko-fi). Placeholder until the page is ready: change it here only.
FC.SUPPORT_URL = "https://ko-fi.com/lurxie"
FC.SUPPORT_ICON = "Interface\\Icons\\INV_Drink_04"

-- A small dialog with a link selected and ready to copy (the game can't open a browser).
StaticPopupDialogs["FOREVERCRAFTING_COPY_LINK"] = {
    text = "%s",
    button1 = OKAY,
    hasEditBox = true,
    editBoxWidth = 320,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnShow = function(self, data)
        local box = self.editBox or self.EditBox
        box:SetText(data or "")
        box:HighlightText()
        box:SetFocus()
    end,
    EditBoxOnTextChanged = function(box, data)
        -- Keep the link intact if a key is pressed by accident.
        if box:GetText() ~= data then box:SetText(data or "") box:HighlightText() end
    end,
    EditBoxOnEnterPressed = function(box) box:GetParent():Hide() end,
    EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
}

function FC:ShowCopyLink(url, text)
    StaticPopup_Show("FOREVERCRAFTING_COPY_LINK", text, nil, url)
end
