--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:GetSellSettings()
	local sellTab = self.sellTab;

	local cacheItem = self:GetSelectedItemFromCache();

	local bidPerItem = sellTab.bidPerItem:GetValue();
	local buyPerItem = sellTab.buyPerItem:GetValue();

	local maxStacks = tonumber(sellTab.maxStacks:GetValue());
	print('m1', maxStacks);
	local realMaxStacks = maxStacks;
	if maxStacks == 0 then
		maxStacks = AuctionFaster:CalcMaxStacks();
	end
	print('m1', maxStacks);
	local stackSize = tonumber(sellTab.stackSize:GetValue());
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
	self.selectedItem = self.inventoryItems[index];

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