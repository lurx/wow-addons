-- Materials on other characters. Uses Syndicator's records when it's installed;
-- otherwise keeps its own snapshots of every character's bags and bank.
-- Bags are saved whenever they change and on logout; the bank whenever it's open.
-- Only characters on the same realm and faction count (they can mail each other).
local _, FC = ...
FC.Inventory = {}
local Inv = FC.Inventory

local function charKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

local function store()
    FC.db.inventory = FC.db.inventory or {}
    local key = charKey()
    local rec = FC.db.inventory[key]
    if not rec then
        rec = { bags = {}, bank = {} }
        FC.db.inventory[key] = rec
    end
    local _, class = UnitClass("player")
    rec.name = UnitName("player")
    rec.realm = GetRealmName()
    rec.faction = UnitFactionGroup("player")
    rec.class = class
    return rec
end

local function slotsOf(bag)
    local n = C_Container.GetContainerNumSlots(bag)
    return n or 0
end

local function readContainers(ids)
    local counts = {}
    for _, bag in ipairs(ids) do
        for slot = 1, slotsOf(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                counts[info.itemID] = (counts[info.itemID] or 0) + (info.stackCount or 1)
            end
        end
    end
    return counts
end

-- Player bags: backpack plus equipped bags (and the reagent bag where it exists).
local function bagIDs()
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    local ids = {}
    for i = 0, last do table.insert(ids, i) end
    return ids
end

-- Bank: the main bank container, the reagent bank, and every container ID above the
-- player's bags (bank bags or bank tabs, depending on the client). Empty IDs are skipped.
local function bankIDs()
    local ids = { (Enum.BagIndex and Enum.BagIndex.Bank) or -1 }
    if Enum.BagIndex and Enum.BagIndex.Reagentbank then table.insert(ids, Enum.BagIndex.Reagentbank) end
    local first = (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) + 1
    for i = first, first + 15 do table.insert(ids, i) end
    return ids
end

function Inv:SaveBags()
    if not FC.db then return end
    local rec = store()
    rec.bags = readContainers(bagIDs())
    rec.bagsTime = time()
end

function Inv:SaveBank()
    if not FC.db then return end
    -- Only while the bank is actually readable, or we'd save an empty bank.
    if slotsOf((Enum.BagIndex and Enum.BagIndex.Bank) or -1) == 0 then return end
    local rec = store()
    rec.bank = readContainers(bankIDs())
    rec.bankTime = time()
    FC:Fire("BAGS_UPDATED")
end

-- This character's last bank snapshot for an item (nil if never seen).
function Inv:MyBank(itemID)
    local rec = FC.db and FC.db.inventory and FC.db.inventory[charKey()]
    if not rec or not rec.bankTime then return nil end
    return rec.bank[itemID] or 0
end

-- Total of an item on this realm's other characters of the same faction.
-- Returns total and a list { { name, class, count }, ... } sorted by count.
function Inv:HasSyndicator()
    return Syndicator and Syndicator.API and Syndicator.API.GetInventoryInfoByItemID
        and (not Syndicator.API.IsReady or Syndicator.API.IsReady()) and true or false
end

-- From Syndicator (when installed): its records also include mail.
local function fromSyndicator(itemID)
    local ok, info = pcall(Syndicator.API.GetInventoryInfoByItemID, itemID, true, true)
    if not ok or not info or not info.characters then return end
    local me = UnitName("player")
    local myRealm = GetNormalizedRealmName and GetNormalizedRealmName()
    local total, list = 0, {}
    for _, c in ipairs(info.characters) do
        local isMe = c.character == me and (not myRealm or c.realmNormalized == myRealm)
        local n = (c.bags or 0) + (c.bank or 0) + (c.mail or 0)
        if not isMe and n > 0 then
            total = total + n
            table.insert(list, { name = c.character, class = c.className, count = n, bank = c.bank or 0, mail = c.mail or 0 })
        end
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return total, list
end

function Inv:OnAlts(itemID)
    if self:HasSyndicator() then
        local total, list = fromSyndicator(itemID)
        if total then return total, list end
    end
    local inv = FC.db and FC.db.inventory
    if not inv then return 0, {} end
    local me, realm, faction = charKey(), GetRealmName(), UnitFactionGroup("player")
    local total, list = 0, {}
    for key, rec in pairs(inv) do
        if key ~= me and rec.realm == realm and rec.faction == faction then
            local n = (rec.bags and rec.bags[itemID] or 0) + (rec.bank and rec.bank[itemID] or 0)
            if n > 0 then
                total = total + n
                table.insert(list, { name = rec.name, class = rec.class, count = n,
                    bank = rec.bank and rec.bank[itemID] or 0 })
            end
        end
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return total, list
end

-- Tooltip lines like "Tempest: 120 (bank 100)", in class colours.
function Inv:AltLines(itemID)
    local _, list = self:OnAlts(itemID)
    local lines = {}
    for _, e in ipairs(list) do
        local c = e.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
        local name = c and string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, e.name) or e.name
        local parts = {}
        if e.bank and e.bank > 0 then table.insert(parts, string.format("%s %d", FC.L["bank"], e.bank)) end
        if e.mail and e.mail > 0 then table.insert(parts, string.format("%s %d", FC.L["mail"], e.mail)) end
        local where = #parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or ""
        table.insert(lines, string.format("%s: %d%s", name, e.count, where))
    end
    return lines
end

local ev = CreateFrame("Frame")
local bankOpen = false
local pending
local function saveSoon()
    if pending then return end
    pending = true
    C_Timer.After(1, function()
        pending = false
        Inv:SaveBags()
        if bankOpen then Inv:SaveBank() end
    end)
end

ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("BANKFRAME_OPENED")
ev:RegisterEvent("BANKFRAME_CLOSED")
for _, e in ipairs({ "PLAYERBANKSLOTS_CHANGED", "PLAYERREAGENTBANKSLOTS_CHANGED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event)
    if event == "BANKFRAME_OPENED" then
        bankOpen = true
        C_Timer.After(0.5, function() Inv:SaveBank() end)
    elseif event == "BANKFRAME_CLOSED" then
        -- Don't save here: the bank can already be unreadable once it closes.
        bankOpen = false
    elseif event == "PLAYER_LOGOUT" then
        Inv:SaveBags()
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(3, function() Inv:SaveBags() end)
    else
        saveSoon()
    end
end)
