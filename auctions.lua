AuctionFaster.auctionDb = {};

function AuctionFaster:GetItemFromCache(itemId, itemName)
	if self.auctionDb[itemId .. itemName] then
		local item = self.auctionDb[itemId .. itemName];
		if ((GetTime() - item.scanTime) > 60 * 10) then -- older than 10 minutes
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

	local cachedItem = self:GetItemFromCache(itemId, name);
	if (cachedItem) then
		self:UpdateAuctionTable(cachedItem);
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

function AuctionFaster:AUCTION_ITEM_LIST_UPDATE(a, b, c, d)
	if (self.currentlySorting) then
		return;
	end

	print(a, b, c, d);
	local shown, total = GetNumAuctionItems('list');

	-- since we did scan anyway, put it in cache

	local cacheKey;
	local cachedItem = {
		scanTime = GetTime(),
		auctions = {}
	};

	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		if not cacheKey then
			cachedItem.itemName = name;
			cachedItem.itemId = itemId;
			cacheKey = itemId .. name;
		end

		tinsert(cachedItem.auctions, {
			owner,
			count,
			floor(minBid / count),
			floor(buyoutPrice / count),
		});
	end

	table.sort(cachedItem.auctions, function(a, b)
		return a[4] < b[4];
	end);

	self.auctionDb[cacheKey] = cachedItem;
	self:UpdateAuctionTable(cachedItem);
end

function AuctionFaster:UpdateAuctionTable(cachedItem)
	self.auctionTab.currentAuctions:SetData(cachedItem.auctions, true);
	self.auctionTab.lastScan:SetText('Last Scan: ' .. self:FormatDuration(GetTime() - cachedItem.scanTime));
	self:UpdateInventoryItemPrice(cachedItem.itemId, cachedItem.itemName, cachedItem.auctions[1][4]);
end