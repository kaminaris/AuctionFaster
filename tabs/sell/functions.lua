---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type ItemCache
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type AuctionCache
local AuctionCache = AuctionFaster:GetModule('AuctionCache');
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

function Sell:Enable()
	self:AddSellAuctionHouseTab();
end

function Sell:OnShow()
	--self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');
	self:RegisterMessage('AFTER_INVENTORY_SCAN');
	self:InitTutorial();
	Inventory:ScanInventory();
end

function Sell:OnHide()
	--self:UnregisterEvent('AUCTION_ITEM_LIST_UPDATE');
end

function Sell:Disable()
	self:OnHide();
end

function Sell:AFTER_INVENTORY_SCAN()
	if Auctions.isInMultisellProcess then
		-- Do not update inventory while multiselling
		return;
	end
print('AFTER INV scan');
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

	local cacheKey = AuctionCache:MakeCacheKeyFromItemKey(self.selectedItem.itemKey);
	return ItemCache:FindOrCreateCacheItem(cacheKey, self.selectedItem.itemKey);
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
	for i = 1, #Inventory.inventoryItems do
		local item = Inventory.inventoryItems[i];

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

function Sell:GetCurrentAuctions(force)
	local selectedItem = self.selectedItem;
	local itemKey = selectedItem.itemKey;
	local cacheKey = AuctionCache:MakeCacheKeyFromItemKey(selectedItem.itemKey);

	local itemRecord = ItemCache:FindOrCreateCacheItem(cacheKey, itemKey);
	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemKey);

	local cacheLifetime = 60 * 5; -- 5 minutes

	local needRescan = not force and
		(auctionRecord.lastScanTime == nil or auctionRecord.lastScanTime + cacheLifetime < GetServerTime());

	-- We still have pretty recent results from auction house, no need to scan again
	if not needRescan and itemRecord and auctionRecord and #auctionRecord.auctions > 0 then
		self:UpdateSellTabAuctions(itemRecord, auctionRecord);
		self:UpdateInfoPaneText();
		return ;
	end

	Auctions:QueryItem(itemKey, function(items)
		Sell:CurrentAuctionsCallback(items);
	end);
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

	local cacheKey = AuctionCache:MakeCacheKeyFromItemKey(self.selectedItem.itemKey);
	local cacheItem = ItemCache:FindOrCreateCacheItem(cacheKey, self.selectedItem.itemKey);

	-- Clear prices
	self:UpdateTabPrices(nil, nil);

	if cacheItem.settings.rememberStack then
		self:UpdateStackSettings(cacheItem.stackSize or self.selectedItem.maxStackSize)
	else
		self:UpdateStackSettings(self.selectedItem.maxStackSize);
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
		for k, button in pairs(sellTab.buttons) do
			button:Enable();
		end
	else
		sellTab.bidPerItem:Disable();
		sellTab.buyPerItem:Disable();
		sellTab.stackSize:Disable();
		for k, button in pairs(sellTab.buttons) do
			button:Disable();
		end
	end
end

function Sell:UpdateItemsTabPrice(itemId, itemName, newPrice)
	local itemFrames = self.sellTab.scrollChild.items;
	for i = 1, #itemFrames do
		local f = itemFrames[i];
		if f.item.itemId == itemId and f.item.itemName == itemName then
			f.itemPrice:SetText(StdUi.Util.formatMoney(newPrice, true));
		end
	end
end

function Sell:CurrentAuctionsCallback(items)
	local itemRecord = self:GetSelectedItemRecord();
	-- No item selected ? - should not happen
	if not itemRecord then return; end

	-- we skip any auctions that are not the same as selected item so no problem
	AuctionCache:ParseScanResults(items);

	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemRecord.itemKey);

	self:UpdateSellTabAuctions(itemRecord, auctionRecord);
	self:UpdateInfoPaneText();
end

function Sell:CalculatePrice(itemRecord, auctionRecord)
	local priceModel = itemRecord.settings.priceModel or 'Simple';
	local sellSettings = self:GetSellSettings();
	local lowestBid, lowestBuy, fail, message = Pricing:CalculatePrice(
		priceModel,
		itemRecord,
		auctionRecord.auctions,
		sellSettings.stackSize,
		1 --- @TODO: Update this
	);

	if fail == true and message then
		AuctionFaster:Echo(3, message);
	end

	self:UpdateTabPrices(lowestBid, lowestBuy);

	return lowestBuy;
end

function Sell:RecalculatePrice(itemRecord, auctionRecord)
	if not itemRecord then return; end

	local minBuy;

	if itemRecord.settings.alwaysUndercut then
		minBuy = self:CalculatePrice(itemRecord, auctionRecord);
	elseif itemRecord.settings.rememberLastPrice then
		self:UpdateTabPrices(itemRecord.bid, itemRecord.buy);
		minBuy = itemRecord.buy;
	end

	Inventory:UpdateInventoryItemPrice(itemRecord.itemKey, minBuy);
	-- update the UI
	self:UpdateItemsTabPrice(itemRecord.itemId, itemRecord.itemName, minBuy);
end

function Sell:RecalculateCurrentPrice()
	if not self.selectedItem then
		return;
	end

	local itemRecord = self:GetSelectedItemRecord();
	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemRecord.itemId, itemRecord.itemName);
	self:RecalculatePrice(itemRecord, auctionRecord);
end

function Sell:UpdateSellTabAuctions(itemRecord, auctionRecord)
	self.sellTab.currentAuctions:SetData(auctionRecord.auctions, true);
	if auctionRecord.lastScanTime then
		self.sellTab.lastScan:SetText(
			format(L['Last scan: %s'], AuctionFaster:FormatDuration(GetServerTime() - auctionRecord.lastScanTime))
		);
	end

	self:RecalculatePrice(itemRecord, auctionRecord);
end

function Sell:RemoveSearchAuction(index)
	local itemKey = self.selectedItem.itemKey;
	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemKey);
	if not auctionRecord.auctions[index] then
		return;
	end

	local cacheKey = AuctionCache:MakeCacheKeyFromItemKey(itemKey);
	local itemRecord = ItemCache:FindOrCreateCacheItem(cacheKey, itemKey);

	tremove(auctionRecord.auctions, index);
	self:UpdateSellTabAuctions(itemRecord, auctionRecord);

	return auctionRecord;
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