-- Reusable widgets: leather buttons, checkboxes, a search box, and a "canvas" that
-- lays out pooled text lines and rows top-to-bottom inside a scroll frame.
local _, FC = ...
local S = FC.Style
FC.UI = {}
local UI = FC.UI

-- Leather button / tab -------------------------------------------------------------
function UI.Button(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 110, height or 24)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(S.media .. "Tab")
    bg:SetAllPoints()
    b.bg = bg
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetColorTexture(1, 0.85, 0.5, 0.18)
    hl:SetAllPoints()
    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(S.fonts.tab)
    fs:SetPoint("CENTER", 0, 1)
    fs:SetText(text)
    b.text = fs
    function b:SetSelected(on)
        self.selected = on
        self.bg:SetVertexColor(on and 1 or 0.72, on and 1 or 0.66, on and 1 or 0.60)
        self.text:SetTextColor(on and 1 or 0.85, on and 0.92 or 0.78, on and 0.7 or 0.6)
    end
    b:SetSelected(false)
    return b
end

-- Button group: a row of joined buttons, one selected ------------------------------
-- choices = { { value = "all", text = "All" }, ... }
function UI.ButtonGroup(parent, choices, get, set)
    local g = CreateFrame("Frame", nil, parent)
    g.buttons = {}
    local x = 0
    for i, ch in ipairs(choices) do
        local b = UI.Button(g, ch.text, 80, 22)
        b:SetWidth(math.max(64, b.text:GetStringWidth() + 26))
        b:SetPoint("LEFT", g, "LEFT", x, 0)
        x = x + b:GetWidth() + 2
        b.value = ch.value
        b:SetScript("OnClick", function()
            set(ch.value)
            g:Refresh()
        end)
        g.buttons[i] = b
    end
    g:SetSize(x, 22)
    function g:Refresh()
        local cur = get()
        for _, b in ipairs(self.buttons) do b:SetSelected(b.value == cur) end
    end
    g:SetScript("OnShow", g.Refresh)
    g:Refresh()
    return g
end

-- Dropdown: a leather button showing "Label: Choice" that opens a list below it.
-- choices = { { value = "any", text = "Any" }, ... }
local openList
function UI.Dropdown(parent, label, choices, get, set, width)
    local b = UI.Button(parent, "", width or 140, 22)
    local list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    list:SetFrameStrata("FULLSCREEN_DIALOG")
    list:SetClampedToScreen(true)
    list:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    list:SetBackdropColor(0.93, 0.86, 0.70, 0.98)
    list:SetBackdropBorderColor(0.36, 0.22, 0.11, 1)
    list:Hide()
    list:EnableMouse(true)
    local y = -4
    list.items = {}
    for i, ch in ipairs(choices) do
        local it = CreateFrame("Button", nil, list)
        it:SetHeight(20)
        it:SetPoint("TOPLEFT", 4, y)
        it:SetPoint("TOPRIGHT", -4, y)
        local hl = it:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(S.highlight[1], S.highlight[2], S.highlight[3], 0.6)
        it.text = it:CreateFontString(nil, "OVERLAY")
        it.text:SetFontObject(S.fonts.body)
        it.text:SetPoint("LEFT", 6, 0)
        it.text:SetText(ch.text)
        it.value = ch.value
        it:SetScript("OnClick", function()
            set(ch.value)
            list:Hide()
            b:Refresh()
        end)
        list.items[i] = it
        y = y - 20
    end
    list:SetSize(math.max(width or 140, 160), -y + 4)
    function b:Refresh()
        local cur = get()
        local curText = choices[1].text
        for _, ch in ipairs(choices) do if ch.value == cur then curText = ch.text end end
        self.text:SetText(label .. ": " .. curText)
        self:SetSelected(cur ~= choices[1].value)
        for _, it in ipairs(list.items) do
            it.text:SetTextColor(unpack(it.value == cur and S.accent or S.ink))
        end
    end
    b:SetScript("OnClick", function(self)
        if list:IsShown() then list:Hide() return end
        if openList and openList ~= list then openList:Hide() end
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        list:SetScale(self:GetEffectiveScale() / UIParent:GetEffectiveScale())
        list:Show()
        openList = list
    end)
    b:SetScript("OnHide", function() list:Hide() end)
    b:Refresh()
    b.list = list
    return b
end

-- Checkbox with a label -------------------------------------------------------------
function UI.Check(parent, label, get, set, tooltip)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(24, 24)
    local fs = c:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(S.fonts.body)
    fs:SetPoint("LEFT", c, "RIGHT", 4, 0)
    fs:SetText(label)
    c.label = fs
    c:SetScript("OnShow", function(self) self:SetChecked(get()) end)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    if tooltip then
        c:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        c:SetScript("OnLeave", GameTooltip_Hide)
    end
    c:SetChecked(get())
    return c
end

-- Cycle button: click to step through a list of choices ------------------------------
function UI.Cycle(parent, choices, get, set, width)
    local b = UI.Button(parent, "", width or 140, 22)
    local function refresh()
        local cur = get()
        for _, ch in ipairs(choices) do
            if ch.value == cur then b.text:SetText(ch.text) end
        end
    end
    b:SetScript("OnClick", function(_, button)
        local cur, idx = get(), 1
        for i, ch in ipairs(choices) do if ch.value == cur then idx = i end end
        idx = button == "RightButton" and (idx - 2) % #choices + 1 or idx % #choices + 1
        set(choices[idx].value)
        refresh()
    end)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnShow", refresh)
    b.Refresh = refresh
    refresh()
    return b
end

-- Search box -------------------------------------------------------------------------
function UI.Search(parent, width, onChange)
    local e = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
    e:SetSize(width or 160, 20)
    e:SetAutoFocus(false)
    e:HookScript("OnTextChanged", function(self)
        onChange(self:GetText() or "")
    end)
    return e
end

-- Tooltip helpers ----------------------------------------------------------------------
function UI.ItemTooltip(owner, itemID, extra)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(itemID)
    if extra then
        GameTooltip:AddLine(" ")
        for _, line in ipairs(extra) do GameTooltip:AddLine(line, 1, 0.82, 0.4, true) end
    end
    GameTooltip:Show()
end

-- Tooltip for a recipe: the item it makes, or the spell itself (enchants make no item).
function UI.RecipeTooltip(owner, itemID, spellID, extra)
    if itemID then return UI.ItemTooltip(owner, itemID, extra) end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(spellID)
    if extra then
        GameTooltip:AddLine(" ")
        for _, line in ipairs(extra) do GameTooltip:AddLine(line, 1, 0.82, 0.4, true) end
    end
    GameTooltip:Show()
end

function UI.TextTooltip(owner, title, lines)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    for _, line in ipairs(lines or {}) do GameTooltip:AddLine(line, 1, 0.82, 0.4, true) end
    GameTooltip:Show()
end

-- Skill-up indicator ---------------------------------------------------------------------
-- Shows where the player's skill sits in a recipe's colour range.
-- mode: "bar" (colour bar with a marker), "text" (status pill), "both".
local L = FC.L
local SEG = { "orange", "yellow", "green", "gray" }

local function createIndicator(row)
    local ind = CreateFrame("Frame", nil, row)
    ind:SetSize(180, 28)
    ind.bar = CreateFrame("Frame", nil, ind)
    ind.bar.border = ind.bar:CreateTexture(nil, "BACKGROUND")
    ind.bar.border:SetColorTexture(0.25, 0.15, 0.06, 1)
    ind.bar.border:SetPoint("TOPLEFT", -1, 1)
    ind.bar.border:SetPoint("BOTTOMRIGHT", 1, -1)
    ind.segs = {}
    for i = 1, 4 do
        ind.segs[i] = ind.bar:CreateTexture(nil, "ARTWORK")
    end
    ind.marker = ind.bar:CreateTexture(nil, "OVERLAY")
    ind.marker:SetColorTexture(0.05, 0.03, 0.01, 1)
    ind.markerCap = ind.bar:CreateTexture(nil, "OVERLAY")
    ind.markerCap:SetColorTexture(0.05, 0.03, 0.01, 1)
    ind.lo = ind:CreateFontString(nil, "OVERLAY")
    ind.lo:SetFontObject(S.fonts.tiny)
    ind.hi = ind:CreateFontString(nil, "OVERLAY")
    ind.hi:SetFontObject(S.fonts.tiny)
    ind.pillBg = ind:CreateTexture(nil, "BACKGROUND")
    ind.pill = ind:CreateFontString(nil, "OVERLAY")
    ind.pill:SetFontObject(S.fonts.pill)
    ind.note = ind:CreateFontString(nil, "OVERLAY")
    ind.note:SetFontObject(S.fonts.tiny)
    ind.note:SetJustifyH("RIGHT")
    row.ind = ind
    return ind
end

-- Words for the current state: "Green · 50%", and the next threshold ("Gray at 130").
function UI.SkillStatus(lv, skill, known)
    local U = FC.Util
    local diff = U.Difficulty(lv, skill)
    if diff == "red" then
        return diff, string.format(L["Learn at %d"], lv.o or 0), nil
    end
    local chance = math.floor(U.SkillUpChance(lv, skill) * 100 + 0.5)
    local status
    if diff == "gray" then
        status = L["Gray"] .. " · " .. L["no skill-ups"]
    else
        status = L[U.DIFF_NAMES[diff]] .. " · " .. chance .. "%"
    end
    local nextText
    if diff == "orange" and lv.y then nextText = string.format(L["Yellow at %d"], lv.y)
    elseif diff == "yellow" and lv.g then nextText = string.format(L["Green at %d"], lv.g)
    elseif diff == "green" and lv.gr then nextText = string.format(L["Gray at %d"], lv.gr) end
    if not known then nextText = L["Not learned"] end
    return diff, status, nextText
end

local function layoutBar(ind, lv, skill, width, height, labels)
    local lo = lv.o or lv.y or 1
    local cuts = { lo, lv.y or lo, lv.g or lv.y or lo, lv.gr or lv.g or lv.y or lo }
    local top = cuts[4] + math.max(5, math.floor((cuts[4] - lo) * 0.15))
    local span = math.max(top - lo, 1)
    ind.bar:SetSize(width, height)
    local x = 0
    for i = 1, 4 do
        local from = cuts[i]
        local to = (i < 4) and cuts[i + 1] or top
        local w = math.max(0, (to - from) / span * width)
        local t = ind.segs[i]
        t:ClearAllPoints()
        if w >= 0.5 then
            t:SetColorTexture(unpack(FC.Util.DIFF_FILLS[SEG[i]]))
            t:SetPoint("TOPLEFT", ind.bar, "TOPLEFT", x, 0)
            t:SetSize(w, height)
            t:Show()
        else
            t:Hide()
        end
        x = x + w
    end
    local pos = math.min(math.max((skill - lo) / span, 0), 1) * width
    ind.marker:ClearAllPoints()
    ind.marker:SetSize(2, height + 6)
    ind.marker:SetPoint("CENTER", ind.bar, "LEFT", pos, 0)
    ind.markerCap:ClearAllPoints()
    ind.markerCap:SetSize(6, 2)
    ind.markerCap:SetPoint("BOTTOM", ind.marker, "TOP", 0, 0)
    ind.marker:Show()
    ind.markerCap:Show()
    if labels then
        ind.lo:ClearAllPoints()
        ind.lo:SetPoint("TOPLEFT", ind.bar, "BOTTOMLEFT", 0, -2)
        ind.lo:SetText(lo)
        ind.lo:Show()
        local grayX = (cuts[4] - lo) / span * width
        ind.hi:ClearAllPoints()
        ind.hi:SetPoint("TOP", ind.bar, "BOTTOMLEFT", grayX, -2)
        ind.hi:SetText(cuts[4])
        ind.hi:SetShown(grayX > 22)
    else
        ind.lo:Hide()
        ind.hi:Hide()
    end
end

local function layoutPill(ind, diff, text, anchorY)
    ind.pill:SetText(text)
    ind.pill:ClearAllPoints()
    ind.pill:SetPoint("TOPRIGHT", ind, "TOPRIGHT", -5, anchorY - 2)
    ind.pillBg:ClearAllPoints()
    ind.pillBg:SetPoint("TOPLEFT", ind.pill, "TOPLEFT", -5, 2)
    ind.pillBg:SetPoint("BOTTOMRIGHT", ind.pill, "BOTTOMRIGHT", 5, -2)
    local c = FC.Util.DIFF_COLORS[diff] or S.ink
    ind.pillBg:SetColorTexture(c[1], c[2], c[3], 1)
    ind.pill:Show()
    ind.pillBg:Show()
end

function UI.ShowSkill(row, lv, skill, known, mode)
    local ind = row.ind or createIndicator(row)
    ind:ClearAllPoints()
    ind:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -2)
    ind:Show()
    local diff, status, nextText = UI.SkillStatus(lv, skill, known)
    ind.pill:Hide() ind.pillBg:Hide() ind.note:Hide()
    if mode == "text" then
        ind.bar:Hide() ind.lo:Hide() ind.hi:Hide()
        layoutPill(ind, diff, status, 0)
        if nextText then
            ind.note:SetText(nextText)
            ind.note:ClearAllPoints()
            ind.note:SetPoint("TOPRIGHT", ind.pill, "BOTTOMRIGHT", 0, -4)
            ind.note:Show()
        end
    elseif mode == "both" then
        local text = status
        if nextText and known then text = text .. " · " .. nextText:lower() end
        layoutPill(ind, diff, text, 0)
        ind.bar:ClearAllPoints()
        ind.bar:SetPoint("TOPRIGHT", ind, "TOPRIGHT", -5, -20)
        ind.bar:Show()
        layoutBar(ind, lv, skill, 160, 5, false)
    else
        ind.bar:ClearAllPoints()
        ind.bar:SetPoint("TOPRIGHT", ind, "TOPRIGHT", -5, -7)
        ind.bar:Show()
        layoutBar(ind, lv, skill, 160, 8, true)
        if diff == "red" then
            ind.note:SetText(status)
            ind.note:ClearAllPoints()
            ind.note:SetPoint("BOTTOMRIGHT", ind.bar, "TOPRIGHT", 0, 3)
            ind.note:Show()
        end
    end
end

-- Canvas ---------------------------------------------------------------------------------
-- A scroll frame whose child is filled top-down. Elements are pooled and released on Reset.
local Canvas = {}
Canvas.__index = Canvas

function UI.ScrollCanvas(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(10, 10)
    sf:SetScrollChild(child)
    sf:SetScript("OnSizeChanged", function(self, w) child:SetWidth(w) end)
    local c = setmetatable({ scroll = sf, child = child, y = 0, pools = { text = {}, row = {} }, used = { text = {}, row = {} } }, Canvas)
    return c
end

function Canvas:Width()
    return math.max(self.child:GetWidth(), 200)
end

function Canvas:Reset(keepScroll)
    for kind, list in pairs(self.used) do
        for _, obj in ipairs(list) do
            obj:Hide()
            obj:ClearAllPoints()
            table.insert(self.pools[kind], obj)
        end
        wipe(list)
    end
    self.y = 0
    local w = self.scroll:GetWidth()
    if w and w > 0 then self.child:SetWidth(w) end
    if self.dividers then
        for _, t in ipairs(self.dividers) do t:Hide() end
    end
    self.divUsed = 0
    if not keepScroll then self.scroll:SetVerticalScroll(0) end
end

function Canvas:Space(h)
    self.y = self.y + (h or 8)
end

function Canvas:Text(text, fontKey, indent, opts)
    local fs = table.remove(self.pools.text)
    if not fs then
        fs = self.child:CreateFontString(nil, "OVERLAY")
        fs:SetWordWrap(true)
        fs:SetNonSpaceWrap(true)
    end
    table.insert(self.used.text, fs)
    fs:SetFontObject(S.fonts[fontKey or "body"])
    fs:SetJustifyH(opts and opts.justify or "LEFT")
    fs:SetTextColor(unpack(opts and opts.color or (fontKey == "small" and S.inkSoft or S.ink)))
    indent = indent or 0
    fs:SetWidth(self:Width() - indent - 8)
    fs:SetText(text)
    fs:SetPoint("TOPLEFT", self.child, "TOPLEFT", indent, -self.y)
    fs:Show()
    self.y = self.y + fs:GetStringHeight() + (opts and opts.gap or 4)
    return fs
end

-- A clickable line with an optional icon, left text, right text and a second line.
function Canvas:Row(opts)
    local r = table.remove(self.pools.row)
    if not r then
        r = CreateFrame("Button", nil, self.child)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(S.highlight[1], S.highlight[2], S.highlight[3], S.highlight[4])
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.ring = r:CreateTexture(nil, "OVERLAY")
        r.left = r:CreateFontString(nil, "OVERLAY")
        r.left:SetJustifyH("LEFT")
        r.left:SetWordWrap(false)
        r.right = r:CreateFontString(nil, "OVERLAY")
        r.right:SetJustifyH("RIGHT")
        r.sub = r:CreateFontString(nil, "OVERLAY")
        r.sub:SetJustifyH("LEFT")
        r.sub:SetWordWrap(true)
        r:SetScript("OnClick", function(self, button) if self.onClick then self.onClick(self, button) end end)
        r:SetScript("OnEnter", function(self) if self.onEnter then self.onEnter(self) end end)
        r:SetScript("OnLeave", function(self) GameTooltip_Hide() if self.onLeave then self.onLeave(self) end end)
    end
    table.insert(self.used.row, r)
    opts = opts or {}
    local indent = opts.indent or 0
    local h = opts.height or 22
    local iconSize = opts.iconSize or (h - 4)
    r:SetPoint("TOPLEFT", self.child, "TOPLEFT", indent, -self.y)
    r:SetSize(self:Width() - indent - 4, h)

    if opts.bg then r.bg:SetColorTexture(unpack(opts.bg)) r.bg:Show() else r.bg:Hide() end

    local x = 4
    if opts.icon then
        r.icon:SetTexture(opts.icon)
        r.icon:SetSize(iconSize, iconSize)
        r.icon:ClearAllPoints()
        r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 4, -2)
        r.icon:SetDesaturated(opts.desaturate or false)
        r.icon:Show()
        x = iconSize + 10
    else
        r.icon:Hide()
    end
    if opts.ring then
        r.ring:SetTexture(opts.ring)
        r.ring:SetSize(iconSize + 8, iconSize + 8)
        r.ring:ClearAllPoints()
        r.ring:SetPoint("CENTER", r.icon, "CENTER")
        r.ring:SetVertexColor(1, 0.8, 0.3)
        r.ring:Show()
    else
        r.ring:Hide()
    end

    r.left:SetFontObject(S.fonts[opts.leftFont or "body"])
    r.left:SetTextColor(unpack(opts.leftColor or S.ink))
    r.left:ClearAllPoints()
    local rowWidth = self:Width() - indent - 4
    r.left:SetPoint("TOPLEFT", r, "TOPLEFT", x, opts.sub and -3 or -((h - 12) / 2))
    r.left:SetWidth(math.max(rowWidth - x - (((opts.right and opts.right ~= "") or opts.skill or opts.cols) and (opts.rightWidth or 150) or 6), 40))
    r.left:SetText(opts.left or "")

    r.right:SetFontObject(S.fonts[opts.rightFont or "body"])
    r.right:SetTextColor(unpack(opts.rightColor or S.inkSoft))
    r.right:ClearAllPoints()
    r.right:SetPoint("TOPRIGHT", r, "TOPRIGHT", -6, opts.sub and -3 or -((h - 12) / 2))
    r.right:SetWidth(opts.rightWidth or 150)
    r.right:SetText(opts.right or "")

    r.sub:SetFontObject(S.fonts.small)
    r.sub:SetTextColor(unpack(S.inkSoft))
    r.sub:ClearAllPoints()
    if opts.sub then
        r.sub:SetPoint("TOPLEFT", r.left, "BOTTOMLEFT", 0, -2)
        r.sub:SetWidth(math.max(rowWidth - x - 6, 40))
        r.sub:SetText(opts.sub)
        r.sub:Show()
        local need = 3 + r.left:GetStringHeight() + 2 + r.sub:GetStringHeight() + 4
        if need > h then h = need r:SetHeight(h) end
    else
        r.sub:Hide()
    end

    -- Fixed-width columns laid out from the right edge: { { text, width, justify, font, color }, ... }
    r.colFs = r.colFs or {}
    for _, fs in ipairs(r.colFs) do fs:Hide() end
    if opts.cols then
        local xr = -6
        for i = #opts.cols, 1, -1 do
            local c = opts.cols[i]
            local fs = r.colFs[i]
            if not fs then
                fs = r:CreateFontString(nil, "OVERLAY")
                fs:SetWordWrap(false)
                r.colFs[i] = fs
            end
            fs:SetFontObject(S.fonts[c.font or opts.colFont or "number"])
            fs:SetTextColor(unpack(c.color or S.ink))
            fs:SetJustifyH(c.justify or "RIGHT")
            fs:SetWidth(c.width)
            fs:ClearAllPoints()
            fs:SetPoint("TOPRIGHT", r, "TOPRIGHT", xr, -((h - 12) / 2))
            fs:SetText(c.text or "")
            fs:Show()
            xr = xr - c.width - 8
        end
    end

    if opts.skill then
        UI.ShowSkill(r, opts.skill.lv, opts.skill.skill, opts.skill.known, FC.db and FC.db.skillDisplay or "bar")
    elseif r.ind then
        r.ind:Hide()
    end

    r.onClick, r.onEnter, r.onLeave = opts.onClick, opts.onEnter, opts.onLeave
    r:Show()
    self.y = self.y + h + (opts.gap or 2)
    return r
end

function Canvas:Divider()
    self.dividers = self.dividers or {}
    self.divUsed = (self.divUsed or 0) + 1
    local t = self.dividers[self.divUsed]
    if not t then
        t = S:Divider(self.child, 300)
        self.dividers[self.divUsed] = t
    end
    local w = self:Width()
    t:ClearAllPoints()
    t:SetSize(w * 0.8, 12)
    t:SetPoint("TOPLEFT", self.child, "TOPLEFT", w * 0.1, -(self.y + 4))
    t:Show()
    self.y = self.y + 20
end

function Canvas:Finish()
    self.child:SetHeight(math.max(self.y + 10, 10))
end
