--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:DrawInfoPane()
	local sellTab = self.sellTab;

	sellTab.infoPane = StdUi:PanelWithTitle(sellTab, 200, 100, 'Auction Info');
	sellTab.infoPane:Hide();
	StdUi:GlueAfter(sellTab.infoPane, sellTab, 0, 0, 0, sellTab:GetHeight() - 200);

	local totalLabel = StdUi:Label(sellTab.infoPane, 'Total: ' .. StdUi.Util.formatMoney(0));
	StdUi:GlueTop(totalLabel, sellTab.infoPane, 5, -15, 'LEFT');

	local deposit = StdUi:Label(sellTab.infoPane, 'Deposit: ' .. StdUi.Util.formatMoney(0));
	StdUi:GlueBelow(deposit, totalLabel, 0, -5, 'LEFT');

	local auctionNo = StdUi:Label(sellTab.infoPane, '# Auctions: 0');
	StdUi:GlueBelow(auctionNo, deposit, 0, -5, 'LEFT');

	local duration = StdUi:Label(sellTab.infoPane, 'Duration: 24h');
	StdUi:GlueBelow(duration, auctionNo, 0, -5, 'LEFT');

	sellTab.infoPane.totalLabel = totalLabel;
	sellTab.infoPane.auctionNo = auctionNo;
	sellTab.infoPane.deposit = deposit;
	sellTab.infoPane.duration = duration;


	-- Figure out what to do with
	--local columns = {
	--	{header = 'Name', dataIndex = 'name', width = 80, align = 'RIGHT'},
	--	{header = 'Price', dataIndex = 'price', width = 80},
	--};
	--local data = {
	--	{name = 'Item one', price = StdUi.Util.formatMoney(random(10000, 999999))},
	--	{name = 'Item two', price = StdUi.Util.formatMoney(random(10000, 999999))},
	--	{name = 'Item three', price = StdUi.Util.formatMoney(random(10000, 999999))},
	--}
	--
	--local tab = StdUi:Table(sellTab.infoPane, 160, 80, 20, columns, data);
	--StdUi:GlueTop(tab, sellTab.infoPane, 10, -20, 'RIGHT');
end

function AuctionFaster:UpdateInfoPaneText()
	if not self.selectedItem then
		return ;
	end

	local sellTab = self.sellTab;
	local sellSettings = self:GetSellSettings();

	if not sellSettings.buyPerItem or not sellSettings.stackSize or not sellSettings.maxStacks then
		return ;
	end

	local total = sellSettings.buyPerItem * sellSettings.stackSize;
	local deposit = self:CalculateDeposit(self.selectedItem.itemId, self.selectedItem.itemName);

	sellTab.infoPane.totalLabel:SetText('Per auction: ' .. StdUi.Util.formatMoney(total));
	sellTab.infoPane.auctionNo:SetText('# Auctions: ' .. sellSettings.maxStacks);
	sellTab.infoPane.deposit:SetText('Deposit: ' .. StdUi.Util.formatMoney(deposit));
	sellTab.infoPane.duration:SetText('Duration: ' .. self:FormatAuctionDuration(sellSettings.duration));
end

function AuctionFaster:ToggleInfoPane()
	if self.sellTab.infoPane:IsShown() then
		self.sellTab.infoPane:Hide();
	else
		self.sellTab.infoPane:Show();
	end
end