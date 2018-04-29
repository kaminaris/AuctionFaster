
--- @var StdUi
local StdUi = LibStub('StdUi');

AuctionFaster.itemFramePool = {};
AuctionFaster.itemFrames = {};

function AuctionFaster:AddAuctionHouseTab()
	if self.TabAdded then
		return;
	end

	local auctionTab = StdUi:Panel(AuctionFrame);
	auctionTab:Hide();
	auctionTab:SetAllPoints();

	local titlePanel = StdUi:Panel(auctionTab, 100, 20);
	local titlePanelText = StdUi:Label(titlePanel, 'Auction Faster');
	titlePanelText:SetAllPoints();
	titlePanelText:SetJustifyH('MIDDLE');
	StdUi:GlueTop(titlePanel, auctionTab);

	self.auctionTab = auctionTab;

	local n = AuctionFrame.numTabs + 1;

	local tab = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate')
	tab:Hide();
	tab:SetID(n);
	tab:SetText('Sell Items');
	tab:SetNormalFontObject(GameFontHighlightSmall);
	tab:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0);
	tab:Show();
	tab.auctionFaster = true;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);

	self.TabAdded = true;

	self:ScanInventory();

	self:DrawItemsFrame();
	self:DrawRightPane();
	self:DrawTabButtons();

	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:DrawItemsFrame()
	local marginTop = -35;
	local auctionTab = self.auctionTab;
	local panel, scrollFrame, scrollChild = StdUi:ScrollFrame(auctionTab, 'AFLeftScroll', 300, 300);
	panel:SetPoint('TOPLEFT', 25, marginTop);
	panel:SetPoint('BOTTOMLEFT', 300, 38);

	auctionTab.scrollFrame = scrollFrame;
	auctionTab.scrollChild = scrollChild;

	self.safeToDrawItems = true;
	self:DrawItems();

end

function AuctionFaster:DrawItems()
	-- Update bag delayed may cause this to happen before we open auction tab
	if not self.safeToDrawItems then
		return;
	end

	local scrollChild = self.auctionTab.scrollChild;
	local lineHeight = 30;
	local margin = 5;

	scrollChild:SetHeight(margin * 2 + lineHeight * #self.inventoryItems);

	-- hide all frames
	for i = 1, #self.itemFramePool do
		self.itemFramePool[i]:Hide();
	end

	local holdingFrames = {};
	for i = 1, #self.inventoryItems do

		-- next time we will be running this function we will reuse frames
		local holdingFrame = self.itemFramePool[i];

		if not holdingFrame then
			-- no allocated frame need to create one
			holdingFrame = StdUi:Button(scrollChild, scrollChild:GetWidth() - margin * 2,
				lineHeight, nil, false, true, false);
			StdUi:ClearBackdrop(holdingFrame);

			holdingFrame.highlightTexture:SetColorTexture(1, 0.9, 0, 0.5);

			holdingFrame:EnableMouse();
			holdingFrame:RegisterForClicks('AnyUp');
			holdingFrame:SetScript('OnEnter', function(self)
				AuctionFaster:ShowTooltip(self, self.itemLink, true);
			end)
			holdingFrame:SetScript('OnLeave', function(self)
				AuctionFaster:ShowTooltip(self, nil, false);
			end)
			holdingFrame:SetScript('OnClick', function(self)
				AuctionFaster:SelectItem(self.itemIndex);
			end)

			holdingFrame.itemIcon = StdUi:Texture(holdingFrame, lineHeight - 2, lineHeight - 2);
			holdingFrame.itemIcon:SetPoint('TOPLEFT', holdingFrame, 1, -1)

			holdingFrame.itemName = StdUi:Label(holdingFrame, '', nil, nil, 150, 20);
			holdingFrame.itemName:SetPoint('TOPLEFT', 35, -5);

			holdingFrame.itemPrice = StdUi:Label(holdingFrame, '', nil, nil, 80, 20);
			holdingFrame.itemPrice:SetJustifyH('RIGHT');
			holdingFrame.itemPrice:SetPoint('TOPRIGHT', 0, -5);

			-- insert only newly created to frame pool
			self.itemFramePool[i] = holdingFrame;
		end

		-- there is a frame so we need to update it
		holdingFrame:ClearAllPoints();
		holdingFrame:SetPoint('TOPLEFT', margin, -(i - 1) * lineHeight - margin);
		holdingFrame.itemLink = self.inventoryItems[i].link;
		holdingFrame.item = self.inventoryItems[i];
		holdingFrame.itemIndex = i;
		holdingFrame.itemIcon:SetTexture(self.inventoryItems[i].icon);
		holdingFrame.itemName:SetText(self.inventoryItems[i].name);
		holdingFrame.itemPrice:SetText(AuctionFaster:FormatMoney(self.inventoryItems[i].price));
		holdingFrame:Show();
	end
end

function AuctionFaster:DrawRightPane()
	local auctionTab = self.auctionTab;

	local leftMargin = 340;
	local topMargin = -35;

	local iconSize = 48;

	self:DrawRightPaneItemIcon(leftMargin, topMargin, iconSize);
	self:DrawRightPaneItemPrices();
	self:DrawRightPaneStackSettings();
	self:DrawRightPaneCurrentAuctionsTable(leftMargin);
end

function AuctionFaster:DrawRightPaneItemIcon(leftMargin, topMargin, iconSize)
	local auctionTab = self.auctionTab;

	auctionTab.itemIcon = StdUi:Texture(auctionTab, iconSize, iconSize, '');
	auctionTab.itemIcon:SetPoint('TOPLEFT', leftMargin, topMargin)

	auctionTab.itemName = StdUi:Label(auctionTab, 'No item selected', 16, nil, 250, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, topMargin);

	auctionTab.itemQty = StdUi:Label(auctionTab, 'Qty: O, Max Stacks: 0', 14, nil, 250, 20);
	auctionTab.itemQty:SetPoint('TOPLEFT', leftMargin + iconSize + 5, topMargin - 20);

	-- Last scan time
	auctionTab.lastScan = StdUi:Label(auctionTab, 'Last scan: ---', 12);
	StdUi:GlueRight(auctionTab.lastScan, auctionTab.itemName, 5, 0);
end

function AuctionFaster:DrawRightPaneItemPrices()
	local auctionTab = self.auctionTab;

	local marginToIcon = -25;

	-- Bid per item edit box
	auctionTab.bidPerItem = StdUi:MoneyBoxWithLabel(auctionTab, 150, 20, '-', 'Bid Per Item', 'TOP');
	auctionTab.bidPerItem:Validate();
	StdUi:GlueBelow(auctionTab.bidPerItem, auctionTab.itemIcon, 0, marginToIcon);

	-- Buy per item edit box
	auctionTab.buyPerItem = StdUi:MoneyBoxWithLabel(auctionTab, 150, 20, '-', 'Buy Per Item', 'TOP');
	auctionTab.buyPerItem:Validate();
	StdUi:GlueBelow(auctionTab.buyPerItem, auctionTab.bidPerItem, 0, -20);
end

function AuctionFaster:DrawRightPaneStackSettings()
	local auctionTab = self.auctionTab;

	-- Stack Size
	auctionTab.stackSize = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '1', 'Stack Size', 'TOP');
	auctionTab.stackSize:SetNumeric(true);
	StdUi:GlueRight(auctionTab.stackSize, auctionTab.bidPerItem, 100, 0);

	auctionTab.maxStacks = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '0', 'Limit of stacks (0 = no limit)', 'TOP');
	auctionTab.maxStacks:SetNumeric(true);
	StdUi:GlueRight(auctionTab.maxStacks, auctionTab.buyPerItem, 100, 0);

	auctionTab.stackSize:SetScript('OnTextChanged', function(self)
		AuctionFaster:ValidateStackSize(self);
	end)

	auctionTab.maxStacks:SetScript('OnTextChanged', function(self)
		AuctionFaster:ValidateMaxStacks(self);
	end)

end

function AuctionFaster:DrawTabButtons()
	local auctionTab = self.auctionTab;

	auctionTab.postButton = StdUi:Button(auctionTab, 60, 20, 'Post All');
	StdUi:GlueBottomRight(auctionTab.postButton, auctionTab, -20, 20);

	auctionTab.postOneButton = StdUi:Button(auctionTab, 60, 20, 'Post One');
	StdUi:GlueLeft(auctionTab.postOneButton, auctionTab.postButton, -10, 0);

	auctionTab.buyItemButton = StdUi:Button(auctionTab, 60, 20, 'Buy Item');
	StdUi:GlueLeft(auctionTab.buyItemButton, auctionTab.postOneButton, -10, 0);

	auctionTab.postOneButton:SetScript('OnClick', function()
		AuctionFaster:SellItem();
	end);

	auctionTab.buyItemButton:SetScript('OnClick', function()
		AuctionFaster:BuyItem();
	end);
end

local function FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols)
	local rowdata = table:GetRow(realrow);
	local celldata = table:GetCell(rowdata, column);
	local highlight;

	if type(celldata) == 'table' then
		highlight = celldata.highlight;
	end

	if table.fSelect then
		if table.selected == realrow then
			table:SetHighLightColor(rowFrame, highlight or cols[column].highlight
				or rowdata.highlight or table:GetDefaultHighlight());
		else
			table:SetHighLightColor(rowFrame, table:GetDefaultHighlightBlank());
		end
	end
end

local function FxDoCellUpdate(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, table)
	if fShow then
		local idx = cols[column].index;
		local format = cols[column].format;

		local val = data[realrow][idx];
		if (format == 'money') then
			val = StdUi.Util.formatMoney(val);
		elseif (format == 'number') then
			val = tostring(val);
		end

		cellFrame.text:SetText(val);
		FxHighlightScrollingTableRow(table, realrow, column, rowFrame, cols);
	end
end

local function FxCompareSort(table, rowa, rowb, sortby)
	local a = table:GetRow(rowa);
	local b = table:GetRow(rowb);
	local column = table.cols[sortby];
	local idx = column.index;

	local direction = column.sort or column.defaultsort or 'asc';

	if column.format == 'money' or column.format == 'number' then
		if direction:lower() == 'asc' then
			return a[idx] > b[idx];
		else
			return a[idx] < b[idx];
		end
	else
		if direction:lower() == 'asc' then
			return a[idx] > b[idx];
		else
			return a[idx] < b[idx];
		end
	end
end

function AuctionFaster:DrawRightPaneCurrentAuctionsTable(leftMargin)
	local auctionTab = self.auctionTab;

	local cols = {
		{
			name = 'Seller',
			width = 150,
			align = 'LEFT',
			index = 'owner',
			format = 'string',
			DoCellUpdate = FxDoCellUpdate,
			comparesort = FxCompareSort
		},
		{
			name = 'Qty',
			width = 40,
			align = 'LEFT',
			index = 'count',
			format = 'number',
			DoCellUpdate = FxDoCellUpdate,
			comparesort = FxCompareSort
		},
		{
			name = 'Bid / Item',
			width = 120,
			align = 'RIGHT',
			index = 'bid',
			format = 'money',
			DoCellUpdate = FxDoCellUpdate,
			comparesort = FxCompareSort
		},
		{
			name = 'Buy / Item',
			width = 120,
			align = 'RIGHT',
			index = 'buy',
			format = 'money',
			DoCellUpdate = FxDoCellUpdate,
			comparesort = FxCompareSort
		},
	}

	auctionTab.currentAuctions = StdUi:ScrollTable(auctionTab, cols, 10, 18);
	auctionTab.currentAuctions:EnableSelection(true);
	auctionTab.currentAuctions.frame:SetPoint('TOPLEFT', leftMargin, -200);
	auctionTab.currentAuctions.frame:SetPoint('BOTTOMRIGHT', -20, 55);
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	if tab.auctionFaster then
		self.auctionTab:Show();
	else
		self.auctionTab:Hide();
	end
end