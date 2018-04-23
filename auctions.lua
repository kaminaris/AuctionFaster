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
	self:UnderCutPrices(cachedItem);
end

function AuctionFaster:UnderCutPrices(cachedItem)
	if #cachedItem.auctions < 1 then
		return;
	end

	local lowestBid, lowestBuy = self:FindLowestBidBuy(cachedItem);

	self:UpdateTabPrices(lowestBid - 1, lowestBuy - 1);
end

function AuctionFaster:FindLowestBidBuy(cachedItem)
	if #cachedItem.auctions < 1 then
		return nil, nil;
	end

	local lowestBid, lowestBuy;
	for i = 1, #cachedItem.auctions do
		local auc = cachedItem.auctions[i];
		if auc[3] > 0 and (not lowestBid or lowestBid > auc[3]) then
			lowestBid = auc[3];
		end

		if auc[4] > 0 and (not lowestBuy or lowestBuy > auc[4]) then
			lowestBuy = auc[4];
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
	DevTools_Dump(sellSettings);
--[[

	PickupContainerItem(bag, slot);
	if not CursorHasItem() then
		return;
	end

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = 2
	end
	--ClickAuctionSellItemButton()
	StartAuction(minBid, buyoutPrice, runTime, stackSize, numStacks)
	]]--
end