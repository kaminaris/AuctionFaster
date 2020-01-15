---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

--- @class AuctionCache
local AuctionCache = AuctionFaster:NewModule('AuctionCache');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');

AuctionCache.cache = {};

function AuctionCache:MakeCacheKeyFromItemKey(itemKey)
	return itemKey.itemID or 0 .. '-' ..
		itemKey.itemLevel or 0 .. '-' ..
		itemKey.itemSuffix or 0 .. '-' ..
		itemKey.battlePetSpeciesID or 0;
end

-- Make sure to call this only on first page
function AuctionCache:ParseScanResults(items)
	local serverTime = GetServerTime();

	-- Clean all found items first
	for i = 1, #items do
		local item = items[i];
		local cacheKey = self:MakeCacheKeyFromItemKey(item.itemKey);

		self.cache[cacheKey] = {
			lastScanTime = serverTime,
			auctions = {}
		};
	end

	-- Add all auctions to cache
	local touchedRecords = {};
	for i = 1, #items do
		local item = items[i];
		local cacheKey = self:MakeCacheKeyFromItemKey(item.itemKey);
		local cacheItem = self.cache[cacheKey];
		tinsert(cacheItem.auctions, item);

		local itemRecord = ItemCache:FindOrCreateCacheItem(cacheKey, item.itemKey);
		itemRecord.lastScanTime = serverTime;
		if not tContains(touchedRecords, itemRecord) then
			tinsert(touchedRecords, itemRecord);
		end

		if not itemRecord.buy or itemRecord.buy > item.buy then
			itemRecord.buy = item.buy;
		end
	end

	if AuctionFaster.db.historical.enabled then
		for i = 1, #touchedRecords do
			ItemCache:RefreshHistoricalData(touchedRecords[i], serverTime);
		end
	end
end

function AuctionCache:GetItemFromCache(itemKey)
	local cacheKey = self:MakeCacheKeyFromItemKey(itemKey);

	return self.cache[cacheKey];
end

function AuctionCache:FindOrCreateAuctionCache(itemKey)
	local cacheKey = self:MakeCacheKeyFromItemKey(itemKey);

	if self.cache[cacheKey] then
		return self.cache[cacheKey];
	end

	self.cache[cacheKey] = {
		lastScanTime = nil,
		auctions = {},
	};

	return self.cache[cacheKey];
end

function AuctionCache:GetLowestPrice(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if not self.cache[cacheKey] then
		return nil, nil;
	end

	return self:FindLowestBidBuy(self.cache[cacheKey]);
end

function AuctionCache:FindLowestBidBuy(cacheItem)
	if not cacheItem.auctions or #cacheItem.auctions < 1 then
		return nil, nil;
	end

	local playerName = UnitName('player');

	local lowestBid, lowestBuy;
	for i = 1, #cacheItem.auctions do
		local auction = cacheItem.auctions[i];
		if auction.owner ~= playerName then
			if auction.bid > 0 and (not lowestBid or lowestBid > auction.bid) then
				lowestBid = auction.bid;
			end

			if auction.buy > 0 and (not lowestBuy or lowestBuy > auction.buy) then
				lowestBuy = auction.buy;
			end
		end
	end

	--TODO: Ignore own auctions
	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy - 1;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid + 1;
	end

	return lowestBid, lowestBuy;
end