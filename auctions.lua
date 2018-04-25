
function AuctionFaster:GetItemFromCache(itemId, itemName)
	if self.db.global.auctionDb[itemId .. itemName] then
		local item = self.db.global.auctionDb[itemId .. itemName];
		if ((GetServerTime() - item.scanTime) > 60 * 10) then -- older than 10 minutes
			return nil;
		end
		return item;
	else
		return nil;
	end
end

function AuctionFaster:GetCurrentAuctions()
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local name = selectedItem.name;

	local cacheItem = self:GetItemFromCache(itemId, name);
	if cacheItem and #cacheItem.auctions > 0 then
		self:UpdateAuctionTable(cacheItem);
		return;
	end

	if not CanSendAuctionQuery() then
		print('cant wut');
		return;
	end

	self.currentlySorting = true;
	SortAuctionItems('list', 'buyout')
	if IsAuctionSortReversed('list', 'buyout') then
		SortAuctionItems('list', 'buyout')
	end
	self.currentlySorting = false;

	self.currentlyQuerying = true;
	QueryAuctionItems(name, nil, nil, 0, 0, 0, false, true);
	self.currentlyQuerying = false;
end

function AuctionFaster:AUCTION_ITEM_LIST_UPDATE()
	if (self.currentlySorting) then
		return;
	end

	local selectedId, selectedName = self:GetSelectedItemIdName();

	if not selectedId then
		-- Not our scan, ignore it
		return;
	end;

	local shown, total = GetNumAuctionItems('list');

	-- since we did scan anyway, put it in cache
	local cacheKey;
	local cacheItem = {
		scanTime = GetServerTime(),
		auctions = {},
		totalItems = total
	};

	local addedSome = false;
	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		-- this function runs for every AH scan so make sure to ignore it if item does not match selected one
		if name == selectedName and itemId == selectedId then
			addedSome = true;
			if not cacheKey then
				cacheItem.itemName = name;
				cacheItem.itemId = itemId;
				cacheKey = itemId .. name;
			end

			tinsert(cacheItem.auctions, {
				owner = owner,
				count = count,
				itemId = itemId,
				itemName = name,
				bid = floor(minBid / count),
				buy = floor(buyoutPrice / count),
			});
		end
	end

	if cacheKey and (addedSome or not self.db.global.auctionDb[cacheKey]) then
		-- only cache it when there is no cache or items were added
		table.sort(cacheItem.auctions, function(a, b)
			return a.buy < b.buy;
		end);

		self.db.global.auctionDb[cacheKey] = cacheItem;
	end
	self:UpdateAuctionTable(cacheItem);
end

function AuctionFaster:UpdateAuctionTable(cacheItem)
	self.auctionTab.currentAuctions:SetData(cacheItem.auctions, true);
	self.auctionTab.lastScan:SetText('Last Scan: ' .. self:FormatDuration(GetServerTime() - cacheItem.scanTime));
	local minBid, minBuy = self:FindLowestBidBuy(cacheItem);
	self:UnderCutPrices(cacheItem, minBid, minBuy);
	self:UpdateInventoryItemPrice(cacheItem.itemId, cacheItem.itemName, minBuy);

end

function AuctionFaster:UnderCutPrices(cacheItem, lowestBid, lowestBuy)
	if #cacheItem.auctions < 1 then
		return;
	end

	if not lowestBid or not lowestBuy then
		lowestBid, lowestBuy = self:FindLowestBidBuy(cacheItem);
	end

	self:UpdateTabPrices(lowestBid - 1, lowestBuy - 1);
end

function AuctionFaster:GetLowestPrice(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if not self.db.global.auctionDb[cacheKey] then
		return nil, nil;
	end

	local cacheItem = self.db.global.auctionDb[cacheKey];

	return self:FindLowestBidBuy(cacheItem);
end

function AuctionFaster:FindLowestBidBuy(cacheItem)
	if #cacheItem.auctions < 1 then
		return nil, nil;
	end

	local lowestBid, lowestBuy;
	for i = 1, #cacheItem.auctions do
		local auc = cacheItem.auctions[i];
		if auc.bid > 0 and (not lowestBid or lowestBid > auc.bid) then
			lowestBid = auc.bid;
		end

		if auc.buy > 0 and (not lowestBuy or lowestBuy > auc.buy) then
			lowestBuy = auc.buy;
		end
	end

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy - 1;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid + 1;
	end

	return lowestBid, lowestBuy;
end

function AuctionFaster:SellItem()
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local name = selectedItem.name;

	local bag, slot = self:GetItemFromInventory(itemId, name);
	if not bag or not slot then
		return;
	end

	local sellSettings = self:GetSellSettings();

	PickupContainerItem(bag, slot);
	if not CursorHasItem() then
		return;
	end

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = 2
	end

	-- Putem item in slot
	ClickAuctionSellItemButton();

	StartAuction(sellSettings.bidPerItem * sellSettings.stackSize,
		sellSettings.buyPerItem * sellSettings.stackSize,
		sellSettings.duration,
		sellSettings.stackSize,
		sellSettings.maxStacks);
end

function AuctionFaster:BuyItem()
	local selectedId, selectedName = self:GetSelectedItemIdName();
	if not selectedId then
		return;
	end

	local index = self.auctionTab.currentAuctions:GetSelection();
	if not index then
		return;
	end
	local auctionData = self.auctionTab.currentAuctions:GetRow(index);

	-- maybe index is the same
	local name, texture, count, quality, canUse, level, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', index);

	local bid = floor(minBid / count);
	local buy = floor(buyoutPrice / count);

	if name == auctionData.itemName and itemId == auctionData.itemId and owner == auctionData.owner
		and bid == auctionData.bid and buy == auctionData.buy and count == auctionData.count then
		-- same index, we can buy it
		self:BuyItemByIndex(index);
	end
end

function AuctionFaster:BuyItemByIndex(index)
	local buyPrice = select(10, GetAuctionItemInfo('list', index))

	PlaceAuctionBid('list', index, buyPrice)
	CloseAuctionStaticPopups();
end