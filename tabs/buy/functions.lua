---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @var StdUi StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

--- @type AuctionCache
local AuctionCache = AuctionFaster:GetModule('AuctionCache');
--- @type ConfirmBuy
local ConfirmBuy = AuctionFaster:GetModule('ConfirmBuy');

local format = string.format;
local TableInsert = tinsert;

function Buy:Enable()
	self:AddBuyAuctionHouseTab();
	self:InterceptLinkClick();
end

function Buy:OnShow()

	self.buyTab.auctions = {};
	self.buyTab.items = {};

	self:UpdateSearchAuctions();
	self:UpdateStateText();

	self:InitTutorial();
end

function Buy:OnHide()

end

function Buy:Disable()
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

	Auctions:QueryAuctions(self.currentQuery, function(items)
		Buy:SearchAuctionsCallback(items)
	end);
end

function Buy:SearchItem(itemKey)
	self.currentQuery = {
		itemKey = itemKey,
	};

	-- no need for filter if we are searching for specific item
	-- self:ApplyFilters(self.currentQuery);

	self:ClearSearchAuctions();
	self:UpdateStateText(true);

	Auctions:QueryItem(self.currentQuery, function(items)
		Buy:SearchItemCallback(items)
	end);
end

function Buy:SearchFavoriteItems()
	self.currentQuery = {
		favorites = true,
	};

	self:ClearSearchAuctions();
	self:UpdateStateText(true);

	Auctions:SearchFavoriteItems(self.currentQuery, function(items)
		Buy:SearchItemCallback(items)
	end);
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

function Buy:SearchAuctionsCallback(items)
	print(#items)
	-- TODO: this needs to be done twice
	-- AuctionCache:ParseScanResults(items);
	self.buyTab.items = items;
	self.mode = 'items';

	self:UpdateSearchAuctions();
	self:UpdateStateText();
end

function Buy:SearchItemCallback(items)
	print(#items)
	AuctionCache:ParseScanResults(items);
	self.buyTab.auctions = items;
	self.mode = 'auctions';

	self:UpdateSearchAuctions();
	self:UpdateStateText();
end

function Buy:UpdateStateText(inProgress)
	if inProgress then
		self.buyTab.stateLabel:SetText(L['Search in progress...']);
		self.buyTab.stateLabel:Show();
	elseif #self.buyTab.auctions == 0 and #self.buyTab.items == 0 then
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

	if not self.buyTab.auctions[index] then
		return;
	end

	tremove(self.buyTab.auctions, index);
	self:UpdateSearchAuctions();

	if self.buyTab.auctions[index] then
		self.buyTab.searchResults:SetSelection(index);
	end
end

function Buy:UpdateSearchAuctions()
	if self.mode == 'auctions' then
		self.buyTab.searchResults:SetData(self.buyTab.auctions, true);
	else
		self.buyTab.searchResults:SetData(self.buyTab.items, true);
	end
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