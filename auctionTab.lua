local ScrollingTable = LibStub('ScrollingTable');
local StdUi = LibStub('StdUi-1.0');

function AuctionFaster:AddAuctionHouseTab()
	if self.TabAdded then
		return;
	end

	local auctionTab = CreateFrame('Frame', nil, AuctionFrame);
	auctionTab:Hide();
	auctionTab:SetAllPoints();

	self.auctionTab = auctionTab;

	local n = AuctionFrame.numTabs + 1;

	local tab = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate')
	tab:Hide()
	tab:SetID(n)
	tab:SetText('|cfffe6000Sell Items')
	tab:SetNormalFontObject(GameFontHighlightSmall)
	tab:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0)
	tab:Show();
	tab.auctionFaster = true;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);

	self.TabAdded = true;

	self:ScanInventory();
	--self:UpdateInventoryTable();
	self:DrawItemsFrame(auctionTab);
	self:DrawRightPane(auctionTab);
	self:DrawTabButtons();

	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:DrawItemsFrame(auctionTab)
	local scrollFrame, scrollChild = StdUi:ScrollFrame(auctionTab, 'AFLeftScroll', 300, 300);
	scrollFrame:SetPoint('TOPLEFT', 5, -25);
	scrollFrame:SetPoint('BOTTOMLEFT', 300, 35);

	auctionTab.scrollFrame = scrollFrame;
	auctionTab.scrollChild = scrollChild;

	self:DrawItems(scrollChild);

end


function AuctionFaster:DrawItems(scrollChild)
	local lineHeight = 30;

	scrollChild:SetHeight(lineHeight * #self.inventoryItems);

	for i = 1, #self.inventoryItems do

		local holdingFrame = StdUi:Button(scrollChild, scrollChild:GetWidth(), lineHeight, nil, false, true, false);
		holdingFrame.highlightTexture:SetColorTexture(1, 0.9, 0, 0.5);
		holdingFrame:SetPoint('TOPLEFT', 0, -(i - 1) * lineHeight);
		holdingFrame.itemLink = self.inventoryItems[i].link;
		holdingFrame.itemIndex = i;

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

		local texx = StdUi:Texture(holdingFrame, lineHeight - 2, lineHeight - 2, self.inventoryItems[i].icon);
		texx:SetPoint('TOPLEFT', holdingFrame, 1, -1)

		local name = StdUi:Label(holdingFrame, nil, self.inventoryItems[i].name, nil, 150, 20);
		name:SetPoint('TOPLEFT', 35, -5);

		local price = StdUi:Label(holdingFrame, nil, AuctionFaster:FormatMoney(self.inventoryItems[i].price), nil, 80, 20);
		price:SetJustifyH('RIGHT');
		price:SetPoint('TOPRIGHT', 0, -5);
	end
end


function AuctionFaster:DrawRightPane(auctionTab)
	local leftMargin = 340;
	local iconSize = 48;

	local rightMargin = leftMargin + 200;

	auctionTab.itemIcon = StdUi:Texture(auctionTab, iconSize, iconSize, '');
	auctionTab.itemIcon:SetPoint('TOPLEFT', leftMargin, -25)

	auctionTab.itemName = StdUi:Label(auctionTab, 16, 'No item selected', nil, 300, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -25);

	auctionTab.itemQty = StdUi:Label(auctionTab, 14, 'Qty: O', nil, 300, 20);
	auctionTab.itemQty:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -45);


	-- Bid per item edit box
	auctionTab.bidPerItem = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '10g 6s 6c',
		'Bid Per Item', nil, 'TOP');
	StdUi:GlueBelow(auctionTab.bidPerItem, auctionTab.itemIcon, 0, -25);

	-- Buy per item edit box
	auctionTab.buyPerItem = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '12g 10s 10c',
		'Buy Per Item', nil, 'TOP');
	StdUi:GlueBelow(auctionTab.buyPerItem, auctionTab.bidPerItem, 0, -25);


	-- Stack Size
	auctionTab.stackSize = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '1',
		'Stack Size (Max: 20)', nil, 'TOP');
	auctionTab.stackSize:SetNumeric(true);
	StdUi:GlueRight(auctionTab.stackSize, auctionTab.bidPerItem, 120, 0);

	auctionTab.maxStacks = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '-1',
		'Limit of stacks (-1 means everything)', nil, 'TOP');
	auctionTab.maxStacks:SetNumeric(true);
	StdUi:GlueRight(auctionTab.maxStacks, auctionTab.buyPerItem, 120, 0);

	self:DrawRightPaneCurrentAuctionsTable();
end

function AuctionFaster:DrawTabButtons()
	local auctionTab = self.auctionTab;

	auctionTab.postButton = StdUi:PanelButton(auctionTab, 60, 20, 'Post All');
	auctionTab.postButton:SetPoint('BOTTOMRIGHT', -5, 5)

	auctionTab.postOneButton = StdUi:PanelButton(auctionTab, 60, 20, 'Post One');
	StdUi:GlueLeft(auctionTab.postOneButton, auctionTab.postButton, 5);

	auctionTab.buyItemButton = StdUi:PanelButton(auctionTab, 60, 20, 'Buy Item');
	StdUi:GlueLeft(auctionTab.buyItemButton, auctionTab.postOneButton, 5);
end

function AuctionFaster:DrawRightPaneCurrentAuctionsTable()
	local auctionTab = self.auctionTab;


	local cols = {
		{
			['name'] = 'Seller',
			['width'] = 150,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Qty',
			['width'] = 40,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Bid',
			['width'] = 120,
			['align'] = 'RIGHT',
			['DoCellUpdate'] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
				if fShow then
					cellFrame.text:SetText(AuctionFaster:FormatMoney(data[realrow][3]));
				end
			end,
		},

		{
			['name'] = 'Buy',
			['width'] = 120,
			['align'] = 'RIGHT',
			['DoCellUpdate'] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
				if fShow then
					cellFrame.text:SetText(AuctionFaster:FormatMoney(data[realrow][4]));
				end
			end,
		},
	}

	local leftMargin = 340;
	auctionTab.currentAuctions = ScrollingTable:CreateST(cols, 12, 18, nil, auctionTab);
	auctionTab.currentAuctions.frame:SetPoint('TOPLEFT', leftMargin, -200);
	auctionTab.currentAuctions.frame:SetPoint('BOTTOMRIGHT', 0, 25);
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	if tab.auctionFaster then
		self.auctionTab:Show();
	else
		self.auctionTab:Hide();
	end
end