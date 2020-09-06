---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @var StdUi StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

--- @type ConfirmBuy
local ConfirmBuy = AuctionFaster:GetModule('ConfirmBuy');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');

local format = string.format;
local TableInsert = tinsert;

function Buy:Attach()
	self:AddBuyAuctionHouseTab();
	self:InterceptLinkClick();
end

function Buy:Detach()
end

function Buy:OnShow()
	self.buyTab.items = {};

	self:UpdateSearchAuctions();
	self:UpdateStateText();

	self:InitTutorial();
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_ADDED');
	self:RegisterEvent('AUCTION_HOUSE_BROWSE_FAILURE');
	self:RegisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
end

--	if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
--		self:UpdateBrowseResults();
--	elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
--		local addedBrowseResults = ...;
--		self:UpdateBrowseResults(addedBrowseResults);
--	elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
--		self.ItemList:SetCustomError(RED_FONT_COLOR:WrapTextInColorCode(ERR_AUCTION_DATABASE_ERROR));
--	end

function Buy:OnHide()
	self:UnregisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_UPDATED');
	self:UnregisterEvent('AUCTION_HOUSE_BROWSE_RESULTS_ADDED');
	self:UnregisterEvent('AUCTION_HOUSE_BROWSE_FAILURE');
	self:UnregisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
end

function Buy:AUCTION_HOUSE_BROWSE_RESULTS_UPDATED()
	local items = Auctions:ScanBrowseResults();
	self.buyTab.items = items;

	self:UpdateSearchAuctions(items);
	self:UpdateStateText();
end

function Buy:ITEM_KEY_ITEM_INFO_RECEIVED(_, itemId)
	local itemUpdated = false;

	for _, itemResult in pairs(self.buyTab.items) do
		if itemResult.itemId == itemId then
			local itemKey = itemResult.itemKey;
			local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);
			if itemKeyInfo then
				itemResult.name = itemKeyInfo.itemName;
				itemResult.quality = itemKeyInfo.quality;
				itemResult.texture = itemKeyInfo.iconFileID;
				itemResult.isCommodity = itemKeyInfo.isCommodity;
				itemResult.itemLink = AuctionHouseUtil.GetItemDisplayTextFromItemKey(itemKey, itemKeyInfo, false);
				itemUpdated = true;
			end
		end
	end

	if itemUpdated then
		self:UpdateSearchAuctions(self.buyTab.items);
	end
end

function Buy:AUCTION_HOUSE_BROWSE_RESULTS_ADDED(...)
	--print(...)
end

function Buy:AUCTION_HOUSE_BROWSE_FAILURE()
	self:UpdateSearchAuctions({});
	self:UpdateStateText(false, true);
end

----------------------------------------------------------------------------
--- Searching functions
----------------------------------------------------------------------------

function Buy:SearchAuctions(name, exact)
	self.currentQuery = {
		name = name,
		exact = exact or false,
	};

	self:ApplyFilters(self.currentQuery);

	self:ClearSearchAuctions();
	self:UpdateStateText(true);
	self:SaveRecentSearches(name);

	Auctions:QueryAuctions(self.currentQuery);
end

function Buy:SearchFavoriteItems()
	self.currentQuery = {
		favorites = true,
	};

	self:ClearSearchAuctions();
	self:UpdateStateText(true);

	Auctions:SearchFavoriteItems(self.currentQuery);
end

function Buy:SaveRecentSearches(searchQuery)
	local rs = AuctionFaster.db.buy.recentSearches;
	local historyLimit = 100;

	for _, v in pairs(rs) do
		if v.text:lower() == searchQuery:lower() then
			return;
		end
	end

	TableInsert(rs, 1, {value = searchQuery, text = searchQuery});
	if #rs > historyLimit then
		for i = historyLimit + 1, #rs do
			rs[i] = nil;
		end
	end
end

function Buy:RefreshSearchAuctions()
	if not self.currentQuery then
		AuctionFaster:Echo(3, L['No query was searched before']);
		return;
	end

	if self.currentQuery.itemKey then
		-- sending another query
		self:SearchItem(self.currentQuery.itemKey);
	else
		self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact);
	end
end

----------------------------------------------------------------------------
--- Searching callback function
----------------------------------------------------------------------------

function Buy:UpdateStateText(inProgress, failure)
	if failure then
		self.buyTab.stateLabel:SetText(RED_FONT_COLOR:WrapTextInColorCode(ERR_AUCTION_DATABASE_ERROR));
		self.buyTab.stateLabel:Show();
		return;
	end

	if inProgress then
		self.buyTab.stateLabel:SetText(L['Search in progress...']);
		self.buyTab.stateLabel:Show();
	elseif #self.buyTab.items == 0 then
		self.buyTab.stateLabel:SetText(L['Nothing was found for this query.']);
		self.buyTab.stateLabel:Show();
	else
		self.buyTab.stateLabel:Hide();
	end
end

function Buy:AddToFavorites()
	local searchBox = self.buyTab.searchBox;
	local text = searchBox:GetText();

	if not text or strlen(text) < 2 then
		--show error or something
		return ;
	end

	local favorites = AuctionFaster.db.favorites;
	for i = 1, #favorites do
		if favorites[i].text == text then
			--already exists - no error
			return ;
		end
	end

	TableInsert(favorites, { text = text });
	self:DrawFavorites();
end

function Buy:RemoveFromFavorites(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		tremove(favorites, i);
	end

	self:DrawFavorites();
end

function Buy:SearchFavorite(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		self.buyTab.searchBox:SetText(favorites[i].text);
		self:SearchAuctions(self.buyTab.searchBox:GetText(), false, 0);
	end
end

function Buy:RemoveCurrentSearchAuction()
	local index = self.buyTab.searchResults:GetSelection();
	if not index then
		return ;
	end

	if not self.buyTab.items[index] then
		return;
	end

	tremove(self.buyTab.items, index);
	self:UpdateSearchAuctions();

	if self.buyTab.items[index] then
		self.buyTab.searchResults:SetSelection(index);
	end
end

function Buy:UpdateSearchAuctions(items)
	items = items or {};
	self.buyTab.items = items;
	self.buyTab.searchResults:SetData(items, true);
end

function Buy:ClearSearchAuctions()
	self.buyTab.searchResults:SetData({}, true);
end

function Buy:LockBuyButton(lock)
	local buyButton = self.confirmFrame.buttons['ok'];

	if lock then
		buyButton:Disable();
	else
		buyButton:Enable();
	end
end

function Buy.CloseCallback()
	Buy:UpdateQueue();
	Buy:RefreshSearchAuctions();
end

function Buy:InstantBuy(rowData)
	ConfirmBuy:ConfirmPurchase(rowData.itemKey, rowData.isCommodity);
end


function Buy:InterceptLinkClick()
	if self.linksIntercepted then
		return;
	end

	local origChatEdit_InsertLink = ChatEdit_InsertLink;
	local origHandleModifiedItemClick = HandleModifiedItemClick;
	local function SearchItemLink(origMethod, link)
		if Buy.buyTab.searchBox:HasFocus() then
			local itemName = GetItemInfo(link);
			Buy.buyTab.searchBox:SetText(itemName);
			return true;
		else
			return origMethod(link);
		end
	end

	Buy:RawHook('HandleModifiedItemClick', function(link)
		return SearchItemLink(origHandleModifiedItemClick, link);
	end, true);

	Buy:RawHook('ChatEdit_InsertLink', function(link)
		return SearchItemLink(origChatEdit_InsertLink, link);
	end, true);

	self.linksIntercepted = true;
end