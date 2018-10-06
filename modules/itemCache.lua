---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @class ItemCache
local ItemCache = AuctionFaster:NewModule('ItemCache');

function ItemCache:Enable()
	if AuctionFaster.db.auctionDb then
		-- upgrade db
		local upgradeNeeded = false;
		for key, val in pairs(AuctionFaster.db.auctionDb) do
			if val.auctions then
				upgradeNeeded = true;
				break;
			end
		end

		if upgradeNeeded then
			self:WipeItemCache();
		end
	end
end

function ItemCache:ParseScan()

end

function ItemCache:GetLastScanPrice(itemId, itemName)
	local itemRecord = self:GetItemFromCache(itemId, itemName);
	if not itemRecord then
		return nil;
	end

	return itemRecord.buy;
end

function ItemCache:GetItemFromCache(itemId, itemName)
	if not itemId or not itemName then
		return nil;
	end

	if AuctionFaster.db.auctionDb[itemId .. itemName] then
		return AuctionFaster.db.auctionDb[itemId .. itemName];
	else
		return nil;
	end
end

--- Puts a blank item in cache as template
function ItemCache:FindOrCreateCacheItem(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if AuctionFaster.db.auctionDb[cacheKey] then
		return AuctionFaster.db.auctionDb[cacheKey];
	end

	AuctionFaster.db.auctionDb[cacheKey] = {
		itemName     = itemName,
		itemId       = itemId,
		icon         = GetItemIcon(itemId),
		settings     = AuctionFaster:GetDefaultItemSettings(),
		bid          = nil,
		buy          = nil,
		prices       = {}
	};

	return AuctionFaster.db.auctionDb[cacheKey];
end

function ItemCache:UpdateItemSettingsInCache(cacheKey, settingName, settingValue)
	if not AuctionFaster.db.auctionDb[cacheKey] then
		AuctionFaster:Echo(3, 'Invalid cache key');
		return ;
	end

	AuctionFaster.db.auctionDb[cacheKey].settings[settingName] = settingValue;
end

function ItemCache:WipeItemCache()
	AuctionFaster.db.auctionDb = {};
end
