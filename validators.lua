function AuctionFaster:CalcMaxStacks()
	local sellTab = self.sellTab;
	if not self.selectedItem then
		return 0, 0;
	end

	local stackSize = tonumber(sellTab.stackSize:GetValue());
	local maxStacks = floor(self.selectedItem.count / stackSize);

	if maxStacks == 0 then
		maxStacks = 1;
	end

	local remainingQty = self.selectedItem.count - (maxStacks * stackSize);

	if remainingQty < 0 then
		remainingQty = 0;
	end

	return maxStacks, remainingQty;
end

function AuctionFaster:ValidateMaxStacks(editBox)
	if not self.selectedItem then
		return ;
	end

	local maxStacks = tonumber(editBox:GetText());
	local origMaxStacks = maxStacks;

	local maxStacksPossible = AuctionFaster:CalcMaxStacks();

	-- 0 means no limit
	if not maxStacks or maxStacks < 0 then
		maxStacks = 0;
	end

	if maxStacks > maxStacksPossible then
		maxStacks = maxStacksPossible;
	end

	if maxStacks ~= origMaxStacks then
		editBox:SetValue(maxStacks);
	end

	self:UpdateItemQtyText();
	self:UpdateInfoPaneText();
end

function AuctionFaster:ValidateStackSize(editBox)
	if not self.selectedItem then
		return ;
	end

	local stackSize = tonumber(editBox:GetText());
	local origStackSize = stackSize;

	if not stackSize or stackSize < 1 then
		stackSize = 1;
	end

	if stackSize > self.selectedItem.maxStackSize then
		stackSize = self.selectedItem.maxStackSize;
	end

	if stackSize ~= origStackSize then
		editBox:SetValue(stackSize);
	end

	self:UpdateItemQtyText();
	self:UpdateInfoPaneText();
end

function AuctionFaster:ValidateItemPrice(editBox)
	if not editBox:IsValid() then
		return;
	end

	self:UpdateInfoPaneText();
end