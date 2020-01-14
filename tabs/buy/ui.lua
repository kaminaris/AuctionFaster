---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @class Buy
local Buy = AuctionFaster:NewModule('Buy', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

local format = string.format;


local AFBuyMode = {
	'AFBuyModeFrame'
}

function Buy:AddBuyAuctionHouseTab()
	if self.buyTabAdded then
		return ;
	end

	AuctionHouseFrameDisplayMode.AFBuyMode = AFBuyMode;
	self.buyTab = AuctionFaster:AddAuctionHouseTab(L['Buy Items'], L['AuctionFaster - Buy'], self, AFBuyMode);

	self.buyTab:SetScript('OnShow', function()
		Buy:OnShow();
	end);

	self.buyTab:SetScript('OnHide', function()
		Buy:OnHide();
	end);

	self.buyTabAdded = true;

	self:DrawSearchPane();
	self:DrawFavoritesPane();
	self:DrawSearchResultsTable();
	self:DrawSearchButtons();
	self:DrawQueue();
	self:DrawPager();

	self:DrawFilterFrame();
	self:DrawSniperFrame();

	self:DrawHelpButton();
end

function Buy:DrawSearchPane()
	local buyTab = self.buyTab;

	local searchBox = StdUi:Autocomplete(buyTab, 400, 30, '', nil, nil, AuctionFaster.db.buy.recentSearches);
	StdUi:ApplyPlaceholder(searchBox, L['Search'], [[Interface\Common\UI-Searchbox-Icon]]);
	searchBox:SetFontSize(16);

	local searchButton = StdUi:Button(buyTab, 80, 30, L['Search']);

	local addFavoritesButton = StdUi:SquareButton(buyTab, 30, 30);
	addFavoritesButton:SetIcon([[Interface\Common\ReputationStar]], 16, 16, true);
	addFavoritesButton.icon:SetTexCoord(0, 0.5, 0, 0.5);
	addFavoritesButton.iconDisabled:SetTexCoord(0, 0.5, 0, 0.5);
	StdUi:FrameTooltip(addFavoritesButton, 'Add to favorites searches', 'af_fav_search', 'TOPRIGHT', true);

	local searchFavorites = StdUi:Button(buyTab, 60, 30, 'Search Favs');
	StdUi:FrameTooltip(searchFavorites, 'Search favorite items', 'af_fav_search_items', 'TOPRIGHT', true);

	local filtersButton = StdUi:Button(buyTab, 80, 30, L['Filters']);
	local sniperButton = StdUi:Button(buyTab, 80, 30, L['Sniper']);

	StdUi:GlueTop(searchBox, buyTab, 10, -30, 'LEFT');
	StdUi:GlueRight(searchButton, searchBox, 5, 0);
	StdUi:GlueRight(addFavoritesButton, searchButton, 5, 0);
	StdUi:GlueRight(searchFavorites, addFavoritesButton, 5, 0);
	StdUi:GlueRight(filtersButton, searchFavorites, 5, 0);
	StdUi:GlueRight(sniperButton, filtersButton, 5, 0);

	addFavoritesButton:SetScript('OnClick', function() Buy:AddToFavorites(); end);
	searchBox:SetScript('OnEnterPressed', function() Buy:SearchAuctions(searchBox:GetText(), false, 0); end);
	searchButton:SetScript('OnClick', function() Buy:SearchAuctions(searchBox:GetText(), false, 0); end);
	filtersButton:SetScript('OnClick', function() Buy:ToggleFilterFrame(); end);
	sniperButton:SetScript('OnClick', function() Buy:ToggleSniperFrame(); end);
	searchFavorites:SetScript('OnClick', function() Buy:SearchFavoriteItems(); end);

	buyTab.searchBox = searchBox;
	buyTab.addFavoritesButton = addFavoritesButton;
	buyTab.filtersButton = filtersButton;
end

function Buy:DrawSearchButtons()
	local buyTab = self.buyTab;

	local buyButton = StdUi:Button(buyTab, 120, 20, L['Buy']);

	StdUi:GlueBottom(buyButton, buyTab, 300, 50, 'LEFT');

	buyButton:SetScript('OnClick', function()
		local index = self.buyTab.searchResults:GetSelection();
		if not index then
			AuctionFaster:Echo(3, L['Please select auction first']);
		end
		Buy:InstantBuy(index);
	end);

	buyTab.buyButton = buyButton;
end

function Buy:DrawQueue()
	local buyTab = self.buyTab;

	local queueLabel = StdUi:Label(buyTab, format(L['Queue Qty: %d'], 0), nil, nil, 100);
	StdUi:GlueRight(queueLabel, buyTab.addToQueueButton, 10, 0);

	local queueProgress = StdUi:ProgressBar(buyTab, 100, 20);
	queueProgress.TextUpdate = function(self, min, max, value)
		return format(L['Auctions: %d / %d'], value, max);
	end;
	queueProgress:SetMinMaxValues(0, 0);
	queueProgress:SetValue(0);

	StdUi:GlueRight(queueProgress, queueLabel, 10, 0);

	buyTab.queueProgress = queueProgress;
	buyTab.queueLabel = queueLabel;
end

function Buy:DrawPager()
	local buyTab = self.buyTab;

	local leftButton = StdUi:SquareButton(buyTab, 20, 20, 'LEFT');
	local rightButton = StdUi:SquareButton(buyTab, 20, 20, 'RIGHT');
	local pageJump = StdUi:Dropdown(buyTab, 80, 20, {});
	local pageText = StdUi:Label(buyTab, format(L['Pages: %d'], 0));

	StdUi:GlueBottom(leftButton, buyTab, 10, 50, 'LEFT');
	StdUi:GlueRight(pageJump, leftButton, 10, 0);
	StdUi:GlueRight(rightButton, pageJump, 10, 0);
	StdUi:GlueRight(pageText, rightButton, 10, 0);

	leftButton:SetScript('OnClick', function()
		Buy:SearchPreviousPage();
	end);

	rightButton:SetScript('OnClick', function()
		Buy:SearchNextPage();
	end);

	pageJump.OnValueChanged = function(pg, value)
		if not self.updatingPagerLock then
			self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, value);
		end
	end

	buyTab.pager = {
		leftButton = leftButton,
		rightButton = rightButton,
		pageText = pageText,
		pageJump = pageJump,
	};
end

function Buy:DrawFavoritesPane()
	local buyTab = self.buyTab;
	local lineHeight = 20;

	local favorites = StdUi:FauxScrollFrame(buyTab, 200, 270, 13, lineHeight);
	StdUi:GlueTop(favorites, buyTab, -10, -100, 'RIGHT');
	StdUi:AddLabel(buyTab, favorites, L['Favorite Searches'], 'TOP');

	buyTab.favorites = favorites;

	self:DrawFavorites(lineHeight);
end

function Buy:DrawFavorites()
	local favFrame = self.buyTab.favorites;
	local lineHeight = 20;

	local buttonCreate = function(parent, data, i)
		return Buy:CreateFavoriteFrame(parent, lineHeight);
	end;

	local buttonUpdate = function(parent, itemFrame, data, i)
		Buy:UpdateFavoriteFrame(i, itemFrame, data);
		itemFrame.itemIndex = i;
	end;

	local data = AuctionFaster.db.favorites;
	if not data then
		AuctionFaster.db.favorites = {};
		data = AuctionFaster.db.favorites;
	end

	if not favFrame.scrollChild.items then
		favFrame.scrollChild.items = {};
	end

	StdUi:ObjectList(favFrame.scrollChild, favFrame.scrollChild.items, buttonCreate, buttonUpdate, data);
	favFrame:UpdateItemsCount(#data);
end

function Buy:CreateFavoriteFrame(parent, lineHeight)
	local favoriteFrame = StdUi:Frame(parent, parent:GetWidth(), lineHeight);

	local favButton = StdUi:HighlightButton(favoriteFrame, favoriteFrame:GetWidth() - 22, lineHeight, '');
	StdUi:GlueLeft(favButton, favoriteFrame, 0, 0, true);

	local removeFav = StdUi:SquareButton(favoriteFrame, 20, 20, 'DELETE');
	removeFav:SetBackdrop(nil);
	StdUi:GlueRight(removeFav, favoriteFrame, 0, 0, true);

	removeFav:SetScript('OnClick', function(self)
		Buy:RemoveFromFavorites(self:GetParent().itemIndex);
	end);

	favButton:SetScript('OnClick', function (self)
		Buy:SearchFavorite(self:GetParent().itemIndex);
	end);

	favoriteFrame.removeFav = removeFav;
	favoriteFrame.favButton = favButton;

	return favoriteFrame;
end

function Buy:UpdateFavoriteFrame(i, itemFrame, data)
	itemFrame.favButton:SetText(data.text);
	itemFrame.itemIndex = i;
end

function Buy:DrawSearchResultsTable()
	local buyTab = self.buyTab;

	local cols = {
		{
			name         = '',
			width        = 32,
			align        = 'LEFT',
			index        = 'texture',
			format       = 'icon',
			sortable	 = false,
			events		 = {
				OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
					if AuctionFaster.db.buy.tooltips.enabled then
						AuctionFaster:ShowTooltip(
							cellFrame,
							rowData,
							true,
							AuctionFaster.db.buy.tooltips.anchor
						);
					end
					return false;
				end,
				OnLeave = function(table, cellFrame)
					if AuctionFaster.db.buy.tooltips.enabled then
						AuctionFaster:ShowTooltip(cellFrame, nil, false);
					end
					return false;
				end
			},
		},
		{
			name         = L['Name'],
			width        = 250,
			align        = 'LEFT',
			index        = 'itemLink',
			format       = 'string',
		},
		{
			name         = L['Qty'],
			width        = 40,
			align        = 'LEFT',
			index        = 'count',
			format       = 'number',
		},
		{
			name         = L['Buy'],
			width        = 120,
			align        = 'RIGHT',
			index        = 'buy',
			format       = 'money',
		},
		{
			name         = 'Fav',
			width        = 50,
			align        = 'LEFT',
			index        = 'buy',
			format       = 'custom',
			sortable	 = false,
			renderer     = function(cellFrame, value, rowData, columnData)
				local isFavorite = C_AuctionHouse.IsFavoriteItem(rowData.itemKey);

				if not cellFrame.texture then
					cellFrame.texture = StdUi:Texture(cellFrame, 32, 32, [[Interface\COMMON\FavoritesIcon]]);
					cellFrame.texture:SetPoint('CENTER', 0, 0);
				end

				if isFavorite then
					cellFrame.texture:SetAlpha(1);
				else
					cellFrame.texture:SetAlpha(0.1);
				end
			end,
			events		 = {
				OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
					local isFavorite = C_AuctionHouse.IsFavoriteItem(rowData.itemKey);
					C_AuctionHouse.SetFavoriteItem(rowData.itemKey, not isFavorite);
				end
			}
		},
	}

	buyTab.searchResults = StdUi:ScrollTable(buyTab, cols, 11, 32);
	buyTab.searchResults:EnableSelection(true);
	buyTab.searchResults:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == 'LeftButton' then
				if IsModifiedClick('CHATLINK') then
					-- link item
					local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(rowData.itemKey);
					if itemKeyInfo and itemKeyInfo.battlePetLink then
						ChatEdit_InsertLink(itemKeyInfo.battlePetLink);
					else
						local _, itemLink = GetItemInfo(rowData.itemId);
						ChatEdit_InsertLink(itemLink);
					end
				elseif IsAltKeyDown() then
					Buy:InstantBuy(rowData, rowIndex);
				elseif IsModifiedClick('DRESSUP') then
					local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(rowData.itemKey);
					if itemKeyInfo and itemKeyInfo.battlePetLink then
						DressUpBattlePetLink(itemKeyInfo.battlePetLink);
					else
						local _, itemLink = GetItemInfo(rowData.itemId);
						DressUpLink(itemLink);
					end
				else
					if table:GetSelection() == rowIndex then
						table:ClearSelection();
					else
						table:SetSelection(rowIndex);
					end
				end
			end
			return true;
		end
	});
	StdUi:GlueAcross(buyTab.searchResults, buyTab, 10, -100, -220, 80);

	buyTab.stateLabel = StdUi:Label(buyTab.searchResults, L['Chose your search criteria nad press "Search"']);
	StdUi:GlueTop(buyTab.stateLabel, buyTab.searchResults, 0, -40, 'CENTER');
end
