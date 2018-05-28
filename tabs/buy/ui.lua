--- @type StdUi
local StdUi = LibStub('StdUi');

AuctionFaster.itemFramePool = {};
AuctionFaster.itemFrames = {};

function AuctionFaster:AddBuyAuctionHouseTab()
	if self.buyTabAdded then
		return ;
	end

	local buyTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, 'Auction Faster - Buy', 160);
	buyTab:Hide();
	buyTab:SetAllPoints();

	self.buyTab = buyTab;

	local n = AuctionFrame.numTabs + 1;

	local tab = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate');
	StdUi:StripTextures(tab);

	tab.backdrop = CreateFrame('Frame', nil, tab);
	tab.backdrop:SetTemplate('Default');
	tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1);
	StdUi:GlueAcross(tab.backdrop, tab, 10, -3, -10, 3);
	StdUi:ApplyBackdrop(tab.backdrop);

	tab:Hide();
	tab:SetID(n);
	tab:SetText('Buy Items');
	tab:SetNormalFontObject(GameFontHighlightSmall);
	tab:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0);
	tab:Show();
	-- reference the actual tab
	tab.auctionFasterTab = buyTab;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);

	self.buyTabAdded = true;

	self:DrawSearchPane();
	self:DrawFavoritesPane();
	self:DrawFavorites(20);
	self:DrawSearchResultsTable();
	self:DrawSearchButtons();
	self:DrawPager();
	self:InterceptLinkClick();
end

function AuctionFaster:DrawSearchPane()
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

	addFavoritesButton:SetScript('OnClick', function()
		AuctionFaster:AddToFavorites();
	end);

	searchBox:SetScript('OnEnterPressed', function()
		AuctionFaster:SearchAuctions(searchBox:GetText(), false, 0);
	end);

	searchButton:SetScript('OnClick', function()
		AuctionFaster:SearchAuctions(searchBox:GetText(), false, 0);
	end);

	buyTab.searchBox = searchBox;
end

function AuctionFaster:DrawSearchButtons()
	local buyTab = self.buyTab;

	local buyButton = StdUi:Button(buyTab, 80, 20, 'Buy');
	StdUi:GlueBottom(buyButton, buyTab, 300, 50, 'LEFT');

	buyButton:SetScript('OnClick', function ()
		AuctionFaster:BuySelectedItem(0, true);
	end);
end

function AuctionFaster:DrawPager()
	local buyTab = self.buyTab;

	local leftButton = StdUi:SquareButton(buyTab, 20, 20, 'LEFT');
	StdUi:GlueBottom(leftButton, buyTab, 80, 50, 'LEFT');

	local rightButton = StdUi:SquareButton(buyTab, 20, 20, 'RIGHT');
	StdUi:GlueBottom(rightButton, buyTab, 105, 50, 'LEFT');

	local pageText = StdUi:Label(buyTab, 'Page 1 of 0');
	StdUi:GlueBottom(pageText, buyTab, 10, 50, 'LEFT');

	leftButton:SetScript('OnClick', function()
		AuctionFaster:SearchPreviousPage();
	end);

	rightButton:SetScript('OnClick', function()
		AuctionFaster:SearchNextPage();
	end);

	buyTab.pager = {
		leftButton = leftButton,
		rightButton = rightButton,
		pageText = pageText,
	};
end

function AuctionFaster:DrawFavoritesPane()
	local buyTab = self.buyTab;

	local favorites = StdUi:ScrollFrame(buyTab, 200, 270);
	StdUi:GlueTop(favorites, buyTab, -10, -100, 'RIGHT');
	StdUi:AddLabel(buyTab, favorites, 'Favorite Searches', 'TOP');

	buyTab.favorites = favorites;
end

local favoriteItemFrames = {};
function AuctionFaster:DrawFavorites()
	local scrollChild = self.buyTab.favorites.scrollChild;
	local lineHeight = 20;

	if not self.db.global.favorites then
		self.db.global.favorites = {};
	end

	local favorites = self.db.global.favorites;

	scrollChild:SetHeight(2 * 2 + lineHeight * #favorites);

	for i = 1, #favoriteItemFrames do
		favoriteItemFrames[i]:Hide();
	end

	for i = 1, #favorites do
		local fav = favorites[i];
		if not favoriteItemFrames[i] then
			favoriteItemFrames[i] = self:CreateFavoriteFrame(scrollChild, lineHeight);
		end

		local favoriteFrame = favoriteItemFrames[i];
		self:UpdateFavoriteFrame(favoriteFrame, fav, i, lineHeight);
	end
end

function AuctionFaster:CreateFavoriteFrame(scrollChild, lineHeight)
	local favoriteFrame = StdUi:HighlightButton(scrollChild, scrollChild:GetWidth() - 22, lineHeight, 'aaaa');
	local removeFav = StdUi:Button(favoriteFrame, 20, lineHeight, 'X');
	StdUi:GlueRight(removeFav, favoriteFrame, 0, 0);

	removeFav:SetScript('OnClick', function(self)
		AuctionFaster:RemoveFromFavorites(self:GetParent().itemIndex);
	end);

	favoriteFrame:SetScript('OnClick', function (self)
		AuctionFaster:SetFavoriteAsSearch(self.itemIndex);
	end);

	return favoriteFrame;
end

function AuctionFaster:UpdateFavoriteFrame(favoriteFrame, fav, i, lineHeight)
	local margin = 2;
	favoriteFrame:SetText(fav.text);
	favoriteFrame:ClearAllPoints();
	favoriteFrame:SetPoint('TOPLEFT', margin, -(i - 1) * lineHeight - margin);
	favoriteFrame.itemIndex = i;
	favoriteFrame:Show();
end

function AuctionFaster:DrawSearchResultsTable()
	local buyTab = self.buyTab;

	local cols = {
		{
			name         = 'Item',
			width        = 32,
			align        = 'LEFT',
			index        = 'icon',
			format       = 'icon',
			sortable	 = false,
			events		 = {
				OnEnter = function(rowFrame, cellFrame, data, cols, row, realRow)
					local cellData = data[realRow];
					AuctionFaster:ShowTooltip(cellFrame, cellData.itemLink, true);
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
