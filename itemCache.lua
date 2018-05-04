
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
function AuctionFaster:PutInventoryItemInCache(selectedItem)
	local cacheKey = selectedItem.itemId .. selectedItem.name;

	if self.db.global.auctionDb[cacheKey] then
		return;
	end

	self.db.global.auctionDb[cacheKey] = {
		itemName = selectedItem.itemName,
		itemId = selectedItem.itemId,
		icon = selectedItem.icon,
		settings = self:GetDefaultItemSettings()
	};
end

function AuctionFaster:CacheItemNeedsUpdate(cacheKey)
	if not self.db.global.auctionDb[cacheKey] then
		return true;
	end

	local cacheItem = self.db.global.auctionDb[cacheKey];

	return not cacheItem.scanTime;
end

function AuctionFaster:UpdateItemInCache(cacheKey, cacheItem)
	if not self.db.global.auctionDb[cacheKey] then
		self.db.global.auctionDb[cacheKey] = cacheItem;
	else
		self.db.global.auctionDb[cacheKey].scanTime = cacheItem.scanTime;
		self.db.global.auctionDb[cacheKey].totalItems = cacheItem.totalItems;
		self.db.global.auctionDb[cacheKey].auctions = cacheItem.auctions;
		self.db.global.auctionDb[cacheKey].itemName = cacheItem.itemName;
		self.db.global.auctionDb[cacheKey].itemId = cacheItem.itemId;
	end
end

function AuctionFaster:UpdateItemSettingsInCache(cacheKey, settingName, settingValue)
	if not self.db.global.auctionDb[cacheKey] then
		return;
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

	local itemId, itemName = self.selectedItem.itemId, self.selectedItem.name;
	return self:GetItemFromCache(itemId, itemName, true);
end