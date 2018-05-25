--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:GetSellSettings()
	local sellTab = self.sellTab;

	local cacheItem = self:GetSelectedItemFromCache();

	local bidPerItem = sellTab.bidPerItem:GetValue();
	local buyPerItem = sellTab.buyPerItem:GetValue();

	local maxStacks = tonumber(sellTab.maxStacks:GetValue());

	local realMaxStacks = maxStacks;
	if maxStacks == 0 then
		maxStacks = AuctionFaster:CalcMaxStacks();
	end

	local stackSize = tonumber(sellTab.stackSize:GetValue());
	print('self.selectedItem.count', self.selectedItem.count);
	if stackSize > self.selectedItem.count then
		stackSize = self.selectedItem.count;
	end

	local duration = 2;
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

function AuctionFaster:UpdateCacheItemVariable(editBox, variable)
	if not editBox:IsValid() then
		return;
	end

	local cacheItem = self:GetSelectedItemFromCache();

	cacheItem[variable] = editBox:GetValue();
end

function AuctionFaster:UpdateTabPrices(bid, buy)
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

function AuctionFaster:UpdateStackSettings(maxStacks, stackSize)
	local sellTab = self.sellTab;

	if maxStacks then
		sellTab.maxStacks:SetValue(maxStacks);
	end

	if stackSize then
		sellTab.stackSize:SetValue(stackSize);
	end
end

function AuctionFaster:SelectItem(index)
	local sellTab = self.sellTab;
	if not self.inventoryItems[index] then
		return;
	end

	self.selectedItem = self.inventoryItems[index];
	self.selectedItemIndex = index;

	sellTab.itemIcon:SetTexture(self.selectedItem.icon);
	sellTab.itemName:SetText(self.selectedItem.link);

	sellTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStackSize .. ')');

	local cacheItem = self:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);

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

function AuctionFaster:GetSelectedItemIdName()
	if not self.selectedItem then
		return nil, nil;
	end

	return self.selectedItem.itemId, self.selectedItem.itemName;
end

function AuctionFaster:UpdateItemQtyText()
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

function AuctionFaster:EnableAuctionTabControls(enable)
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

function AuctionFaster:UpdateItemsTabPrice(itemId, itemName, newPrice)
	for i = 1, #self.itemFramePool do
		local f = self.itemFramePool[i];
		if f.item.itemId == itemId and f.item.itemName == itemName then
			f.itemPrice:SetText(self:FormatMoney(newPrice));
		end
	end
end

function AuctionFaster:BuyItem()
	local selectedId, selectedName = self:GetSelectedItemIdName();
	if not selectedId then
		return ;
	end

	local index = self.sellTab.currentAuctions:GetSelection();
	if not index then
		return ;
	end
	local auctionData = self.sellTab.currentAuctions:GetRow(index);

	-- maybe index is the same
	local name, texture, count, quality, canUse, level, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', index);

	local bid = floor(minBid / count);
	local buy = floor(buyoutPrice / count);

	if name == auctionData.itemName and itemId == auctionData.itemId and owner == auctionData.owner
			and bid == auctionData.bid and buy == auctionData.buy and count == auctionData.count then
		-- same index, we can buy it
		self:BuyItemByIndex(index);
		-- we need to refresh the auctions
		self:GetCurrentAuctions();
	end

	-- item was not found but lets check if it still exists
	-- todo: need to check it
end

function AuctionFaster:SellCurrentItem(singleStack)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	if not self:PutItemInSellBox(itemId, itemName) then
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

	local success, multisell = AuctionFaster:SellItem(sellSettings.bidPerItem * sellSettings.stackSize,
		sellSettings.buyPerItem * sellSettings.stackSize,
		sellSettings.duration,
		sellSettings.stackSize,
		maxStacks
	);

	if success and not multisell then
		C_Timer.After(0.5, function()
			self:CheckEverythingSold();
		end);
	end

	return success;
end


--- Check if all items has been sold, if not, propose to sell last incomplete stack
function AuctionFaster:CheckEverythingSold()
	local sellSettings = self:GetSellSettings();

	--- DISABLED FOR TEST
	--if sellSettings.realMaxStacks ~= 0 then
	--	return;
	--end

	local selectedItem = self.selectedItem;
	if not selectedItem then
		return ;
	end

	local itemId, itemName, itemLink = selectedItem.itemId, selectedItem.itemName, selectedItem.link;

	local currentItemName = GetAuctionSellItemInfo();

	if not currentItemName or currentItemName ~= itemName then
		self:PutItemInSellBox(itemId, itemName);
	end

	-- Check if item is still in inventory
	local qtyLeft = self:UpdateItemInventory(itemId, itemName);
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
				qtyLeft = AuctionFaster:UpdateItemInventory(itemId, itemName);
				if qtyLeft == 0 then
					return ;
				end

				AuctionFaster:SellCurrentItem(false);
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