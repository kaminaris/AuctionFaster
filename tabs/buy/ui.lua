---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type ChainBuy
local ChainBuy = AuctionFaster:GetModule('ChainBuy');
--- @class Buy
local Buy = AuctionFaster:NewModule('Buy', 'AceHook-3.0', 'AceEvent-3.0');

function Buy:AddBuyAuctionHouseTab()
	if self.buyTabAdded then
		return ;
	end

	self.buyTab = AuctionFaster:AddAuctionHouseTab('Buy Items', 'Auction Faster - Buy', self);

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

	self:DrawHelpButton();
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
	buyTab.addFavoritesButton = addFavoritesButton;
	buyTab.filtersButton = filtersButton;
end

function Buy:DrawFilterFrame()
	local buyTab = self.buyTab;

	local filtersPane = StdUi:Window(buyTab, 'Filters', 200, 100);
	filtersPane:Hide();
	StdUi:GlueAfter(filtersPane, buyTab, 0, 0, 0, 0);

	local exactMatch = StdUi:Checkbox(filtersPane, 'Exact Match');

	local minLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, minLevel, 'Level from', 'TOP');

	local maxLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, maxLevel, 'Level to', 'TOP');

	self:GetSearchCategories();
	local category = StdUi:Dropdown(filtersPane, 150, 20, self.categories, 0);
	StdUi:GlueBelow(category, minLevel, 0, -30, 'LEFT');

	local subCategory = StdUi:Dropdown(filtersPane, 150, 20, {}, 0);
	StdUi:AddLabel(filtersPane, subCategory, 'Sub Category', 'TOP');
	subCategory:Disable();


	StdUi:GlueTop(exactMatch, filtersPane, 10, -40, 'LEFT');
	StdUi:GlueBelow(minLevel, exactMatch, 0, -30, 'LEFT');
	StdUi:GlueRight(maxLevel, minLevel, 10, 0);
	StdUi:AddLabel(filtersPane, category, 'Category', 'TOP');
	StdUi:GlueBelow(subCategory, category, 0, -30, 'LEFT');

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

	local chainBuyButton = StdUi:Button(buyTab, 120, 20, 'Chain Buy');
	local addToQueueButton = StdUi:Button(buyTab, 120, 20, 'Add to Queue');
	local addWithXButton = StdUi:Button(buyTab, 120, 20, 'Add With Min Stacks');
	local findXButton = StdUi:Button(buyTab, 120, 20, 'Find X Stacks');

	local minStacksLabel = StdUi:Label(buyTab, 'Min Stacks: ', nil, nil, 100);
	local minStacks = StdUi:NumericBox(buyTab, 100, 20, 1);
	minStacks:SetMinMaxValue(1, 200);

	StdUi:GlueBottom(chainBuyButton, buyTab, 300, 50, 'LEFT');
	StdUi:GlueRight(addToQueueButton, chainBuyButton, 10, 0);
	StdUi:GlueBelow(findXButton, chainBuyButton, 0, -10, 'LEFT');
	StdUi:GlueBelow(addWithXButton, addToQueueButton, 0, -10, 'LEFT');

	StdUi:GlueRight(minStacksLabel, addWithXButton, 10, 0);
	StdUi:GlueRight(minStacks, minStacksLabel, 10, 0);

	chainBuyButton:SetScript('OnClick', function()
		local index = self.buyTab.searchResults:GetSelection();
		if not index then
			AuctionFaster:Echo(3, 'Please select auction first');
		end
		Buy:ChainBuyStart(index);
	end);

	addToQueueButton:SetScript('OnClick', function()
		Buy:AddToQueue();
	end);

	findXButton:SetScript('OnClick', function()
		if not minStacks.isValid then
			AuctionFaster:Echo(3, 'Enter a correct stack amount 1-200');
			return;
		end

		Buy:FindFirstWithXStacks(minStacks:GetValue());
	end);

	addWithXButton:SetScript('OnClick', function()
		if not minStacks.isValid then
			AuctionFaster:Echo(3, 'Enter a correct stack amount 1-200');
			return;
		end

		Buy:AddToQueueWithXStacks(minStacks:GetValue());
	end);

	buyTab.addToQueueButton = addToQueueButton;
	buyTab.chainBuyButton = chainBuyButton;
	buyTab.addWithXButton = addWithXButton;
	buyTab.findXButton = findXButton;
	buyTab.minStacks = minStacks;
end

function Buy:DrawQueue()
	local buyTab = self.buyTab;

	local queueLabel = StdUi:Label(buyTab, 'Queue Qty: 0', nil, nil, 100);
	StdUi:GlueRight(queueLabel, buyTab.addToQueueButton, 10, 0);

	local queueProgress = StdUi:ProgressBar(buyTab, 100, 20);
	queueProgress.TextUpdate = function(self, min, max, value)
		return 'Auctions: ' .. value .. ' / ' .. max;
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
	local pageText = StdUi:Label(buyTab, 'Page 1 of 0');

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
	StdUi:AddLabel(buyTab, favorites, 'Favorite Searches', 'TOP');

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
					AuctionFaster:ShowTooltip(cellFrame, rowData.itemLink, true, rowData.itemId);
					return false;
				end,
				OnLeave = function(table, cellFrame)
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
	buyTab.searchResults:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Auctions:BuyItem(rowData);

					tremove(Buy.buyTab.auctions, rowIndex);
					Buy:UpdateSearchAuctions();
				elseif IsAltKeyDown() then
					ChainBuy:AddBuyRequest(rowData);
					ChainBuy:Start(nil, self.UpdateQueue);

					tremove(Buy.buyTab.auctions, rowIndex);
					Buy:UpdateSearchAuctions();
				elseif IsControlKeyDown() then
					Buy:ChainBuyStart(rowIndex);
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

	buyTab.stateLabel = StdUi:Label(buyTab.searchResults, 'Chose your search criteria nad press "Search"');
	StdUi:GlueTop(buyTab.stateLabel, buyTab.searchResults, 0, -40, 'CENTER');
end
