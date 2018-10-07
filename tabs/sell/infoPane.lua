---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

function Sell:DrawInfoPane()
	local sellTab = self.sellTab;

	sellTab.infoPane = StdUi:Window(sellTab, 'Auction Info', 200, 100);
	sellTab.infoPane:Hide();
	StdUi:GlueAfter(sellTab.infoPane, sellTab, 0, 0, 0, sellTab:GetHeight() - 150);

	local totalLabel = StdUi:Label(sellTab.infoPane, 'Total: ' .. StdUi.Util.formatMoney(0));
	StdUi:GlueTop(totalLabel, sellTab.infoPane, 5, -40, 'LEFT');

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
end

function Sell:UpdateInfoPaneText()
	if not self.selectedItem then
		return ;
	end

	local sellTab = self.sellTab;
	local sellSettings = self:GetSellSettings();

	if not sellSettings.buyPerItem or not sellSettings.stackSize or not sellSettings.maxStacks then
		return ;
	end

	local total = sellSettings.buyPerItem * sellSettings.stackSize;
	local deposit = Auctions:CalculateDeposit(
		self.selectedItem.itemId,
		self.selectedItem.itemName,
		self.selectedItem.quality,
		self.selectedItem.level,
		sellSettings
	);

	sellTab.infoPane.totalLabel:SetText('Per auction: ' .. StdUi.Util.formatMoney(total));
	sellTab.infoPane.auctionNo:SetText('# Auctions: ' .. sellSettings.maxStacks);
	sellTab.infoPane.deposit:SetText('Deposit: ' .. StdUi.Util.formatMoney(deposit));
	sellTab.infoPane.duration:SetText('Duration: ' .. AuctionFaster:FormatAuctionDuration(sellSettings.duration));
end

function Sell:ToggleInfoPane()
	if self.sellTab.infoPane:IsShown() then
		self.sellTab.infoPane:Hide();
	else
		self.sellTab.infoPane:Show();
	end
end