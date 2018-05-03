--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:GetSellSettings()
	local auctionTab = self.auctionTab;

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

	return {
		bidPerItem    = bidPerItem,
		buyPerItem    = buyPerItem,
		stackSize     = stackSize,
		maxStacks     = maxStacks,
		realMaxStacks = realMaxStacks,
		duration      = 2
	};
end



function AuctionFaster:UpdateTabPrices(bid, buy)
	local auctionTab = self.auctionTab;

	auctionTab.bidPerItem:SetValue(bid);
	auctionTab.buyPerItem:SetValue(buy);
end

function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];

	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.name);

	auctionTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStack .. ')');
	auctionTab.stackSize:SetValue(self.selectedItem.maxStack);

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
	self:PutInventoryItemInCache(self.selectedItem);
	self:LoadItemSettings();
end

function AuctionFaster:GetSelectedItemIdName()
	if not self.selectedItem then
		return nil, nil;
	end

	return self.selectedItem.itemId, self.selectedItem.name;
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

function AuctionFaster:UpdateInfoPaneText()
	if not self.selectedItem then
		return ;
	end

	local auctionTab = self.auctionTab;
	local sellSettings = self:GetSellSettings();
	--DevTools_Dump(sellSettings);
	if not sellSettings.buyPerItem or not sellSettings.stackSize or not sellSettings.maxStacks then
		return ;
	end

	local total = sellSettings.buyPerItem * sellSettings.stackSize * sellSettings.maxStacks;
	local deposit = self:CalculateDeposit(self.selectedItem.itemId, self.selectedItem.name);

	auctionTab.infoPane.totalLabel:SetText('Total: ' .. StdUi.Util.formatMoney(total));
	auctionTab.infoPane.auctionNo:SetText('# Auctions: ' .. sellSettings.maxStacks);
	auctionTab.infoPane.deposit:SetText('Deposit: ' .. StdUi.Util.formatMoney(deposit));

end

function AuctionFaster:UpdateItemsTabPrice(itemId, itemName, newPrice)
	for i = 1, #self.itemFramePool do
		local f = self.itemFramePool[i];
		if f.item.itemId == itemId and f.item.name == itemName then
			f.itemPrice:SetText(self:FormatMoney(newPrice));
		end
	end
end