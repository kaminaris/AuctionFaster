--- @type ItemCache
local StdUi = LibStub('StdUi');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type Inventory
local Inventory = AuctionFaster:GetModule('Inventory');

--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

function Sell:AFTER_INVENTORY_SCAN()
	if Auctions.isInMultisellProcess then
		-- Do not update inventory while multiselling
		return;
	end

	-- redraw items
	self:DrawItems();

	-- if it was in the selling process check if everything has been sold
	if not self:CheckIfSelectedItemExists() or not Auctions.lastSoldItem then
		return;
	end

	self:CheckEverythingSold();
	Auctions.lastSoldItem = nil;
end

function Sell:GetSelectedItemFromCache()
	if not self.selectedItem then
		return nil;
	end

	local itemId, itemName = self.selectedItem.itemId, self.selectedItem.itemName;
	return ItemCache:GetItemFromCache(itemId, itemName, true);
end

function Sell:GetSellSettings()
	local sellTab = self.sellTab;

	local cacheItem = self:GetSelectedItemFromCache();

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
	if cacheItem.settings.duration and cacheItem.settings.useCustomDuration then
		duration = cacheItem.settings.duration;
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

function Sell:UpdateCacheItemVariable(editBox, variable)
	if not editBox:IsValid() then
		return;
	end

	local cacheItem = self:GetSelectedItemFromCache();

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

	local cacheItem = ItemCache:GetItemFromCache(itemId, itemName);

	-- We still have pretty recent results from auction house, no need to scan again
	if not force and cacheItem and cacheItem.auctions and #cacheItem.auctions > 0 then
		self:UpdateSellTabAuctions(cacheItem);
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
	if not Inventory.inventoryItems[index] then
		return;
	end

	self.selectedItem = Inventory.inventoryItems[index];
	self.selectedItemIndex = index;

	sellTab.itemIcon:SetTexture(self.selectedItem.icon);
	sellTab.itemName:SetText(self.selectedItem.link);

	sellTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStackSize .. ')');

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
		if #Inventory.inventoryItems > self.selectedItemIndex then
			-- select next item
			self:SelectItem(self.selectedItemIndex);
		else
			-- just select last item
			self:SelectItem(#Inventory.inventoryItems);
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
		'Qty: ' .. self.selectedItem.count ..
		', Max Stacks: ' .. maxStacks ..
		', Remaining: ' .. remainingQty
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
	local selectedId, selectedName = self:GetSelectedItemIdName();

	if not selectedId then
		-- No item selected ? - should not happen
		return ;
	end ;

	-- we skip any auctions that are not the same as selected item so no problem
	local cacheItem = ItemCache:FindOrCreateCacheItem(selectedId, selectedName);

	cacheItem.scanTime = GetServerTime();
	cacheItem.auctions = items;
	cacheItem.totalItems = #items;

	self:UpdateSellTabAuctions(cacheItem);
	self:UpdateInfoPaneText();
end

function Sell:UnderCutPrices(cacheItem, lowestBid, lowestBuy)
	if #cacheItem.auctions < 1 then
		return ;
	end

	if not lowestBid or not lowestBuy then
		lowestBid, lowestBuy = ItemCache:FindLowestBidBuy(cacheItem);
	end

	cacheItem.bid = lowestBid - 1;
	cacheItem.buy = lowestBuy - 1;

	self:UpdateTabPrices(lowestBid - 1, lowestBuy - 1);
end

function Sell:UpdateSellTabAuctions(cacheItem)
	self.sellTab.currentAuctions:SetData(cacheItem.auctions, true);
	self.sellTab.lastScan:SetText('Last Scan: ' .. AuctionFaster:FormatDuration(GetServerTime() - cacheItem.scanTime));

	local minBid, minBuy = ItemCache:FindLowestBidBuy(cacheItem);

	if cacheItem.settings.alwaysUndercut then
		self:UnderCutPrices(cacheItem, minBid, minBuy);
	elseif cacheItem.settings.rememberLastPrice then
		self:UpdateTabPrices(cacheItem.bid, cacheItem.buy);
	end

	Inventory:UpdateInventoryItemPrice(cacheItem.itemId, cacheItem.itemName, minBuy);
	-- update the UI
	self:UpdateItemsTabPrice(cacheItem.itemId, cacheItem.itemName, minBuy);
end

function Sell:AUCTION_ITEM_LIST_UPDATE()
	-- this unlocks the button after buying item
	if self.confirmFrame then
		self:LockBuyButton();
	end
end

function Sell:LockBuyButton(lock)
	local buyButton = self.confirmFrame.buttons['ok'];

	if lock then
		buyButton:Disable();
	else
		buyButton:Enable();
	end
end

function Sell:RemoveCurrentSearchAuction()
	local index = self.sellTab.currentAuctions:GetSelection();
	if not index then
		return ;
	end

	local cacheItem = ItemCache:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);

	if not cacheItem.auctions[index] then
		return;
	end

	tremove(cacheItem.auctions, index);
	self:UpdateSellTabAuctions(cacheItem);

	if cacheItem.auctions[index] then
		self.sellTab.currentAuctions:SetSelection(index);
	end
end

local alreadyBought = 0;
function Sell:BuySelectedItem(boughtSoFar, fresh)
	local auctionData = self.sellTab.currentAuctions:GetSelectedItem();
	if not auctionData then
		return ;
	end

	boughtSoFar = boughtSoFar or 0;
	alreadyBought = alreadyBought + boughtSoFar;
	if fresh then
		alreadyBought = 0;
	end

	local buttons = {
		ok     = {
			text    = 'Yes',
			onClick = function(self)
				local parent = self:GetParent();
				parent:Hide();

				Auctions:BuyItem(parent.auctionData);
				Sell:LockBuyButton(true);
				Sell:RemoveCurrentSearchAuction();

				-- Chain buy
				Sell:BuySelectedItem(parent.count);
			end
		},
		cancel = {
			text    = 'No',
			onClick = function(self)
				self:GetParent():Hide();
			end
		}
	};

	self.confirmFrame = StdUi:Confirm(
		'Confirm Buy',
		'Buying ' .. auctionData.itemLink .. '\n'..
			'qty: ' .. auctionData.count .. '\n\n' ..
			'per item: ' .. StdUi.Util.formatMoney(auctionData.buy) .. '\n' ..
			'Total: ' .. StdUi.Util.formatMoney(auctionData.buy * auctionData.count) .. '\n\n' ..

			'Bought so far: ' .. alreadyBought,
		buttons,
		'afConfirmBuy'
	);

	self.confirmFrame:SetHeight(200);
	self.confirmFrame.count = auctionData.count;
	self.confirmFrame.auctionData = auctionData;
end

function Sell:SellCurrentItem(singleStack)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	if not Auctions:PutItemInSellBox(itemId, itemName) then
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

	local success, multisell = Auctions:SellItem(sellSettings.bidPerItem * sellSettings.stackSize,
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
		Auctions:PutItemInSellBox(itemId, itemName);
	end

	-- Check if item is still in inventory
	local qtyLeft = Inventory:UpdateItemInventory(itemId, itemName);
	if qtyLeft == 0 then
		return ;
	end

	self:SelectItem(self.selectedItemIndex);

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
	self:DrawItems();

	local buttons = {
		yes = {
			text    = 'Yes',
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
			text    = 'No',
			onClick = function(self)
				self:GetParent():Hide();
			end,
		}
	}

	StdUi:Confirm('Incomplete sell', 'You still have ' .. qtyLeft .. ' of ' .. itemLink ..
		' Do you wish to sell rest?', buttons, 'incomplete_sell');
end