---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
---@type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');
--- @class Sell
local Sell = AuctionFaster:NewModule('Sell', 'AceEvent-3.0');

local format = string.format;

function Sell:AddSellAuctionHouseTab()
	if self.sellTabAdded then
		return ;
	end

	self.sellTab = AuctionFaster:AddAuctionHouseTab(L['Sell Items'], L['AuctionFaster - Sell'], self);

	self.sellTab:SetScript('OnShow', function()
		Sell:OnShow();
	end);

	self.sellTab:SetScript('OnHide', function()
		Sell:OnHide();
	end);

	self.sellTabAdded = true;

	self:DrawItemsFrame();
	self:DrawRightPane();
	self:DrawHelpButton();
	self:EnableAuctionTabControls(false);
end

function Sell:DrawItemsFrame()
	local marginTop = -35;
	local sellTab = self.sellTab;
	local panel = StdUi:FauxScrollFrame(sellTab, 300, 300, 11, 32);
	panel:SetPoint('TOPLEFT', 25, marginTop);
	panel:SetPoint('BOTTOMLEFT', 300, 55);

	local refreshInventory = StdUi:Button(sellTab, 20, 20);
	refreshInventory.icon = StdUi:Texture(refreshInventory, 12, 12, [[Interface\Buttons\UI-RefreshButton]]);
	refreshInventory.icon:SetPoint('CENTER', 0, 0);
	StdUi:GlueAbove(refreshInventory, panel, 0, 5, 'RIGHT');
	StdUi:FrameTooltip(refreshInventory, L['Refresh inventory'], 'af_refresh', 'TOPRIGHT', true);
	refreshInventory:SetScript('OnClick', function()
		Inventory:ScanInventory();
	end);

	local sortSettings = StdUi:Button(sellTab, 20, 20);
	sortSettings.icon = StdUi:Texture(sortSettings, 12, 12, [[Interface\GossipFrame\BinderGossipIcon]]);
	sortSettings.icon:SetPoint('CENTER', 0, 0);
	StdUi:GlueLeft(sortSettings, refreshInventory, -5, 0);
	StdUi:FrameTooltip(sortSettings, L['Sort settings'], 'af_sort', 'TOPRIGHT', true);

	local function callback(value, groupName)
		if groupName == 'dd-sortBy' then
			self.sortInventoryBy = value;
			AuctionFaster.db.sell.sortInventoryBy = value;
		else
			self.sortInventoryOrder = value;
			AuctionFaster.db.sell.sortInventoryOrder = value;
		end

		self:DoFilterSort();
	end

	local settDrops = {
		{title = L['Sort by'], color = {1, 0.9, 0}},
		{radio = L['Name'],    value = 'itemName', radioGroup = 'dd-sortBy'},
		{radio = L['Price'],   value = 'price',    radioGroup = 'dd-sortBy'},
		{radio = L['Quality'], value = 'quality',  radioGroup = 'dd-sortBy'},

		{isSeparator = true},
		{title = L['Direction'], color = {1, 0.9, 0}},
		{radio = L['Ascending'],  value = 'asc',  radioGroup = 'dd-sortOrder'},
		{radio = L['Descending'], value = 'desc', radioGroup = 'dd-sortOrder'},
	}

	local sortContext = StdUi:ContextMenu(sortSettings, settDrops, true);
	StdUi:GlueOpposite(sortContext, sortSettings, 0, 0, 'BOTTOMRIGHT');

	StdUi:SetRadioGroupValue('dd-sortBy', 'itemName');
	StdUi:SetRadioGroupValue('dd-sortOrder', 'asc');

	StdUi:OnRadioGroupValueChanged('dd-sortBy', callback);
	StdUi:OnRadioGroupValueChanged('dd-sortOrder', callback);

	sortSettings:SetScript('OnClick', function()
		if sortContext:IsShown() then
			sortContext:Hide();
		else
			sortContext:Show();
		end
	end);

	local filter = StdUi:SearchEditBox(sellTab, 240, 20, L['Filter items']);
	StdUi:GlueAbove(filter, panel, 0, 5, 'LEFT');

	sellTab.filterText = false;
	filter.OnValueChanged = function(_, txt)
		if strlen(txt) > 1 then
			Sell.filterText = txt;
		else
			Sell.filterText = false;
		end

		Sell:DoFilterSort();
	end;

	sellTab.itemsList = panel;
	sellTab.scrollFrame = panel.scrollFrame;
	sellTab.scrollChild = panel.scrollChild;

	self.sortInventoryBy = AuctionFaster.db.sell.sortInventoryBy or 'itemName'; -- quality, price
	self.sortInventoryOrder = AuctionFaster.db.sell.sortInventoryOrder or 'asc';
	self.filterText = false;

	self.safeToDrawItems = true;
	self:DoFilterSort();
end

function Sell:DrawItems()
	-- Update bag delayed may cause this to happen before we open auction tab
	if not self.safeToDrawItems then
		return ;
	end

	local scrollChild = self.sellTab.scrollChild;
	local lineHeight = 32;
	local margin = 5;

	local buttonCreate = function(parent, data, i)
		return Sell:CreateItemFrame(parent, lineHeight, margin);
	end;

	local buttonUpdate = function(parent, itemFrame, data, i)
		Sell:UpdateItemFrame(itemFrame, data);
		itemFrame.itemIndex = i;
	end;

	if not scrollChild.items then
		scrollChild.items = {};
	end

	StdUi:ObjectList(scrollChild, scrollChild.items, buttonCreate, buttonUpdate, self.filteredItems);
	self.sellTab.itemsList:UpdateItemsCount(#self.filteredItems);
end

function Sell:CreateItemFrame(parent, lineHeight, margin)
	local holdingFrame = StdUi:HighlightButton(parent, parent:GetWidth(), lineHeight);

	holdingFrame:SetScript('OnEnter', function(self)
		if AuctionFaster.db.sell.tooltips.itemEnabled then
			AuctionFaster:ShowTooltip(
				self,
				self.itemLink,
				true,
				self.item.itemId,
				AuctionFaster.db.sell.tooltips.itemAnchor or 'RIGHT'
			);
		end
	end);

	holdingFrame:SetScript('OnLeave', function(self)
		if AuctionFaster.db.sell.tooltips.itemEnabled then
			AuctionFaster:ShowTooltip(self, nil, false);
		end
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

	sellTab.iconBackdrop = StdUi:Panel(sellTab, iconSize, iconSize);
	StdUi:GlueTop(sellTab.iconBackdrop, sellTab, leftMargin, topMargin, 'LEFT');

	sellTab.itemIcon = StdUi:Texture(sellTab.iconBackdrop, iconSize, iconSize, '');
	StdUi:GlueAcross(sellTab.itemIcon, sellTab.iconBackdrop, 1, -1, -1, 1);

	sellTab.itemName = StdUi:Label(sellTab, L['No Item selected'], nil, 'GameFontNormalLarge', 250, 20);
	StdUi:GlueAfter(sellTab.itemName, sellTab.itemIcon, 5, 0);

	sellTab.itemQty = StdUi:Label(sellTab, format(L['Qty: %d, Max Stacks: %d, Remaining: %d'], 0, 0, 0), nil, nil, 250,
		20);
	StdUi:GlueBelow(sellTab.itemQty, sellTab.itemName, 0, 5);

	-- Last scan time
	sellTab.lastScan = StdUi:Label(sellTab, format(L['Last scan: %s'], '---'));
	StdUi:GlueRight(sellTab.lastScan, sellTab.itemName, 5, 0);
end

function Sell:DrawRightPaneItemPrices(marginToIcon)
	local sellTab = self.sellTab;

	-- Bid per item edit box
	sellTab.bidPerItem = StdUi:MoneyBox(sellTab, 150, 20, '-');
	StdUi:AddLabel(sellTab, sellTab.bidPerItem,  L['Bid Per Item'], 'TOP');

	sellTab.bidPerItem:Validate();
	StdUi:GlueBelow(sellTab.bidPerItem, sellTab.itemIcon, 0, marginToIcon, 'LEFT');

	-- Buy per item edit box
	sellTab.buyPerItem = StdUi:MoneyBox(sellTab, 150, 20, '-');
	StdUi:AddLabel(sellTab, sellTab.buyPerItem,  L['Buy Per Item'], 'TOP');

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
	sellTab.stackSize = StdUi:NumericBox(sellTab, 150, 20, '1');
	StdUi:AddLabel(sellTab, sellTab.stackSize, L['Stack Size'], 'TOP');

	sellTab.stackSize:SetValue(1);
	StdUi:GlueRight(sellTab.stackSize, sellTab.bidPerItem, marginToPrices, 0);

	sellTab.maxStacks = StdUi:NumericBox(sellTab, 150, 20, '0');
	StdUi:AddLabel(sellTab, sellTab.maxStacks, L['# Stacks'], 'TOP');

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

function Sell:DrawRightPaneButtons()
	local sellTab = self.sellTab;

	local itemSettings = StdUi:Button(sellTab, 120, 20, L['Item Settings']);
	local infoPane = StdUi:Button(sellTab, 120, 20, L['Auction Info']);
	local refresh = StdUi:Button(sellTab, 120, 20, L['Refresh Auctions']);

	StdUi:GlueRight(itemSettings, sellTab.stackSize, 20, 20);
	StdUi:GlueBelow(infoPane, itemSettings, 0, -5);
	StdUi:GlueBelow(refresh, infoPane, 0, -5);

	itemSettings:SetScript('OnClick', function()
		self:ToggleItemSettingsPane();
	end);

	infoPane:SetScript('OnClick', function()
		self:ToggleInfoPane();
	end);

	refresh:SetScript('OnClick', function()
		self:GetCurrentAuctions(true);
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

	local postButton = StdUi:Button(sellTab, 120, 20, L['Post All']);
	StdUi:GlueBottom(postButton, sellTab, -20, 20, 'RIGHT');

	local postOneButton = StdUi:Button(sellTab, 120, 20, L['Post One']);
	StdUi:GlueLeft(postOneButton, postButton, -10, 0);

	local buyItemButton = StdUi:Button(sellTab, 120, 20, L['Chain Buy']);
	StdUi:GlueBottom(buyItemButton, sellTab, leftMargin, 20, 'LEFT');

	postButton:SetScript('OnClick', function()
		Sell:SellCurrentItem();
	end);

	postOneButton:SetScript('OnClick', function()
		Sell:SellCurrentItem(true);
	end);

	buyItemButton:SetScript('OnClick', function()
		local index = sellTab.currentAuctions:GetSelection();
		if not index then
			AuctionFaster:Echo(3, L['Please select item first']);
			return ;
		end
		Sell:ChainBuyStart(index);
	end);

	sellTab.buttons.postButton = postButton;
	sellTab.buttons.postOneButton = postOneButton;
	sellTab.buttons.buyItemButton = buyItemButton;
end

function Sell:DrawRightPaneCurrentAuctionsTable(leftMargin)
	local sellTab = self.sellTab;

	local cols = {
		{
			name         = L['Seller'],
			width        = 116,
			align        = 'LEFT',
			index        = 'owner',
			format       = 'string',
			events		 = {
				OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
					if AuctionFaster.db.sell.tooltips.enabled then
						AuctionFaster:ShowTooltip(
							cellFrame,
							rowData.itemLink,
							true,
							rowData.itemId,
							AuctionFaster.db.sell.tooltips.anchor
						);
					end
					return false;
				end,
				OnLeave = function(table, cellFrame)
					if AuctionFaster.db.sell.tooltips.enabled then
						AuctionFaster:ShowTooltip(cellFrame, nil, false);
					end
					return false;
				end
			},
		},
		{
			name         = L['Qty'],
			width        = 38,
			align        = 'LEFT',
			index        = 'count',
			format       = 'number',
		},
		{
			name         = L['Lvl'],
			width        = 38,
			align        = 'LEFT',
			index        = 'level',
			format       = 'number',
		},
		{
			name         = L['Bid / Item'],
			width        = 120,
			align        = 'RIGHT',
			index        = 'bid',
			format       = 'money',
		},
		{
			name         = L['Buy / Item'],
			width        = 120,
			align        = 'RIGHT',
			index        = 'buy',
			format       = 'money',
		},
	}

	sellTab.currentAuctions = StdUi:ScrollTable(sellTab, cols, 10, 18);
	sellTab.currentAuctions:EnableSelection(true);
	sellTab.currentAuctions:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Sell:InstantBuy(rowData, rowIndex)
				elseif IsAltKeyDown() then
					Sell:AddToQueue(rowData, rowIndex);
				elseif IsControlKeyDown() then
					Sell:ChainBuyStart(rowIndex);
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
	StdUi:GlueAcross(sellTab.currentAuctions, sellTab, leftMargin, -200, -20, 55);
end
