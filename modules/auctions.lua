---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local format = string.format;
local pairs = pairs;
--local C_AuctionHouse = C_AuctionHouse;
--local AuctionHouseUtil = AuctionHouseUtil;

--- @type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');
--- @class Auctions
local Auctions = AuctionFaster:NewModule('Auctions', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0');

--- Enable is a must so we know when AH has been closed or opened, all events are handled in this module
function Auctions:Enable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	self:Hook(C_AuctionHouse, 'SendBrowseQuery', 'SendBrowseQueryHook', true);
end

function Auctions:SendBrowseQueryHook(q)
	--DevTools_Dump(q);
end

function Auctions:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:RegisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_SEARCH_RESULTS_UPDATED');

	self:RegisterEvent('AUCTION_MULTISELL_UPDATE');
	self:RegisterEvent('UI_ERROR_MESSAGE');
end

function Auctions:AUCTION_HOUSE_CLOSED()
	self:UnregisterEvent('AUCTION_MULTISELL_UPDATE');
	self:UnregisterEvent('UI_ERROR_MESSAGE');
end


Auctions.currentQuery = nil;
Auctions.currentCallback = nil;
Auctions.retries = 0;
-- this is used to prevent checking if everything has been sold
Auctions.lastSoldTimestamp = 0;
-- this is used for checking if everything has been sold
Auctions.soldFlag = false;

--function AuctionHouseBrowseResultsFrameMixin:OnEvent(event, ...)
--	if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
--		self:UpdateBrowseResults();
--	elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
--		local addedBrowseResults = ...;
--		self:UpdateBrowseResults(addedBrowseResults);
--	elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
--		self.ItemList:SetCustomError(RED_FONT_COLOR:WrapTextInColorCode(ERR_AUCTION_DATABASE_ERROR));
--	end
--end

--- NEW system for quering AH

--- Query auction house to search for items
function Auctions:QueryAuctions(query, callback)
	query = query or Auctions.currentQuery;
	callback = callback or Auctions.currentCallback;
	Auctions.currentQuery = query;
	Auctions.currentCallback = callback;

	if self.currentlyQuerying then
		return ;
	end

	self.currentlyQuerying = true;

	local cq = {};
	cq.searchString = query.name or '';
	cq.minLevel = query.minLevel or 0;
	cq.maxLevel = query.maxLevel or 0;
	cq.filters = {
		4,
		5,
		6,
		7,
		8,
		10,
		9
	}
	cq.itemClassFilters = nil --filterData;
	cq.sorts = {
		{
			sortOrder = Enum.AuctionHouseSortOrder.Price,
			reverseSort = false
		},
		{
			sortOrder = Enum.AuctionHouseSortOrder.Buyout,
			reverseSort = false
		},
	};

	C_AuctionHouse.SendBrowseQuery(cq);

	Auctions.retries = 0;
	self.currentlyQuerying = false;
end

function Auctions:SearchFavoriteItems(query, callback)
	query = query or Auctions.currentQuery;
	callback = callback or Auctions.currentCallback;
	Auctions.currentQuery = query;
	Auctions.currentCallback = callback;

	if self.currentlyQuerying then
		return ;
	end

	self.currentlyQuerying = true;

	local sorts = {
		{
			sortOrder = Enum.AuctionHouseSortOrder.Price,
			reverseSort = false
		},
		{
			sortOrder = Enum.AuctionHouseSortOrder.Buyout,
			reverseSort = false
		},
	};

	C_AuctionHouse.SearchForFavorites(sorts)

	Auctions.retries = 0;
	self.currentlyQuerying = false;
end

Auctions.searchResults = {};

--- Fetch auction house results
function Auctions:AUCTION_HOUSE_BROWSE_RESULTS_UPDATED()
	if not self.currentCallback then
		return ;
	end

	local browseResults = C_AuctionHouse.GetBrowseResults();

	print('amount of items ', #browseResults)
	local waitingForKeyInfo = false;
	self.searchResults = {};
	for _, result in pairs(browseResults) do
		local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(result.itemKey);
		if not itemKeyInfo then
			waitingForKeyInfo = true;
			self:RegisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
		end

		local itemInfo = {
			name = itemKeyInfo and itemKeyInfo.itemName or nil,
			quality = itemKeyInfo and itemKeyInfo.quality or nil,
			texture = itemKeyInfo and itemKeyInfo.iconFileID or nil,
			itemId = result.itemKey.itemID,
			level = result.itemKey.itemLevel,
			battlePetSpeciesID = result.battlePetSpeciesID,
			isCommodity = itemKeyInfo and itemKeyInfo.isCommodity or nil,
			count = result.totalQuantity,
			itemKey = result.itemKey,
			buy = result.minPrice
		};

		if itemKeyInfo then
			itemInfo.itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(result.itemKey, itemKeyInfo, false);
		end
		tinsert(self.searchResults, itemInfo);
	end

	table.sort(self.searchResults, function(a,b)
		return a.buy < b.buy;
	end)

	if not waitingForKeyInfo then
		self.currentCallback(self.searchResults);
		-- no longer our scan
		self.currentCallback = nil;
	else
		self.keyInfoTimeout = self:ScheduleTimer('WaitingForKeyInfoTimeout', 5);
	end
end

function Auctions:ITEM_KEY_ITEM_INFO_RECEIVED(_, itemId)
	local itemKey = C_AuctionHouse.MakeItemKey(itemId);
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);
	if not itemKeyInfo then
		return;
	end

	local infoComplete = true;
	for _, itemResult in pairs(self.searchResults) do
		if itemResult.itemId == itemId then
			itemResult.name = itemKeyInfo.itemName;
			itemResult.quality = itemKeyInfo.quality;
			itemResult.texture = itemKeyInfo and itemKeyInfo.iconFileID;
			itemResult.isCommodity = itemKeyInfo.isCommodity;
		end

		if not itemResult.name then
			infoComplete = false;
		end
	end

	if infoComplete then
		self.currentCallback(self.searchResults);
		-- no longer our scan
		self.currentCallback = nil;
		self:UnregisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
		if self.keyInfoTimeout then
			self:CancelTimer(self.keyInfoTimeout);
			self.keyInfoTimeout = nil;
		end
	end
end

function Auctions:WaitingForKeyInfoTimeout()
	self.currentCallback(self.searchResults);
	-- no longer our scan
	self.currentCallback = nil;
	self:UnregisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
	if self.keyInfoTimeout then
		self.keyInfoTimeout = nil;
	end
end

--- NEW system for querying specific item

function Auctions:QueryItem(itemKey, callback)
	self.subQueryCallback = callback;

	if C_AuctionHouse.HasSearchResults(itemKey) then
		local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);

		if itemKeyInfo.isCommodity then
			C_AuctionHouse.RefreshCommoditySearchResults(itemKey.itemID);
		else
			C_AuctionHouse.RefreshItemSearchResults(itemKey);
		end
	else
		print('sending query of item')
		local sorts = {
			sortOrder = Enum.AuctionHouseSortOrder.Price,
			reverseSort = false
		};
		C_AuctionHouse.SendSearchQuery(itemKey, sorts, true);
	end

	self.itemQueryTimeout = self:ScheduleTimer('SendItemQueryTimeout', 1);
end

function Auctions:SendItemQueryTimeout()
	if not self.subQueryCallback then
		return
	end

	self.subQueryCallback({});
	-- no longer our scan
	self.subQueryCallback = nil;
end

function Auctions:FetchCommodityResults(itemId)
	local items = {};
	local itemKey = C_AuctionHouse.MakeItemKey(itemId);
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);
	local itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(itemKey, itemKeyInfo, false);

	local numSearchResults = C_AuctionHouse.GetNumCommoditySearchResults(itemId);
	print('NUM RESULTS', numSearchResults);
	for i = 1, numSearchResults do
		local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemId, i);
		tinsert(items, {
			itemId = info.itemID,
			count = info.quantity,
			buy = info.unitPrice,
			auctionId = info.auctionID,
			owners = info.owners,
			owner = table.concat(info.owners, ', '),
			timeLeft = info.timeLeftSeconds,
			numItems = info.numOwnerItems,
			containsOwnerItem = info.containsOwnerItem,
			containsAccountItem = info.containsAccountItem,
			texture = itemKeyInfo.iconFileID,
			isCommodity = true,
			name = itemKeyInfo.itemName,
			quality = itemKeyInfo.quality,
			level = 0,
			itemKey = itemKey,
			itemLink = itemLink,
		});
	end

	return items, numSearchResults;
end

function Auctions:COMMODITY_SEARCH_RESULTS_UPDATED(_, itemId)
	if not self.subQueryCallback then
		return ;
	end

	print('trying to get all commodity items', itemId);
	local items, numSearchResults = self:FetchCommodityResults(itemId);

	if numSearchResults > 0 then
		self.subQueryCallback(items);

		-- no longer our scan
		self.subQueryCallback = nil;
		if self.itemQueryTimeout then
			self:CancelTimer(self.itemQueryTimeout);
		end
	end
end

function Auctions:ITEM_SEARCH_RESULTS_UPDATED()
	if not self.subQueryCallback then
		return ;
	end

	local items = {};
	local itemId = self.currentItemInfo.itemKey.itemID;
	print('trying to get all commodity items', itemId)
	--DevTools_Dump(self.currentItemInfo)
	local numSearchResults = C_AuctionHouse.GetNumItemSearchResults(self.currentItemInfo.itemKey);

	for i = 1, numSearchResults do
		local info = C_AuctionHouse.GetItemSearchResultInfo(self.currentItemInfo.itemKey, i);

		--itemKey	structure ItemKey
		--owners	string[]
		--timeLeft	Enum.AuctionHouseTimeLeftBand
		--auctionID	number
		--quantity	number
		--itemLink	string (nilable)
		--containsOwnerItem	boolean
		--containsSocketedItem	boolean
		--bidder	string (nilable)
		--minBid	number (nilable)
		--bidAmount	number (nilable)
		--buyoutAmount	number (nilable)
		--timeLeftSeconds	number (nilable)

		tinsert(items, {
			itemId = info.itemID,
			count = info.quantity,
			bid = info.bidAmount,
			buy = info.buyoutAmount,
			auctionId = info.auctionID,
			owners = info.owners,
			owner = table.concat(info.owners, ', '),
			timeLeft = info.timeLeftSeconds,
			numItems = info.numOwnerItems,
			isCommodity = false,
			containsOwnerItem = info.containsOwnerItem,
			containsSocketedItem = info.containsSocketedItem,
			texture = self.currentItemInfo.texture,
			name = self.currentItemInfo.name,
			quality = self.currentItemInfo.quality,
			itemKey = self.currentItemInfo.itemKey,
			itemLink = info.itemLink,
			itemLinkProper = info.itemLink,
		});
	end

	-- wait for next event
	if numSearchResults > 0 then
		self.subQueryCallback(items);

		-- no longer our scan
		self.subQueryCallback = nil;
		if self.itemQueryTimeout then
			self:CancelTimer(self.itemQueryTimeout);
		end
	end
end

--- TODO

function Auctions:PutItemInSellBox(itemId, itemName, itemQuality, itemLevel)
	-- Since there is no way to check level of sold item, clear item regardless
	local currentItemName = GetAuctionSellItemInfo();
	if currentItemName then
		if CursorHasItem() then
			ClearCursor();
		end
		ClickAuctionSellItemButton();
		ClearCursor();
	end

	local bag, slot = Inventory:GetItemFromInventory(itemId, itemName, itemQuality, itemLevel);
	if not bag or not slot then
		return false;
	end

	PickupContainerItem(bag, slot);
	if not CursorHasItem() then
		AuctionFaster:Echo(3, L['Could not pick up item from inventory']);
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

function Auctions:CalculateDeposit(itemId, itemName, itemQuality, itemLevel, settings)
	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = settings.duration;
	end

	if not self:PutItemInSellBox(itemId, itemName, itemQuality, itemLevel) then
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

function Auctions:HasAuctionsList()
	local auctionName = GetAuctionItemInfo('list', 1);
	return auctionName and true or false;
end

function Auctions:BuyItem(auctionData, qty)
	print('BUYING ITEM ?COMMODITY', auctionData.isCommodity, auctionData.auctionId)
	if auctionData.isCommodity then
		print('buying commodity', auctionData.itemId, qty)
		C_AuctionHouse.StartCommoditiesPurchase(auctionData.itemId, qty)
		C_AuctionHouse.ConfirmCommoditiesPurchase(auctionData.itemId, qty);
	else
		C_AuctionHouse.PlaceBid(auctionData.auctionId, auctionData.buy);
	end

	return true;
end

function Auctions:BuyCommodity(itemId, qty)
	C_AuctionHouse.StartCommoditiesPurchase(itemId, qty)
	C_AuctionHouse.ConfirmCommoditiesPurchase(itemId, qty);
end

local failedAuctionErrors = {
	[ERR_NOT_ENOUGH_MONEY] = 'ERR_NOT_ENOUGH_MONEY',
	[ERR_AUCTION_BAG] = 'ERR_AUCTION_BAG',
	[ERR_AUCTION_BOUND_ITEM] = 'ERR_AUCTION_BOUND_ITEM',
	[ERR_AUCTION_CONJURED_ITEM] = 'ERR_AUCTION_CONJURED_ITEM',
	[ERR_AUCTION_DATABASE_ERROR] = 'ERR_AUCTION_DATABASE_ERROR',
	[ERR_AUCTION_ENOUGH_ITEMS] = 'ERR_AUCTION_ENOUGH_ITEMS',
	[ERR_AUCTION_HOUSE_DISABLED] = 'ERR_AUCTION_HOUSE_DISABLED',
	[ERR_AUCTION_LIMITED_DURATION_ITEM] = 'ERR_AUCTION_LIMITED_DURATION_ITEM',
	[ERR_AUCTION_LOOT_ITEM] = 'ERR_AUCTION_LOOT_ITEM',
	[ERR_AUCTION_QUEST_ITEM] = 'ERR_AUCTION_QUEST_ITEM',
	[ERR_AUCTION_REPAIR_ITEM] = 'ERR_AUCTION_REPAIR_ITEM',
	[ERR_AUCTION_USED_CHARGES] = 'ERR_AUCTION_USED_CHARGES',
	[ERR_AUCTION_WRAPPED_ITEM] = 'ERR_AUCTION_WRAPPED_ITEM',
	[ERR_AUCTION_REPAIR_ITEM] = 'ERR_AUCTION_REPAIR_ITEM',
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
	self.lastSoldTimestamp = GetTime();
	self.soldFlag = true;

	local isMultisell = numStacks > 1;

	if self.lastUIError and failedAuctionErrors[self.lastUIError] then
		self.lastSoldItem = nil;
		return false, false;
	end

	AuctionFaster:Echo(
		1,
		format(
			L['Posting: %s for:\nper auction: %s\nper item: %s\n# stacks: %d stack size: %d'],
			self.lastSoldItem,
			StdUi.Util.formatMoney(buy),
			StdUi.Util.formatMoney(buy / stackSize),
			numStacks,
			stackSize
		)
	);
	return true, isMultisell;
end