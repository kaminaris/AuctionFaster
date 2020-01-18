---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type ItemCache
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');
--- @type Pricing
local Pricing = AuctionFaster:GetModule('Pricing');
--- @type ConfirmBuy
local ConfirmBuy = AuctionFaster:GetModule('ConfirmBuy');

--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local format = string.format;
local pairs = pairs;

function Sell:Enable()
	self:AddSellAuctionHouseTab();
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');

	self:RegisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
end

function Sell:Disable()
	self:OnHide();
	self:UnregisterEvent('AUCTION_HOUSE_CLOSED');
	self:UnregisterEvent('AUCTION_HOUSE_SHOW');
end

function Sell:AUCTION_HOUSE_SHOW()
end

function Sell:AUCTION_HOUSE_CLOSED()
	--self:UnregisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	--self:UnregisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
end

function Sell:OnShow()
	--self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');
	self:RegisterMessage('AFTER_INVENTORY_SCAN');
	self:InitTutorial();
	Inventory:ScanInventory();
end

function Sell:OnHide()
	self:UnregisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:UnregisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
end

function Sell:COMMODITY_SEARCH_RESULTS_UPDATED(_, itemId)
	local items = Auctions:ScanCommodityResults(itemId);

	local selectedItem = self:GetSelectedItemRecord();
	-- No item selected ? - should not happen
	if not selectedItem then return; end

	self:UpdateItemListPrices(selectedItem, items);
	self:UpdateInfoPaneText();
end

function Sell:ITEM_SEARCH_RESULTS_UPDATED(_, itemKey)
	local items = Auctions:ScanItemResults(itemKey);

	local itemRecord = self:GetSelectedItemRecord();
	-- No item selected ? - should not happen
	if not itemRecord then return; end

	self:UpdateItemListPrices(itemRecord, items);
	self:UpdateInfoPaneText();
end

function Sell:AFTER_INVENTORY_SCAN()
	-- redraw items
	self:DoFilterSort();

	-- ignore if last sold item was over 2 seconds ago, prevents from opening when closing and opening AH again
	if GetTime() - Auctions.lastSoldTimestamp > 2 or not Auctions.soldFlag then
		return;
	end

	--self:CheckEverythingSold();
	Auctions.lastSoldItem = nil;
end

function Sell:GetSelectedItemRecord()
	if not self.selectedItem then
		return nil;
	end

	return ItemCache:FindOrCreateCacheItem(self.selectedItem.itemKey);
end

function Sell:GetSellSettings()
	local sellTab = self.sellTab;

	local itemRecord = self:GetSelectedItemRecord();

	local bidPerItem = sellTab.bidPerItem:GetValue();
	local buyPerItem = sellTab.buyPerItem:GetValue();

	local stackSize = tonumber(sellTab.stackSize:GetValue());

	if stackSize > self.selectedItem.count then
		stackSize = self.selectedItem.count;
	end

	local duration = AuctionFaster.db.auctionDuration;
	if itemRecord.settings.duration and itemRecord.settings.useCustomDuration then
		duration = itemRecord.settings.duration;
	end

	return {
		bidPerItem    = bidPerItem,
		buyPerItem    = buyPerItem,
		stackSize     = stackSize,
		duration      = duration
	};
end

function Sell:DoFilterSort()
	self.filteredItems = {};
	for _, item in pairs(Inventory.inventoryItems) do
		if self.filterText == false or strfind(item.itemName:lower(), self.filterText:lower()) then
			tinsert(self.filteredItems, item);
		end
	end

	table.sort(self.filteredItems, function(rowA, rowB)
		return self:CompareSort(rowA, rowB, sortBy);
	end);

	self:DrawItems();
end

function Sell:CompareSort(a, b)
	local valA, valB = a[self.sortInventoryBy], b[self.sortInventoryBy];

	if self.sortInventoryBy == 'price' then
		if valA == nil or valA == '---' then valA = 0; end
		if valB == nil or valB == '---' then valB = 0; end
	end

	if self.sortInventoryOrder == 'asc' then
		return valA < valB;
	else
		return valA > valB;
	end
end

function Sell:UpdateCacheItemVariable(editBox, variable)
	if not editBox:IsValid() then
		return;
	end

	local cacheItem = self:GetSelectedItemRecord();
	cacheItem[variable] = editBox:GetValue();
end

function Sell:UpdateTabPrices(bid, buy)
	local sellTab = self.sellTab;

	if bid then
		sellTab.bidPerItem:SetValue(bid);
	else
		sellTab.bidPerItem:SetText('-');
		sellTab.bidPerItem:Validate();
	end

	if buy then
		sellTab.buyPerItem:SetValue(buy);
	else
		sellTab.buyPerItem:SetText('-');
		sellTab.buyPerItem:Validate();
	end
end

function Sell:GetCurrentAuctions()
	local selectedItem = self:GetSelectedItemRecord();
	-- No item selected ? - should not happen
	if not selectedItem then return; end

	self:UpdateItemListPrices(selectedItem, {});
	Auctions:QueryItem(selectedItem.itemKey);
end

function Sell:UpdateStackSettings(stackSize)
	local sellTab = self.sellTab;

	if stackSize then
		sellTab.stackSize:SetValue(stackSize);
	end
end

function Sell:SelectItem(index)
	local sellTab = self.sellTab;
	if not self.filteredItems[index] then
		return;
	end

	self.selectedItem = self.filteredItems[index];
	self.selectedItemIndex = index;

	sellTab.itemIcon:SetTexture(self.selectedItem.icon);
	sellTab.itemName:SetText(self.selectedItem.link);

	local cacheItem = ItemCache:FindOrCreateCacheItem(self.selectedItem.itemKey);

	-- Clear prices
	self:UpdateTabPrices(nil, nil);

	if cacheItem.settings.rememberStack then
		self:UpdateStackSettings(cacheItem.stackSize or self.selectedItem.count or 1)
	else
		self:UpdateStackSettings(self.selectedItem.count);
	end

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
	self:LoadItemSettings();
	self:EnableAuctionTabControls(true);
end

function Sell:CheckIfSelectedItemExists()
	local selectedId, selectedName = self:GetSelectedItemIdName();
	if not selectedId then
		return false;
	end

	local qtyLeft = Inventory:UpdateItemInventory(selectedId, selectedName);
	if qtyLeft == 0 then
		if #self.filteredItems > self.selectedItemIndex then
			-- select next item
			self:SelectItem(self.selectedItemIndex);
		else
			-- just select last item
			self:SelectItem(#self.filteredItems);
		end
		return false;
	end

	return true;
end

function Sell:GetSelectedItemIdName()
	if not self.selectedItem then
		return nil, nil;
	end

	return self.selectedItem.itemId, self.selectedItem.itemName;
end

function Sell:UpdateItemQtyText()
	if not self.selectedItem then
		return ;
	end

	local sellTab = self.sellTab;
	local remainingQty = self:CalcMaxStacks();
	sellTab.itemQty:SetText(
		format(
			L['Qty: %d, Remaining: %d'],
			self.selectedItem.count,
			remainingQty
		)
	);
end

function Sell:EnableAuctionTabControls(enable)
	local sellTab = self.sellTab;

	if enable then
		sellTab.bidPerItem:Enable();
		sellTab.buyPerItem:Enable();
		sellTab.stackSize:Enable();
		for _, button in pairs(sellTab.buttons) do
			button:Enable();
		end
	else
		sellTab.bidPerItem:Disable();
		sellTab.buyPerItem:Disable();
		sellTab.stackSize:Disable();
		for _, button in pairs(sellTab.buttons) do
			button:Disable();
		end
	end
end

function Sell:UpdateItemsTabPrice(itemKey, newPrice)
	for _, f in pairs(self.sellTab.scrollChild.items) do
		if Inventory:ItemKeyEqual(f.item.itemKey, itemKey) then
			f.itemPrice:SetText(StdUi.Util.formatMoney(newPrice, true));
		end
	end
end

function Sell:HideItemsHighlight(exceptIndex)
	for index, f in pairs(self.sellTab.scrollChild.items) do
		if exceptIndex and exceptIndex == index then
			f.highlightTexture:Show();
		else
			f.highlightTexture:Hide();
		end
	end
end

function Sell:CalculatePrice(itemRecord, auctions)
	local priceModel = itemRecord.settings.priceModel or 'Simple';
	local lowestBid, lowestBuy, fail, message = Pricing:CalculatePrice(
		priceModel,
		itemRecord,
		auctions
	);

	if fail == true and message then
		AuctionFaster:Echo(3, message);
	end

	self:UpdateTabPrices(lowestBid, lowestBuy);

	return lowestBuy;
end

function Sell:RecalculatePrice(itemRecord, auctions)
	if not itemRecord then return; end

	local minBuy;

	if itemRecord.settings.alwaysUndercut then
		minBuy = self:CalculatePrice(itemRecord, auctions);
	elseif itemRecord.settings.rememberLastPrice then
		self:UpdateTabPrices(itemRecord.bid, itemRecord.buy);
		minBuy = itemRecord.buy;
	end

	Inventory:UpdateInventoryItemPrice(itemRecord.itemKey, minBuy);
	-- update the UI
	self:UpdateItemsTabPrice(itemRecord.itemKey, minBuy);
end

function Sell:RecalculateCurrentPrice()
	if not self.selectedItem then
		return;
	end

	local itemRecord = self:GetSelectedItemRecord();

	self:RecalculatePrice(itemRecord, self.items);
end

function Sell:UpdateItemListPrices(itemRecord, auctions)
	if not auctions then
		return;
	end

	self.sellTab.currentAuctions:SetData(auctions, true);
	local cacheItem = ItemCache:FindOrCreateCacheItem(itemRecord.itemKey);

	self:RecalculatePrice(itemRecord, auctions, cacheItem);
end

function Sell:InstantBuy(rowData)
	ConfirmBuy:ConfirmPurchase(rowData.itemKey, rowData.isCommodity);

	Sell:GetCurrentAuctions(true);
end

function Sell:CloseCallback()
	Sell:GetCurrentAuctions(true);
end

function Sell:SellCurrentItem()
	local selectedItem = self.selectedItem;
	if not selectedItem then
		return false;
	end

	local sellSettings = self:GetSellSettings();

	local success = Auctions:SellItem(
		selectedItem.itemLocation,
		sellSettings.stackSize,
		sellSettings.duration,
		sellSettings.buyPerItem,
		sellSettings.bidPerItem
	);

	return success;
end