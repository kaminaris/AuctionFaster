--- @type StdUi
local StdUi = LibStub('StdUi');

---@type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');

--- @class Sell
local Sell = AuctionFaster:NewModule('Sell', 'AceEvent-3.0');

function Sell:Enable()
	self:AddSellAuctionHouseTab();
	self:RegisterMessage('AFTER_INVENTORY_SCAN');
end

function Sell:AddSellAuctionHouseTab()
	if self.sellTabAdded then
		return ;
	end

	self.sellTab = AuctionFaster:AddAuctionHouseTab('Sell Items', 'Auction Faster - Sell');

	self.sellTabAdded = true;

	Inventory:ScanInventory();
	self:DrawItemsFrame();
	self:DrawRightPane();
	self:EnableAuctionTabControls(false);
end

function Sell:DrawItemsFrame()
	local marginTop = -35;
	local sellTab = self.sellTab;
	local panel, scrollFrame, scrollChild = StdUi:FauxScrollFrame(sellTab, 300, 300, 11, 32);
	panel:SetPoint('TOPLEFT', 25, marginTop);
	panel:SetPoint('BOTTOMLEFT', 300, 55);

	StdUi:AddLabel(sellTab, panel, 'Inventory Items', 'TOP');

	local refreshInventory = StdUi:Button(sellTab, 100, 20, 'Refresh');
	StdUi:GlueAbove(refreshInventory, panel, 0, 5, 'RIGHT');

	refreshInventory:SetScript('OnClick', function()
		Inventory:ScanInventory();
	end);

	sellTab.scrollFrame = scrollFrame;
	sellTab.scrollChild = scrollChild;

	self.safeToDrawItems = true;
	self:DrawItems();
end

function Sell:DrawItems()
	-- Update bag delayed may cause this to happen before we open auction tab
	if not self.safeToDrawItems then
		return ;
	end

	local scrollChild = self.sellTab.scrollChild;
	local lineHeight = 32;
	local margin = 5;

	local buttonCreate = function(parent, i)
		return Sell:CreateItemFrame(parent, lineHeight, margin);
	end;

	local buttonUpdate = function(parent, i, itemFrame, data)
		Sell:UpdateItemFrame(itemFrame, data);
		itemFrame.itemIndex = i;
	end;

	StdUi:ButtonList(scrollChild, buttonCreate, buttonUpdate, Inventory.inventoryItems, lineHeight);
end

function Sell:CreateItemFrame(parent, lineHeight, margin)
	local holdingFrame = StdUi:HighlightButton(parent, parent:GetWidth(), lineHeight);

	holdingFrame:SetScript('OnEnter', function(self)
		AuctionFaster:ShowTooltip(self, self.itemLink, true, self.item.itemId);
	end);
	holdingFrame:SetScript('OnLeave', function(self)
		AuctionFaster:ShowTooltip(self, nil, false);
	end);
	holdingFrame:SetScript('OnClick', function(self)
		Sell:SelectItem(self.itemIndex);
	end);

	holdingFrame.itemIcon = StdUi:Texture(holdingFrame, lineHeight - 2, lineHeight - 2);
	StdUi:GlueTop(holdingFrame.itemIcon, holdingFrame, 1, -1, 'LEFT');

	holdingFrame.itemName = StdUi:Label(holdingFrame, '', nil, nil, 150, 12);
	StdUi:GlueAfter(holdingFrame.itemName, holdingFrame.itemIcon, 5, 0);

	holdingFrame.itemPrice = StdUi:Label(holdingFrame, '', nil, nil, 100, 12);
	holdingFrame.itemPrice:SetJustifyH('RIGHT');
	StdUi:GlueTop(holdingFrame.itemPrice, holdingFrame, 0, 0, 'RIGHT');

	holdingFrame.itemQty = StdUi:Label(holdingFrame, '', nil, nil, 80, 12);
	StdUi:GlueBelow(holdingFrame.itemQty, holdingFrame.itemName, 0, -2, 'LEFT');

	return holdingFrame;
end

function Sell:UpdateItemFrame(holdingFrame, inventoryItem)
	holdingFrame.itemLink = inventoryItem.link;
	holdingFrame.item = inventoryItem;
	holdingFrame.itemIcon:SetTexture(inventoryItem.icon);
	holdingFrame.itemName:SetText(inventoryItem.link);
	holdingFrame.itemQty:SetText('#: |cff00f209' .. inventoryItem.count .. '|r');
	holdingFrame.itemPrice:SetText(StdUi.Util.formatMoney(inventoryItem.price));
end

function Sell:DrawRightPane()
	local leftMargin = 340;
	local topMargin = -35;
	local iconSize = 48;

	self:DrawRightPaneItemIcon(leftMargin, topMargin, iconSize);
	self:DrawRightPaneItemPrices(-25);
	self:DrawRightPaneStackSettings(10);
	self:InitEditboxTooltips();

	self:DrawRightPaneCurrentAuctionsTable(leftMargin);
	self:DrawRightPaneButtons();

	self:DrawTabButtons(leftMargin);
	-- Auction info panel
	self:DrawInfoPane();
	-- Auction item settings
	self:DrawItemSettingsPane();
end

function Sell:DrawRightPaneItemIcon(leftMargin, topMargin, iconSize)
	local sellTab = self.sellTab;

	local iconBackdrop = StdUi:Panel(sellTab, iconSize, iconSize);
	StdUi:GlueTop(iconBackdrop, sellTab, leftMargin, topMargin, 'LEFT');

	sellTab.itemIcon = StdUi:Texture(iconBackdrop, iconSize, iconSize, '');
	StdUi:GlueAcross(sellTab.itemIcon, iconBackdrop, 1, -1, -1, 1);

	sellTab.itemName = StdUi:Label(sellTab, 'No item selected', 16, nil, 250, 20);
	StdUi:GlueAfter(sellTab.itemName, sellTab.itemIcon, 5, 0);

	sellTab.itemQty = StdUi:Label(sellTab, 'Qty: O, Max Stacks: 0', 14, nil, 250, 20);
	StdUi:GlueBelow(sellTab.itemQty, sellTab.itemName, 0, 5);

	-- Last scan time
	sellTab.lastScan = StdUi:Label(sellTab, 'Last scan: ---', 12);
	StdUi:GlueRight(sellTab.lastScan, sellTab.itemName, 5, 0);
end

function Sell:DrawRightPaneItemPrices(marginToIcon)
	local sellTab = self.sellTab;

	-- Bid per item edit box
	sellTab.bidPerItem = StdUi:MoneyBoxWithLabel(sellTab, 150, 20, '-', 'Bid Per Item', 'TOP');
	sellTab.bidPerItem:Validate();
	StdUi:GlueBelow(sellTab.bidPerItem, sellTab.itemIcon, 0, marginToIcon, 'LEFT');

	-- Buy per item edit box
	sellTab.buyPerItem = StdUi:MoneyBoxWithLabel(sellTab, 150, 20, '-', 'Buy Per Item', 'TOP');
	sellTab.buyPerItem:Validate();
	StdUi:GlueBelow(sellTab.buyPerItem, sellTab.bidPerItem, 0, -20);

	sellTab.bidPerItem:SetScript('OnTabPressed', function(self)
		sellTab.buyPerItem:SetFocus();
	end);

	sellTab.buyPerItem:SetScript('OnTabPressed', function(self)
		sellTab.stackSize:SetFocus();
	end);

	sellTab.bidPerItem.OnValueChanged = function(self)
		Sell:ValidateItemPrice(self)
		Sell:UpdateCacheItemVariable(self, 'bid');
	end;

	sellTab.buyPerItem.OnValueChanged = function(self)
		Sell:ValidateItemPrice(self);
		Sell:UpdateCacheItemVariable(self, 'buy');
	end;
end

function Sell:DrawRightPaneStackSettings(marginToPrices)
	local sellTab = self.sellTab;

	-- Stack Size
	sellTab.stackSize = StdUi:NumericBoxWithLabel(sellTab, 150, 20, '1', 'Stack Size', 'TOP');
	sellTab.stackSize:SetValue(0);
	StdUi:GlueRight(sellTab.stackSize, sellTab.bidPerItem, marginToPrices, 0);

	sellTab.maxStacks = StdUi:NumericBoxWithLabel(sellTab, 150, 20, '0', '# Stacks', 'TOP');
	sellTab.maxStacks:SetValue(0);
	StdUi:GlueRight(sellTab.maxStacks, sellTab.buyPerItem, marginToPrices, 0);

	sellTab.stackSize.OnValueChanged = function(self)
		Sell:ValidateStackSize(self);
		Sell:UpdateCacheItemVariable(self, 'stackSize');
	end;

	sellTab.maxStacks.OnValueChanged = function(self)
		Sell:ValidateMaxStacks(self);
		Sell:UpdateCacheItemVariable(self, 'maxStacks');
	end;
end

function Sell:InitEditboxTooltips()
	local sellTab = self.sellTab;

	StdUi:FrameTooltip(sellTab.maxStacks, 'Left text', 'NoStacksTooltip', 'TOPLEFT', true);
end

function Sell:DrawRightPaneButtons()
	local sellTab = self.sellTab;

	local itemSettings = StdUi:Button(sellTab, 120, 20, 'Item Settings');
	StdUi:GlueRight(itemSettings, sellTab.stackSize, 20, 20);

	local infoPane = StdUi:Button(sellTab, 120, 20, 'Auction Info');
	StdUi:GlueBelow(infoPane, itemSettings, 0, -5);

	local refresh = StdUi:Button(sellTab, 120, 20, 'Refresh Auctions');
	StdUi:GlueBelow(refresh, infoPane, 0, -5);

	itemSettings:SetScript('OnClick', function()
		Sell:ToggleItemSettingsPane();
	end);

	infoPane:SetScript('OnClick', function()
		Sell:ToggleInfoPane();
	end);

	refresh:SetScript('OnClick', function()
		Sell:GetCurrentAuctions(true);
	end);

	sellTab.buttons = {
		itemSettings = itemSettings,
		infoPane = infoPane,
		refresh = refresh,
	};
end

--- Draws tab buttons like Post All, Post One and Buy Item
function Sell:DrawTabButtons(leftMargin)
	local sellTab = self.sellTab;

	local postButton = StdUi:Button(sellTab, 60, 20, 'Post All');
	StdUi:GlueBottom(postButton, sellTab, -20, 20, 'RIGHT');

	local postOneButton = StdUi:Button(sellTab, 60, 20, 'Post One');
	StdUi:GlueLeft(postOneButton, postButton, -10, 0);

	local buyItemButton = StdUi:Button(sellTab, 60, 20, 'Buy Item');
	StdUi:GlueBottom(buyItemButton, sellTab, leftMargin, 20, 'LEFT');

	postButton:SetScript('OnClick', function()
		Sell:SellCurrentItem();
	end);

	postOneButton:SetScript('OnClick', function()
		Sell:SellCurrentItem(true);
	end);

	buyItemButton:SetScript('OnClick', function()
		Sell:BuyItem();
	end);

	sellTab.buttons.postButton = postButton;
	sellTab.buttons.postOneButton = postOneButton;
	sellTab.buttons.buyItemButton = buyItemButton;
end

function Sell:DrawRightPaneCurrentAuctionsTable(leftMargin)
	local sellTab = self.sellTab;

	local cols = {
		{
			name         = 'Seller',
			width        = 150,
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

	sellTab.currentAuctions = StdUi:ScrollTable(sellTab, cols, 10, 18);
	sellTab.currentAuctions:EnableSelection(true);
	StdUi:GlueAcross(sellTab.currentAuctions.frame, sellTab, leftMargin, -200, -20, 55);
end