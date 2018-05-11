--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:DrawInfoPane()
	local auctionTab = self.auctionTab;

	auctionTab.infoPane = StdUi:PanelWithTitle(auctionTab, 200, 100, 'Auction Info');
	auctionTab.infoPane:Hide();
	StdUi:GlueAfter(auctionTab.infoPane, auctionTab, 0, 0, 0, auctionTab:GetHeight() - 200);

	local totalLabel = StdUi:Label(auctionTab.infoPane, 'Total: ' .. StdUi.Util.formatMoney(0));
	StdUi:GlueTop(totalLabel, auctionTab.infoPane, 5, -15, 'LEFT');

	local deposit = StdUi:Label(auctionTab.infoPane, 'Deposit: ' .. StdUi.Util.formatMoney(0));
	StdUi:GlueBelow(deposit, totalLabel, 0, -5, 'LEFT');

	local auctionNo = StdUi:Label(auctionTab.infoPane, '# Auctions: 0');
	StdUi:GlueBelow(auctionNo, deposit, 0, -5, 'LEFT');

	local duration = StdUi:Label(auctionTab.infoPane, 'Duration: 24h');
	StdUi:GlueBelow(duration, auctionNo, 0, -5, 'LEFT');

	auctionTab.infoPane.totalLabel = totalLabel;
	auctionTab.infoPane.auctionNo = auctionNo;
	auctionTab.infoPane.deposit = deposit;
	auctionTab.infoPane.duration = duration;
end

function AuctionFaster:UpdateInfoPaneText()
	if not self.selectedItem then
		return ;
	end

	local auctionTab = self.auctionTab;
	local sellSettings = self:GetSellSettings();

	if not sellSettings.buyPerItem or not sellSettings.stackSize or not sellSettings.maxStacks then
		return ;
	end

	local total = sellSettings.buyPerItem * sellSettings.stackSize;
	local deposit = self:CalculateDeposit(self.selectedItem.itemId, self.selectedItem.itemName);

	auctionTab.infoPane.totalLabel:SetText('Per auction: ' .. StdUi.Util.formatMoney(total));
	auctionTab.infoPane.auctionNo:SetText('# Auctions: ' .. sellSettings.maxStacks);
	auctionTab.infoPane.deposit:SetText('Deposit: ' .. StdUi.Util.formatMoney(deposit));
	auctionTab.infoPane.duration:SetText('Duration: ' .. self:FormatAuctionDuration(sellSettings.duration));
end

function AuctionFaster:ToggleInfoPane()
	if self.auctionTab.infoPane:IsShown() then
		self.auctionTab.infoPane:Hide();
	else
		self.auctionTab.infoPane:Show();
	end
end