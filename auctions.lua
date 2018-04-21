

function AuctionFaster:GetCurrentAuctions()
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local name = selectedItem.name;

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

	local tableData = {};
	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		tinsert(tableData, {
			owner,
			count,
			floor(minBid / count),
			floor(buyoutPrice / count),
		});
	end

	self.auctionTab.currentAuctions:SetData(tableData, true);
end