local ScrollingTable = LibStub('ScrollingTable');
local StdUi = LibStub('StdUi-1.0');

AuctionFaster.itemFramePool = {};
AuctionFaster.itemFrames = {};

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
	self:DrawItemsFrame();
	self:DrawRightPane();
	self:DrawTabButtons();

	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:DrawItemsFrame()

	local auctionTab = self.auctionTab;
	local scrollFrame, scrollChild = StdUi:ScrollFrame(auctionTab, 'AFLeftScroll', 300, 300);
	scrollFrame:SetPoint('TOPLEFT', 5, -25);
	scrollFrame:SetPoint('BOTTOMLEFT', 300, 35);

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

	scrollChild:SetHeight(lineHeight * #self.inventoryItems);

	local holdingFrames = {};
	for i = 1, #self.inventoryItems do

		-- next time we will be running this function we will reuse frames
		local holdingFrame = tremove(self.itemFramePool);

		if not holdingFrame then
			-- no allocated frame need to create one
			holdingFrame = StdUi:Button(scrollChild, scrollChild:GetWidth(), lineHeight, nil, false, true, false);
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

			holdingFrame.itemName = StdUi:Label(holdingFrame, nil, '', nil, 150, 20);
			holdingFrame.itemName:SetPoint('TOPLEFT', 35, -5);

			holdingFrame.itemPrice = StdUi:Label(holdingFrame, nil, '', nil, 80, 20);
			holdingFrame.itemPrice:SetJustifyH('RIGHT');
			holdingFrame.itemPrice:SetPoint('TOPRIGHT', 0, -5);

			tinsert(holdingFrames, holdingFrame);
		end

		-- there is a frame so we need to update it
		holdingFrame:SetPoint('TOPLEFT', 0, -(i - 1) * lineHeight);
		holdingFrame.itemLink = self.inventoryItems[i].link;
		holdingFrame.itemIndex = i;
		holdingFrame.itemIcon:SetTexture(self.inventoryItems[i].icon);
		holdingFrame.itemName:SetText(self.inventoryItems[i].name);
		holdingFrame.itemPrice:SetText(AuctionFaster:FormatMoney(self.inventoryItems[i].price));
		holdingFrame:Show();
	end

	-- hide all not used frames
	for i = 1, #self.itemFramePool do
		self.itemFramePool[i]:Hide();
	end

	for i = 1, #holdingFrames do
		tinsert(self.itemFramePool, holdingFrames[i]);
	end
end

function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];

	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.name);


	auctionTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStack .. ')');
	auctionTab.stackSize:SetText(self.selectedItem.maxStack);

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
end

function AuctionFaster:UpdateItemQtyText()
	if not self.selectedItem then
		return
	end

	local auctionTab = self.auctionTab;
	local maxStacks, remainingQty = self:CalcMaxStacks();
	auctionTab.itemQty:SetText(
		'Qty: ' .. self.selectedItem.count ..
		', Max Stacks: ' .. maxStacks ..
		', Remaining: ' .. remainingQty
	);
end

function AuctionFaster:DrawRightPane()

	local auctionTab = self.auctionTab;
	local leftMargin = 340;
	local iconSize = 48;

	local rightMargin = leftMargin + 200;

	auctionTab.itemIcon = StdUi:Texture(auctionTab, iconSize, iconSize, '');
	auctionTab.itemIcon:SetPoint('TOPLEFT', leftMargin, -25)

	auctionTab.itemName = StdUi:Label(auctionTab, 16, 'No item selected', nil, 250, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -25);

	auctionTab.itemQty = StdUi:Label(auctionTab, 14, 'Qty: O, Max Stacks: 0', nil, 250, 20);
	auctionTab.itemQty:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -45);

	-- Last scan time
	auctionTab.lastScan = StdUi:Label(auctionTab, 12, 'Last scan: ---');
	StdUi:GlueRight(auctionTab.lastScan, auctionTab.itemName, 5, 0);

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
	auctionTab.stackSize:SetScript('OnTextChanged', function(self)
		AuctionFaster:ValidateStackSize(self);
	end)
	StdUi:GlueRight(auctionTab.stackSize, auctionTab.bidPerItem, 120, 0);


	auctionTab.maxStacks = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '0',
		'Limit of stacks (0 = no limit)', nil, 'TOP');
	auctionTab.maxStacks:SetNumeric(true);
	auctionTab.maxStacks:SetScript('OnTextChanged', function(self)
		AuctionFaster:ValidateMaxStacks(self);
	end)
	StdUi:GlueRight(auctionTab.maxStacks, auctionTab.buyPerItem, 120, 0);

	self:DrawRightPaneCurrentAuctionsTable();
end

function AuctionFaster:CalcMaxStacks()
	local auctionTab = self.auctionTab;
	if not self.selectedItem then
		return 0, 0;
	end

	local stackSize = tonumber(auctionTab.stackSize:GetText());
	local maxStacks = floor(self.selectedItem.count / stackSize);
	if maxStacks == 0 then
		maxStacks = 1;
	end
	local remainingQty = self.selectedItem.count - (maxStacks * stackSize);
	if remainingQty < 0 then
		remainingQty = 0;
	end
	return maxStacks, remainingQty;
end

function AuctionFaster:ValidateMaxStacks(editBox)
	if not self.selectedItem then
		return;
	end

	local maxStacks = tonumber(editBox:GetText());
	local origMaxStacks = maxStacks;

	local maxStacksPossible = AuctionFaster:CalcMaxStacks();

	-- 0 means no limit
	if maxStacks < 0 then
		maxStacks = 0;
	end

	if maxStacks > maxStacksPossible then
		maxStacks = maxStacksPossible;
	end

	if maxStacks ~= origMaxStacks then
		editBox:SetText(maxStacks);
	end
	AuctionFaster:UpdateItemQtyText();
end

function AuctionFaster:ValidateStackSize(editBox)
	if not self.selectedItem then
		return;
	end

	local stackSize = tonumber(editBox:GetText());
	local origStackSize = stackSize;

	if stackSize < 1 then
		stackSize = 1;
	end

	if stackSize > self.selectedItem.maxStack then
		stackSize = self.selectedItem.maxStack;
	end

	if stackSize ~= origStackSize then
		editBox:SetText(stackSize);
	end
	AuctionFaster:UpdateItemQtyText();
end

function AuctionFaster:GetSellSettings()
	local auctionTab = self.auctionTab;

	local bidPerItemText = auctionTab.bidPerItem:GetText();
	local buyPerItemText = auctionTab.buyPerItem:GetText();

	return {
		bidPerItem = self:ParseMoney(bidPerItemText),
		buyPerItem = self:ParseMoney(buyPerItemText),
		stackSize = auctionTab.stackSize
	};
end

function AuctionFaster:UpdateTabPrices(bid, buy)
	local auctionTab = self.auctionTab;

	local bidText = self:FormatMoneyNoColor(bid);
	local buyText = self:FormatMoneyNoColor(buy);

	auctionTab.bidPerItem:SetText(bidText);
	auctionTab.buyPerItem:SetText(buyText);
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
			['name'] = 'Bid / Item',
			['width'] = 120,
			['align'] = 'RIGHT',
			['DoCellUpdate'] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
				if fShow then
					cellFrame.text:SetText(AuctionFaster:FormatMoney(data[realrow][3]));
				end
			end,
		},

		{
			['name'] = 'Buy / Item',
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