--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:GetSellSettings()
	local auctionTab = self.auctionTab;

	local cacheItem = self:GetSelectedItemFromCache();

	local bidPerItem = auctionTab.bidPerItem:GetValue();
	local buyPerItem = auctionTab.buyPerItem:GetValue();

	local maxStacks = tonumber(auctionTab.maxStacks:GetValue());
	local realMaxStacks = maxStacks;
	if maxStacks == 0 then
		maxStacks = AuctionFaster:CalcMaxStacks();
	end

	local stackSize = tonumber(auctionTab.stackSize:GetValue());
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
	local auctionTab = self.auctionTab;

	if bid then
		auctionTab.bidPerItem:SetValue(bid);
	else
		auctionTab.bidPerItem:SetText('-');
		auctionTab.bidPerItem:Validate();
	end

	if buy then
		auctionTab.buyPerItem:SetValue(buy);
	else
		auctionTab.buyPerItem:SetText('-');
		auctionTab.buyPerItem:Validate();
	end
end

function AuctionFaster:UpdateStackSettings(maxStacks, stackSize)
	local auctionTab = self.auctionTab;

	if maxStacks then
		auctionTab.maxStacks:SetValue(maxStacks);
	end

	if stackSize then
		auctionTab.stackSize:SetValue(stackSize);
	end
end

function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];

	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.link);

	auctionTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStackSize .. ')');

	local cacheItem = self:FindOrCreateCacheItem(self.selectedItem.itemId, self.selectedItem.itemName);

	-- Clear prices
	self:UpdateTabPrices(nil, nil);

	if cacheItem.settings.rememberStack then
		self:UpdateStackSettings(cacheItem.maxStacks, cacheItem.stackSize)
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

	local auctionTab = self.auctionTab;
	local maxStacks, remainingQty = self:CalcMaxStacks();
	auctionTab.itemQty:SetText(
		'Qty: ' .. self.selectedItem.count ..
		', Max Stacks: ' .. maxStacks ..
		', Remaining: ' .. remainingQty
	);
end

function AuctionFaster:EnableAuctionTabControls(enable)
	local auctionTab = self.auctionTab;

	if enable then
		auctionTab.bidPerItem:Enable();
		auctionTab.buyPerItem:Enable();
		auctionTab.maxStacks:Enable();
		auctionTab.stackSize:Enable();
		for k, button in pairs(auctionTab.buttons) do
			button:Enable();
		end
	else
		auctionTab.bidPerItem:Disable();
		auctionTab.buyPerItem:Disable();
		auctionTab.maxStacks:Disable();
		auctionTab.stackSize:Disable();
		for k, button in pairs(auctionTab.buttons) do
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