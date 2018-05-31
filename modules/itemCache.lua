local ItemCache = AuctionFaster:NewModule('ItemCache');

function ItemCache:GetItemFromCache(itemId, itemName, skipOldCheck)
	if not itemId or not itemName then
		return nil;
	end

	if AuctionFaster.db.global.auctionDb[itemId .. itemName] then
		local item = AuctionFaster.db.global.auctionDb[itemId .. itemName];
		if not skipOldCheck and item.scanTime and ((GetServerTime() - item.scanTime) > 60 * 10) then
			-- older than 10 minutes
			return nil;
		end
		return item;
	else
		return nil;
	end
end

--- Puts a blank item in cache as template
function ItemCache:FindOrCreateCacheItem(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if AuctionFaster.db.global.auctionDb[cacheKey] then
		return AuctionFaster.db.global.auctionDb[cacheKey];
	end

	AuctionFaster.db.global.auctionDb[cacheKey] = {
		itemName   = itemName,
		itemId     = itemId,
		icon       = GetItemIcon(itemId),
		settings   = self:GetDefaultItemSettings(),
		scanTime   = nil,
		auctions   = {},
		totalItems = 0,
		bid        = nil,
		buy        = nil
	};

	return AuctionFaster.db.global.auctionDb[cacheKey];
end

function ItemCache:CacheItemNeedsUpdate(cacheKey)
	if not AuctionFaster.db.global.auctionDb[cacheKey] then
		return true;
	end

	local cacheItem = AuctionFaster.db.global.auctionDb[cacheKey];

	return not cacheItem.scanTime;
end

function ItemCache:UpdateItemSettingsInCache(cacheKey, settingName, settingValue)
	if not AuctionFaster.db.global.auctionDb[cacheKey] then
		return ;
	end

	AuctionFaster.db.global.auctionDb[cacheKey].settings[settingName] = settingValue;
end

function ItemCache:WipeItemCache()
	AuctionFaster.db.global.auctionDb = {};
end
