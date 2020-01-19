---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @class ItemCache
local ItemCache = AuctionFaster:NewModule('ItemCache', 'AceEvent-3.0');
---@type Pricing
local Pricing = AuctionFaster:GetModule('Pricing');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local TableInsert = tinsert;
local TableRemove = tremove;
local GetServerTime = GetServerTime;
local pairs = pairs;

function ItemCache:Enable()
	if AuctionFaster.db.auctionDb then
		-- upgrade db
		local upgradeNeeded = false;
		for _, val in pairs(AuctionFaster.db.auctionDb) do
			if not val.itemKey then
				upgradeNeeded = true;
				break ;
			end
		end

		if upgradeNeeded then
			self:WipeItemCache();
		end
	end

	self.db = AuctionFaster.db.auctionDb;
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:RegisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
end

function ItemCache:Disable()
	self:UnregisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:UnregisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:UnregisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
end

function ItemCache:AUCTION_HOUSE_BROWSE_RESULTS_UPDATED()
	local browseResults = C_AuctionHouse.GetBrowseResults();
	local serverTime = GetServerTime();

	for _, result in pairs(browseResults) do
		local itemKey = result.itemKey;

		local cacheItem = self:FindOrCreateCacheItem(itemKey);
		cacheItem.buy = result.minPrice;
		cacheItem.lastScanTime = serverTime;
	end
end

function ItemCache:COMMODITY_SEARCH_RESULTS_UPDATED(_, itemId)
	if not self.Auctions then
		self.Auctions = AuctionFaster:GetModule('Auctions');
	end

	local items = self.Auctions:ScanCommodityResults(itemId);
	if #items < 1 then
		return;
	end

	local serverTime = GetServerTime();
	local itemKey = items[1].itemKey;
	local cacheItem = self:FindOrCreateCacheItem(itemKey);

	self:RefreshHistoricalData(cacheItem, items, serverTime);
end

function ItemCache:ITEM_SEARCH_RESULTS_UPDATED(_, itemKey)
	if not self.Auctions then
		self.Auctions = AuctionFaster:GetModule('Auctions');
	end

	local items = self.Auctions:ScanItemResults(itemKey);
	if #items < 1 then
		return;
	end

	local serverTime = GetServerTime();
	local cacheItem = self:FindOrCreateCacheItem(itemKey);

	self:RefreshHistoricalData(cacheItem, items, serverTime);
end

local function isSameDate(date1, date2)
	return date1.year == date2.year and date1.month == date2.month and date1.day == date2.day;
end

function ItemCache:MakeCacheKeyFromItemKey(itemKey)
	return (itemKey.itemID or '0') .. '-' ..
		(itemKey.itemLevel or '0') .. '-' ..
		(itemKey.itemSuffix or '0') .. '-' ..
		(itemKey.battlePetSpeciesID or '0');
end

function ItemCache:RefreshHistoricalData(cacheItem, auctions, serverTime)
	if not cacheItem.prices then
		cacheItem.prices = {};
	end

	local auctionInfo = Pricing:CalculateStatData(auctions);
	auctionInfo.itemRecord = nil;
	auctionInfo.auctions = nil;
	auctionInfo.stackSize = nil;
	auctionInfo.maxBidDeviation = nil;
	auctionInfo.scanTime = serverTime;

	local cacheLifetime = AuctionFaster.db.historical.keepDays * 24 * 60 * 60;
	local limit = serverTime - cacheLifetime;

	for i = #cacheItem.prices, 1, -1 do
		local historicalData = cacheItem.prices[i];

		if historicalData.scanTime < limit then
			-- remove old records
			TableRemove(cacheItem.prices, i);
		end
	end

	-- if there are no records, just insert and bail out
	if #cacheItem.prices == 0 then
		TableInsert(cacheItem.prices, auctionInfo);
		return ;
	end

	-- since it is impossible to perform future scans we can be sure that last record is newest
	local lastHistoricalData = cacheItem.prices[#cacheItem.prices];
	local lastDate = date('*t', lastHistoricalData.scanTime);
	local currentDate = date('*t', serverTime);

	if isSameDate(lastDate, currentDate) then
		-- same day, replace last record
		cacheItem.prices[#cacheItem.prices] = auctionInfo;
	else
		-- last date is older than today, we can safely insert new one
		TableInsert(cacheItem.prices, auctionInfo);
	end
end

function ItemCache:GetLastScanPrice(itemKey)
	local itemRecord = self:GetItemFromCache(itemKey);
	if not itemRecord then
		return nil;
	end

	return itemRecord.buy;
end

function ItemCache:GetItemFromCache(itemKey)
	local cacheKey = self:MakeCacheKeyFromItemKey(itemKey);
	if self.db[cacheKey] then
		return self.db[cacheKey];
	else
		return nil;
	end
end

--- Puts a blank item in cache as template
function ItemCache:FindOrCreateCacheItem(itemKey)
	local cacheKey = self:MakeCacheKeyFromItemKey(itemKey);

	if self.db[cacheKey] then
		return self.db[cacheKey];
	end

	self.db[cacheKey] = {
		itemKey      = itemKey,
		settings     = AuctionFaster:GetDefaultItemSettings(),
		bid          = nil,
		buy          = nil,
		lastScanTime = nil,
		prices       = {}
	};

	return self.db[cacheKey];
end

function ItemCache:UpdateItemSettingsInCache(itemKey, settingName, settingValue)
	local cacheItem = self:FindOrCreateCacheItem(itemKey);

	cacheItem.settings[settingName] = settingValue;
end

function ItemCache:WipeItemCache()
	self.db = {};
end

function ItemCache:UpdateSingleItemInCache(item, serverTime)
	local cacheItem = self:FindOrCreateCacheItem(item.itemKey);

	cacheItem.lastScanTime = serverTime;

	if item.buy and (not cacheItem.buy or cacheItem.buy > item.buy) then
		cacheItem.buy = item.buy;
	end

	if item.bid and (not cacheItem.bid or cacheItem.bid > item.bid) then
		cacheItem.bid = item.bid;
	end
end

--- Parsing couple of items
function ItemCache:ParseAuctionsResults(auctions)
	local serverTime = GetServerTime();

	-- Add all auctions to cache
	for _, auction in pairs(auctions) do
		self:UpdateSingleItemInCache(auction, serverTime);

		if AuctionFaster.db.historical.enabled then
			ItemCache:RefreshHistoricalData(auction, serverTime);
		end
	end
end

--- Parsing single item scan
function ItemCache:ParseItemResults(items)
	local serverTime = GetServerTime();

	if #items < 1 then
		return ;
	end

	-- we only care about cheapest one
	local auction = items[1];
	self:UpdateSingleItemInCache(auction, serverTime);

	if AuctionFaster.db.historical.enabled then
		ItemCache:RefreshHistoricalData(auction, serverTime);
	end
end