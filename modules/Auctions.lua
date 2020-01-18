---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local format = string.format;
local pairs = pairs;

--- @type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');
--- @class Auctions
local Auctions = AuctionFaster:NewModule('Auctions', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0');

local defaultSorts = {
	{
		sortOrder   = Enum.AuctionHouseSortOrder.Price,
		reverseSort = false
	},
	{
		sortOrder   = Enum.AuctionHouseSortOrder.Buyout,
		reverseSort = false
	},
};

--- Enable is a must so we know when AH has been closed or opened, all events are handled in this module
function Auctions:Enable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	--self:Hook(C_AuctionHouse, 'SendBrowseQuery', 'SendBrowseQueryHook', true);
	--self:Hook(C_AuctionHouse, 'PostItem', 'PostItemHook', true);
end

--function Auctions:SendBrowseQueryHook(q)
--	DevTools_Dump(q);
--end
--
--function Auctions:PostItemHook(...)
--	local x = {...};
--	for i, v in pairs(x) do
--		if i > 1 then
--			DevTools_Dump(v);
--		end
--	end
--end

function Auctions:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:RegisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');

	self:RegisterEvent('AUCTION_MULTISELL_UPDATE');
	self:RegisterEvent('UI_ERROR_MESSAGE');
end

function Auctions:AUCTION_HOUSE_CLOSED()
	self:UnregisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:UnregisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:UnregisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
	self:UnregisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');

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
	cq.filters = query.filters or {
		4,
		5,
		6,
		7,
		8,
		9,
		10
	}
	cq.itemClassFilters = query.itemClassFilters or nil;
	cq.sorts = defaultSorts;

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

	local sorts = defaultSorts;

	C_AuctionHouse.SearchForFavorites(sorts)

	Auctions.retries = 0;
	self.currentlyQuerying = false;
end

Auctions.searchResults = {};

function Auctions:ScanBrowseResults()
	local browseResults = C_AuctionHouse.GetBrowseResults();

	local waitingForKeyInfo = false;
	local searchResults = {};
	for _, result in pairs(browseResults) do
		local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(result.itemKey);
		if not itemKeyInfo then
			waitingForKeyInfo = true;
		end

		local itemInfo = {
			name               = itemKeyInfo and itemKeyInfo.itemName or nil,
			quality            = itemKeyInfo and itemKeyInfo.quality or nil,
			texture            = itemKeyInfo and itemKeyInfo.iconFileID or nil,
			itemId             = result.itemKey.itemID,
			level              = result.itemKey.itemLevel,
			battlePetSpeciesID = result.battlePetSpeciesID,
			isCommodity        = itemKeyInfo and itemKeyInfo.isCommodity or nil,
			count              = result.totalQuantity,
			itemKey            = result.itemKey,
			buy                = result.minPrice
		};

		if itemKeyInfo then
			itemInfo.itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(result.itemKey, itemKeyInfo, false);
		end
		tinsert(searchResults, itemInfo);
	end

	table.sort(searchResults, function(a, b)
		return a.buy < b.buy;
	end);

	return searchResults;
end

--- Fetch auction house results
function Auctions:AUCTION_HOUSE_BROWSE_RESULTS_UPDATED()
	self.searchResults = self:ScanBrowseResults();

	if self.currentCallback then
		if not waitingForKeyInfo then
			self.currentCallback(self.searchResults);
			-- no longer our scan
			self.currentCallback = nil;
		else
			self.keyInfoTimeout = self:ScheduleTimer('WaitingForKeyInfoTimeout', 5);
		end
	end
end

function Auctions:ITEM_KEY_ITEM_INFO_RECEIVED(_, itemId)
	local infoComplete = true;
	for _, itemResult in pairs(self.searchResults) do

		if itemResult.itemId == itemId then
			local itemKey = itemResult.itemKey;
			local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);

			itemResult.name = itemKeyInfo.itemName;
			itemResult.quality = itemKeyInfo.quality;
			itemResult.texture = itemKeyInfo and itemKeyInfo.iconFileID;
			itemResult.isCommodity = itemKeyInfo.isCommodity;
			itemResult.itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(itemKey, itemKeyInfo, false);
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
		C_AuctionHouse.SendSearchQuery(itemKey, defaultSorts, true);
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

function Auctions:ScanCommodityResults(itemId)
	local items = {};
	local itemKey = C_AuctionHouse.MakeItemKey(itemId);
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);
	local itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(itemKey, itemKeyInfo, false);

	local numSearchResults = C_AuctionHouse.GetNumCommoditySearchResults(itemId);

	for i = 1, numSearchResults do
		local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemId, i);

		tinsert(items, {
			itemId              = info.itemID,
			count               = info.quantity,
			buy                 = info.unitPrice,
			auctionId           = info.auctionID,
			owners              = info.owners,
			owner               = table.concat(info.owners, ', '),
			timeLeft            = info.timeLeftSeconds,
			numItems            = info.numOwnerItems,
			containsOwnerItem   = info.containsOwnerItem,
			containsAccountItem = info.containsAccountItem,
			texture             = itemKeyInfo.iconFileID,
			isCommodity         = true,
			name                = itemKeyInfo.itemName,
			quality             = itemKeyInfo.quality,
			level               = 0,
			itemKey             = itemKey,
			itemLink            = itemLink,
		});
	end

	return items, numSearchResults;
end

function Auctions:COMMODITY_SEARCH_RESULTS_UPDATED(_, itemId)
	if not self.subQueryCallback then
		return ;
	end

	local items = self:ScanCommodityResults(itemId);

	if #items > 0 then
		self.subQueryCallback(items);

		-- no longer our scan
		self.subQueryCallback = nil;
		if self.itemQueryTimeout then
			self:CancelTimer(self.itemQueryTimeout);
		end
	end
end

function Auctions:ScanItemResults(itemKey)
	local items = {};
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);
	local numSearchResults = C_AuctionHouse.GetNumItemSearchResults(itemKey);

	for i = 1, numSearchResults do
		local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, i);

		tinsert(items, {
			itemId               = info.itemID,
			count                = info.quantity,
			bid                  = info.bidAmount,
			buy                  = info.buyoutAmount,
			auctionId            = info.auctionID,
			owners               = info.owners,
			owner                = table.concat(info.owners, ', '),
			timeLeft             = info.timeLeftSeconds,
			numItems             = info.numOwnerItems,
			isCommodity          = false,
			containsOwnerItem    = info.containsOwnerItem,
			containsSocketedItem = info.containsSocketedItem,
			texture              = itemKeyInfo.texture,
			name                 = itemKeyInfo.name,
			quality              = itemKeyInfo.quality,
			itemKey              = itemKey,
			itemLink             = info.itemLink,
			itemLinkProper       = info.itemLink,
		});
	end

	return items;
end

function Auctions:ITEM_SEARCH_RESULTS_UPDATED(_, itemKey)
	if not self.subQueryCallback then
		return ;
	end

	local items = self:ScanItemResults(itemKey);

	-- wait for next event
	if #items > 0 then
		self.subQueryCallback(items);

		-- no longer our scan
		self.subQueryCallback = nil;
		if self.itemQueryTimeout then
			self:CancelTimer(self.itemQueryTimeout);
		end
	end
end

--- TODO
function Auctions:SellItem(itemLocation, qty, duration, price, bid)
	local isCommodity = C_AuctionHouse.GetItemCommodityStatus(itemLocation) == 2;
	local listCount = C_AuctionHouse.GetAvailablePostCount(itemLocation);
	local isValid = C_AuctionHouse.IsSellItemValid(itemLocation);

	if qty > listCount or not isValid then
		return false;
	end

	if isCommodity then
		C_AuctionHouse.PostCommodity(itemLocation, duration, qty, price);
	else
		if bid and bid > 0 and bid ~= price then
			C_AuctionHouse.PostItem(itemLocation, duration, qty, bid, price);
		else
			C_AuctionHouse.PostItem(itemLocation, duration, qty, nil, price);
		end
	end

	return true;
end

function Auctions:CalculateDeposit(itemLocation, settings)
	local isCommodity = C_AuctionHouse.GetItemCommodityStatus(itemLocation) == 2;
	local itemKey = C_AuctionHouse.GetItemKeyFromItem(itemLocation);

	if isCommodity then
		return C_AuctionHouse.CalculateCommodityDeposit(itemKey.itemID, settings.duration, settings.stackSize)
	else
		return C_AuctionHouse.CalculateItemDeposit(itemLocation, settings.duration, settings.stackSize)
	end
end

function Auctions:BuyItem(auctionData, qty, callback)
	print('BUYING ITEM/COMMODITY', auctionData.isCommodity, auctionData.auctionId)
	if auctionData.isCommodity then
		print('buying commodity', auctionData.itemId, qty)
		self:BuyCommodity(auctionData.itemId, qty, auctionData.buy, callback)
	else
		print('buying item', auctionData.auctionId, auctionData.buy)
		C_AuctionHouse.PlaceBid(auctionData.auctionId, auctionData.buy);
	end

	return true;
end

function Auctions:BuyCommodity(itemId, qty, unitPrice)
	C_AuctionHouse.StartCommoditiesPurchase(itemId, qty, unitPrice);
	C_AuctionHouse.ConfirmCommoditiesPurchase(itemId, qty);
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