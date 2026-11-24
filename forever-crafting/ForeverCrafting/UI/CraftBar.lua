-- Craft bar: one button that crafts the guide's next recipe (prep items first).
-- First click opens the profession window if it isn't open (the game needs it open to
-- craft); after that, left-click crafts what the step still needs, right-click crafts one.
local _, FC = ...
local L = FC.L
local U = FC.Util
local S = FC.Style
FC.CraftBar = {}
local CB = FC.CraftBar

local bar, button
CB.moduleKey = nil

local function activeModule()
    local key = CB.moduleKey
    if key and FC.modules[key] then return FC.modules[key] end
    return FC.modules[FC.moduleOrder[1] or ""]
end

local function windowOpenFor(mod)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return false end
    local shown = (ProfessionsFrame and ProfessionsFrame:IsShown()) or (TradeSkillFrame and TradeSkillFrame:IsShown())
    if not shown then return false end
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    return info and info.professionID == mod.mainSkillLine
end

-- "Crafting" = a tracked profession window is open, or our own window is.
local function crafting()
    local prof = (ProfessionsFrame and ProfessionsFrame:IsShown()) or (TradeSkillFrame and TradeSkillFrame:IsShown())
    if prof then
        local info = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
        if info and FC:GetModuleForSkillLine(info.professionID) then return true end
    end
    return FC.Window and FC.Window.frame and FC.Window.frame:IsShown() or false
end

-- The profession's own spell ID, read from the spellbook slot GetProfessionInfo reports.
function CB.ProfessionSpell(mod)
    local sk = FC:GetSkill(mod.mainSkillLine)
    if not (sk and sk.spellOffset) then return nil end
    local slot = sk.spellOffset + 1
    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum.SpellBookSpellBank then
        local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, Enum.SpellBookSpellBank.Player)
        if ok and info and info.spellID then return info.spellID end
    end
    if GetSpellBookItemInfo then
        local ok, _, id = pcall(GetSpellBookItemInfo, slot, BOOKTYPE_SPELL or "spell")
        if ok and id then return id end
    end
    return nil
end

local function create()
    bar = CreateFrame("Frame", "ForeverCraftingCraftBar", UIParent, "BackdropTemplate")
    bar:SetSize(360, 60)
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    -- Above action bars, unit frames and the profession window, but below the game menu,
    -- popups and other dialogs (DIALOG strata); tooltips still go on top.
    bar:SetFrameStrata("HIGH")
    bar:SetFrameLevel(100)
    bar:SetToplevel(true)
    bar:SetClampedToScreen(true)
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        FC.db.craftBarPoint = { p, rp, x, y }
    end)
    bar:SetBackdrop({ bgFile = S.media .. "Parchment", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    bar:SetBackdropBorderColor(0.36, 0.22, 0.11, 1)
    if FC.db.craftBarPoint then
        local p = FC.db.craftBarPoint
        bar:ClearAllPoints()
        bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end

    -- The whole bar is the button; the icon is drawn at its left.
    button = CreateFrame("Button", "ForeverCraftingCraftButton", bar, "SecureActionButtonTemplate")
    button:SetAllPoints(bar)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function() if IsShiftKeyDown() then bar:StartMoving() end end)
    button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    -- Act on mouse-up, like ForeverFishing's secure buttons. The cast attribute is set
    -- ahead of time in Update (never inside the click), so the click itself stays secure.
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetScript("PreClick", function(self, mouse, down)
        if FC.db and FC.db.debugBar then
            print(string.format("|cffd4a017FC bar|r %s %s  type=%s type1=%s type2=%s spell=%s click1=%s",
                tostring(mouse), down and "down" or "up", tostring(self:GetAttribute("type")),
                tostring(self:GetAttribute("type1")), tostring(self:GetAttribute("type2")),
                tostring(self:GetAttribute("spell")),
                tostring(self:GetAttribute("clickbutton1") and (self:GetAttribute("clickbutton1"):GetName() or "frame"))))
        end
    end)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(44, 44)
    button.icon:SetPoint("LEFT", 6, 0)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 2, -2) hl:SetPoint("BOTTOMRIGHT", -2, 2)
    hl:SetColorTexture(1, 0.85, 0.5, 0.18)
    local iconHl = button:CreateTexture(nil, "HIGHLIGHT")
    iconHl:SetAllPoints(button.icon)
    iconHl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    iconHl:SetBlendMode("ADD")
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -2, 2)

    bar.title = bar:CreateFontString(nil, "OVERLAY")
    bar.title:SetFontObject(S.fonts.body)
    bar.title:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 8, -1)
    bar.title:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    bar.title:SetJustifyH("LEFT")
    bar.title:SetWordWrap(false)
    bar.line2 = bar:CreateFontString(nil, "OVERLAY")
    bar.line2:SetFontObject(S.fonts.small)
    bar.line2:SetPoint("TOPLEFT", bar.title, "BOTTOMLEFT", 0, -3)
    bar.line2:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    bar.line2:SetJustifyH("LEFT")
    bar.line2:SetWordWrap(false)
    bar.line3 = bar:CreateFontString(nil, "OVERLAY")
    bar.line3:SetFontObject(S.fonts.small)
    bar.line3:SetPoint("TOPLEFT", bar.line2, "BOTTOMLEFT", 0, -2)
    bar.line3:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    bar.line3:SetJustifyH("LEFT")
    bar.line3:SetWordWrap(false)

    -- Progress bar shown while a craft is being cast (replaces lines 2 and 3).
    local prog = CreateFrame("Frame", nil, bar)
    prog:SetPoint("TOPLEFT", bar.title, "BOTTOMLEFT", 0, -5)
    prog:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
    prog:SetHeight(16)
    prog.bg = prog:CreateTexture(nil, "BACKGROUND")
    prog.bg:SetAllPoints()
    prog.bg:SetColorTexture(0.22, 0.14, 0.07, 0.35)
    prog.fill = prog:CreateTexture(nil, "ARTWORK")
    prog.fill:SetPoint("TOPLEFT", 1, -1)
    prog.fill:SetPoint("BOTTOMLEFT", 1, 1)
    prog.fill:SetWidth(1)
    prog.fill:SetColorTexture(0.55, 0.36, 0.12, 0.85)
    prog.spark = prog:CreateTexture(nil, "OVERLAY")
    prog.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    prog.spark:SetBlendMode("ADD")
    prog.spark:SetSize(14, 28)
    prog.spark:SetPoint("CENTER", prog.fill, "RIGHT", 0, 0)
    local function edge(a, b)
        local t = prog:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.36, 0.22, 0.11, 0.9)
        t:SetPoint(a) t:SetPoint(b)
        if a:find("TOP") and b:find("TOP") or a:find("BOTTOM") and b:find("BOTTOM") then t:SetHeight(1) else t:SetWidth(1) end
    end
    edge("TOPLEFT", "TOPRIGHT") edge("BOTTOMLEFT", "BOTTOMRIGHT") edge("TOPLEFT", "BOTTOMLEFT") edge("TOPRIGHT", "BOTTOMRIGHT")
    prog.left = prog:CreateFontString(nil, "OVERLAY")
    prog.left:SetFontObject(S.fonts.tiny)
    prog.left:SetPoint("LEFT", 5, 0)
    prog.left:SetTextColor(1, 0.95, 0.85)
    prog.left:SetShadowOffset(1, -1)
    prog.right = prog:CreateFontString(nil, "OVERLAY")
    prog.right:SetFontObject(S.fonts.tiny)
    prog.right:SetPoint("RIGHT", -5, 0)
    prog.right:SetTextColor(1, 0.95, 0.85)
    prog.right:SetShadowOffset(1, -1)
    prog:Hide()
    prog:SetScript("OnUpdate", function(self)
        local c = CB.cast
        if not c then return end
        local now = GetTime() * 1000
        local pct = c.endMS > c.startMS and math.min(1, math.max(0, (now - c.startMS) / (c.endMS - c.startMS))) or 1
        local w = (self:GetWidth() - 2) * pct
        self.fill:SetWidth(math.max(1, w))
        self.right:SetText(string.format("%.1f", math.max(0, (c.endMS - now) / 1000)))
    end)
    bar.prog = prog

    -- Before the click: if the profession window isn't open, cast the profession's own
    -- spell (by spell ID from the spellbook) through the secure button. After the click,
    -- if the window still isn't open, ask the trade skill API to open it.
    button:SetScript("PostClick", function(self, mouse, down)
        if down then return end
        if self.opening then
            C_Timer.After(0.8, function()
                local mod = activeModule()
                if mod and not windowOpenFor(mod) then
                    print("|cffd4a017Forever Crafting:|r " .. L["Couldn't open the profession window. Open it from your spellbook, then click the bar again."])
                end
                CB:Update()
            end)
            return
        end
        -- Crafting happens through the secure click on the window's own Create buttons.
        C_Timer.After(0.5, function() CB:Update() end)
    end)
    button:SetScript("OnEnter", function(self)
        local mod, next = activeModule(), self.next
        if windowOpenFor(mod) then CB.PrepareWindow(next) end
        GameTooltip:SetOwner(bar, "ANCHOR_TOP")
        if next and next.spell then
            local r = mod.data.recipes[next.spell]
            if r and r.item then GameTooltip:SetItemByID(r.item) else GameTooltip:SetSpellByID(next.spell) end
            GameTooltip:AddLine(" ")
        else
            GameTooltip:SetText(L["Craft bar"], 1, 0.82, 0)
        end
        if not windowOpenFor(mod) then
            GameTooltip:AddLine(L["Click to open your profession window, then click again to craft."], 1, 1, 1, true)
        else
            GameTooltip:AddLine(L["Left-click: craft what this step still needs"], 1, 1, 1)
            GameTooltip:AddLine(L["Right-click: Create All"], 1, 1, 1)
        end
        GameTooltip:AddLine(L["Shift-drag the bar to move it"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

-- The bar holds a secure button, so it can't be shown or hidden in combat.
local function setShown(v)
    if not bar then return end
    if InCombatLockdown() then CB.dirty = true return end
    bar:SetShown(v)
end

-- The open window's Create and Create All buttons (modern or classic layout).
local function createButtons()
    local pf = ProfessionsFrame
    if pf and pf:IsShown() and pf.CraftingPage then
        return pf.CraftingPage.CreateButton, pf.CraftingPage.CreateAllButton
    end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then
        return _G.TradeSkillCreateButton, _G.TradeSkillCreateAllButton
    end
end

-- The recipe the window currently shows.
local function selectedRecipe()
    local pf = ProfessionsFrame
    if pf and pf:IsShown() and pf.CraftingPage and pf.CraftingPage.SchematicForm then
        local form = pf.CraftingPage.SchematicForm
        local ok, info = pcall(function() return form.GetRecipeInfo and form:GetRecipeInfo() end)
        if ok and info then return info.recipeID end
        return form.currentRecipeInfo and form.currentRecipeInfo.recipeID
    end
end
CB.selectedRecipe = selectedRecipe

-- Put the step's amount into the window's quantity box, so Create makes exactly that.
function CB.SetQuantity(next)
    if not (next and next.spell and not next.blocked) or InCombatLockdown() then return end
    if CB.selectedRecipe() ~= next.spell and not (TradeSkillFrame and TradeSkillFrame:IsShown()) then return end
    local n = math.max(1, math.min(next.want or 1, next.canMake or 1))
    local box = _G.TradeSkillInputBox
    if box and box:IsVisible() then
        box:SetNumber(n)
        return
    end
    local pf = ProfessionsFrame
    box = pf and pf.CraftingPage and pf.CraftingPage.CreateMultipleInputBox
    if box and box.SetValue then pcall(box.SetValue, box, n) end
end

-- Select the recipe, then set the amount once the window has switched to it.
-- The window may still be loading its recipe list (right after it opens), when the
-- game ignores a selection. Keep asking until it shows the recipe, then set the amount.
function CB.PrepareWindow(next, tries)
    tries = tries or 0
    CB.SelectInWindow(next)
    C_Timer.After(0.25, function()
        if not (next and next.spell) or not (button.next and button.next.spell == next.spell) then return end
        if selectedRecipe() == next.spell or tries >= 8 then
            CB.SetQuantity(next)
        else
            CB.PrepareWindow(next, tries + 1)
        end
    end)
end

-- Ask the window to show the bar's recipe. OpenRecipe goes through the game's own
-- event handler, so the selection stays secure and its Create button still works.
function CB.SelectInWindow(next)
    -- Select it even when materials are missing (the window then shows what's short);
    -- skip only recipes you don't know yet or can't gain from (at your rank cap).
    if not (next and next.spell) or next.blocked == "learn" or next.blocked == "train" then return end
    if InCombatLockdown() then return end
    if selectedRecipe() == next.spell then return end
    if C_TradeSkillUI and C_TradeSkillUI.OpenRecipe then pcall(C_TradeSkillUI.OpenRecipe, next.spell) end
end

-- Window closed: the button casts the profession spell (opens the window).
-- Window open: left-click presses Create All, right-click presses Create.
function CB.SetCastAttributes(mod)
    if not button or InCombatLockdown() then return end
    local open = mod and windowOpenFor(mod)
    local spellID = (mod and not open) and CB.ProfessionSpell(mod) or nil
    local one, all
    if open and button.next and button.next.spell and not button.next.blocked then
        one, all = createButtons()
    end
    button.opening = spellID ~= nil
    if spellID then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", spellID)
        button:SetAttribute("type1", nil) button:SetAttribute("type2", nil)
    elseif one then
        button:SetAttribute("type", nil)
        button:SetAttribute("type1", "click")
        button:SetAttribute("clickbutton1", one)
        button:SetAttribute("type2", "click")
        button:SetAttribute("clickbutton2", all or one)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("type1", nil)
        button:SetAttribute("type2", nil)
    end
end

-- You can start, but not finish the step from your bags: say what's in the bank
-- (from the last bank visit or Syndicator) and what you still need to get.
function CB.ShortLine(mod, next)
    local bank, short = {}, {}
    for _, m in ipairs(mod:MissingInBags(next.spell, next.want)) do
        local fromBank = math.min(m.short, m.inBank)
        if fromBank > 0 then table.insert(bank, string.format("%d× %s", fromBank, U.ItemName(m.id))) end
        if m.short > fromBank then table.insert(short, string.format("%d× %s", m.short - fromBank, U.ItemName(m.id))) end
    end
    if bank[1] then
        return U.Colorize(L["In your bank"] .. ": ", unpack(S.accent)) .. table.concat(bank, ", ")
    elseif short[1] then
        return U.Colorize(L["Still need"] .. ": " .. table.concat(short, ", "), unpack(U.DIFF_COLORS.red))
    end
end

function CB:Update()
    if not FC.db then return end
    local mod = activeModule()
    if not FC.db.craftBar or not mod or not crafting() then
        setShown(false)
        return
    end
    if not bar then
        if InCombatLockdown() then CB.dirty = true return end
        create()
    end
    local next = mod.NextCraft and mod:NextCraft()
    button.next = next
    CB.SetCastAttributes(mod)
    local key = next and next.spell
    if windowOpenFor(mod) then
        -- Just opened (by the bar or by you): select the bar's recipe again.
        if not CB.windowWasOpen then CB.lastSelected = nil end
        CB.windowWasOpen = true
        if key ~= CB.lastSelected then
            CB.lastSelected = key
            CB.PrepareWindow(next)
        else
            CB.SetQuantity(next)
        end
    else
        CB.lastSelected = nil
        CB.windowWasOpen = false
    end
    if not next then
        setShown(false)
        return
    end
    setShown(true)
    if CB.cast then
        CB:ShowCasting(mod)
        return
    end
    bar.prog:Hide()
    bar.line2:Show() bar.line3:Show()
    if next.action then
        button.icon:SetTexture(132853)
        button.icon:SetDesaturated(false)
        button.count:SetText("")
        bar.title:SetText(L["Disenchant uncommon (green) or better items"])
        bar.line2:SetText(string.format("%d–%d", next.step.from, next.step.to))
        bar.line3:SetText("")
        return
    end
    local skill = mod:Skill()
    local r = mod.data.recipes[next.spell]
    button.icon:SetTexture(mod:RecipeIcon(next.spell))
    button.icon:SetDesaturated(next.blocked ~= nil)
    button.count:SetText(next.canMake > 0 and next.canMake or "")
    local diff = r and U.Difficulty(r.lv, skill) or "gray"
    local color = U.DIFF_COLORS[diff] or S.ink
    local prefix = next.label == "prepare" and (L["Prepare"] .. ": ") or ""
    bar.title:SetText(prefix .. U.Colorize(mod:RecipeName(next.spell), color[1], color[2], color[3]))

    local stepText = next.step.fixed and string.format("%d", next.step.to)
        or string.format("%d–%d", next.step.from, next.step.to)
    bar.line2:SetText(string.format(L["Need %d  ·  can make %d  ·  step %s"], next.want, next.canMake, stepText))

    if next.blocked == "train" then
        local names = {}
        for _, t in ipairs(mod:TrainersFor(next.rank.key)) do table.insert(names, t.name) end
        bar.line2:SetText(U.Colorize(string.format(L["At your cap (%d). Train %s to keep going."], skill, L[next.rank.key]), unpack(S.accent)))
        bar.line3:SetText(L["Trainers"] .. ": " .. table.concat(names, ", "))
    elseif next.capped and next.canMake > 0 and not (next.canMake < next.want and CB.ShortLine(mod, next)) then
        bar.line3:SetText(U.Colorize(string.format(L["Stops at %d: then train %s"], next.capped.max, L[next.capped.rank.key]), unpack(S.accent)))
    elseif next.blocked == "learn" then
        bar.line3:SetText(U.Colorize(L["You don't know this recipe yet."], unpack(U.DIFF_COLORS.red)))
    elseif next.blocked == "mats" then
        local parts = {}
        for _, m in ipairs(mod:MissingInBags(next.spell, 1)) do
            local t = string.format("%d× %s", m.short, U.ItemName(m.id))
            if m.inBank > 0 then t = t .. " (" .. L["bank"] .. " " .. m.inBank .. ")" end
            table.insert(parts, t)
        end
        bar.line3:SetText(U.Colorize(L["Missing"] .. ": " .. table.concat(parts, ", "), unpack(U.DIFF_COLORS.red)))
    elseif next.canMake < next.want and CB.ShortLine(mod, next) then
        bar.line3:SetText(CB.ShortLine(mod, next))
    elseif not windowOpenFor(mod) then
        bar.line3:SetText(L["Click to open your profession window"])
    else
        local keep = next.label ~= "prepare" and next.index and mod:KeepFor(next.index, skill) or {}
        if next.label == "prepare" then
            bar.line3:SetText(U.Colorize(L["Keep"] .. ": ", unpack(S.accent)) .. string.format(L["needed for %s"], mod:RecipeName(next.step.spell)))
        elseif keep[1] then
            local k = keep[1]
            bar.line3:SetText(U.Colorize(L["Keep"] .. ": ", unpack(S.accent)) .. string.format(L["needed for %s"], mod:RecipeName(k.step.spell)))
        else
            bar.line3:SetText(L["Click to craft"])
        end
    end
end

local pending
local function updateSoon()
    if pending then return end
    pending = true
    C_Timer.After(0.3, function()
        pending = false
        CB:Update()
    end)
end
FC:On("BAGS_UPDATED", updateSoon)
FC:On("SKILLS_UPDATED", updateSoon)
FC:On("RECIPES_UPDATED", updateSoon)
FC:On("MODULE_REGISTERED", updateSoon)
FC:On("LOGIN", updateSoon)
FC:On("TRADE_SKILL_SHOW", function()
    -- Follow whichever profession window was opened.
    local info = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
    local mod = info and FC:GetModuleForSkillLine(info.professionID)
    if mod then CB.moduleKey = mod.key end
    CB:Update()
    C_Timer.After(0.2, function() CB:Update() end)
end)
FC:On("TRADE_SKILL_CLOSE", function()
    CB.windowWasOpen, CB.lastSelected = false, nil
    if button and not InCombatLockdown() then CB.SetCastAttributes(activeModule()) end
    updateSoon()
end)
FC:On("WINDOW_SHOWN", updateSoon)
FC:On("WINDOW_HIDDEN", updateSoon)

-- Crafting view --------------------------------------------------------------------

-- How many crafts are still queued after this one, if the client tells us.
local function repeatsLeft()
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeRepeatCount then
        local ok, n = pcall(C_TradeSkillUI.GetRecipeRepeatCount)
        if ok and n then return n end
    end
    if GetTradeskillRepeatCount then
        local ok, n = pcall(GetTradeskillRepeatCount)
        if ok and n then return n end
    end
end

function CB:ShowCasting(mod)
    local c = CB.cast
    button.icon:SetTexture(c.icon or mod:RecipeIcon(c.spell))
    button.icon:SetDesaturated(false)
    button.count:SetText("")
    bar.title:SetText(L["Crafting"] .. ": " .. U.Colorize(c.name, 0.45, 0.25, 0.05))
    bar.line2:Hide() bar.line3:Hide()
    local left = repeatsLeft()
    if c.batch and c.batch > 1 then
        local done = c.done or 0
        bar.prog.left:SetText(string.format(L["%d of %d"], math.min(done + 1, c.batch), c.batch))
    elseif left and left > 1 then
        bar.prog.left:SetText(string.format(L["%d left"], left))
    else
        bar.prog.left:SetText("")
    end
    bar.prog:Show()
end

-- Is this spell one of the active profession's recipes?
local function isRecipe(spellID)
    local mod = activeModule()
    return mod and mod.data and mod.data.recipes and mod.data.recipes[spellID] and mod
end

local castWatch = CreateFrame("Frame")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
castWatch:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
castWatch:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if event == "UNIT_SPELLCAST_START" then
        local mod = isRecipe(spellID)
        if not mod or not bar then return end
        local name, _, icon, startMS, endMS = UnitCastingInfo("player")
        local prev = CB.cast
        local batch = CB.batch
        if not (batch and batch.spell == spellID) then
            local left = repeatsLeft()
            batch = { spell = spellID, total = math.max(1, (left or 1)), done = 0 }
            CB.batch = batch
        end
        CB.cast = { spell = spellID, name = mod:RecipeName(spellID) or name, icon = icon,
            startMS = startMS or GetTime() * 1000, endMS = endMS or GetTime() * 1000,
            batch = batch.total, done = batch.done }
        if bar:IsShown() then CB:ShowCasting(mod) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if CB.batch and CB.batch.spell == spellID then
            CB.batch.done = CB.batch.done + 1
            if CB.batch.done >= CB.batch.total then CB.batch = nil end
        end
    elseif CB.cast and (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") then
        CB.cast = nil
        CB.batch = nil
        updateSoon()
    elseif event == "UNIT_SPELLCAST_STOP" and CB.cast then
        -- Between crafts of a batch the next START comes right after; wait briefly.
        local stopped = CB.cast
        C_Timer.After(0.25, function()
            if CB.cast == stopped then
                CB.cast = nil
                local left = repeatsLeft()
                if not (left and left > 0) then CB.batch = nil end
                CB:Update()
            end
        end)
    end
end)

local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_ENABLED")
combat:SetScript("OnEvent", function()
    if CB.dirty then
        CB.dirty = false
        CB:Update()
    end
end)

function CB:SetModule(key)
    self.moduleKey = key
    updateSoon()
end
