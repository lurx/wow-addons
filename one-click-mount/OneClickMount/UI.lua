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
local SUB_H, SUB_INDENT = 24, 20 -- compact sub-rows (an option under a rule)
local ICON = "Interface\\Icons\\inv_horse3saddle008_brown"
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function CardHeight(rows) return CARD_HEAD + rows * ROW_H + 4 end

-- Everything an optional reskin (EllesmereUI) needs to reach.
local skinCards, skinRows = {}, {}

-- Skin helpers: no-ops until EllesmereUI hands us its skinning facade
-- (ns.euiSkin). Called at creation time too, so pages built later (like
-- EllesmereUI's own options pages, built when first opened) get skinned.
-- Every FontString we create is listed here, so EllesmereUI's font (whatever
-- the user picked from its list) can be re-applied to all of them whenever one
-- of our pages opens. Without EllesmereUI, nothing is touched: Blizzard fonts.
local fonts = {}

-- The user's global EllesmereUI font. (The skin API's S.Font uses the font
-- of EllesmereUI's Blizzard-skin module, which can differ from the global one.)
local function EUIFont(fs)
  local S = ns.euiSkin
  if not S or not fs or not fs.GetFont then return end
  local path = EllesmereUI and EllesmereUI.GetFontPath and EllesmereUI.GetFontPath()
  if not path then S.Font(fs) return end
  local _, size = fs:GetFont()
  local _, flag = S.GetFont()
  fs:SetFont(path, size or 12, flag or "")
end

local function SkinText(fs)
  if not fs then return end
  if not fonts[fs] then fonts[fs] = true; fonts[#fonts + 1] = fs end
  EUIFont(fs)
end

-- /ocm font: what the font step sees (for troubleshooting).
function ns.DebugFont()
  local p = function(...) print("|cff66ccffOCM font:|r", ...) end
  p("skin active:", ns.euiSkin and "yes" or "no", " registered texts:", #fonts)
  if EllesmereUI then
    p("GetFontPath():", tostring(EllesmereUI.GetFontPath and EllesmereUI.GetFontPath()))
    p("GetFontName():", tostring(EllesmereUI.GetFontName and EllesmereUI.GetFontName()))
  else
    p("EllesmereUI not loaded")
  end
  if ns.euiSkin then p("skin S.GetFont():", tostring((ns.euiSkin.GetFont()))) end
  local fs = fonts[1]
  if fs then
    p("first text now uses:", tostring((fs:GetFont())))
    local path = EllesmereUI and EllesmereUI.GetFontPath and EllesmereUI.GetFontPath()
    if path then
      local ok = fs:SetFont(path, select(2, fs:GetFont()) or 12, "")
      p("SetFont with that path returned:", tostring(ok), " now:", tostring((fs:GetFont())))
    end
  end
end

local function ApplyFonts()
  if not ns.euiSkin then return end
  for i = 1, #fonts do EUIFont(fonts[i]) end
end

local function SkinCard(card)
  local S = ns.euiSkin
  if not S or card.euiSkinned then return end
  card.euiSkinned = true
  if card.SetBackdrop then card:SetBackdrop(nil) end
  S.Panel(card, { inset = true })
  SkinText(card.title)
end

local function SkinIconSlot(b)
  local S = ns.euiSkin
  if not S or not b then return end
  if b.rim then b.rim:SetAlpha(0) end
  S.SquareIcon(b.icon, b)
end

local function SkinButton(btn)
  local S = ns.euiSkin
  if not S or not btn then return end
  S.Button(btn)
  S.WhiteButtonLabel(btn)
end

-- EllesmereUI-style switch (dark track, square knob, accent colour when on).
-- Drawn by us: EllesmereUI's own switch lives in its load-on-demand options.
local switches = {}
local function PaintSwitch(sw)
  local r, g, b = 0.05, 0.82, 0.62
  if ns.euiSkin then r, g, b = ns.euiSkin.GetAccentColor() end
  sw.knob:ClearAllPoints()
  if sw.on then
    sw.track:SetColorTexture(r, g, b, 0.85)
    sw.knob:SetColorTexture(1, 1, 1, 1)
    sw.knob:SetPoint("RIGHT", sw, "RIGHT", -2, 0)
  else
    sw.track:SetColorTexture(0.22, 0.22, 0.22, 1)
    sw.knob:SetColorTexture(0.6, 0.6, 0.6, 1)
    sw.knob:SetPoint("LEFT", sw, "LEFT", 2, 0)
  end
end

local function SkinRowWidgets(w)
  local S = ns.euiSkin
  if not S or w.switch then return end
  local sw = CreateFrame("Button", nil, w.parent)
  local indent = w.compact and SUB_INDENT or 0
  sw:SetSize(w.compact and 24 or 30, w.compact and 12 or 16)
  sw:SetPoint("LEFT", w.parent, "TOPLEFT", 16 + indent, w.mid)
  sw.track = sw:CreateTexture(nil, "BACKGROUND")
  sw.track:SetAllPoints()
  sw.knob = sw:CreateTexture(nil, "ARTWORK")
  sw.knob:SetSize(w.compact and 8 or 12, w.compact and 8 or 12)
  function sw:SetChecked(on) self.on = on and true or false; PaintSwitch(self) end
  sw:SetScript("OnClick", function() w.Toggle() end)
  sw:SetScript("OnEnter", w.check:GetScript("OnEnter"))
  sw:SetScript("OnLeave", GameTooltip_Hide)
  sw:SetChecked(w.check:GetChecked())
  switches[#switches + 1] = sw
  w.switch = sw
  w.check:Hide()
  w.label:ClearAllPoints()
  if w.compact then
    w.label:SetPoint("LEFT", sw, "RIGHT", 6, 0)
  else
    w.label:SetPoint("BOTTOMLEFT", w.parent, "TOPLEFT", 16 + 38, w.mid + 1)
    w.label:SetWidth(112)
  end
  SkinText(w.label)
  SkinText(w.hint)
  SkinText(w.note)
  if w.remove then S.CloseButton(w.remove) end
end

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
local N_PRESETS = ns.CLASSIC_RULES and 1 or 3 -- Forever/Classic: Ahn'Qiraj only
local LOC_HEIGHT = CardHeight(N_PRESETS) + GAP + CardHeight(ns.MAX_CUSTOM)
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
SkinText(P.titleText)

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
SkinText(heading)
SkinText(sub)

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
-- A drag-to-bar button: picks up the One-Click Mount macro.
local function MakeDragButton(parent, size)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(size, size)
  SkinSlot(btn, size)
  SkinIconSlot(btn)
  btn:RegisterForDrag("LeftButton")
  btn:RegisterForClicks("LeftButtonUp")
  btn:SetScript("OnDragStart", ns.PickupButton)
  btn:SetScript("OnClick", ns.PickupButton)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("One-Click Mount")
    GameTooltip:AddLine("Drag this onto your action bar.", 1, 1, 1, true)
    GameTooltip:AddLine("It updates itself when you change slots, spec or zone.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)
  return btn
end

local out = MakeDragButton(P, 32)
out:SetPoint("TOPRIGHT", -EDGE - 4, -27)

local outLabel = P:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
outLabel:SetPoint("RIGHT", out, "LEFT", -8, 0)
outLabel:SetText("Drag to your bar")
SkinText(outLabel)

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
  SkinText(tab:GetFontString())
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
local function CreateCard(page, y, rows, titleText, extraH)
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
  card:SetHeight(CardHeight(rows) + (extraH or 0))
  card.title = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  card.title:SetPoint("TOPLEFT", PAD, -14)
  card.title:SetText(titleText)
  SkinText(card.title)
  card.bottom = y - CardHeight(rows) - (extraH or 0)
  skinCards[#skinCards + 1] = card
  SkinCard(card)
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
  SkinText(b.plus)
  SkinText(b.tag)
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
  SkinIconSlot(b)
  return b
end

local function CreateRow(parent, y, nSlots, removable, first, compact)
  local w = { parent = parent, slots = {} }
  local mid = y - (compact and SUB_H or ROW_H) / 2 -- vertical centre of the row
  w.compact = compact
  local indent = compact and SUB_INDENT or 0
  w.mid = mid

  -- Flip this row's rule (used by the EllesmereUI switch).
  function w.Toggle()
    if InCombatLockdown() or not w.row then return end
    local on = not w.row.isOn()
    PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    w.row.setOn(on)
    Changed()
  end

  if not first and not compact then
    w.line = parent:CreateTexture(nil, "ARTWORK")
    w.line:SetColorTexture(1, 1, 1, 0.07)
    w.line:SetHeight(1)
    w.line:SetPoint("TOPLEFT", PAD, y)
    w.line:SetPoint("TOPRIGHT", -PAD, y)
  end

  w.check = FromTemplate("CheckButton", nil, parent, "MinimalCheckboxTemplate")
    or CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  w.check:SetSize(compact and 20 or 26, compact and 20 or 26)
  w.check:SetPoint("LEFT", parent, "TOPLEFT", PAD - 4 + indent, mid)
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

  w.label = parent:CreateFontString(nil, "ARTWORK", compact and "GameFontNormalSmall" or "GameFontNormal")
  if compact then
    w.label:SetPoint("LEFT", w.check, "RIGHT", 2, 0)
  else
    w.label:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", PAD + 26, mid + 1)
  end
  w.label:SetWidth(122)
  w.label:SetJustifyH("LEFT")
  w.label:SetWordWrap(false)

  w.hint = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  if compact then
    w.hint:SetPoint("LEFT", w.label, "RIGHT", 8, 0) -- same line, after the label
  else
    w.hint:SetPoint("TOPLEFT", w.label, "BOTTOMLEFT", 0, -3)
  end
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
    for _, k in ipairs({ "line", "check", "switch", "label", "hint", "note", "remove" }) do
      if self[k] then self[k]:SetShown(shown and not (k == "check" and self.switch)) end
    end
    for _, b in ipairs(self.slots) do b:SetShown(shown) end
  end

  skinRows[#skinRows + 1] = w
  SkinText(w.label)
  SkinText(w.hint)
  SkinText(w.note)
  SkinRowWidgets(w)
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
  if w.switch then w.switch:SetChecked(enabled) end
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
-- Pages as builders. Each one renders into whatever frame it's given, so the
-- same pages appear in our window and in EllesmereUI's options panel. All of
-- them read the same saved data and refresh together.
---------------------------------------------------------------------------
local views, headers = {}, {}

local function RefreshViews()
  for _, v in ipairs(views) do
    if v.frame:IsVisible() then v:Refresh() end
  end
end

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
  {
    label = "Dismount while flying", hint = "mid-air clicks drop you", slots = 0, compact = true,
    list = function() return {} end,
    isOn = function() return ns.AllowFlyingDismount() end,
    setOn = function(v) ns.SetAllowFlyingDismount(v) end,
    note = function() return "" end,
  },
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

-- Which card each row sits in.
for i, row in ipairs(GENERAL) do row.group = (i <= 4) and "mounts" or "mods" end

-- No flying (Forever, Classic Era): drop Flying and its sub-row, and Ground
-- becomes the one mount row, used everywhere.
if not ns.HAS_FLYING then
  for i = #GENERAL, 1, -1 do
    local row = GENERAL[i]
    if row.acceptKey == "flying" or row.compact then table.remove(GENERAL, i) end
  end
  for _, row in ipairs(GENERAL) do
    if row.acceptKey == "ground" then
      row.label, row.hint = "Mount", "Everywhere"
      row.emptyHint = "Drop a mount here, from the Mount Journal or your bags."
    end
  end
end

-- General page: Mounts and Modifiers cards. Returns the view and its height.
local function BuildGeneral(parent)
  local v = { frame = parent, widgets = {} }
  -- Mounts card: Flying (+ its sub-row), Ground, Combat; Modifiers card: Shift/Ctrl/Alt.
  local full, compact, mods = 0, 0, 0
  for _, row in ipairs(GENERAL) do
    if row.group == "mods" then mods = mods + 1
    elseif row.compact then compact = compact + 1
    else full = full + 1 end
  end
  local mountsCard = CreateCard(parent, 0, full, "Mounts", compact * SUB_H)
  local modsCard = CreateCard(parent, mountsCard.bottom - GAP, mods, "Modifiers")
  local y, firstIn = -CARD_HEAD, { mounts = true, mods = true }
  local lastGroup
  for r = 1, #GENERAL do
    local row = GENERAL[r]
    local card = (row.group == "mods") and modsCard or mountsCard
    if row.group ~= lastGroup then y = -CARD_HEAD; lastGroup = row.group end
    local first = firstIn[row.group]
    firstIn[row.group] = false
    v.widgets[r] = CreateRow(card, y, row.slots, false, first, row.compact)
    y = y - (row.compact and SUB_H or ROW_H)
  end

  v.modsHint = modsCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  v.modsHint:SetPoint("TOPRIGHT", -PAD, -16)
  v.modsHint:SetTextColor(0.6, 0.6, 0.6)
  v.modsHint:SetText("Hold a key while clicking. Works everywhere.")

  v.help = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  v.help:SetPoint("TOPLEFT", 4, modsCard.bottom - 10)
  v.help:SetPoint("TOPRIGHT", -4, modsCard.bottom - 10)
  v.help:SetJustifyH("LEFT")
  v.help:SetTextColor(0.6, 0.6, 0.6)
  v.help:SetText("Flying takes flying mounts, Ground takes ground mounts, modifier rows take anything. Mounts a character can't use are skipped. Drag a slot to move it, right-click to clear it.")
  SkinText(v.modsHint)
  SkinText(v.help)

  function v:Refresh()
    for r, w in ipairs(self.widgets) do RefreshRow(w, GENERAL[r], false) end
  end
  views[#views + 1] = v
  return v, -modsCard.bottom + 44
end

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

-- Forever / Classic Era have no Undermine or Vashj'ir.
if ns.CLASSIC_RULES then
  for i = #PRESETS, 1, -1 do
    if PRESETS[i].locKey ~= "aq" then table.remove(PRESETS, i) end
  end
  PRESETS[1].emptyHint = "Drop a Qiraji battle tank here, from the Mount Journal or your bags."
end

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

-- Locations page: Special zones and Your zones cards.
local function BuildLocations(parent)
  local v = { frame = parent, presets = {}, custom = {} }
  local presetCard = CreateCard(parent, 0, #PRESETS, "Special zones")
  for r = 1, #PRESETS do
    v.presets[r] = CreateRow(presetCard, RowY(r), PRESETS[r].slots, false, r == 1)
  end

  local zonesCard = CreateCard(parent, presetCard.bottom - GAP, ns.MAX_CUSTOM, "Your zones")

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
  SkinButton(addBtn)
  SkinText(addBtn:GetFontString())
  v.addBtn = addBtn

  for i = 1, ns.MAX_CUSTOM do
    v.custom[i] = CreateRow(zonesCard, RowY(i), 4, true, i == 1)
  end

  v.empty = zonesCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  v.empty:SetPoint("TOPLEFT", PAD, RowY(1) - 6)
  v.empty:SetPoint("TOPRIGHT", -PAD, RowY(1) - 6)
  v.empty:SetJustifyH("LEFT")
  v.empty:SetTextColor(0.6, 0.6, 0.6)
  v.empty:SetText("Stand in a zone and press Add current zone to give it its own mounts. Zone rules beat Flying and Ground; Shift, Ctrl, Alt and Combat still work everywhere.")
  SkinText(v.empty)

  function v:Refresh()
    local here = ns.LocationHere()
    for r, w in ipairs(self.presets) do
      local row = PRESETS[r]
      RefreshRow(w, row, ns.activeLocation == row.locKey or (here[row.locKey] and row.isOn()))
    end
    local custom = ns.LocDB().custom
    for i, w in ipairs(self.custom) do
      local rule = custom[i]
      local row = rule and CustomRow(i, rule)
      RefreshRow(w, row, row and here[row.locKey] and row.isOn())
    end
    self.empty:SetShown(#custom == 0)
    if #custom >= ns.MAX_CUSTOM or ns.SpecialZoneHere() then self.addBtn:Disable() else self.addBtn:Enable() end
  end
  views[#views + 1] = v
  return v, -zonesCard.bottom + 4
end

-- Our own window shows one of each.
BuildGeneral(pages[1])
BuildLocations(pages[2])

---------------------------------------------------------------------------
-- Settings switcher: "Shared" or "<Name> only" (name in class colour)
---------------------------------------------------------------------------
local function ClassColoredName()
  local name = UnitName("player") or "?"
  local _, class = UnitClass("player")
  local color = class and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class)
  if color then return color:WrapTextInColorCode(name) end
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c and c.colorStr then return "|c" .. c.colorStr .. name .. "|r" end
  return name
end

local function SetOwnSettings(on)
  if InCombatLockdown() then return end
  if on == ns.UsesOwnSettings() then return end
  ns.SetUseOwnSettings(on)
  Changed()
end

local switchers = {}
local function MakeSettingsSwitcher(parent)
  local dd = FromTemplate("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
  if dd and dd.SetupMenu then
    dd:SetWidth(160)
    dd:SetupMenu(function(_, root)
      root:CreateRadio("Shared",
        function() return not ns.UsesOwnSettings() end,
        function() SetOwnSettings(false) end)
      root:CreateRadio(ClassColoredName() .. " only",
        function() return ns.UsesOwnSettings() end,
        function() SetOwnSettings(true) end)
    end)
    function dd:RefreshSwitch() self:GenerateMenu() end
  else
    if dd then dd:Hide() end
    dd = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dd:SetSize(160, 22)
    dd:SetScript("OnClick", function() SetOwnSettings(not ns.UsesOwnSettings()) end)
    function dd:RefreshSwitch()
      self:SetText(ns.UsesOwnSettings() and (ClassColoredName() .. " only") or "Shared")
    end
  end
  dd:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Whose settings")
    GameTooltip:AddLine("Shared: every character uses the same setup.", 1, 1, 1, true)
    GameTooltip:AddLine(ClassColoredName() .. " only: this character keeps its own copy, starting from the shared setup.", 1, 1, 1, true)
    GameTooltip:AddLine("Combat / indoors is always per character.", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
  end)
  dd:HookScript("OnLeave", GameTooltip_Hide)
  if ns.euiSkin then
    if dd.SetupMenu then ns.euiSkin.Dropdown(dd) else SkinButton(dd) end
  end
  dd:RefreshSwitch()
  switchers[#switchers + 1] = dd
  return dd
end

-- Our window: top right, above the tabs.
local ourSwitch = MakeSettingsSwitcher(P)
ourSwitch:SetPoint("TOPRIGHT", P, "TOPRIGHT", -EDGE - 4, -64)
local switchLabel = P:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
switchLabel:SetPoint("RIGHT", ourSwitch, "LEFT", -8, 0)
switchLabel:SetText("Settings")
SkinText(switchLabel)

---------------------------------------------------------------------------
-- Status and refresh
---------------------------------------------------------------------------
local status = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
status:SetPoint("BOTTOMLEFT", EDGE + 4, 10)
SkinText(status)

-- Footer credit, bottom right (like Lueur's version line).
local credit = P:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
credit:SetPoint("BOTTOMRIGHT", -EDGE - 4, 10)
credit:SetTextColor(0.55, 0.55, 0.55)
SkinText(credit)
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
  if P:IsShown() then
    heading:SetText(HeadingText())
    sub:SetText(ns.GAME or "")
    out.icon:SetTexture(ns.previewIcon or ICON)
    ns.UpdateStatus()
  end
  for _, h in ipairs(headers) do h:Refresh() end
  for _, dd in ipairs(switchers) do dd:RefreshSwitch() end
  RefreshViews()
end

P:SetScript("OnShow", function() ApplyFonts(); SelectTab(currentTab); ns.Rebuild(); ns.RefreshUI() end)
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

    -- Everything built so far; anything built later skins itself.
    for _, card in ipairs(skinCards) do SkinCard(card) end
    for _, b in ipairs(allSlots) do SkinIconSlot(b) end
    SkinIconSlot(out)
    for _, w in ipairs(skinRows) do SkinRowWidgets(w) end
    for _, dd in ipairs(switchers) do
      if dd.SetupMenu then S.Dropdown(dd) else SkinButton(dd) end
    end
    for _, v in ipairs(views) do
      SkinButton(v.addBtn)
      SkinText(v.modsHint)
      SkinText(v.help)
      SkinText(v.empty)
    end
    ApplyFonts()

    -- Keep our switches in step with live accent colour changes.
    S.OnLooksChanged(function()
      for _, sw in ipairs(switches) do PaintSwitch(sw) end
    end)
    RefreshViews()
  end)
end

---------------------------------------------------------------------------
-- EllesmereUI options panel: our own sidebar section with the same two
-- pages, built by the same builders. (EllesmereUI only lets plugins add a
-- section of their own, so this can't live under Quality of Life.)
---------------------------------------------------------------------------
local function BuildEUIHeader(header, width)
  local h = {}
  local btn = MakeDragButton(header, 32)
  btn:SetPoint("RIGHT", header, "RIGHT", -4, 0)
  local label = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  label:SetPoint("RIGHT", btn, "LEFT", -8, 0)
  label:SetText("Drag to your bar")
  local dd = MakeSettingsSwitcher(header)
  dd:SetPoint("RIGHT", label, "LEFT", -16, 0)
  local who = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  who:SetPoint("LEFT", header, "LEFT", 4, 0)
  local st = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  st:SetPoint("LEFT", who, "RIGHT", 12, -1)
  for _, fs in ipairs({ label, who, st }) do SkinText(fs) end
  function h:Refresh()
    btn.icon:SetTexture(ns.previewIcon or ICON)
    who:SetText(HeadingText())
    st:SetText(ns.statusText or "")
    if ns.statusError then st:SetTextColor(1, 0.4, 0.4) else st:SetTextColor(0.5, 0.9, 0.5) end
  end
  h:Refresh()
  headers[#headers + 1] = h
  return 48
end

if EllesmereUI and EllesmereUI.RegisterPlugin then
  local builders = { General = BuildGeneral, Locations = BuildLocations }
  EllesmereUI.RegisterPlugin(ADDON, {
    label = "One-Click Mount",
    modules = {
      {
        key = "Main",
        title = "One-Click Mount",
        description = "One action bar button for every mount and movement spell.",
        pages = { "General", "Locations" },
        buildPage = function(pageName, parent, yOffset)
          -- EllesmereUI's search runs builders once in a hidden pass: build nothing then.
          if EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild() then return 0 end
          local holder = CreateFrame("Frame", nil, parent)
          holder:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset - 8)
          holder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOffset - 8)
          -- Top bar: who you are, status, and the drag-to-bar button.
          local bar = CreateFrame("Frame", nil, holder)
          bar:SetPoint("TOPLEFT")
          bar:SetPoint("TOPRIGHT")
          bar:SetHeight(44)
          local barH = BuildEUIHeader(bar)
          local body = CreateFrame("Frame", nil, holder)
          body:SetPoint("TOPLEFT", 0, -barH)
          body:SetPoint("TOPRIGHT", 0, -barH)
          local _, height = builders[pageName](body)
          body:SetHeight(height)
          height = height + barH
          holder:SetHeight(height)
          holder:HookScript("OnShow", function() ApplyFonts(); ns.Rebuild(); ns.RefreshUI() end)
          ns.Rebuild()
          ns.RefreshUI()
          return math.abs(yOffset) + 8 + height
        end,
        onPageCacheRestore = function() ApplyFonts(); ns.Rebuild(); ns.RefreshUI() end,
      },
    },
  })
end
