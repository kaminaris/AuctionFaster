--- @type StdUi
local StdUi = LibStub('StdUi');

--- @class Buy
local Buy = AuctionFaster:NewModule('Buy', 'AceHook-3.0');

function Buy:Enable()
	self:AddBuyAuctionHouseTab();
	self:InterceptLinkClick();
end

function Buy:AddBuyAuctionHouseTab()
	if self.buyTabAdded then
		return ;
	end

	self.buyTab = AuctionFaster:AddAuctionHouseTab('Buy Items', 'Auction Faster - Buy');

	self.buyTabAdded = true;

	self:DrawSearchPane();
	self:DrawFavoritesPane();
	self:DrawSearchResultsTable();
	self:DrawSearchButtons();
	self:DrawPager();

	self:DrawFilterFrame();
end

function Buy:DrawSearchPane()
	local buyTab = self.buyTab;

	local searchBox = StdUi:SearchEditBox(buyTab, 400, 30, 'Search');
	searchBox:SetFontSize(16);
	StdUi:GlueTop(searchBox, buyTab, 10, -30, 'LEFT');

	local searchButton = StdUi:Button(buyTab, 80, 30, 'Search');
	StdUi:GlueRight(searchButton, searchBox, 5, 0);

	local addFavoritesButton = StdUi:Button(buyTab, 30, 30, '');
	addFavoritesButton.texture = StdUi:Texture(addFavoritesButton, 17, 17, [[Interface\Common\ReputationStar]]);
	addFavoritesButton.texture:SetPoint('CENTER');
	addFavoritesButton.texture:SetBlendMode('ADD');
	addFavoritesButton.texture:SetTexCoord(0, 0.5, 0, 0.5);
	StdUi:GlueRight(addFavoritesButton, searchButton, 5, 0);


	local filtersButton = StdUi:Button(buyTab, 150, 30, 'Filters');
	StdUi:GlueRight(filtersButton, addFavoritesButton, 5, 0);

	addFavoritesButton:SetScript('OnClick', function()
		Buy:AddToFavorites();
	end);

	searchBox:SetScript('OnEnterPressed', function()
		Buy:SearchAuctions(searchBox:GetText(), false, 0);
	end);

	searchButton:SetScript('OnClick', function()
		Buy:SearchAuctions(searchBox:GetText(), false, 0);
	end);

	filtersButton:SetScript('OnClick', function()
		Buy:ToggleFilters();
	end);

	buyTab.searchBox = searchBox;
end

function Buy:DrawFilterFrame()
	local buyTab = self.buyTab;

	local filtersPane = StdUi:PanelWithTitle(buyTab, 200, 100, 'Filters');
	filtersPane:Hide();
	StdUi:GlueAfter(filtersPane, buyTab, 0, 0, 0, 0);

	local exactMatch = StdUi:Checkbox(filtersPane, 'Exact Match');
	StdUi:GlueTop(exactMatch, filtersPane, 10, -20, 'LEFT');

	local minLevel = StdUi:NumericBoxWithLabel(filtersPane, 50, 20, '', 'Level from', 'TOP');
	local maxLevel = StdUi:NumericBoxWithLabel(filtersPane, 50, 20, '', 'Level to', 'TOP');
	StdUi:GlueBelow(minLevel, exactMatch, 0, -30, 'LEFT');
	StdUi:GlueRight(maxLevel, minLevel, 20, 0);

	self:GetSearchCategories();
	local category = StdUi:Dropdown(filtersPane, 150, 20, self.categories, 0);
	StdUi:AddLabel(filtersPane, category, 'Category', 'TOP');
	StdUi:GlueBelow(category, minLevel, 0, -30, 'LEFT');

	local subCategory = StdUi:Dropdown(filtersPane, 150, 20, {}, 0);
	StdUi:AddLabel(filtersPane, subCategory, 'Sub Category', 'TOP');
	StdUi:GlueBelow(subCategory, category, 0, -30, 'LEFT');
	subCategory:Disable();

	category.OnValueChanged = function(dropdown, value, text)
		local subCategories = Buy.subCategories[value];

		if #subCategories > 0 then
			subCategory:SetOptions(subCategories);
			subCategory:SetValue(0);
			subCategory:Enable();
		else
			subCategory:SetOptions({});
			subCategory:SetValue(0);
			subCategory:Disable();
		end
	end;

	self.filtersPane = filtersPane;
	self.filtersPane.exactMatch = exactMatch;
	self.filtersPane.minLevel = minLevel;
	self.filtersPane.maxLevel = maxLevel;
	self.filtersPane.category = category;
	self.filtersPane.subCategory = subCategory;
end

function Buy:ToggleFilters()
	if self.filtersPane:IsVisible() then
		self.filtersPane:Hide();
	else
		self.filtersPane:Show();
	end
end

function Buy:DrawSearchButtons()
	local buyTab = self.buyTab;

	local buyButton = StdUi:Button(buyTab, 80, 20, 'Buy');
	StdUi:GlueBottom(buyButton, buyTab, 300, 50, 'LEFT');

	buyButton:SetScript('OnClick', function ()
		Buy:BuySelectedItem(0, true);
	end);
end

function Buy:DrawPager()
	local buyTab = self.buyTab;

	local leftButton = StdUi:SquareButton(buyTab, 20, 20, 'LEFT');
	StdUi:GlueBottom(leftButton, buyTab, 80, 50, 'LEFT');

	local rightButton = StdUi:SquareButton(buyTab, 20, 20, 'RIGHT');
	StdUi:GlueBottom(rightButton, buyTab, 105, 50, 'LEFT');

	local pageText = StdUi:Label(buyTab, 'Page 1 of 0');
	StdUi:GlueBottom(pageText, buyTab, 10, 50, 'LEFT');

	leftButton:SetScript('OnClick', function()
		Buy:SearchPreviousPage();
	end);

	rightButton:SetScript('OnClick', function()
		Buy:SearchNextPage();
	end);

	buyTab.pager = {
		leftButton = leftButton,
		rightButton = rightButton,
		pageText = pageText,
	};
end

function Buy:DrawFavoritesPane()
	local buyTab = self.buyTab;
	local lineHeight = 20;

	local favorites = StdUi:FauxScrollFrame(buyTab, 200, 270, 13, lineHeight);
	StdUi:GlueTop(favorites, buyTab, -10, -100, 'RIGHT');
	StdUi:AddLabel(buyTab, favorites, 'Favorite Searches', 'TOP');

	buyTab.favorites = favorites;

	self:DrawFavorites(lineHeight);
end

function Buy:DrawFavorites()
	local favFrame = self.buyTab.favorites;
	local lineHeight = 20;

	local buttonCreate = function(parent, i)
		return Buy:CreateFavoriteFrame(parent, lineHeight);
	end;

	local buttonUpdate = function(parent, i, itemFrame, data)
		Buy:UpdateFavoriteFrame(i, itemFrame, data);
		itemFrame.itemIndex = i;
	end;

	local data = AuctionFaster.db.global.favorites;
	if not data then
		AuctionFaster.db.global.favorites = {};
		data = AuctionFaster.db.global.favorites;
	end

	StdUi:ButtonList(favFrame.scrollChild, buttonCreate, buttonUpdate, data, lineHeight);
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
		Buy:SetFavoriteAsSearch(self:GetParent().itemIndex);
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
				OnEnter = function(rowFrame, cellFrame, data, cols, row, realRow)
					local cellData = data[realRow];
					AuctionFaster:ShowTooltip(cellFrame, cellData.itemLink, true, cellData.itemId);
					return false;
				end,
				OnLeave = function(rowFrame, cellFrame)
					AuctionFaster:ShowTooltip(cellFrame, nil, false);
					return false;
				end
			},
		},
		{
			name         = 'Name',
			width        = 150,
			align        = 'LEFT',
			index        = 'itemLink',
			format       = 'string',
		},
		{
			name         = 'Seller',
			width        = 100,
			align        = 'LEFT',
			index        = 'owner',
			format       = 'string',
		},
		{
			name         = 'Qty',
			width        = 40,
			align        = 'LEFT',
			index        = 'count',
			format       = 'number',
		},
		{
			name         = 'Bid / Item',
			width        = 120,
			align        = 'RIGHT',
			index        = 'bid',
			format       = 'money',
		},
		{
			name         = 'Buy / Item',
			width        = 120,
			align        = 'RIGHT',
			index        = 'buy',
			format       = 'money',
		},
	}

	buyTab.searchResults = StdUi:ScrollTable(buyTab, cols, 8, 32);
	buyTab.searchResults:EnableSelection(true);
	StdUi:GlueAcross(buyTab.searchResults.frame, buyTab, 10, -100, -220, 80);

	buyTab.stateLabel = StdUi:Label(buyTab.searchResults.frame, 'Chose your search criteria nad press "Search"');
	StdUi:GlueTop(buyTab.stateLabel, buyTab.searchResults.frame, 0, -40, 'CENTER');
end
