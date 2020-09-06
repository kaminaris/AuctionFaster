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
--- @type ChainBuy
local ChainBuy = AuctionFaster:GetModule('ChainBuy');
--- @type Pricing
local Pricing = AuctionFaster:GetModule('Pricing');

--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local format = string.format;

function Sell:OnEnable()
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
end

Sell.initialized = false;
function Sell:AUCTION_HOUSE_SHOW()
	if AuctionFaster.db.enabled then
		if not self.initialized then
			self:AddSellAuctionHouseTab();
			self.initialized = true;
		end

		if AuctionFaster.db.defaultTab == 'SELL' then
			AuctionFrameTab_OnClick(self.auctionTabs[1].tabButton);
		end
	end
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

function Sell:AUCTION_HOUSE_CLOSED()
	self:OnHide();
end

function Sell:AFTER_INVENTORY_SCAN()
	if Auctions.isInMultisellProcess then
		-- Do not update inventory while multiselling
		return;
	end

	-- redraw items
	self:DoFilterSort();

	-- if it was in the selling process check if everything has been sold
	if not self:CheckIfSelectedItemExists() or not Auctions.lastSoldItem then
		return;
	end

	-- ignore if last sold item was over 2 seconds ago, prevents from opening when closing and opening AH again
	if GetTime() - Auctions.lastSoldTimestamp > 2 or not Auctions.soldFlag then
		return;
	end

	self:CheckEverythingSold();
	Auctions.lastSoldItem = nil;
end

function Sell:GetSelectedItemRecord()
	if not self.selectedItem then
		return nil;
	end

	return ItemCache:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);
end

function Sell:GetSellSettings()
	local sellTab = self.sellTab;

	local itemRecord = self:GetSelectedItemRecord();

	local bidPerItem = sellTab.bidPerItem:GetValue();
	local buyPerItem = sellTab.buyPerItem:GetValue();

	local maxStacks = tonumber(sellTab.maxStacks:GetValue());

	local realMaxStacks = maxStacks;
	if maxStacks == 0 then
		maxStacks = self:CalcMaxStacks();
	end

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
		maxStacks     = maxStacks,
		realMaxStacks = realMaxStacks,
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
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	local itemRecord = ItemCache:FindOrCreateCacheItem(itemId, itemName);
	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemId, itemName);

	local cacheLifetime = 60 * 5; -- 5 minutes

	local needRescan = not force and
		(auctionRecord.lastScanTime == nil or auctionRecord.lastScanTime + cacheLifetime < GetServerTime());

	-- We still have pretty recent results from auction house, no need to scan again
	if not needRescan and itemRecord and auctionRecord and #auctionRecord.auctions > 0 then
		self:UpdateSellTabAuctions(itemRecord, auctionRecord);
		self:UpdateInfoPaneText();
		return ;
	end

	local query = {
		name = itemName,
		exact = true
	};

	Auctions:QueryAuctions(query, function(shown, total, items)
		Sell:CurrentAuctionsCallback(shown, total, items);
	end);
end

function Sell:UpdateStackSettings(maxStacks, stackSize)
	local sellTab = self.sellTab;

	if maxStacks then
		sellTab.maxStacks:SetValue(maxStacks);
	end

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

	sellTab.stackSize.label:SetText(format(L['Stack Size (Max: %d)'], self.selectedItem.maxStackSize));

	local cacheItem = ItemCache:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);

	-- Clear prices
	self:UpdateTabPrices(nil, nil);

	if cacheItem.settings.rememberStack then
		self:UpdateStackSettings(cacheItem.maxStacks, cacheItem.stackSize or self.selectedItem.maxStackSize)
	else
		self:UpdateStackSettings(0, self.selectedItem.maxStackSize);
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
	local maxStacks, remainingQty = self:CalcMaxStacks();
	sellTab.itemQty:SetText(
		format(
			L['Qty: %d, Max Stacks: %d, Remaining: %d'],
			self.selectedItem.count,
			maxStacks,
			remainingQty
		)
	);
end

function Sell:EnableAuctionTabControls(enable)
	local sellTab = self.sellTab;

	if enable then
		sellTab.bidPerItem:Enable();
		sellTab.buyPerItem:Enable();
		sellTab.maxStacks:Enable();
		sellTab.stackSize:Enable();
		for k, button in pairs(sellTab.buttons) do
			button:Enable();
		end
	else
		sellTab.bidPerItem:Disable();
		sellTab.buyPerItem:Disable();
		sellTab.maxStacks:Disable();
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
			f.itemPrice:SetText(StdUi.Util.formatMoney(newPrice));
		end
	end
end

function Sell:CurrentAuctionsCallback(shown, total, items)
	local itemRecord = self:GetSelectedItemRecord();
	-- No item selected ? - should not happen
	if not itemRecord then return; end

	-- we skip any auctions that are not the same as selected item so no problem
	AuctionCache:ParseScanResults(items, total);

	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(itemRecord.itemId, itemRecord.itemName);

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

	Inventory:UpdateInventoryItemPrice(itemRecord.itemId, itemRecord.itemName, minBuy);
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
	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(self.selectedItem.itemId, self.selectedItem.itemName);
	if not auctionRecord.auctions[index] then
		return;
	end

	local itemRecord = ItemCache:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);

	tremove(auctionRecord.auctions, index);
	self:UpdateSellTabAuctions(itemRecord, auctionRecord);

	return auctionRecord;
end


function Sell:InstantBuy(rowData, rowIndex)
	if not Auctions:HasAuctionsList() then
		AuctionFaster:Echo(3, L['Please refresh auctions first']);
		return;
	end

	Auctions:BuyItem(rowData);

	Sell:RemoveSearchAuction(rowIndex);
	Sell:GetCurrentAuctions(true);
end

function Sell:CloseCallback()
	Sell:GetCurrentAuctions(true);
end

function Sell:ChainBuyStart(index)
	if not Auctions:HasAuctionsList() then
		AuctionFaster:Echo(3, L['Please refresh auctions first']);
		return;
	end

	local queue = {};
	local filtered = self.sellTab.currentAuctions.filtered;
	local filteredIndex = 0;

	local auctionRecord = AuctionCache:FindOrCreateAuctionCache(self.selectedItem.itemId, self.selectedItem.itemName);
	if not auctionRecord.auctions[index] then
		return;
	end

	for i = 1, #filtered do
		if filtered[i] == index then filteredIndex = i; break; end
	end

	for i = filteredIndex, #auctionRecord.auctions do
		local rowIndex = filtered[i];
		tinsert(queue, auctionRecord.auctions[rowIndex]);
	end

	ChainBuy:Start(queue, nil, Sell.CloseCallback);
end

function Sell:AddToQueue(rowData, rowIndex)
	if not Auctions:HasAuctionsList() then
		AuctionFaster:Echo(3, L['Please refresh auctions first']);
		return;
	end

	ChainBuy:AddBuyRequest(rowData);
	ChainBuy:Start();

	Sell:RemoveSearchAuction(rowIndex);
end
--
--function Sell:AddToQueueWithXStacks(amount)
--	local queue = {};
--	local cacheItem = ItemCache:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);
--	if not cacheItem.auctions[index] then
--		return;
--	end
--
--	for i = 1, #cacheItem.auctions do
--		local auction = cacheItem.auctions[i];
--		if auction.count >= amount then
--			tinsert(queue, auction);
--		end
--	end
--
--	if #queue == 0 then
--		AuctionFaster:Echo(3, format(L['No auctions found with requested stack count: %d'], amount));
--	end
--
--	ChainBuy:Start(queue);
--end

function Sell:SellCurrentItem(singleStack)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;
	local itemQuality = selectedItem.quality;
	local itemLevel = selectedItem.level;

	if not Auctions:PutItemInSellBox(itemId, itemName, itemQuality, itemLevel) then
		return false;
	end

	local sellSettings = self:GetSellSettings();

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = sellSettings.duration;
	end

	local maxStacks = sellSettings.maxStacks;
	if singleStack then
		maxStacks = 1;
	end

	local success, multisell = Auctions:SellItem(
		sellSettings.bidPerItem * sellSettings.stackSize,
		sellSettings.buyPerItem * sellSettings.stackSize,
		sellSettings.duration,
		sellSettings.stackSize,
		maxStacks
	);

	return success;
end


--- Check if all items has been sold, if not, propose to sell last incomplete stack
function Sell:CheckEverythingSold()
	local sellSettings = self:GetSellSettings();

	if sellSettings.realMaxStacks ~= 0 then
		return;
	end

	local selectedItem = self.selectedItem;
	if not selectedItem then
		return ;
	end

	local itemId, itemName, itemLink = selectedItem.itemId, selectedItem.itemName, selectedItem.link;

	local currentItemName = GetAuctionSellItemInfo();
	if not currentItemName or currentItemName ~= itemName then
		Auctions:PutItemInSellBox(itemId, itemName, selectedItem.quality, selectedItem.level);
	end

	-- Check if item is still in inventory
	local qtyLeft = Inventory:UpdateItemInventory(itemId, itemName);
	if qtyLeft == 0 then
		return ;
	end

	self:SelectItem(self.selectedItemIndex);

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
	self:DoFilterSort();

	local buttons = {
		yes = {
			text    = L['Yes'],
			onClick = function(self)
				self:GetParent():Hide();

				-- Double check if item is still in inventory
				--qtyLeft = AuctionFaster:UpdateItemInventory(itemId, itemName);
				if qtyLeft == 0 then
					return ;
				end

				Sell:SellCurrentItem(false);
			end,
		},
		no  = {
			text    = L['No'],
			onClick = function(self)
				self:GetParent():Hide();
			end,
		}
	}

	StdUi:Confirm(
		L['Incomplete sell'],
		format(L['You still have %d of %s Do you wish to sell rest?'], qtyLeft, itemLink),
		buttons,
		'incomplete_sell'
	);

	Auctions.soldFlag = false;
end