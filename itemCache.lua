function AuctionFaster:GetItemFromCache(itemId, itemName, skipOldCheck)
	if self.db.global.auctionDb[itemId .. itemName] then
		local item = self.db.global.auctionDb[itemId .. itemName];
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
function AuctionFaster:FindOrCreateCacheItem(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if self.db.global.auctionDb[cacheKey] then
		return self.db.global.auctionDb[cacheKey];
	end

	self.db.global.auctionDb[cacheKey] = {
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

	return self.db.global.auctionDb[cacheKey];
end

function AuctionFaster:CacheItemNeedsUpdate(cacheKey)
	if not self.db.global.auctionDb[cacheKey] then
		return true;
	end

	local cacheItem = self.db.global.auctionDb[cacheKey];

	return not cacheItem.scanTime;
end

function AuctionFaster:UpdateItemSettingsInCache(cacheKey, settingName, settingValue)
	if not self.db.global.auctionDb[cacheKey] then
		return ;
	end

	self.db.global.auctionDb[cacheKey].settings[settingName] = settingValue;
end

function AuctionFaster:WipeItemCache()
	self.db.global.auctionDb = {};
end

function AuctionFaster:GetSelectedItemFromCache()
	if not self.selectedItem then
		return nil;
	end

	local itemId, itemName = self.selectedItem.itemId, self.selectedItem.itemName;
	return self:GetItemFromCache(itemId, itemName, true);
end