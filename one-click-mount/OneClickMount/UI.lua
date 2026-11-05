local ADDON, ns = ...

-- Layout, same approach as Lueur: Blizzard's portrait frame, dark cards with
-- a tooltip border, fixed margins.
local WIDTH = 480
local EDGE = 12              -- window edge to cards
local TOP, FOOT = 94, 30     -- space above the cards (portrait + tabs) and below (status)
local GAP = 6                -- between two cards
local PAD = 16               -- inside a card
local CARD_HEAD = 40         -- card title row
local SLOT, SLOT_GAP, ROW_H = 38, 8, 50
local ICON = "Interface\\Icons\\Ability_Mount_RidingHorse"
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function CardHeight(rows) return CARD_HEAD + rows * ROW_H + 4 end

-- Everything an optional reskin (EllesmereUI) needs to reach.
local skinCards, skinRows = {}, {}

local function FromTemplate(kind, name, parent, template)
  local ok, frame = pcall(CreateFrame, kind, name, parent, template)
  return ok and frame or nil
end

local function HasAtlas(atlas)
  if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
  local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
  return ok and info ~= nil
end

---------------------------------------------------------------------------
-- Window: the game's portrait frame
---------------------------------------------------------------------------
local LOC_HEIGHT = CardHeight(3) + GAP + CardHeight(ns.MAX_CUSTOM)
local HEIGHT = TOP + LOC_HEIGHT + FOOT

local P = FromTemplate("Frame", "OneClickMountPanel", UIParent, "PortraitFrameTemplate")
if P then
  P.titleText = P.TitleContainer and P.TitleContainer.TitleText or P.TitleText
  local portrait = P.PortraitContainer and P.PortraitContainer.portrait or P.portrait
  if portrait then
    if SetPortraitToTexture then SetPortraitToTexture(portrait, ICON) else portrait:SetTexture(ICON) end
  end
  if P.CloseButton then P.CloseButton:SetScript("OnClick", function() P:Hide() end) end
else
  P = CreateFrame("Frame", "OneClickMountPanel", UIParent, "BasicFrameTemplate")
end
if not P.titleText then
  P.titleText = P:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  P.titleText:SetPoint("TOP", 0, -6)
end
P.titleText:SetText("One-Click Mount")

P:SetSize(WIDTH, HEIGHT)
P:SetPoint("CENTER")
P:SetFrameStrata("HIGH")
P:SetToplevel(true)
P:SetClampedToScreen(true)
P:SetMovable(true)
P:EnableMouse(true)
P:RegisterForDrag("LeftButton")
P:SetScript("OnDragStart", P.StartMoving)
P:SetScript("OnDragStop", P.StopMovingOrSizing)
P:Hide()
tinsert(UISpecialFrames, "OneClickMountPanel")

-- Under the title bar, right of the portrait: the page name, then who you are.
local heading = P:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
heading:SetPoint("TOPLEFT", 68, -33)

local sub = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("LEFT", heading, "RIGHT", 10, -1)
sub:SetTextColor(0.65, 0.65, 0.65)

---------------------------------------------------------------------------
-- Icon slot look (black back, icon, profession-window rim)
---------------------------------------------------------------------------
local function SkinSlot(b, size)
  b.back = b:CreateTexture(nil, "BACKGROUND")
  b.back:SetAllPoints()
  b.back:SetColorTexture(0, 0, 0, 0.85)
  b.icon = b:CreateTexture(nil, "BORDER")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  b.rim = b:CreateTexture(nil, "BORDER", nil, 1)
  b.rim:SetPoint("CENTER")
  if HasAtlas("Profession-square-frame") then
    b.rim:SetAtlas("Profession-square-frame")
    b.rim:SetSize(size + 6, size + 6)
  else
    b.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    b.rim:SetSize(size * 1.7, size * 1.7)
  end
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
end

---------------------------------------------------------------------------
-- The button you drag to your action bar
---------------------------------------------------------------------------
local out = CreateFrame("Button", nil, P)
out:SetSize(32, 32)
out:SetPoint("TOPRIGHT", -EDGE - 4, -27)
SkinSlot(out, 32)
out:RegisterForDrag("LeftButton")
out:RegisterForClicks("LeftButtonUp")
out:SetScript("OnDragStart", ns.PickupButton)
out:SetScript("OnClick", ns.PickupButton)
out:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("One-Click Mount")
  GameTooltip:AddLine("Drag this onto your action bar.", 1, 1, 1, true)
  GameTooltip:AddLine("It updates itself when you change slots, spec or zone.", 0.7, 0.7, 0.7, true)
  GameTooltip:Show()
end)
out:SetScript("OnLeave", GameTooltip_Hide)

local outLabel = P:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
outLabel:SetPoint("RIGHT", out, "LEFT", -8, 0)
outLabel:SetText("Drag to your bar")

---------------------------------------------------------------------------
-- Tabs: Blizzard's top tabs, inside the window, sitting on the cards
---------------------------------------------------------------------------
local pages = {}
local currentTab = 1
P.Tabs = {}

local function SelectTab(i)
  currentTab = i
  for j, page in ipairs(pages) do page:SetShown(j == i) end
  if PanelTemplates_SetTab and P.numTabs then
    PanelTemplates_SetTab(P, i)
  else
    for j, tab in ipairs(P.Tabs) do
      if j == i then tab:LockHighlight() else tab:UnlockHighlight() end
    end
  end
  if ns.euiSkin and ns.euiSkin.SetTabSelection then
    for j, tab in ipairs(P.Tabs) do ns.euiSkin.SetTabSelection(tab, j == i) end
  end
  if ns.RefreshUI then ns.RefreshUI() end
end

local function TopTab(i, name)
  local tabName = "OneClickMountPanelTab" .. i
  local tab = FromTemplate("Button", tabName, P, "PanelTopTabButtonTemplate")
    or FromTemplate("Button", tabName, P, "PanelTabButtonTemplate")
    or CreateFrame("Button", tabName, P, "UIPanelButtonTemplate")
  tab:SetID(i)
  tab:SetText(name)
  if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 15, nil, 90) end
  tab:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    SelectTab(i)
  end)
  if i == 1 then
    tab:SetPoint("BOTTOMLEFT", P, "TOPLEFT", EDGE + 8, -TOP)
  else
    tab:SetPoint("LEFT", P.Tabs[i - 1], "RIGHT", 2, 0)
  end
  P.Tabs[i] = tab
  return tab
end

for i, name in ipairs({ "General", "Locations" }) do
  TopTab(i, name)
  local page = CreateFrame("Frame", nil, P)
  page:SetPoint("TOPLEFT", EDGE, -TOP)
  page:SetPoint("BOTTOMRIGHT", -EDGE, FOOT)
  pages[i] = page
end
if PanelTemplates_SetNumTabs then PanelTemplates_SetNumTabs(P, #P.Tabs) end

---------------------------------------------------------------------------
-- Cards: dark panels with a tooltip border and a title, stacked
---------------------------------------------------------------------------
local CARD_BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 14,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- y is the card's top, relative to the page.
local function CreateCard(page, y, rows, titleText)
  local card = FromTemplate("Frame", nil, page, "BackdropTemplate") or CreateFrame("Frame", nil, page)
  if card.SetBackdrop then
    card:SetBackdrop(CARD_BACKDROP)
    card:SetBackdropColor(0.03, 0.03, 0.03, 0.72)
    card:SetBackdropBorderColor(0.62, 0.56, 0.46, 0.9)
  else
    local back = card:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.55)
  end
  card:SetPoint("TOPLEFT", 0, y)
  card:SetPoint("TOPRIGHT", 0, y)
  card:SetHeight(CardHeight(rows))
  card.title = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  card.title:SetPoint("TOPLEFT", PAD, -14)
  card.title:SetText(titleText)
  card.bottom = y - CardHeight(rows)
  skinCards[#skinCards + 1] = card
  return card
end

-- Top of row r inside a card.
local function RowY(r) return -CARD_HEAD - (r - 1) * ROW_H end

---------------------------------------------------------------------------
-- Dropping things into slots
---------------------------------------------------------------------------
local function EntryFromCursor()
  local t, a, b, c = GetCursorInfo()
  -- The Journal's "Summon Random Favorite Mount" button: not a real mount.
  if (t == "mount" and a == 268435455) or (t == "spell" and c == 150544) then
    return { kind = "randomfav" }
  end
  if t == "mount" then
    local id = a
    if not ns.MountInfo(id) and C_MountJournal and C_MountJournal.GetDisplayedMountID then
      id = C_MountJournal.GetDisplayedMountID(a)
    end
    if ns.MountInfo(id) then return { kind = "mount", id = id } end
  elseif t == "spell" then
    local sid = c
    if not sid and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
      local info = C_SpellBook.GetSpellBookItemInfo(a, b)
      sid = info and info.spellID
    end
    if sid then return { kind = "spell", id = sid } end
  elseif t == "item" or t == "toy" then
    local name = type(b) == "string" and b:match("%[(.-)%]")
    if not name and C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(a) end
    if not name and GetItemInfo then name = GetItemInfo(a) end
    return { kind = "item", id = a, name = name }
  end
end

local function Changed()
  ns.Rebuild()
  ns.RefreshUI()
end

local function Drop(row, index)
  if InCombatLockdown() or not row then return end
  local e = EntryFromCursor()
  if not e then
    if GetCursorInfo() then ns.SetStatus("That can't go in a slot. Use a mount, spell or item.", true) end
    return
  end
  local ok, msg = ns.Accepts(row.acceptKey, e)
  if not ok then
    -- Keep it on the cursor so it can be dropped in another row.
    UIErrorsFrame:AddMessage(msg, 1, 0.2, 0.2)
    ns.SetStatus(msg, true)
    return
  end
  local list = row.list()
  if index > #list then index = #list + 1 end
  if ns.FindEntry(list, e, index) then
    UIErrorsFrame:AddMessage("Already in this row.", 1, 0.2, 0.2)
    ns.SetStatus("Already in this row.", true)
    return
  end
  ClearCursor()
  list[index] = e
  Changed()
  if msg then ns.SetStatus(msg, true) end
end

local function Clear(row, index)
  local list = row and row.list()
  if list and list[index] then
    table.remove(list, index)
    Changed()
  end
end

-- Why a placed entry won't be used here (nil if it's fine).
local function Problem(row, e)
  local ok, msg = ns.Accepts(row.acceptKey, e)
  if not ok then return "wrongType", msg end
  if e.kind == "mount" and not ns.MountForChar(e.id) then
    return "notForChar", "This character can't use it, so it's skipped."
  end
end

---------------------------------------------------------------------------
-- Row widgets (bound to row data at refresh time)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Dragging between our own slots (no game cursor involved)
---------------------------------------------------------------------------
local allSlots = {}
local drag -- { row, index, entry, button }

local ghost = CreateFrame("Frame", nil, UIParent)
ghost:SetSize(SLOT, SLOT)
ghost:SetFrameStrata("TOOLTIP")
ghost.icon = ghost:CreateTexture(nil, "OVERLAY")
ghost.icon:SetAllPoints()
ghost.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
ghost:Hide()
ghost:SetScript("OnUpdate", function(self)
  local x, y = GetCursorPosition()
  local s = UIParent:GetEffectiveScale()
  self:ClearAllPoints()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
end)

local function EndDrag()
  if drag and drag.button then drag.button.icon:SetAlpha(1) end
  drag = nil
  ghost:Hide()
end

local function Refuse(msg)
  UIErrorsFrame:AddMessage(msg, 1, 0.2, 0.2)
  ns.SetStatus(msg, true)
end

local function Clone(e)
  return { kind = e.kind, id = e.id, name = e.name }
end

-- Move (or copy) entry from one slot to another, following each row's rules.
local function MoveEntry(src, srcIdx, dst, dstIdx, copy)
  local srcList, dstList = src.list(), dst.list()
  local e = srcList[srcIdx]
  if not e then return end
  local sameList = (srcList == dstList)
  if sameList and srcIdx == dstIdx then return end
  if dstIdx > #dstList then dstIdx = #dstList + 1 end
  local target = dstList[dstIdx]

  local ok, msg = ns.Accepts(dst.acceptKey, e)
  if not ok then return Refuse(msg) end

  if copy then
    if sameList then return Refuse("Already in this row.") end
    if ns.FindEntry(dstList, e, dstIdx) then return Refuse("Already in this row.") end
    dstList[dstIdx] = Clone(e) -- replaces whatever was in that slot
  elseif target then
    -- Swap, like action bars.
    if not sameList then
      local ok2, msg2 = ns.Accepts(src.acceptKey, target)
      if not ok2 then return Refuse("Can't swap: " .. msg2) end
      if ns.FindEntry(dstList, e, dstIdx) then return Refuse("Already in that row.") end
      if ns.FindEntry(srcList, target, srcIdx) then return Refuse("Already in this row.") end
    end
    dstList[dstIdx], srcList[srcIdx] = e, target
  else
    -- Into an empty slot.
    if not sameList and ns.FindEntry(dstList, e) then return Refuse("Already in that row.") end
    table.remove(srcList, srcIdx)
    table.insert(dstList, e)
  end
  Changed()
end

local function StartDrag(w, index, b)
  if InCombatLockdown() or GetCursorInfo() or not w.row then return end
  local e = w.row.list()[index]
  if not e then return end
  local _, icon = ns.EntryInfo(e)
  drag = { row = w.row, index = index, entry = e, button = b }
  ghost.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  ghost:Show()
  b.icon:SetAlpha(0.3)
  GameTooltip:Hide()
end

local function StopDrag()
  if not drag then return end
  local d = drag
  EndDrag()
  for _, s in ipairs(allSlots) do
    if s:IsVisible() and s:IsMouseOver() and s.w.row then
      MoveEntry(d.row, d.index, s.w.row, s.index, IsControlKeyDown())
      return
    end
  end
  -- Released outside a slot: snap back (nothing changes).
  ns.RefreshUI()
end

local function CreateSlot(w, index, x, y)
  local b = CreateFrame("Button", nil, w.parent)
  b:SetSize(SLOT, SLOT)
  b:SetPoint("TOPLEFT", x, y)
  SkinSlot(b, SLOT)

  b.plus = b:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
  b.plus:SetTextColor(0.45, 0.45, 0.45)
  b.plus:SetPoint("CENTER")
  b.plus:SetText("+")

  b.tag = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.tag:SetPoint("BOTTOM", 0, 2)

  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b.w, b.index = w, index
  allSlots[#allSlots + 1] = b
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function(self) StartDrag(w, index, self) end)
  b:SetScript("OnDragStop", StopDrag)
  b:SetScript("OnReceiveDrag", function() Drop(w.row, index) end)
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then Clear(w.row, index)
    elseif GetCursorInfo() then Drop(w.row, index) end
  end)
  b:SetScript("OnEnter", function(self)
    local row = w.row
    if not row then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local placed = row.list()[index]
    local e = placed or self.autoEntry
    if e and e.kind == "item" then
      GameTooltip:SetItemByID(e.id)
    elseif e then
      local _, _, sid = ns.EntryInfo(e)
      if sid then GameTooltip:SetSpellByID(sid) end
    end
    if self.autoEntry and not placed then
      GameTooltip:AddLine("Picked automatically for your class and spec.", 0.4, 0.8, 1, true)
      GameTooltip:AddLine("Drop a spell here to override.", 0.7, 0.7, 0.7, true)
    elseif placed then
      local _, why = Problem(row, placed)
      if why then GameTooltip:AddLine(why, 1, 0.3, 0.3, true) end
      GameTooltip:AddLine("Drag to move. Hold Ctrl when you let go to copy.", 0.7, 0.7, 0.7, true)
      GameTooltip:AddLine("Right-click to clear.", 0.7, 0.7, 0.7)
    else
      GameTooltip:AddLine(row.label)
      GameTooltip:AddLine(row.emptyHint or "Drop a mount, spell or item here.", 1, 1, 1, true)
      if row.slots > 1 then
        GameTooltip:AddLine("Several in one row are picked at random.", 0.7, 0.7, 0.7, true)
      end
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  return b
end

local function CreateRow(parent, y, nSlots, removable, first)
  local w = { parent = parent, slots = {} }
  local mid = y - ROW_H / 2 -- vertical centre of the row

  if not first then
    w.line = parent:CreateTexture(nil, "ARTWORK")
    w.line:SetColorTexture(1, 1, 1, 0.07)
    w.line:SetHeight(1)
    w.line:SetPoint("TOPLEFT", PAD, y)
    w.line:SetPoint("TOPRIGHT", -PAD, y)
  end

  w.check = FromTemplate("CheckButton", nil, parent, "MinimalCheckboxTemplate")
    or CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  w.check:SetSize(26, 26)
  w.check:SetPoint("LEFT", parent, "TOPLEFT", PAD - 4, mid)
  w.check:SetScript("OnClick", function(self)
    if InCombatLockdown() or not w.row then
      self:SetChecked(not self:GetChecked())
      return
    end
    local on = self:GetChecked()
    PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    w.row.setOn(on)
    Changed()
  end)
  w.check:SetScript("OnEnter", function(self)
    if not w.row then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(w.row.label)
    GameTooltip:AddLine("Turn this rule on or off.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  w.check:SetScript("OnLeave", GameTooltip_Hide)

  w.label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  w.label:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", PAD + 26, mid + 1)
  w.label:SetWidth(122)
  w.label:SetJustifyH("LEFT")
  w.label:SetWordWrap(false)

  w.hint = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  w.hint:SetPoint("TOPLEFT", w.label, "BOTTOMLEFT", 0, -3)
  w.hint:SetTextColor(0.6, 0.6, 0.6)

  for i = 1, nSlots do
    w.slots[i] = CreateSlot(w, i, 170 + (i - 1) * (SLOT + SLOT_GAP), mid + SLOT / 2)
  end

  w.note = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  w.note:SetJustifyH("RIGHT")
  w.note:SetWidth(removable and 66 or 86)
  w.note:SetPoint("RIGHT", parent, "TOPRIGHT", removable and -38 or -PAD, mid)

  if removable then
    w.remove = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    w.remove:SetSize(24, 24)
    w.remove:SetPoint("RIGHT", parent, "TOPRIGHT", -10, mid)
    w.remove:SetScript("OnClick", function()
      if InCombatLockdown() or not w.row then return end
      w.row.onRemove()
      Changed()
    end)
    w.remove:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Remove this zone rule")
      GameTooltip:Show()
    end)
    w.remove:SetScript("OnLeave", GameTooltip_Hide)
  end

  function w:SetShown(shown)
    for _, k in ipairs({ "line", "check", "label", "hint", "note", "remove" }) do
      if self[k] then self[k]:SetShown(shown) end
    end
    for _, b in ipairs(self.slots) do b:SetShown(shown) end
  end

  skinRows[#skinRows + 1] = w
  return w
end

local function RefreshRow(w, row, active)
  w.row = row
  if not row then w:SetShown(false) return end
  w:SetShown(true)

  local list = row.list()
  local auto = row.auto and ns.ClassDefault(row.auto)
  for i, b in ipairs(w.slots) do
    local e = list[i]
    b.autoEntry = nil
    b.tag:SetText("")
    b.icon:SetDesaturated(false)
    b.icon:SetAlpha(1)
    b.icon:SetVertexColor(1, 1, 1)
    if e then
      local _, icon = ns.EntryInfo(e)
      b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      b.plus:Hide()
      local problem = Problem(row, e)
      if problem == "wrongType" then
        b.icon:SetVertexColor(1, 0.25, 0.25)
        b.tag:SetText("|cffff4040Wrong|r")
      elseif problem == "notForChar" then
        b.icon:SetDesaturated(true)
        b.icon:SetAlpha(0.5)
        b.tag:SetText("Skipped")
      end
    elseif i == 1 and auto then
      local _, icon = ns.EntryInfo(auto)
      b.autoEntry = auto
      b.icon:SetTexture(icon)
      b.icon:SetDesaturated(true)
      b.icon:SetAlpha(0.7)
      b.tag:SetText("Auto")
      b.plus:Hide()
    else
      b.icon:SetTexture(nil)
      b.plus:Show()
    end
    -- Only the filled slots plus the next free one, keeps rows tidy.
    b:SetShown(i <= #list + 1)
  end

  local enabled = row.isOn()
  local note = row.note and row.note(list, auto) or ""
  w.check:SetChecked(enabled)
  w.label:SetText(row.label)
  w.hint:SetText(active and "|cff40ff40Active here|r" or row.hint)
  if not enabled then
    w.label:SetTextColor(0.5, 0.5, 0.5)
    note = "Off"
  elseif active then
    w.label:SetTextColor(0.25, 1, 0.25)
  else
    w.label:SetTextColor(1, 0.82, 0)
  end
  for _, b in ipairs(w.slots) do b:SetAlpha(enabled and 1 or 0.35) end
  w.note:SetText(note)
end

local function PoolNote(emptyText)
  return function(list)
    if #list == 0 then return emptyText end
    if #list > 1 then return "Random of " .. #list end
    return ns.EntryInfo(list[1]) or ""
  end
end

---------------------------------------------------------------------------
-- General tab
---------------------------------------------------------------------------
local function GeneralRow(key, label, hint, slots, opts)
  opts = opts or {}
  return {
    label = label, hint = hint, slots = slots, acceptKey = key,
    auto = opts.auto and key or nil, emptyHint = opts.emptyHint,
    list = function() return ns.Slots(key) end,
    isOn = function() return ns.IsEnabled(key) end,
    setOn = function(v) ns.SetEnabled(key, v) end,
    note = opts.note or PoolNote(""),
  }
end

local GENERAL = {
  GeneralRow("flying", "Flying", "Where you can fly", 4,
    { note = PoolNote("Empty: random favorite"), emptyHint = "Drop a flying mount here." }),
  GeneralRow("ground", "Ground", "No-fly zones", 4,
    { note = PoolNote("Empty: random favorite"), emptyHint = "Drop a ground mount here." }),
  GeneralRow("combat", "Combat / indoors", "Class speed spell", 1, {
    auto = true,
    note = function(list, auto)
      local e = list[1] or auto
      return (e and ns.EntryInfo(e)) or "None for your class"
    end,
  }),
  GeneralRow("shift", "Shift", "Vendor, passenger...", 4),
  GeneralRow("ctrl", "Ctrl", "Anything", 4),
  GeneralRow("alt", "Alt", "Anything", 4),
}

local generalWidgets = {}
local mountsCard = CreateCard(pages[1], 0, 3, "Mounts")
local modsCard = CreateCard(pages[1], mountsCard.bottom - GAP, 3, "Modifiers")
for r = 1, #GENERAL do
  local card = (r <= 3) and mountsCard or modsCard
  local k = (r <= 3) and r or (r - 3)
  generalWidgets[r] = CreateRow(card, RowY(k), GENERAL[r].slots, false, k == 1)
end

local modsHint = modsCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
modsHint:SetPoint("TOPRIGHT", -PAD, -16)
modsHint:SetTextColor(0.6, 0.6, 0.6)
modsHint:SetText("Hold a key while clicking. Works everywhere.")

local help = pages[1]:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
help:SetPoint("TOPLEFT", 4, modsCard.bottom - 10)
help:SetPoint("TOPRIGHT", -4, modsCard.bottom - 10)
help:SetJustifyH("LEFT")
help:SetTextColor(0.6, 0.6, 0.6)
help:SetText("Flying takes flying mounts, Ground takes ground mounts, modifier rows take anything. Mounts a character can't use are skipped. Drag a slot to move it, right-click to clear it.")

---------------------------------------------------------------------------
-- Locations tab
---------------------------------------------------------------------------
local function PresetRow(key, label, hint, slots, opts)
  return {
    label = label, hint = hint, slots = slots, acceptKey = opts.acceptKey, emptyHint = opts.emptyHint,
    list = function()
      local p = ns.LocDB().presets[key]
      if slots == 0 then return {} end
      p.slots = p.slots or {}
      return p.slots
    end,
    isOn = function() return ns.LocDB().presets[key].enabled end,
    setOn = function(v) ns.LocDB().presets[key].enabled = v and true or false end,
    note = opts.note,
    locKey = key,
  }
end

local PRESETS = {
  PresetRow("aq", "Ahn'Qiraj", "Qiraji tanks only", 4, {
    acceptKey = "loc:aq",
    emptyHint = "Drop a Qiraji battle tank here.",
    note = PoolNote("Empty: random tank"),
  }),
  PresetRow("undermine", "Undermine", "G-99, or your mounts", 4, {
    acceptKey = "loc:undermine",
    emptyHint = "Drop a ground mount to use instead of the G-99.",
    note = function(list)
      if #list > 0 then return PoolNote("")(list) end
      if ns.G99Active() then return "G-99 ready" end
      if ns.G99Unlocked() then return "G-99 unlocked" end
      return "G-99 not unlocked"
    end,
  }),
  PresetRow("vashjir", "Vashj'ir", "Underwater only", 4, {
    acceptKey = "loc:vashjir",
    emptyHint = "Drop an underwater mount here. Used only while swimming in Vashj'ir.",
    note = PoolNote("Empty: seahorse first"),
  }),
}

local locWidgets = {}
local presetCard = CreateCard(pages[2], 0, #PRESETS, "Special zones")
for r = 1, #PRESETS do
  locWidgets[r] = CreateRow(presetCard, RowY(r), PRESETS[r].slots, false, r == 1)
end

local zonesCard = CreateCard(pages[2], presetCard.bottom - GAP, ns.MAX_CUSTOM, "Your zones")

local addBtn = CreateFrame("Button", nil, zonesCard, "UIPanelButtonTemplate")
addBtn:SetSize(150, 22)
addBtn:SetPoint("TOPRIGHT", -PAD + 4, -9)
addBtn:SetText("Add current zone")
addBtn:SetScript("OnClick", function()
  if InCombatLockdown() then return end
  local ok, msg = ns.AddCurrentZone()
  if not ok then
    UIErrorsFrame:AddMessage(msg, 1, 0.2, 0.2)
    ns.SetStatus(msg, true)
    return
  end
  Changed()
end)
if addBtn.SetMotionScriptsWhileDisabled then addBtn:SetMotionScriptsWhileDisabled(true) end
addBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  local special = ns.SpecialZoneHere()
  local _, name = ns.CurrentZone()
  if special then
    GameTooltip:AddLine(special .. " is a special zone")
    GameTooltip:AddLine("Set its mounts in Special zones above.", 1, 1, 1, true)
  elseif #ns.LocDB().custom >= ns.MAX_CUSTOM then
    GameTooltip:AddLine("All " .. ns.MAX_CUSTOM .. " zone rules are in use")
    GameTooltip:AddLine("Remove one to add this zone.", 1, 1, 1, true)
  else
    GameTooltip:AddLine("Add " .. (name or "this zone"))
    GameTooltip:AddLine("Mounts you drop here are used in this zone, including its buildings and caves.", 1, 1, 1, true)
  end
  GameTooltip:Show()
end)
addBtn:SetScript("OnLeave", GameTooltip_Hide)

local customWidgets = {}
for i = 1, ns.MAX_CUSTOM do
  customWidgets[i] = CreateRow(zonesCard, RowY(i), 4, true, i == 1)
end

local emptyCustom = zonesCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
emptyCustom:SetPoint("TOPLEFT", PAD, RowY(1) - 6)
emptyCustom:SetPoint("TOPRIGHT", -PAD, RowY(1) - 6)
emptyCustom:SetJustifyH("LEFT")
emptyCustom:SetTextColor(0.6, 0.6, 0.6)
emptyCustom:SetText("Stand in a zone and press Add current zone to give it its own mounts. Zone rules beat Flying and Ground; Shift, Ctrl, Alt and Combat still work everywhere.")

local function CustomRow(i, rule)
  return {
    label = rule.name or ("Zone " .. rule.mapID), hint = "Any mount", slots = 4, acceptKey = "custom",
    emptyHint = "Drop a mount for this zone.",
    list = function() rule.slots = rule.slots or {}; return rule.slots end,
    isOn = function() return rule.enabled ~= false end,
    setOn = function(v) rule.enabled = v and true or false end,
    note = PoolNote("Add a mount"),
    onRemove = function() table.remove(ns.LocDB().custom, i) end,
    locKey = "custom:" .. i,
  }
end

---------------------------------------------------------------------------
-- Status and refresh
---------------------------------------------------------------------------
local status = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
status:SetPoint("BOTTOMLEFT", EDGE + 4, 10)

-- Footer credit, bottom right (like Lueur's version line).
local credit = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
credit:SetPoint("BOTTOMRIGHT", -EDGE - 4, 10)
credit:SetTextColor(0.55, 0.55, 0.55)
do
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = getMeta and getMeta(ADDON, "Version")
  credit:SetText("v" .. (version or "?") .. "  ·  Created by Lurx")
end

function ns.UpdateStatus()
  status:SetText(ns.statusText or "")
  if ns.statusError then status:SetTextColor(1, 0.4, 0.4) else status:SetTextColor(0.5, 0.9, 0.5) end
end

local function HeadingText()
  local className = UnitClass("player")
  local spec = ""
  if GetSpecialization and GetSpecializationInfo then
    local i = GetSpecialization()
    if i then
      local _, name = GetSpecializationInfo(i)
      if name then spec = " · " .. name end
    end
  end
  return (className or "") .. spec
end

function ns.RefreshUI()
  if not P:IsShown() then return end
  heading:SetText(HeadingText())
  sub:SetText((select(4, GetBuildInfo()) < 100000) and "Forever" or "Retail")
  out.icon:SetTexture(ns.previewIcon or ICON)

  if currentTab == 1 then
    for r, w in ipairs(generalWidgets) do RefreshRow(w, GENERAL[r], false) end
  else
    local here = ns.LocationHere()
    for r, w in ipairs(locWidgets) do
      local row = PRESETS[r]
      RefreshRow(w, row, ns.activeLocation == row.locKey or (here[row.locKey] and row.isOn()))
    end
    local custom = ns.LocDB().custom
    for i, w in ipairs(customWidgets) do
      local rule = custom[i]
      local row = rule and CustomRow(i, rule)
      RefreshRow(w, row, row and here[row.locKey] and row.isOn())
    end
    emptyCustom:SetShown(#custom == 0)
    if #custom >= ns.MAX_CUSTOM or ns.SpecialZoneHere() then addBtn:Disable() else addBtn:Enable() end
  end
  ns.UpdateStatus()
end

P:SetScript("OnShow", function() SelectTab(currentTab); ns.Rebuild(); ns.RefreshUI() end)
P:HookScript("OnHide", EndDrag)

---------------------------------------------------------------------------
-- Open / close, and the combat rule
---------------------------------------------------------------------------
function ns.Toggle(show)
  if InCombatLockdown() then
    UIErrorsFrame:AddMessage("One-Click Mount: available after combat", 1, 0.82, 0)
    return
  end
  if show == nil then show = not P:IsShown() end
  P:SetShown(show)
end

local reopen = false
function ns.OnCombatStart()
  EndDrag()
  reopen = P:IsShown()
  if reopen then
    ClearCursor()
    P:Hide()
  end
end

function ns.OnCombatEnd()
  if reopen then
    reopen = false
    P:Show()
  end
end

---------------------------------------------------------------------------
-- Entry in Esc > Options > AddOns that just opens our panel
---------------------------------------------------------------------------
if Settings and Settings.RegisterCanvasLayoutCategory then
  local cp = CreateFrame("Frame")
  local btn = CreateFrame("Button", nil, cp, "UIPanelButtonTemplate")
  btn:SetSize(220, 26)
  btn:SetPoint("TOPLEFT", 16, -16)
  btn:SetText("Open One-Click Mount")
  btn:SetScript("OnClick", function()
    if InCombatLockdown() then ns.Toggle(true) return end
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    ns.Toggle(true)
  end)
  local category = Settings.RegisterCanvasLayoutCategory(cp, "One-Click Mount")
  Settings.RegisterAddOnCategory(category)
end

---------------------------------------------------------------------------
-- Optional EllesmereUI skin. Uses EllesmereUI's public skinning API, so it
-- follows the user's EUI theme, accent and font, and can be turned off in
-- EllesmereUI's options (Blizzard Skins+ > Window Skins > Third-Party Addons).
-- Without EllesmereUI this does nothing.
---------------------------------------------------------------------------
if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin(ADDON, function(S)
    ns.euiSkin = S
    S.Shell(P)
    if P.CloseButton then S.CloseButton(P.CloseButton) end
    for _, tab in ipairs(P.Tabs) do S.Tab(tab) end
    if S.SetTabSelection then
      for j, tab in ipairs(P.Tabs) do S.SetTabSelection(tab, j == currentTab) end
    end

    for _, card in ipairs(skinCards) do
      if card.SetBackdrop then card:SetBackdrop(nil) end
      S.Panel(card, { inset = true })
      S.Font(card.title)
    end

    local function SkinSlot(b)
      if b.rim then b.rim:SetAlpha(0) end
      S.SquareIcon(b.icon, b)
    end
    for _, b in ipairs(allSlots) do SkinSlot(b) end
    SkinSlot(out)

    for _, w in ipairs(skinRows) do
      S.Checkbox(w.check)
      S.Font(w.label)
      S.Font(w.hint)
      S.Font(w.note)
      if w.remove then S.CloseButton(w.remove) end
    end

    S.Button(addBtn)
    S.WhiteButtonLabel(addBtn)
    for _, fs in ipairs({ heading, sub, outLabel, modsHint, help, emptyCustom, status, credit }) do
      S.Font(fs)
    end
  end)
end
