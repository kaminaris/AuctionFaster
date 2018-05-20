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
	tab:StripTextures();
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

	buyTab.searchBox = searchBox;
end



--function AuctionFaster:DrawRightPaneItemIcon(leftMargin, topMargin, iconSize)
--	local sellTab = self.sellTab;
--
--	local iconBackdrop = StdUi:Panel(sellTab, iconSize, iconSize);
--	StdUi:GlueTop(iconBackdrop, sellTab, leftMargin, topMargin, 'LEFT');
--
--	sellTab.itemIcon = StdUi:Texture(iconBackdrop, iconSize, iconSize, '');
--	StdUi:GlueAcross(sellTab.itemIcon, iconBackdrop, 1, -1, -1, 1);
--
--	sellTab.itemName = StdUi:Label(sellTab, 'No item selected', 16, nil, 250, 20);
--	StdUi:GlueAfter(sellTab.itemName, sellTab.itemIcon, 5, 0);
--
--	sellTab.itemQty = StdUi:Label(sellTab, 'Qty: O, Max Stacks: 0', 14, nil, 250, 20);
--	StdUi:GlueBelow(sellTab.itemQty, sellTab.itemName, 0, 5);
--
--	-- Last scan time
--	sellTab.lastScan = StdUi:Label(sellTab, 'Last scan: ---', 12);
--	StdUi:GlueRight(sellTab.lastScan, sellTab.itemName, 5, 0);
--end
--
--local function FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols)
--	local rowdata = table:GetRow(realrow);
--	local celldata = table:GetCell(rowdata, column);
--	local highlight;
--
--	if type(celldata) == 'table' then
--		highlight = celldata.highlight;
--	end
--
--	if table.fSelect then
--		if table.selected == realrow then
--			table:SetHighLightColor(rowFrame, highlight or cols[column].highlight
--					or rowdata.highlight or table:GetDefaultHighlight());
--		else
--			table:SetHighLightColor(rowFrame, table:GetDefaultHighlightBlank());
--		end
--	end
--end
--
--local function FxDoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table)
--	if fShow then
--		local idx = cols[column].index;
--		local format = cols[column].format;
--
--		local val = data[realrow][idx];
--		if (format == 'money') then
--			val = StdUi.Util.formatMoney(val);
--		elseif (format == 'number') then
--			val = tostring(val);
--		end
--
--		cellFrame.text:SetText(val);
--		FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols);
--	end
--end
--
--local function FxCompareSort(table, rowA, rowB, sortBy)
--	local a = table:GetRow(rowA);
--	local b = table:GetRow(rowB);
--	local column = table.cols[sortBy];
--	local idx = column.index;
--
--	local direction = column.sort or column.defaultsort or 'asc';
--
--	if direction:lower() == 'asc' then
--		return a[idx] > b[idx];
--	else
--		return a[idx] < b[idx];
--	end
--end
--
--function AuctionFaster:DrawRightPaneCurrentAuctionsTable(leftMargin)
--	local sellTab = self.sellTab;
--
--	local cols = {
--		{
--			name         = 'Seller',
--			width        = 150,
--			align        = 'LEFT',
--			index        = 'owner',
--			format       = 'string',
--			DoCellUpdate = FxDoCellUpdate,
--			comparesort  = FxCompareSort
--		},
--		{
--			name         = 'Qty',
--			width        = 40,
--			align        = 'LEFT',
--			index        = 'count',
--			format       = 'number',
--			DoCellUpdate = FxDoCellUpdate,
--			comparesort  = FxCompareSort
--		},
--		{
--			name         = 'Bid / Item',
--			width        = 120,
--			align        = 'RIGHT',
--			index        = 'bid',
--			format       = 'money',
--			DoCellUpdate = FxDoCellUpdate,
--			comparesort  = FxCompareSort
--		},
--		{
--			name         = 'Buy / Item',
--			width        = 120,
--			align        = 'RIGHT',
--			index        = 'buy',
--			format       = 'money',
--			DoCellUpdate = FxDoCellUpdate,
--			comparesort  = FxCompareSort
--		},
--	}
--
--	sellTab.currentAuctions = StdUi:ScrollTable(sellTab, cols, 10, 18);
--	sellTab.currentAuctions:EnableSelection(true);
--	StdUi:GlueAcross(sellTab.currentAuctions.frame, sellTab, leftMargin, -200, -20, 55);
--end
