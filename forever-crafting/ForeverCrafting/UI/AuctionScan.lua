-- "Scan prices" button on the Auction House. Shown only when neither Auctioneer nor
-- Auctionator is installed (or when forced in settings). Looks up each tracked item
-- one at a time and stores the lowest unit price.
local _, FC = ...
local L = FC.L
local UI = FC.UI
FC.AuctionScan = {}
local AS = FC.AuctionScan

local button, queue, index, waitingFor, timeoutTimer, updated

local function finish()
    if timeoutTimer then timeoutTimer:Cancel() timeoutTimer = nil end
    waitingFor = nil
    queue = nil
    if button then
        button:Enable()
        button.text:SetText(L["Scan prices"])
    end
    FC:Print(string.format(L["Scan finished: %d prices updated."], updated or 0))
    FC:Fire("PRICES_UPDATED")
end

local function record(itemID, price)
    if price and price > 0 then
        FC.db.prices[itemID] = { p = price, t = time() }
        updated = updated + 1
    end
end

local step

local function advance()
    if timeoutTimer then timeoutTimer:Cancel() timeoutTimer = nil end
    waitingFor = nil
    index = index + 1
    C_Timer.After(0.15, step)
end

step = function()
    if not queue then return end
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then finish() return end
    if index > #queue then finish() return end
    if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        C_Timer.After(0.3, step)
        return
    end
    local itemID = queue[index]
    button.text:SetText(string.format(L["Scanning %d / %d"], index, #queue))
    waitingFor = itemID
    local key = C_AuctionHouse.MakeItemKey(itemID)
    C_AuctionHouse.SendSearchQuery(key, { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }, false)
    timeoutTimer = C_Timer.NewTimer(4, advance)
end

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, arg)
    if not waitingFor then return end
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" and arg == waitingFor then
        local r = C_AuctionHouse.GetNumCommoditySearchResults(waitingFor) > 0 and C_AuctionHouse.GetCommoditySearchResultInfo(waitingFor, 1)
        record(waitingFor, r and r.unitPrice)
        advance()
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" and arg and arg.itemID == waitingFor then
        local best
        for i = 1, C_AuctionHouse.GetNumItemSearchResults(arg) do
            local r = C_AuctionHouse.GetItemSearchResultInfo(arg, i)
            local per = r and r.buyoutAmount -- unit price for item auctions
            if per and (not best or per < best) then best = per end
        end
        record(waitingFor, best and math.floor(best))
        advance()
    end
end)
ev:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
ev:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")

function AS:Start()
    queue = FC.Prices:TrackedItems()
    index, updated = 1, 0
    if #queue == 0 then finish() return end
    button:Disable()
    step()
end

local function create()
    button = UI.Button(AuctionHouseFrame, L["Scan prices"], 120, 24)
    button:SetPoint("TOPRIGHT", AuctionHouseFrame, "TOPRIGHT", -30, -1)
    button:SetFrameStrata("HIGH")
    button:SetScript("OnClick", function() AS:Start() end)
    button:SetScript("OnEnter", function(self)
        UI.TextTooltip(self, L["Scan prices"], { L["Scan the Auction House for the materials Forever Crafting tracks."] })
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

local function onShow()
    local wanted = FC.db.forceScanButton or not (FC.Prices:HasAuctioneer() or FC.Prices:HasAuctionator())
    if not wanted or #FC.moduleOrder == 0 then
        if button then button:Hide() end
        return
    end
    if not button then create() end
    button:Show()
end

local hooker = CreateFrame("Frame")
hooker:RegisterEvent("AUCTION_HOUSE_SHOW")
hooker:SetScript("OnEvent", function()
    C_Timer.After(0, onShow)
end)
