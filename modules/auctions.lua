--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type ItemCache
local Inventory = AuctionFaster:GetModule('Inventory');

--- @class Auctions
local Auctions = AuctionFaster:NewModule('Auctions', 'AceEvent-3.0', 'AceTimer-3.0');

--- Enable is a must so we know when AH has been closed or opened, all events are handled in this module
function Auctions:Enable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
end

function Auctions:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');

	self:RegisterEvent('AUCTION_MULTISELL_UPDATE');
	self:RegisterEvent('UI_ERROR_MESSAGE');
end

function Auctions:AUCTION_HOUSE_CLOSED()
	self:UnregisterEvent('AUCTION_MULTISELL_UPDATE');
	self:UnregisterEvent('UI_ERROR_MESSAGE');
end

function Auctions:SetAuctionSort()
	self.currentlySorting = true;
	local sortColumn, reversed = GetAuctionSort('list', 1);
	if sortColumn == 'unitprice' then
		-- at least there is no need to sort twice
		if reversed then
			SortAuctionItems('list', 'unitprice');
		end

		self.currentlySorting = false;
		return;
	end

	SortAuctionItems('list', 'unitprice');

	if IsAuctionSortReversed('list', 'unitprice') then
		SortAuctionItems('list', 'unitprice');
	end

	self.currentlySorting = false;
end

Auctions.currentQuery = nil;
Auctions.currentCallback = nil;
Auctions.retries = 0;

function Auctions:QueryAuctions(query, callback)
	query = query or Auctions.currentQuery;
	callback = callback or Auctions.currentCallback;
	Auctions.currentQuery = query;
	Auctions.currentCallback = callback;

	if self.currentlyQuerying then
		return;
	end


	if not CanSendAuctionQuery() then
		self.currentlyQuerying = false;
		if Auctions.retries < 5 then
			Auctions.retries = Auctions.retries + 1;
			print('Auctions.retries', Auctions.retries);

			self:ScheduleTimer('QueryAuctions', 0.8);
			return;
		else
			print('Cannot query AH. Please reload UI');
		end
	end

	self:SetAuctionSort();

	self.currentlyQuerying = true;
	--QueryAuctionItems("name", minLevel, maxLevel, page, isUsable, qualityIndex, getAll, exactMatch, filterData)
	QueryAuctionItems(
		query.name or '',
		query.minLevel,
		query.maxLevel,
		query.page or 0,
		query.isUsable,
		query.qualityIndex,
		false, -- No support for getAll
		query.exact or false,
		query.filterData or nil
	);

	Auctions.retries = 0;
	self.currentlyQuerying = false;
end

local itemKeys = {
	'name', 'texture', 'count', 'quality', 'canUse', 'level', 'levelColHeader', 'minBid',
	'minIncrement', 'buyoutPrice', 'bidAmount', 'highBidder', 'bidderFullName', 'owner',
	'ownerFullName', 'saleStatus', 'itemId', 'hasAllInfo'
};
function Auctions:GetItemFromAuctionList(index)
	local itemInfo = AuctionFaster:TableCombine(itemKeys, {GetAuctionItemInfo('list', index)});

	local _, itemLink = GetItemInfo(itemInfo.itemId);
	itemInfo.itemLink = itemLink;
	itemInfo.itemIndex = i;
	itemInfo.bid = floor(itemInfo.minBid / itemInfo.count);
	itemInfo.buy = floor(itemInfo.buyoutPrice / itemInfo.count);

	return itemInfo;
end

function Auctions:AUCTION_ITEM_LIST_UPDATE()
	if self.currentlySorting or not self.currentCallback then
		return;
	end

	local shown, total = GetNumAuctionItems('list');
	local items = {};

	local hasAllInfo = true;
	for i = 1, shown do
		local itemInfo = self:GetItemFromAuctionList(i);

		if not AuctionFaster:IsFastMode() and (not itemInfo.owner) then
			hasAllInfo = false;
		end

		if AuctionFaster:IsFastMode() and not itemInfo.owner then
			itemInfo.owner = '---';
		end

		items[i] = itemInfo;
	end

	-- wait for next event
	if not AuctionFaster:IsFastMode() and not hasAllInfo then
		return;
	end

	self.currentCallback(shown, total, items);

	-- no longer our scan
	self.currentCallback = nil;
end

function Auctions:PutItemInSellBox(itemId, itemName)
	local currentItemName = GetAuctionSellItemInfo();
	if currentItemName and currentItemName == itemName then
		return true;
	end

	local bag, slot = Inventory:GetItemFromInventory(itemId, itemName);
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

function Auctions:CalculateDeposit(itemId, itemName, settings)
	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = settings.duration;
	end

	if not self:PutItemInSellBox(itemId, itemName) then
		return 0;
	end

	--return GetAuctionDeposit(duration);
	return GetAuctionDeposit(
		settings.duration,
		settings.bidPerItem * settings.stackSize, -- minBid
		settings.buyPerItem * settings.stackSize, -- buyoutPrice
		settings.stackSize, -- itemCount
		settings.maxStacks -- numStacks
	);
end

function Auctions:FindAuctionIndex(auctionData)
	for index = 1, 50 do
		local listData = Auctions:GetItemFromAuctionList(index);

		if
		listData.name == auctionData.name and
			listData.itemId == auctionData.itemId and
			--listData.owner == auctionData.owner and -- actually there is no need to check owner
			listData.bid == auctionData.bid and
			listData.buy == auctionData.buy and
			listData.count == auctionData.count
		then
			return index, listData.name, listData.count;
		end
	end

	return false, '', 0;
end

function Auctions:BuyItemByIndex(index)
	local buyPrice = select(10, GetAuctionItemInfo('list', index))

	PlaceAuctionBid('list', index, buyPrice);
	CloseAuctionStaticPopups();
end

function Auctions:BuyItem(auctionData)
	local index = self:FindAuctionIndex(auctionData)
	if not index then
		return false;
	end

	self:BuyItemByIndex(index);
	return true;
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

function Auctions:UI_ERROR_MESSAGE(_, message)
	self.lastUIError = message;
end

function Auctions:AUCTION_MULTISELL_UPDATE(_, current, max)
	self.isInMultisellProcess = true;
	if current == max then
		self.isInMultisellProcess = false;
	end
end

function Auctions:SellItem(bid, buy, duration, stackSize, numStacks)
	self.lastUIError = nil;
	self.lastSoldItem = GetAuctionSellItemInfo();
	PostAuction(bid, buy, duration, stackSize, numStacks);

	local isMultisell = numStacks > 1;

	if self.lastUIError and failedAuctionErrors[self.lastUIError] then
		self.lastSoldItem = nil;
		return false, false;
	end

	return true, isMultisell;
end