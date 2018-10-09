---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local Graph = LibStub('LibGraph-2.0');

function Sell:DrawInfoPane()
	if self.sellTab.infoPane then
		return ;
	end

	local sellTab = self.sellTab;

	local infoPane = StdUi:Window(sellTab, 'Auction Info', 200, 100);
	sellTab.infoPane = infoPane;
	infoPane:Hide();

	local totalLabel = StdUi:Label(infoPane, 'Total: ' .. StdUi.Util.formatMoney(0));
	local deposit = StdUi:Label(infoPane, 'Deposit: ' .. StdUi.Util.formatMoney(0));
	local auctionNo = StdUi:Label(infoPane, '# Auctions: 0');
	local duration = StdUi:Label(infoPane, 'Duration: 24h');
	local historicalBtn = StdUi:Button(infoPane, 180, 20, 'Historical Data')

	StdUi:GlueAfter(infoPane, sellTab, 0, 0, 0, sellTab:GetHeight() - 150);
	StdUi:GlueTop(totalLabel, infoPane, 5, -40, 'LEFT');
	StdUi:GlueBelow(deposit, totalLabel, 0, -5, 'LEFT');
	StdUi:GlueBelow(auctionNo, deposit, 0, -5, 'LEFT');
	StdUi:GlueBelow(duration, auctionNo, 0, -5, 'LEFT');
	StdUi:GlueBelow(historicalBtn, duration, 0, -10, 'LEFT');

	historicalBtn:SetScript('OnClick', function()
		local itemRecord = self:GetSelectedItemRecord();
		if not itemRecord then
			return ;
		end
		local historicalData = self:PrepareHistoricalData(itemRecord);
		if historicalData then
			self:ShowHistoricalWindow(historicalData);
		end
	end);

	infoPane.totalLabel = totalLabel;
	infoPane.auctionNo = auctionNo;
	infoPane.deposit = deposit;
	infoPane.duration = duration;
end

function Sell:UpdateInfoPaneText()
	if not self.selectedItem then
		return ;
	end

	local infoPane = self.sellTab.infoPane;
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

	infoPane.totalLabel:SetText('Per auction: ' .. StdUi.Util.formatMoney(total));
	infoPane.auctionNo:SetText('# Auctions: ' .. sellSettings.maxStacks);
	infoPane.deposit:SetText('Deposit: ' .. StdUi.Util.formatMoney(deposit));
	infoPane.duration:SetText('Duration: ' .. AuctionFaster:FormatAuctionDuration(sellSettings.duration));
end

function Sell:ToggleInfoPane()
	if self.sellTab.infoPane:IsShown() then
		self.sellTab.infoPane:Hide();
	else
		self.sellTab.infoPane:Show();
	end
end

function Sell:PrepareHistoricalData(itemRecord)
	if #itemRecord.prices == 0 then
		AuctionFaster:Echo(3, 'No historical data available for: ' .. itemRecord.itemName);
		return false;
	end

	local result = {
		stats = {
			startingStamp = 0,
		},
		lowestBuy     = { text = 'Lowest Buy', color = { 1.0, 0.0, 0.0, 0.8 }, series = {} },
		averageBuy    = { text = 'Average Buy', color = { 1.0, 1.0, 0.0, 0.8 }, series = {} },
		highestBuy    = { text = 'Highest Buy', color = { 1.0, 1.0, 1.0, 0.8 }, series = {} },
	};

	local yts = 0;
	for i = 1, #itemRecord.prices do
		local historicalData = itemRecord.prices[i];
		if i == 1 then
			yts = historicalData.scanTime;
			result.stats.startingStamp = yts;
		end

		local ts = ((historicalData.scanTime - yts) / 3600) + (24 * (i - 1));

		tinsert(result.lowestBuy.series, { ts, historicalData.lowestBuy / 10000 });
		tinsert(result.averageBuy.series, { ts, historicalData.averageBuy / 10000 });
		tinsert(result.highestBuy.series, { ts, historicalData.highestBuy / 10000 });

	end

	return result;
end


function Sell:RescaleLines(historicalData)
	local g = self.historicalWindow.g;
	local horizontalDivs = self.historicalWindow.horizontalDivs;
	local verticalDivs = self.historicalWindow.verticalDivs;

	print(g.YMax);
	print(g.YMin);

	local yStep = (g.YMax - g.YMin) / 7;

	for i = 1, #verticalDivs do
		local moneyValue = math.floor((g.YMax - ((i - 1) * yStep)) * 10000);

		verticalDivs[i]:SetText(StdUi.Util.formatMoney(moneyValue));
	end

	local xTotal = g:GetWidth() / (g.XMax - g.XMin);
	local xOffset = g.XMin * -1 * xTotal;
	local xStep = 48 * xTotal;

	local numLines = math.ceil(#historicalData.lowestBuy.series / 2);

	for i = 1, #horizontalDivs do
		horizontalDivs[i]:Hide();
		horizontalDivs[i].line:Hide();
	end

	for i = 1, numLines do
		local div = horizontalDivs[i];

		if not div then
			local line = g:CreateTexture(nil, 'overlay');
			line:SetColorTexture(1, 1, 1, .2);
			line:SetWidth(1);
			line:SetHeight(g:GetHeight());

			div = StdUi:Label(self.historicalWindow, '00-00');

			line:SetPoint('BOTTOM', div, 'TOP', 0, 5);

			div.line = line;
			horizontalDivs[i] = div;
		end

		div:ClearAllPoints();
		div:SetPoint('TOP', g, 'BOTTOMLEFT', xOffset + ((i - 1) * xStep), -5);

		local ts = historicalData.stats.startingStamp + (i - 1) * 48 * 60 * 60;
		div:SetText(date('%m-%d', ts));

		div:Show();
		div.line:Show();
	end

end

function Sell:ShowHistoricalWindow(historicalData)
	local historicalWindow, g;
	if not self.historicalWindow then
		historicalWindow = StdUi:Window(UIParent, 'Test Line', 600, 500);
		historicalWindow:SetPoint('CENTER');
		historicalWindow:Show();

		local graphWidth = 480;
		local graphHeight = 300;

		g = Graph:CreateGraphLine('TestLineGraph', historicalWindow, 'TOPLEFT', 'TOPLEFT', 100, -100,
			graphWidth, graphHeight);
		g:SetXAxis(-1, 1);
		g:SetYAxis(-1, 1);
		g:SetGridSpacing(false, false);
		g:SetGridColor({ 0.5, 0.5, 0.5, 0.3 });
		g:SetAxisDrawing(false, false);
		g:SetAxisColor({ 1.0, 1.0, 1.0, 1.0 });
		g:SetAutoScale(true);

		historicalWindow.verticalDivs = {};
		historicalWindow.horizontalDivs = {};

		for i = 1, 8 do
			local line = g:CreateTexture(nil, 'overlay');
			line:SetColorTexture(1, 1, 1, .2);
			line:SetWidth(graphWidth);
			line:SetHeight(1);

			local leftLabel = StdUi:Label(historicalWindow, '1g');
			historicalWindow.verticalDivs[i] = leftLabel
			leftLabel:SetPoint('RIGHT', g, 'TOPLEFT', 0, -((graphHeight / 7) * (i - 1)))

			line:SetPoint('TOPLEFT', leftLabel, 'RIGHT', 0, 0);
			line:SetPoint('TOPRIGHT', g, 'RIGHT', 0, 0);

			leftLabel.line = line;
		end

		self.historicalWindow = historicalWindow;
		self.historicalWindow.g = g;
	end

	historicalWindow = self.historicalWindow;
	g = self.historicalWindow.g;

	g:ResetData();

	for k, val in pairs(historicalData) do
		if k ~= 'stats' then
			g:AddDataSeries(val.series, val.color, nil, 'line');
		end
	end

	--UIParentLoadAddOn('Blizzard_DebugTools')
	--DisplayTableInspectorWindow(g)

	C_Timer.After(0.1, function()
		self:RescaleLines(historicalData);
	end)
end