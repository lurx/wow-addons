local ADDON, ns = ...

local MACRO_NAME = "OneClickMount"
local BUTTON_NAME = "OneClickMountSecureButton"
local MACRO_LIMIT = 255

ns.MACRO_NAME = MACRO_NAME


-- Mount type IDs that can fly (steady flight and skyriding variants).
local FLYING_TYPES = {
  [247] = true, [248] = true, [398] = true, [402] = true, [407] = true,
  [424] = true, [436] = true, [437] = true, [444] = true,
}
-- Underwater-only mounts (Journal: Aquatic).
local AQUATIC_TYPES = { [231] = true, [232] = true, [254] = true }
-- Ground mounts (incl. water striders, AQ bugs, chauffeured).
local GROUND_TYPES = {
  [230] = true, [241] = true, [269] = true, [284] = true, [408] = true, [412] = true,
}
-- Spells allowed in the Flying row: Soar, Travel Form.
local FLIGHT_SPELLS = { [369536] = true, [783] = true }

-- Location presets
local QIRAJI_TYPE = 241       -- Qiraji battle tanks
local AQ_INSTANCE = 531       -- Temple of Ahn'Qiraj
-- Black Qiraji Battle Tank (Resonating Crystal): a normal ground mount by
-- type, so it's allowed in the AQ rule by its spell ID.
local BLACK_QIRAJI_SPELL = 26656
local UNDERMINE_MAP = 2346    -- Undermine (zone map), backup check only
local RANDOM_FAVORITE_SPELL = 150544 -- the Journal's "Summon Random Favorite Mount"
local G99_SPELL = 1215279     -- G-99 Breakneck: Undermine's zone ability
local G99_QUEST = 86618       -- "License Not Required": unlocks it, per character
-- Vashj'ir and its three zones: Kelp'thar Forest, Abyssal Depths, Shimmering Expanse.
local VASHJIR_MAPS = { 203, 201, 204, 205 }
local VASHJIR_SEAHORSE_TYPE = 232
ns.MAX_CUSTOM = 5

-- Candidate spells per class, first known one wins. Both Retail and
-- Forever/Classic-era spell IDs are listed where they differ.
local CLASS_DEFAULTS = {
  SHAMAN      = { combat = { 2645 } },                 -- Ghost Wolf
  HUNTER      = { combat = { 186257, 5118 } },         -- Aspect of the Cheetah
  DRUID       = { combat = { 783 } },                  -- Travel Form
  PALADIN     = { combat = { 190784 } },               -- Divine Steed
  ROGUE       = { combat = { 2983 } },                 -- Sprint
  MONK        = { combat = { 115008, 109132 } },       -- Chi Torpedo / Roll
  MAGE        = { combat = { 212653, 1953 } },         -- Shimmer / Blink
  DEMONHUNTER = { combat = { 195072 } },               -- Fel Rush
  DEATHKNIGHT = { combat = { 48265, 212552 } },        -- Death's Advance / Wraith Walk
  EVOKER      = { combat = { 358267 } },               -- Hover
}

-- Which slots are shared across characters, which are per character.
ns.CHAR_ROWS = { combat = true }

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
-- Where settings live. Shared (account-wide) by default; a character can
-- switch to its own copy ("<Name> only"). Combat / indoors is always per
-- character, since it depends on class.
local function DeepCopy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = DeepCopy(v) end
  return out
end

function ns.UsesOwnSettings()
  return OneClickMountCharDB and OneClickMountCharDB.useOwn == true
end

-- The settings table in use for this character (shared or its own).
function ns.Store()
  if ns.UsesOwnSettings() then
    OneClickMountCharDB.own = OneClickMountCharDB.own or {}
    return OneClickMountCharDB.own
  end
  return OneClickMountDB
end

-- Switch this character between shared settings and its own copy. The first
-- switch copies the shared setup; later switches keep the existing copy.
function ns.SetUseOwnSettings(on)
  if on and not OneClickMountCharDB.own then
    local shared = OneClickMountDB
    OneClickMountCharDB.own = {
      slots = DeepCopy(shared.slots),
      disabled = DeepCopy(shared.disabled),
      locations = DeepCopy(shared.locations),
      flyingDismount = shared.flyingDismount,
    }
  end
  OneClickMountCharDB.useOwn = on and true or false
end

function ns.Slots(key)
  local db = ns.CHAR_ROWS[key] and OneClickMountCharDB or ns.Store()
  db.slots = db.slots or {}
  db.slots[key] = db.slots[key] or {}
  return db.slots[key]
end

local function RowDB(key)
  return ns.CHAR_ROWS[key] and OneClickMountCharDB or ns.Store()
end

-- Option: let a click dismount you while flying (off by default).
function ns.AllowFlyingDismount()
  return OneClickMountDB and ns.Store().flyingDismount == true
end

function ns.SetAllowFlyingDismount(on)
  ns.Store().flyingDismount = on and true or false
end

function ns.IsEnabled(key)
  local db = RowDB(key)
  return not (db.disabled and db.disabled[key])
end

function ns.SetEnabled(key, on)
  local db = RowDB(key)
  db.disabled = db.disabled or {}
  db.disabled[key] = (not on) or nil
end

-- Same mount/spell/item?
local function EntryKey(e) return tostring(e.kind) .. ":" .. tostring(e.id) end

-- Index of an existing copy of e in list (ignoring skipIndex), or nil.
function ns.FindEntry(list, e, skipIndex)
  local k = EntryKey(e)
  for i, x in ipairs(list) do
    if i ~= skipIndex and EntryKey(x) == k then return i end
  end
end

-- Remove repeats from a row, keeping the first copy.
function ns.Dedupe(list)
  local seen, i = {}, 1
  while i <= #list do
    local k = EntryKey(list[i])
    if seen[k] then table.remove(list, i) else seen[k] = true; i = i + 1 end
  end
end

local function DedupeAll()
  for _, key in ipairs({ "flying", "ground", "combat", "shift", "ctrl", "alt" }) do
    ns.Dedupe(ns.Slots(key))
  end
  local L = ns.LocDB and ns.LocDB()
  if L then
    ns.Dedupe(L.presets.aq.slots)
    for _, rule in ipairs(L.custom) do ns.Dedupe(rule.slots or {}) end
  end
end

local function InitDB()
  OneClickMountDB = OneClickMountDB or {}
  OneClickMountCharDB = OneClickMountCharDB or {}
end

---------------------------------------------------------------------------
-- API wrappers (work on both modern Retail and Forever clients)
---------------------------------------------------------------------------
local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

local function SpellIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
  if GetSpellTexture then return GetSpellTexture(id) end
end

local function Known(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if IsSpellKnown and IsSpellKnown(id) then return true end
  return false
end

function ns.MountInfo(id)
  if not (id and C_MountJournal and C_MountJournal.GetMountInfoByID) then return end
  local name, spellID, icon, _, _, _, isFavorite, _, _, shouldHide, isCollected =
    C_MountJournal.GetMountInfoByID(id)
  return name, spellID, icon, isFavorite, shouldHide, isCollected
end

-- Returns castName, icon, spellID for a stored entry.
function ns.EntryInfo(e)
  if not e then return end
  if e.kind == "mount" then
    local name, spellID, icon = ns.MountInfo(e.id)
    if not name then return end
    return (spellID and SpellName(spellID)) or name, icon, spellID
  elseif e.kind == "spell" then
    local name = SpellName(e.id)
    if not name then return end
    return name, SpellIcon(e.id), e.id
  elseif e.kind == "randomfav" then
    local name = SpellName(RANDOM_FAVORITE_SPELL) or "Random favorite mount"
    return name, SpellIcon(RANDOM_FAVORITE_SPELL) or "Interface\\Icons\\inv_horse3saddle008_brown",
      RANDOM_FAVORITE_SPELL
  elseif e.kind == "item" then
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id))
      or (GetItemIcon and GetItemIcon(e.id))
    return e.name or ("item:" .. e.id), icon
  end
end

---------------------------------------------------------------------------
-- Picking what goes in the macro
---------------------------------------------------------------------------
-- "flying", "ground", "aquatic" or "unknown" (plus the raw type ID).
function ns.MountCategory(id)
  if not (C_MountJournal and C_MountJournal.GetMountInfoExtraByID) then return "unknown" end
  local _, _, _, _, typeID = C_MountJournal.GetMountInfoExtraByID(id)
  if FLYING_TYPES[typeID] then return "flying", typeID end
  if AQUATIC_TYPES[typeID] then return "aquatic", typeID end
  if GROUND_TYPES[typeID] then return "ground", typeID end
  return "unknown", typeID
end

-- Can this character ride it at all? Second value: usable right now.
function ns.MountForChar(id)
  if not (C_MountJournal and C_MountJournal.GetMountInfoByID) then return false end
  local name, _, _, _, isUsable, _, _, isFactionSpecific, faction, shouldHide, isCollected =
    C_MountJournal.GetMountInfoByID(id)
  if not name or not isCollected or shouldHide then return false end
  if isFactionSpecific and faction ~= nil then
    local mine = (UnitFactionGroup("player") == "Horde") and 0 or 1
    if faction ~= mine then return false end
  end
  return true, isUsable and true or false
end

-- Does an entry belong in a row? Returns ok, message.
function ns.IsQirajiTank(id)
  local _, typeID = ns.MountCategory(id)
  if typeID == QIRAJI_TYPE then return true end
  local _, spellID = ns.MountInfo(id)
  return spellID == BLACK_QIRAJI_SPELL
end

function ns.Accepts(rowKey, e)
  if rowKey == "loc:aq" then
    if e.kind == "mount" and ns.IsQirajiTank(e.id) then return true end
    return false, "Only Qiraji battle tanks (and the Black Qiraji) work in AQ."
  end
  if rowKey == "loc:undermine" then
    if e.kind == "mount" then
      local cat, typeID = ns.MountCategory(e.id)
      if cat == "ground" then return true end
      if cat == "unknown" then
        return true, "Couldn't tell this mount's type (" .. tostring(typeID) .. "), so it was accepted."
      end
    end
    return false, "Undermine only takes ground mounts."
  end
  if rowKey == "loc:vashjir" then
    if e.kind == "mount" then
      local cat, typeID = ns.MountCategory(e.id)
      if cat == "aquatic" then return true end
      if cat == "unknown" then
        return true, "Couldn't tell this mount's type (" .. tostring(typeID) .. "), so it was accepted."
      end
    end
    return false, "Only underwater mounts work in Vashj'ir's row."
  end
  if rowKey ~= "flying" and rowKey ~= "ground" then return true end
  if e.kind == "randomfav" then return true end
  if e.kind == "mount" then
    local cat, typeID = ns.MountCategory(e.id)
    if cat == rowKey then return true end
    if cat == "unknown" then
      return true, "Couldn't tell this mount's type (" .. tostring(typeID) .. "), so it was accepted."
    end
    return false, (rowKey == "flying") and "That mount can't fly." or "That's not a ground mount."
  end
  if rowKey == "flying" and e.kind == "spell" and FLIGHT_SPELLS[e.id] then return true end
  return false, (rowKey == "flying") and "Flying only takes flying mounts or flight forms."
    or "Ground only takes ground mounts."
end

-- Random entry from a row, skipping what this character can't use.
-- Prefers what's usable right here; falls back to anything the character
-- can ride, so being indoors at rebuild time never empties a row.
local RandomFavorite, RandomAnyFavorite -- defined below

-- "Random favorite" in a row is resolved to a real mount when the macro is
-- built: a flying favorite in Flying, any favorite elsewhere.
local function Resolve(e, rowKey)
  if e and e.kind == "randomfav" then
    if rowKey == "flying" then return RandomFavorite(true) end
    return RandomAnyFavorite()
  end
  return e
end

local function Pick(list, rowKey)
  local now, ok = {}, {}
  for _, e in ipairs(list) do
    if ns.EntryInfo(e) and (not rowKey or ns.Accepts(rowKey, e)) then
      local valid, usableNow = true, true
      if e.kind == "mount" then valid, usableNow = ns.MountForChar(e.id) end
      if valid then
        ok[#ok + 1] = e
        if usableNow then now[#now + 1] = e end
      end
    end
  end
  local pool = (#now > 0) and now or ok
  if #pool == 0 then return end
  return Resolve(pool[math.random(#pool)], rowKey)
end

RandomAnyFavorite = function()
  if not (C_MountJournal and C_MountJournal.GetMountIDs) then return end
  local now, any = {}, {}
  for _, id in ipairs(C_MountJournal.GetMountIDs()) do
    local name, _, _, isFav = ns.MountInfo(id)
    local valid, usableNow = ns.MountForChar(id)
    if name and isFav and valid then
      any[#any + 1] = id
      if usableNow then now[#now + 1] = id end
    end
  end
  local pool = (#now > 0) and now or any
  if #pool == 0 then return end
  return { kind = "mount", id = pool[math.random(#pool)], auto = true }
end

RandomFavorite = function(wantFlying)
  if not (C_MountJournal and C_MountJournal.GetMountIDs) then return end
  local want = wantFlying and "flying" or "ground"
  local fitsNow, fits, anyNow, any = {}, {}, {}, {}
  for _, id in ipairs(C_MountJournal.GetMountIDs()) do
    local name, _, _, isFav = ns.MountInfo(id)
    local valid, usableNow = ns.MountForChar(id)
    if name and isFav and valid then
      any[#any + 1] = id
      if usableNow then anyNow[#anyNow + 1] = id end
      if ns.MountCategory(id) == want then
        fits[#fits + 1] = id
        if usableNow then fitsNow[#fitsNow + 1] = id end
      end
    end
  end
  local pool = (#fitsNow > 0 and fitsNow) or (#fits > 0 and fits)
  if not pool and not wantFlying then pool = (#anyNow > 0 and anyNow) or (#any > 0 and any) end
  if not pool then return end
  return { kind = "mount", id = pool[math.random(#pool)], auto = true }
end

---------------------------------------------------------------------------
-- Locations
---------------------------------------------------------------------------
function ns.LocDB()
  local store = ns.Store()
  store.locations = store.locations or {}
  local L = store.locations
  L.presets = L.presets or {}
  L.presets.aq = L.presets.aq or { enabled = true, slots = {} }
  L.presets.aq.slots = L.presets.aq.slots or {}
  L.presets.undermine = L.presets.undermine or { enabled = true }
  L.presets.undermine.slots = L.presets.undermine.slots or {}
  L.presets.vashjir = L.presets.vashjir or { enabled = true, slots = {} }
  L.presets.vashjir.slots = L.presets.vashjir.slots or {}
  L.custom = L.custom or {}
  return L
end

-- Set of the current map and all its parents, so a zone rule also applies
-- inside that zone's buildings and caves.
local function MapChain()
  local chain = {}
  local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local guard = 0
  while id and id > 0 and guard < 12 do
    chain[id] = true
    local info = C_Map.GetMapInfo(id)
    id = info and info.parentMapID
    guard = guard + 1
  end
  return chain
end

-- The map to store for "Add current zone": climbs out of buildings (micro
-- and orphan maps) up to the zone or dungeon you're in.
function ns.CurrentZone()
  local id = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local guard = 0
  while id and guard < 12 do
    local info = C_Map.GetMapInfo(id)
    if not info then return end
    if (info.mapType or 0) <= 4 or not info.parentMapID or info.parentMapID == 0 then
      return id, info.name
    end
    id = info.parentMapID
    guard = guard + 1
  end
end

-- Name of the special zone you're in, if any.
function ns.SpecialZoneHere()
  local here = ns.LocationHere()
  if here.aq then return "Ahn'Qiraj" end
  if here.undermine then return "Undermine" end
  if here.vashjir then return "Vashj'ir" end
end

function ns.AddCurrentZone()
  local special = ns.SpecialZoneHere()
  if special then return false, special .. " is already a special zone." end
  local id, name = ns.CurrentZone()
  if not id then return false, "Couldn't read your current zone." end
  local L = ns.LocDB()
  for _, r in ipairs(L.custom) do
    if r.mapID == id then return false, name .. " already has a rule." end
  end
  if #L.custom >= ns.MAX_CUSTOM then
    return false, "You can have up to " .. ns.MAX_CUSTOM .. " zone rules."
  end
  table.insert(L.custom, { mapID = id, name = name, enabled = true, slots = {} })
  return true
end

-- The G-99 is a zone ability in Undermine, not a Journal mount. The rule is
-- on whenever the game says that ability is active.
-- Works anywhere: has this character finished the unlock quest?
-- (The account-wide flag isn't enough; it's per character in practice.)
function ns.G99Unlocked()
  return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    and C_QuestLog.IsQuestFlaggedCompleted(G99_QUEST) or false
end

function ns.G99Active()
  if C_ZoneAbility and C_ZoneAbility.GetActiveAbilities then
    for _, a in ipairs(C_ZoneAbility.GetActiveAbilities() or {}) do
      if a.spellID == G99_SPELL then return true end
    end
  end
  return false
end

local function RandomTank()
  if not (C_MountJournal and C_MountJournal.GetMountIDs) then return end
  local pool = {}
  for _, id in ipairs(C_MountJournal.GetMountIDs()) do
    if ns.MountForChar(id) and ns.IsQirajiTank(id) then pool[#pool + 1] = id end
  end
  if #pool == 0 then return end
  return { kind = "mount", id = pool[math.random(#pool)], auto = true }
end

local function InVashjir(chain)
  for _, id in ipairs(VASHJIR_MAPS) do
    if chain[id] then return true end
  end
end

-- Underwater pick for Vashj'ir: prefers the Vashj'ir seahorse, then any
-- underwater mount you own.
local function RandomAquatic()
  if not (C_MountJournal and C_MountJournal.GetMountIDs) then return end
  local seahorse, aquatic = {}, {}
  for _, id in ipairs(C_MountJournal.GetMountIDs()) do
    if ns.MountForChar(id) then
      local cat, typeID = ns.MountCategory(id)
      if typeID == VASHJIR_SEAHORSE_TYPE then seahorse[#seahorse + 1] = id
      elseif cat == "aquatic" then aquatic[#aquatic + 1] = id end
    end
  end
  local pool = (#seahorse > 0) and seahorse or aquatic
  if #pool == 0 then return end
  return { kind = "mount", id = pool[math.random(#pool)], auto = true }
end

-- Swimming-only pick (Vashj'ir). Doesn't replace your normal rules on land.
function ns.SwimPick()
  local L = ns.LocDB()
  if not L.presets.vashjir.enabled or not InVashjir(MapChain()) then return end
  return Pick(L.presets.vashjir.slots, "loc:vashjir") or RandomAquatic()
end

-- Which location rule applies right here, and what it picks.
-- Returns entry, ruleKey ("aq", "undermine", "custom:N").
function ns.LocationPick()
  local L = ns.LocDB()
  local instanceID = select(8, GetInstanceInfo())
  if L.presets.aq.enabled and instanceID == AQ_INSTANCE then
    local e = Pick(L.presets.aq.slots, "loc:aq") or RandomTank()
    if e then return e, "aq" end
  end
  local chain = MapChain()
  if L.presets.undermine.enabled and (ns.G99Active() or chain[UNDERMINE_MAP]) then
    -- Your own ground mounts here replace the G-99; empty row = G-99.
    local e = Pick(L.presets.undermine.slots, "loc:undermine")
    if e then return e, "undermine" end
    if ns.G99Active() then return { kind = "spell", id = G99_SPELL }, "undermine" end
  end
  for i, rule in ipairs(L.custom) do
    if rule.enabled ~= false and chain[rule.mapID] then
      local e = Pick(rule.slots or {})
      if e then return e, "custom:" .. i end
    end
  end
end

-- Which rule's zone you're standing in, even if it has nothing to pick.
function ns.LocationHere()
  local L = ns.LocDB()
  local here = {}
  if select(8, GetInstanceInfo()) == AQ_INSTANCE then here.aq = true end
  local chain = MapChain()
  if chain[UNDERMINE_MAP] or ns.G99Active() then here.undermine = true end
  if InVashjir(chain) then here.vashjir = true end
  for i, rule in ipairs(L.custom) do
    if chain[rule.mapID] then here["custom:" .. i] = true end
  end
  return here
end

function ns.ClassDefault(key)
  local _, class = UnitClass("player")
  local list = CLASS_DEFAULTS[class] and CLASS_DEFAULTS[class][key]
  if not list then return end
  for _, id in ipairs(list) do
    if Known(id) then return { kind = "spell", id = id, auto = true } end
  end
end

-- A clause is { cond, name }; they're joined (and merged) in BuildBody.
local function Clause(cond, e)
  local name = e and ns.EntryInfo(e)
  if not name then return end
  return { cond, name }
end

-- "[a]X;[b]X" -> "[a][b]X": adjacent clauses casting the same thing share one
-- name, which keeps the macro under WoW's 255-character limit. Safe because
-- clauses are tried in order and the merged one sits in the same place.
-- An unconditional clause ("") can't be merged into, since it matches anything.
local function JoinClauses(list)
  local merged = {}
  for _, cl in ipairs(list) do
    local last = merged[#merged]
    if last and last[2] == cl[2] and last[1] ~= "" and cl[1] ~= "" then
      last[1] = last[1] .. cl[1]
    elseif last and last[2] == cl[2] and cl[1] == "" then
      last[1] = "" -- the later unconditional one covers the earlier
    else
      merged[#merged + 1] = { cl[1], cl[2] }
    end
  end
  local out = {}
  for i, cl in ipairs(merged) do out[i] = cl[1] .. cl[2] end
  return table.concat(out, ";")
end

-- True when we're outdoors, not mounted or in combat, and none of the mounts
-- we'd pick can be summoned here. Only judged on real mounts; spells (G-99,
-- Soar) and items are taken as usable.
function ns.NoMountHere(...)
  if InCombatLockdown() or IsMounted() or IsIndoors() then return false end
  if IsSwimming and IsSwimming() then return false end
  local sawMount = false
  for i = 1, select("#", ...) do
    local e = select(i, ...)
    if e then
      if e.kind ~= "mount" then return false end
      local _, usableNow = ns.MountForChar(e.id)
      if usableNow then return false end
      sawMount = true
    end
  end
  return sawMount
end

-- The mount you're riding right now, as an entry (nil if none found).
function ns.ActiveMountEntry()
  if not (C_MountJournal and C_MountJournal.GetMountIDs) then return end
  for _, id in ipairs(C_MountJournal.GetMountIDs()) do
    local _, _, _, isActive = C_MountJournal.GetMountInfoByID(id)
    if isActive then return { kind = "mount", id = id } end
  end
end

function ns.BuildBody()
  local clauses = {}
  local function add(c) if c then clauses[#clauses + 1] = c end end

  local on = ns.IsEnabled
  -- Each /cast line starts with an empty "[mounted];" clause: when mounted it
  -- matches first and casts nothing, so no other clause needs "nomounted".
  -- [form]: already in Ghost Wolf / Travel Form -> casting it again cancels it.
  local COMBAT = "[form][combat][indoors]"
  local speed = on("combat") and (Pick(ns.Slots("combat")) or ns.ClassDefault("combat")) or nil
  if speed then add(Clause(COMBAT, speed)) end

  for _, m in ipairs({ "shift", "ctrl", "alt" }) do
    if on(m) then add(Clause("[mod:" .. m .. "]", Pick(ns.Slots(m)))) end
  end

  -- A location rule replaces Flying/Ground here; modifiers and combat still win.
  -- Vashj'ir: underwater mount while swimming, normal rules otherwise.
  local swim = ns.SwimPick()
  if swim then add(Clause("[swimming]", swim)) end
  ns.swimActive = swim and true or false

  local loc, locKey = ns.LocationPick()
  ns.activeLocation = locKey
  local fly, ground
  if not loc then
    fly = on("flying") and (Pick(ns.Slots("flying"), "flying") or RandomFavorite(true)) or nil
    ground = on("ground") and (Pick(ns.Slots("ground"), "ground") or RandomFavorite(false)) or nil
  end

  -- Outdoors but no mounting allowed (the Trading Post, Lorewalking areas...):
  -- there's no macro condition for that, so check whether the mounts we'd use
  -- are usable right here, and use the class speed spell instead if none are.
  ns.noMountHere = speed and ns.NoMountHere(loc, fly, ground) or false
  -- What the watcher below re-tests (same test, same entries).
  ns.watch = { loc or false, fly or false, ground or false }
  ns.hasSpeed = speed and true or false
  if ns.noMountHere then
    add(Clause("", speed))
  elseif loc then
    add(Clause("", loc))
  elseif ground then
    add(Clause("[flyable]", fly))
    add(Clause("", ground))
  else
    -- No ground rule: the flying mount is used everywhere (it runs on the ground too).
    add(Clause("", fly))
  end

  -- When something is already active, a click ends it:
  --   in a vehicle: leave it (and cast nothing)
  --   flying: nothing at all (no mid-air dismount)
  --   mounted: cast the mount you're riding, which dismounts you (casting a
  --     different mount would swap to it) and shows its icon
  --   in a form (Ghost Wolf, Travel Form...): cast it again, which cancels it
  local lines = { "/leavevehicle" }
  local riding = IsMounted() and ns.ActiveMountEntry() or nil
  local default = riding or loc or ground or fly
  local defaultName = default and ns.EntryInfo(default)
  -- Mid-air clicks do nothing, unless the player allowed dismounting while
  -- flying (glides, fall-damage achievements).
  local airDrop = ns.AllowFlyingDismount()
  local head = airDrop and "" or "[flying];"
  if defaultName then
    table.insert(clauses, 1, { "[mounted]", defaultName })
  else
    head = head .. "[mounted];"
    lines[#lines + 1] = airDrop and "/dismount [mounted]" or "/dismount [mounted,noflying]"
  end
  if #clauses > 0 then lines[#lines + 1] = "/cast " .. head .. JoinClauses(clauses) end


  local preview = loc or (IsFlyableArea and IsFlyableArea() and fly) or ground or fly
  local _, icon = ns.EntryInfo(preview)
  return table.concat(lines, "\n"), icon
end

---------------------------------------------------------------------------
-- Writing the macro (never in combat)
---------------------------------------------------------------------------
local secure = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
secure:SetAttribute("type", "macro")
secure:RegisterForClicks("AnyUp", "AnyDown")
secure:Hide()

ns.pending = false
ns.macrosReady = false
ns.lastBody = ""
ns.previewIcon = nil

function ns.Rebuild()
  if not ns.macrosReady then return end
  if InCombatLockdown() then
    ns.pending = true
    ns.SetStatus("Changes apply after combat")
    return
  end
  ns.pending = false
  DedupeAll()

  local actions, icon = ns.BuildBody()
  ns.previewIcon = icon
  ns.lastBody = actions

  local body = "#showtooltip\n" .. actions
  local macroIcon = 134400 -- question mark = dynamic icon from #showtooltip
  ns.lastLength = #body
  ns.usedClick = #body > MACRO_LIMIT
  if ns.usedClick then
    -- Too long for a macro: run it from our own secure button instead.
    secure:SetAttribute("macrotext", actions)
    local down = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
    body = "/click " .. BUTTON_NAME .. " LeftButton" .. (down and " 1" or "")
    macroIcon = icon or "inv_horse3saddle008_brown"
  end

  local idx = GetMacroIndexByName(MACRO_NAME)
  if idx == 0 then
    local _, numChar = GetNumMacros()
    if numChar >= (MAX_CHARACTER_MACROS or 18) then
      ns.SetStatus("Your character macro slots are full. Free one up and reload.", true)
      return
    end
    CreateMacro(MACRO_NAME, macroIcon, body, true)
  else
    local _, _, current = GetMacroInfo(idx)
    if current ~= body then EditMacro(idx, MACRO_NAME, macroIcon, body) end
  end
  ns.SetStatus("Macro up to date")
  if ns.RefreshUI then ns.RefreshUI() end
end

local queued = false
function ns.QueueRebuild()
  if queued then return end
  queued = true
  C_Timer.After(0.3, function()
    queued = false
    ns.Rebuild()
  end)
end

function ns.PickupButton()
  if InCombatLockdown() then return end
  ns.Rebuild()
  local idx = GetMacroIndexByName(MACRO_NAME)
  if idx > 0 then PickupMacro(idx) end
end

---------------------------------------------------------------------------
-- Status (UI hooks this)
---------------------------------------------------------------------------
function ns.SetStatus(text, isError)
  ns.statusText, ns.statusError = text, isError
  if ns.UpdateStatus then ns.UpdateStatus() end
  if isError then print("|cffff6060One-Click Mount:|r " .. text) end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
local function Reg(name) pcall(ev.RegisterEvent, ev, name) end

for _, name in ipairs({
  "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UPDATE_MACROS",
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
  "SPELLS_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE",
  "TRAIT_CONFIG_UPDATED", "NEW_MOUNT_ADDED", "COMPANION_UPDATE",
  "PLAYER_MOUNT_DISPLAY_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
  "ZONE_CHANGED_INDOORS", "CVAR_UPDATE", "PLAYER_CONTROL_GAINED",
  "MOUNT_JOURNAL_USABILITY_CHANGED",
}) do Reg(name) end

local function MarkReady()
  if ns.macrosReady then return end
  ns.macrosReady = true
  ns.Rebuild()
end

ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON then InitDB() end
  elseif event == "UPDATE_MACROS" then
    MarkReady() -- first fire means the server has sent our macros
  elseif event == "PLAYER_ENTERING_WORLD" then
    C_Timer.After(3, MarkReady)
    ns.QueueRebuild()
  elseif event == "PLAYER_REGEN_DISABLED" then
    if ns.OnCombatStart then ns.OnCombatStart() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if ns.pending then ns.Rebuild() end
    if ns.OnCombatEnd then ns.OnCombatEnd() end
  elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
    ns.QueueRebuild() -- mounted: learn the ridden mount; dismounted: re-roll random picks
  elseif event == "CVAR_UPDATE" then
    if arg1 == "ActionButtonUseKeyDown" then ns.QueueRebuild() end
  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED"
      or event == "ZONE_CHANGED_INDOORS" then
    ns.QueueRebuild()
    -- Zone abilities (like the G-99) and mount usability can update a moment
    -- after arriving, so check again shortly.
    C_Timer.After(1.5, ns.QueueRebuild)
  else
    ns.QueueRebuild()
  end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_ONECLICKMOUNT1 = "/ocm"
SLASH_ONECLICKMOUNT2 = "/oneclickmount"
SlashCmdList.ONECLICKMOUNT = function(msg)
  msg = (msg or ""):lower()
  if msg == "font" then
    if ns.DebugFont then ns.DebugFont() end
    return
  end
  if msg == "eui" then
    if EllesmereUI and EllesmereUI.OpenPlugin and EllesmereUI.OpenPlugin(ADDON) then return end
    print("|cff66ccffOne-Click Mount:|r EllesmereUI isn't loaded.")
    return
  end
  if msg == "debug" then
    print(("|cff66ccffOne-Click Mount macro|r (%d/%d chars%s):"):format(
      ns.lastLength or 0, MACRO_LIMIT, ns.usedClick and ", too long: using /click fallback" or ""))
    for line in (ns.lastBody or ""):gmatch("[^\n]+") do print("  " .. line) end
    if ns.noMountHere then print("  (mounting looks blocked here: using your speed spell)") end
    return
  end
  ns.Toggle()
end

---------------------------------------------------------------------------
-- No-mount areas (the Trading Post, Lorewalking spots) are often invisible
-- boundaries that fire no zone event. So, out of combat, check twice a second
-- whether the mounts the button uses are still usable here, and rebuild
-- only when that answer flips. Up to three lookups per tick, no collection scan.
---------------------------------------------------------------------------
C_Timer.NewTicker(0.5, function()
  if not ns.macrosReady or not ns.hasSpeed or not ns.watch then return end
  if InCombatLockdown() then return end
  local w = ns.watch
  local blocked = ns.NoMountHere(w[1] or nil, w[2] or nil, w[3] or nil) and true or false
  if blocked ~= (ns.noMountHere and true or false) then ns.QueueRebuild() end
end)
