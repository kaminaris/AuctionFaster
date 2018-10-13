---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

--- @class AuctionCache
local AuctionCache = AuctionFaster:NewModule('AuctionCache');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');

AuctionCache.cache = {};

-- Make sure to call this only on first page
function AuctionCache:ParseScanResults(items, total)
	local serverTime = GetServerTime();

	-- Clean all found items first
	for i = 1, #items do
		local item = items[i];
		local cacheKey = item.itemId .. item.name;
		self.cache[cacheKey] = {
			lastScanTime = serverTime,
			auctions     = {},
			totalItems   = total --this will be a little over the real total items
		};
	end

	-- Add all auctions to cache
	local touchedRecords = {};
	for i = 1, #items do
		local item = items[i];
		local cacheItem = self.cache[item.itemId .. item.name];
		tinsert(cacheItem.auctions, item);

		local itemRecord = ItemCache:FindOrCreateCacheItem(item.itemId, item.name);
		itemRecord.lastScanTime = serverTime;
		if not tContains(touchedRecords, itemRecord) then
			tinsert(touchedRecords, itemRecord);
		end

		if not itemRecord.buy or itemRecord.buy > item.buy then
			itemRecord.buy = item.buy;
		end

		if not itemRecord.bid or itemRecord.bid > item.bid then
			itemRecord.bid = item.bid;
		end
	end

	if AuctionFaster.db.historical.enabled then
		for i = 1, #touchedRecords do
			ItemCache:RefreshHistoricalData(touchedRecords[i], serverTime, items, total);
		end
	end
end

function AuctionCache:GetItemFromCache(itemId, itemName)
	local cacheKey = itemId .. itemName;

	return self.cache[cacheKey];
end

function AuctionCache:FindOrCreateAuctionCache(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if self.cache[cacheKey] then
		return self.cache[cacheKey];
	end

	self.cache[cacheKey] = {
		lastScanTime = nil,
		auctions     = {},
		totalItems   = 0
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