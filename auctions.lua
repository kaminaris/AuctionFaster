--- @type StdUi
local StdUi = LibStub('StdUi');
local ItemCache = AuctionFaster:GetModule('ItemCache');

function AuctionFaster:SetAuctionSort()
	self.currentlySorting = true;
	SortAuctionItems('list', 'unitprice');

	if IsAuctionSortReversed('list', 'unitprice') then
		SortAuctionItems('list', 'unitprice');
	end

	self.currentlySorting = false;
end

function AuctionFaster:CanSendAuctionQuery()
	if not CanSendAuctionQuery() then
		StdUi:Dialog('Error', 'Cannot query auction house, please reload UI', 'AFError');
		return false;
	end
	return true;
end

function AuctionFaster:FindAuctionIndex(auctionData)
	for index = 1, 50 do
		local name, _, count, _, _, _, _, minBid, _, buyoutPrice, _, _, _, owner, _, _, itemId = GetAuctionItemInfo('list', index);

		local bid = floor(minBid / count);
		local buy = floor(buyoutPrice / count);

		if
			name == auctionData.itemName and
			itemId == auctionData.itemId and
			--owner == auctionData.owner and -- actually there is no need to check owner
			bid == auctionData.bid and
			buy == auctionData.buy and
			count == auctionData.count
		then
			return index, name, count;
		end
	end

	return false, '', 0;
end

function AuctionFaster:GetCurrentAuctions(force)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	local cacheItem = ItemCache:GetItemFromCache(itemId, itemName);
	-- We still have pretty recent results from auction house, no need to scan again
	if not force and cacheItem and cacheItem.auctions and #cacheItem.auctions > 0 then
		self:UpdateSellTabAuctions(cacheItem);
		self:UpdateInfoPaneText();
		return ;
	end

	if self.currentlyQuerying or not self:CanSendAuctionQuery() then
		return ;
	end

	self:SetAuctionSort();

	self.currentlyQuerying = true;
	self.afScan = 'CurrentAuctions';
	QueryAuctionItems(itemName, nil, nil, 0, 0, 0, false, true);
	self.currentlyQuerying = false;
end

local itemKeys = {
	'name', 'texture', 'count', 'quality', 'canUse', 'level', 'levelColHeader', 'minBid',
	'minIncrement', 'buyoutPrice', 'bidAmount', 'highBidder', 'bidderFullName', 'owner',
	'ownerFullName', 'saleStatus', 'itemId', 'hasAllInfo'
};
function AuctionFaster:GetItemFromAuctionList(index)
	return self:TableCombine(itemKeys, {GetAuctionItemInfo('list', index)});
end

function AuctionFaster:AUCTION_ITEM_LIST_UPDATE()
	if self.currentlySorting or not self.afScan then
		return;
	end

	local shown, total = GetNumAuctionItems('list');
	local items = {};

	local hasAllInfo = true;
	for i = 1, shown do
		local itemInfo = self:GetItemFromAuctionList(i);

		if not itemInfo.hasAllInfo or not itemInfo.owner then
			hasAllInfo = false;
		end

		items[i] = itemInfo;
	end

	-- wait for next event
	if not hasAllInfo then
		return;
	end

	if self.afScan == 'CurrentAuctions' then
		self:CurrentAuctionsCallback(shown, total, items);
	elseif self.afScan == 'SearchAuctions' then
		self:SearchAuctionsCallback(shown, total, items);
	end

	-- no longer our scan
	self.afScan = false;
end

function AuctionFaster:UnderCutPrices(cacheItem, lowestBid, lowestBuy)
	if #cacheItem.auctions < 1 then
		return ;
	end

	if not lowestBid or not lowestBuy then
		lowestBid, lowestBuy = self:FindLowestBidBuy(cacheItem);
	end

	cacheItem.bid = lowestBid - 1;
	cacheItem.buy = lowestBuy - 1;

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

function AuctionFaster:PutItemInSellBox(itemId, itemName)
	local currentItemName = GetAuctionSellItemInfo();
	if currentItemName and currentItemName == itemName then
		return true;
	end

	local bag, slot = self:GetItemFromInventory(itemId, itemName);
	if not bag or not slot then
		return false;
	end

	PickupContainerItem(bag, slot);
	if not CursorHasItem() then
		return false;
	end

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = 2;
	end

	-- This only puts item in sell slot despite name
	ClickAuctionSellItemButton();
	ClearCursor();

	return true;
end

function AuctionFaster:CalculateDeposit(itemId, itemName)
	local sellSettings = self:GetSellSettings();
	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = sellSettings.duration;
	end

	if not self:PutItemInSellBox(itemId, itemName) then
		return 0;
	end

	return CalculateAuctionDeposit(sellSettings.duration);
end

function AuctionFaster:BuyItemByIndex(index)
	local buyPrice = select(10, GetAuctionItemInfo('list', index))

	PlaceAuctionBid('list', index, buyPrice);
	CloseAuctionStaticPopups();
end

local failedAuctionErrors = {
	[ERR_NOT_ENOUGH_MONEY]              = 'ERR_NOT_ENOUGH_MONEY',
	[ERR_AUCTION_BAG]                   = 'ERR_AUCTION_BAG',
	[ERR_AUCTION_BOUND_ITEM]            = 'ERR_AUCTION_BOUND_ITEM',
	[ERR_AUCTION_CONJURED_ITEM]         = 'ERR_AUCTION_CONJURED_ITEM',
	[ERR_AUCTION_DATABASE_ERROR]        = 'ERR_AUCTION_DATABASE_ERROR',
	[ERR_AUCTION_ENOUGH_ITEMS]          = 'ERR_AUCTION_ENOUGH_ITEMS',
	[ERR_AUCTION_HOUSE_DISABLED]        = 'ERR_AUCTION_HOUSE_DISABLED',
	[ERR_AUCTION_LIMITED_DURATION_ITEM] = 'ERR_AUCTION_LIMITED_DURATION_ITEM',
	[ERR_AUCTION_LOOT_ITEM]             = 'ERR_AUCTION_LOOT_ITEM',
	[ERR_AUCTION_QUEST_ITEM]            = 'ERR_AUCTION_QUEST_ITEM',
	[ERR_AUCTION_REPAIR_ITEM]           = 'ERR_AUCTION_REPAIR_ITEM',
	[ERR_AUCTION_USED_CHARGES]          = 'ERR_AUCTION_USED_CHARGES',
	[ERR_AUCTION_WRAPPED_ITEM]          = 'ERR_AUCTION_WRAPPED_ITEM',
	[ERR_AUCTION_REPAIR_ITEM]           = 'ERR_AUCTION_REPAIR_ITEM',
}

function AuctionFaster:SellItem(bid, buy, duration, stackSize, numStacks)
	self.lastUIError = nil;
	self.lastSoldItem = GetAuctionSellItemInfo();
	StartAuction(bid, buy, duration, stackSize, numStacks);

	local isMultisell = numStacks > 1;

	if self.lastUIError and failedAuctionErrors[self.lastUIError] then
		self.lastSoldItem = nil;
		return false, false;
	end

	return true, isMultisell;
end