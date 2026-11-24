-- Price lookup chain: vendor price (if a vendor sells it) -> Auctioneer -> Auctionator -> own AH scan.
local _, FC = ...
local L = FC.L
FC.Prices = {}
local P = FC.Prices

-- Modules register items that vendors sell, with a default buy price in copper.
-- Real prices seen at a merchant replace the defaults.
P.vendorDefaults = {}

function P:RegisterVendorItems(t)
    for id, price in pairs(t) do self.vendorDefaults[id] = price end
end

function P:HasAuctioneer()
    return AucAdvanced and AucAdvanced.API and AucAdvanced.API.GetMarketValue and true or false
end

function P:HasAuctionator()
    return Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID and true or false
end

function P:SourceName()
    if self:HasAuctioneer() then return "Auctioneer" end
    if self:HasAuctionator() then return "Auctionator" end
    return L["Own scan"]
end

-- "Auction house data via Auctionator" / "via your last scan (3 hours ago)".
function P:Footnote()
    if self:HasAuctioneer() then return string.format(L["Auction house data via %s"], "Auctioneer") end
    if self:HasAuctionator() then return string.format(L["Auction house data via %s"], "Auctionator") end
    local newest
    for _, e in pairs(FC.db and FC.db.prices or {}) do
        if e.t and (not newest or e.t > newest) then newest = e.t end
    end
    if not newest then return L["No auction house data yet. Use Scan prices at the Auction House."] end
    local ago = time() - newest
    local when
    if ago < 3600 then when = string.format(L["%d minutes ago"], math.max(1, math.floor(ago / 60)))
    elseif ago < 86400 then when = string.format(L["%d hours ago"], math.floor(ago / 3600))
    else when = string.format(L["%d days ago"], math.floor(ago / 86400)) end
    return string.format(L["Auction house data via your last scan (%s)"], when)
end

function P:VendorPrice(itemID)
    local seen = FC.db and FC.db.vendorPrices[itemID]
    return seen or self.vendorDefaults[itemID]
end

function P:AuctionPrice(itemID)
    if self:HasAuctioneer() then
        local link = FC.Util.ItemLink(itemID)
        if link then
            local ok, v = pcall(AucAdvanced.API.GetMarketValue, link)
            if ok and v and v > 0 then return v, L["Auction"] end
        end
    end
    if self:HasAuctionator() then
        local ok, v = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "ForeverCrafting", itemID)
        if ok and v and v > 0 then return v, L["Auction"] end
    end
    local own = FC.db and FC.db.prices[itemID]
    if own and own.p then return own.p, L["Auction"] end
end

-- Returns unit price in copper and where it came from ("vendor", "AH" source name), or nil.
function P:Get(itemID)
    local v = self:VendorPrice(itemID)
    if v then return v, L["vendor"] end
    return self:AuctionPrice(itemID)
end

-- Remember what merchants actually charge for items we care about.
function P:ReadMerchant()
    if not (GetMerchantNumItems and FC.db) then return end
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        local id = link and C_Item.GetItemInfoInstant(link)
        if id and self.vendorDefaults[id] then
            local price, qty
            if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
                local info = C_MerchantFrame.GetItemInfo(i)
                price, qty = info and info.price, info and info.stackCount
            else
                local _, _, p, q = GetMerchantItemInfo(i)
                price, qty = p, q
            end
            if price and price > 0 then
                FC.db.vendorPrices[id] = math.floor(price / math.max(qty or 1, 1) + 0.5)
            end
        end
    end
end

-- Every item any loaded module wants priced (used by the AH scan).
function P:TrackedItems()
    local set, list = {}, {}
    for _, key in ipairs(FC.moduleOrder) do
        local mod = FC.modules[key]
        if mod.GetTrackedItems then
            for _, id in ipairs(mod:GetTrackedItems()) do
                if not set[id] and not self.vendorDefaults[id] then
                    set[id] = true
                    table.insert(list, id)
                end
            end
        end
    end
    table.sort(list)
    return list
end
