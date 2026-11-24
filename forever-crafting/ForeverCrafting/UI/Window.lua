-- The main parchment window. Modules supply pages; the core supplies Settings.
-- Page definition: { key, title, setup = fn(toolbar, mod), render = fn(canvas, mod, toolbar) }
local _, FC = ...
local L = FC.L
local S = FC.Style
local UI = FC.UI
FC.Window = {}
local W = FC.Window

local WIDTH, HEIGHT = 720, 580
W.current = { module = nil, page = nil }
W.pageTabs = {}
W.toolbars = {}

local function create()
    local f = CreateFrame("Frame", "ForeverCraftingFrame", UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        FC.db.window.point = { p, rp, x, y }
    end)
    f:Hide()
    S:Decorate(f)
    table.insert(UISpecialFrames, "ForeverCraftingFrame")

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", 22, -18)
    f.icon = icon

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(S.fonts.title)
    title:SetPoint("LEFT", icon, "RIGHT", 10, 4)
    f.title = title

    local sub = f:CreateFontString(nil, "OVERLAY")
    sub:SetFontObject(S.fonts.small)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -2)
    f.subtitle = sub

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    local gear = CreateFrame("Button", nil, f)
    gear:SetSize(22, 22)
    gear:SetPoint("RIGHT", close, "LEFT", -4, 0)
    gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    gear:SetScript("OnClick", function() W:Open(W.current.module, "settings") end)
    gear:SetScript("OnEnter", function(self) UI.TextTooltip(self, L["Settings"]) end)
    gear:SetScript("OnLeave", GameTooltip_Hide)

    -- Profession tabs down the right edge, like the game's profession window.
    f.profTabs = {}

    -- Page tabs row
    local tabs = CreateFrame("Frame", nil, f)
    tabs:SetPoint("TOPLEFT", 22, -70)
    tabs:SetPoint("TOPRIGHT", -22, -70)
    tabs:SetHeight(26)
    f.tabs = tabs

    local tabLine = f:CreateTexture(nil, "ARTWORK")
    tabLine:SetColorTexture(0.45, 0.28, 0.12, 0.8)
    tabLine:SetHeight(2)
    tabLine:SetPoint("TOPLEFT", tabs, "BOTTOMLEFT", 0, 0)
    tabLine:SetPoint("TOPRIGHT", tabs, "BOTTOMRIGHT", 0, 0)

    -- Toolbar area for page controls
    local toolbarHost = CreateFrame("Frame", nil, f)
    toolbarHost:SetPoint("TOPLEFT", tabs, "BOTTOMLEFT", 0, -6)
    toolbarHost:SetPoint("TOPRIGHT", tabs, "BOTTOMRIGHT", 0, -6)
    toolbarHost:SetHeight(26)
    f.toolbarHost = toolbarHost

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", toolbarHost, "BOTTOMLEFT", 0, -6)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, 20)
    f.content = content

    W.canvas = UI.ScrollCanvas(content)
    W.canvas.scroll:SetAllPoints(content)

    f:SetScript("OnShow", function() W:Refresh() FC:Fire("WINDOW_SHOWN") end)
    f:SetScript("OnHide", function() FC:Fire("WINDOW_HIDDEN") end)
    W.frame = f
    W:ApplyPosition()
    return f
end

function W:ApplyPosition()
    local f = self.frame
    if not f then return end
    f:SetScale(FC.db.window.scale or 1)
    local p = FC.db.window.point
    if p then
        f:ClearAllPoints()
        f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end
end

local SETTINGS_PAGE = { key = "settings" }
local NONE_PAGE = { key = "none" }

local function pagesFor(mod)
    local list = {}
    if mod and mod.pages then
        for _, p in ipairs(mod.pages) do table.insert(list, p) end
        -- Pages every profession shares (Leftovers).
        for _, p in ipairs(FC.SharedPages or {}) do table.insert(list, p) end
    end
    return list
end

local function findPage(mod, key)
    if key == "settings" then return SETTINGS_PAGE end
    if not mod then return NONE_PAGE end
    for _, p in ipairs(pagesFor(mod)) do
        if p.key == key then return p end
    end
    return pagesFor(mod)[1] or SETTINGS_PAGE
end

function W:BuildTabs(mod)
    local f = self.frame
    for _, b in ipairs(self.pageTabs) do b:Hide() end
    local x = 0
    for i, p in ipairs(pagesFor(mod)) do
        local b = self.pageTabs[i]
        if not b then
            b = UI.Button(f.tabs, "", 110, 26)
            self.pageTabs[i] = b
        end
        b.text:SetText(p.title)
        b:SetWidth(math.max(90, b.text:GetStringWidth() + 30))
        b:ClearAllPoints()
        b:SetPoint("BOTTOMLEFT", f.tabs, "BOTTOMLEFT", x, 0)
        x = x + b:GetWidth() + 4
        b.pageKey = p.key
        b:SetScript("OnClick", function() W:Open(W.current.module, p.key) end)
        b:Show()
    end
end

-- One square icon tab per loaded profession, on the outside of the right edge.
-- Hidden when only one profession is loaded.
local TAB_SIZE, TAB_GAP, TAB_TOP = 36, 8, -64
function W:BuildProfessionTabs()
    local f = self.frame
    local order = FC.moduleOrder
    for _, t in ipairs(f.profTabs) do t:Hide() end
    if #order < 2 then return end
    for i, key in ipairs(order) do
        local mod = FC.modules[key]
        local t = f.profTabs[i]
        if not t then
            t = CreateFrame("Button", nil, f)
            t:SetSize(TAB_SIZE, TAB_SIZE)
            t:SetPoint("TOPLEFT", f, "TOPRIGHT", -2, TAB_TOP - (i - 1) * (TAB_SIZE + TAB_GAP))
            -- Leather backing a little larger than the icon, so it reads as a tab.
            local back = t:CreateTexture(nil, "BACKGROUND")
            back:SetPoint("TOPLEFT", -3, 3)
            back:SetPoint("BOTTOMRIGHT", 5, -3)
            back:SetColorTexture(0.22, 0.13, 0.06, 1)
            local rim = t:CreateTexture(nil, "BORDER")
            rim:SetPoint("TOPLEFT", -1, 1)
            rim:SetPoint("BOTTOMRIGHT", 1, -1)
            rim:SetColorTexture(0.45, 0.28, 0.12, 1)
            t.icon = t:CreateTexture(nil, "ARTWORK")
            t.icon:SetAllPoints()
            t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            t:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            t.selected = t:CreateTexture(nil, "OVERLAY")
            t.selected:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            t.selected:SetBlendMode("ADD")
            t.selected:SetAllPoints()
            t:SetScript("OnClick", function(self) W:Open(self.key) end)
            t:SetScript("OnEnter", function(self)
                local m = FC.modules[self.key]
                UI.TextTooltip(self, m.title, m.Subtitle and { m:Subtitle() } or nil)
            end)
            t:SetScript("OnLeave", GameTooltip_Hide)
            f.profTabs[i] = t
        end
        t.key = key
        t.icon:SetTexture(mod.icon)
        local on = key == self.current.module
        t.selected:SetShown(on)
        t.icon:SetVertexColor(on and 1 or 0.85, on and 1 or 0.85, on and 1 or 0.85)
        t:Show()
    end
end

function W:Open(moduleKey, pageKey)
    local f = self.frame or create()
    moduleKey = moduleKey or self.current.module or FC.moduleOrder[1]
    local mod = moduleKey and FC.modules[moduleKey]
    self.current.module = moduleKey
    if moduleKey and FC.CraftBar then FC.CraftBar:SetModule(moduleKey) end
    local page = findPage(mod, pageKey or (mod and mod.lastPage))
    self.current.page = page.key
    if mod and page.key ~= "settings" then mod.lastPage = page.key end
    f:Show()
    self:Refresh()
end

function W:Toggle(moduleKey)
    if self.frame and self.frame:IsShown() and (not moduleKey or moduleKey == self.current.module) then
        self.frame:Hide()
    else
        self:Open(moduleKey)
    end
end

function W:IsShowing(moduleKey, pageKey)
    return self.frame and self.frame:IsShown()
        and (not moduleKey or self.current.module == moduleKey)
        and (not pageKey or self.current.page == pageKey)
end

-- Rebuild the visible page. keepScroll keeps the scroll position (for live updates).
function W:Refresh(keepScroll)
    local f = self.frame
    if not f or not f:IsShown() or self.refreshing then return end
    self.refreshing = true
    local ok, err = pcall(self.Draw, self, keepScroll)
    self.refreshing = false
    if not ok then geterrorhandler()(err) end
end

function W:Draw(keepScroll)
    local f = self.frame
    local mod = self.current.module and FC.modules[self.current.module]
    local page = findPage(mod, self.current.page)

    f.icon:SetTexture(mod and mod.icon or (S.media .. "Icon"))
    f.title:SetText(mod and mod.title or L["Forever Crafting"])
    f.subtitle:SetText(mod and mod.Subtitle and mod:Subtitle() or ("v" .. FC.version))

    self:BuildProfessionTabs()

    self:BuildTabs(mod)
    for _, b in ipairs(self.pageTabs) do b:SetSelected(b.pageKey == page.key) end

    -- Toolbars are created once per page and kept.
    for _, tb in pairs(self.toolbars) do tb:Hide() end
    local tbKey = (mod and mod.key or "core") .. ":" .. page.key
    local tb = self.toolbars[tbKey]
    if not tb then
        tb = CreateFrame("Frame", nil, f.toolbarHost)
        tb.height = page.toolbarHeight or 26
        tb:SetAllPoints()
        self.toolbars[tbKey] = tb
        if page.setup then page.setup(tb, mod) end
    end
    tb:Show()
    f.toolbarHost:SetHeight(tb.height or 26)

    local canvas = self.canvas
    canvas:Reset(keepScroll)
    if page.key == "settings" then
        FC.SettingsPage:Render(canvas, mod)
    elseif not mod then
        canvas:Space(30)
        canvas:Text(L["No profession modules are loaded on this character."], "heading", 0, { justify = "CENTER" })
        canvas:Text(L["Learn a crafting profession and its Forever Crafting module will load automatically."], "body", 0, { justify = "CENTER" })
    else
        local ok, err = pcall(page.render, canvas, mod, tb)
        if not ok then
            canvas:Text("|cffaa2222" .. tostring(err) .. "|r", "small")
            geterrorhandler()(err)
        end
    end
    canvas:Finish()
end

-- Live updates from the game (bags, skill, recipes) refresh whatever page is open.
local pending
local function refreshSoon()
    if pending then return end
    pending = true
    C_Timer.After(0.4, function()
        pending = false
        W:Refresh(true)
    end)
end
FC:On("BAGS_UPDATED", refreshSoon)
FC:On("SKILLS_UPDATED", refreshSoon)
FC:On("RECIPES_UPDATED", refreshSoon)
FC:On("PRICES_UPDATED", refreshSoon)
FC:On("MODULE_REGISTERED", refreshSoon)
