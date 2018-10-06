---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

--- @class AuctionCache
local AuctionCache = AuctionFaster:NewModule('AuctionCache');

AuctionCache.cache = {};

-- Make sure to call this only on first page
function AuctionCache:ParseScanResults(items)
	local serverTime = GetServerTime();

	-- Clean all found items first
	for i = 1, #items do
		local item = items[i];
		local cacheKey = item.itemId .. item.name;
		self.cache[cacheKey] = {
			lastScanTime = serverTime,
			auctions     = {},
		};
	end

	-- Add all auctions to cache
	for i = 1, #items do
		local item = items[i];
		local cacheItem = self.cache[item.itemId .. item.name];
		tinsert(cacheItem.auctions, item);
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