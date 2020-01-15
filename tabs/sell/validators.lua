---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

function Sell:CalcMaxStacks()
	local sellTab = self.sellTab;
	if not self.selectedItem then
		return 0;
	end

	local stackSize = tonumber(sellTab.stackSize:GetValue());
	if stackSize == 0 then
		stackSize = 1;
	end

	local remainingQty = self.selectedItem.count - stackSize;

	if remainingQty < 0 then
		remainingQty = 0;
	end

	return remainingQty;
end

function Sell:ValidateStackSize(editBox)
	if not self.selectedItem then
		return ;
	end

	local stackSize = tonumber(editBox:GetText());
	local origStackSize = stackSize;

	if not stackSize or stackSize < 1 then
		stackSize = 1;
	end

	if stackSize ~= origStackSize then
		editBox:SetValue(stackSize);
	end

	self:UpdateItemQtyText();
	self:UpdateInfoPaneText();
end

function Sell:ValidateItemPrice(editBox)
	if not editBox:IsValid() then
		return;
	end

	self:UpdateInfoPaneText();
end