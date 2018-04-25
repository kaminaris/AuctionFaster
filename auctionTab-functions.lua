
function AuctionFaster:GetSellSettings()
	local auctionTab = self.auctionTab;

	local bidPerItemText = auctionTab.bidPerItem:GetText();
	local buyPerItemText = auctionTab.buyPerItem:GetText()

	local maxStacks = tonumber(auctionTab.maxStacks:GetText());
	if maxStacks == 0 then
		maxStacks = AuctionFaster:CalcMaxStacks();
	end

	local stackSize = tonumber(auctionTab.stackSize:GetText());
	if stackSize > self.selectedItem.count then
		stackSize = self.selectedItem.count;
	end

	return {
		bidPerItem = self:ParseMoney(bidPerItemText),
		buyPerItem = self:ParseMoney(buyPerItemText),
		stackSize = stackSize,
		maxStacks = maxStacks,
		duration = 2
	};
end

function AuctionFaster:UpdateTabPrices(bid, buy)
	local auctionTab = self.auctionTab;

	local bidText = self:FormatMoneyNoColor(bid);
	local buyText = self:FormatMoneyNoColor(buy);

	auctionTab.bidPerItem:SetText(bidText);
	auctionTab.buyPerItem:SetText(buyText);
end


function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];

	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.name);


	auctionTab.stackSize.label:SetText('Stack Size (Max: ' .. self.selectedItem.maxStack .. ')');
	auctionTab.stackSize:SetText(self.selectedItem.maxStack);

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
end

function AuctionFaster:UpdateItemQtyText()
	if not self.selectedItem then
		return
	end

	local auctionTab = self.auctionTab;
	local maxStacks, remainingQty = self:CalcMaxStacks();
	auctionTab.itemQty:SetText(
		'Qty: ' .. self.selectedItem.count ..
				', Max Stacks: ' .. maxStacks ..
				', Remaining: ' .. remainingQty
	);
end