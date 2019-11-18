---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local Graph = LibStub('LibGraph-2.0');

local format = string.format;

function Sell:DrawInfoPane()
	if self.sellTab.infoPane then
		return ;
	end

	local sellTab = self.sellTab;

	local infoPane = StdUi:Window(sellTab, 200, 100, L['Auction Info']);
	sellTab.infoPane = infoPane;

	if AuctionFaster.db.infoPaneOpened then
		infoPane:Show();
	else
		infoPane:Hide();
	end

	infoPane:SetScript('OnShow', function() AuctionFaster.db.infoPaneOpened = true; end);
	infoPane:SetScript('OnHide', function() AuctionFaster.db.infoPaneOpened = false; end);

	local totalLabel = StdUi:Label(infoPane, format(L['Total: %s'], StdUi.Util.formatMoney(0)));
	local deposit = StdUi:Label(infoPane, format(L['Deposit: %s'], StdUi.Util.formatMoney(0)));
	local auctionNo = StdUi:Label(infoPane, format(L['# Auctions: %d'], 0));
	local duration = StdUi:Label(infoPane, format(L['Duration: %s'], '24h'));
	local historicalBtn = StdUi:Button(infoPane, 180, 20, L['Historical Data'])

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

	infoPane.totalLabel:SetText(format(L['Per auction: %s'], StdUi.Util.formatMoney(total)));
	infoPane.auctionNo:SetText(format(L['# Auctions: %d'], sellSettings.maxStacks));
	infoPane.deposit:SetText(format(L['Deposit: %s'], StdUi.Util.formatMoney(deposit)));
	infoPane.duration:SetText(format(L['Duration: %s'], AuctionFaster:FormatAuctionDuration(sellSettings.duration)));
end

function Sell:ToggleInfoPane()
	if self.sellTab.infoPane:IsShown() then
		self.sellTab.infoPane:Hide();
	else
		self.sellTab.infoPane:Show();
	end
end

function Sell:PrepareHistoricalData(itemRecord)
	if #itemRecord.prices < 2 then
		AuctionFaster:Echo(3, format(L['No historical data available for: %s'], itemRecord.itemName));
		return false;
	end

	local result = {
		stats = {
			itemRecord = itemRecord,
			startingStamp = 0,
			maxLowestBuy = itemRecord.prices[1].lowestBuy,
			minLowestBuy = itemRecord.prices[1].lowestBuy,
		},
	};

	local lowestBuy, trendLowest, averageBuy, trendAverage, highestBuy = {}, {}, {}, {}, {};
	local X, YLow, YAvg = {}, {}, {};
	local yts = 0;
	for i = 1, #itemRecord.prices do
		local historicalData = itemRecord.prices[i];
		if i == 1 then
			yts = historicalData.scanTime - 1;
			result.stats.startingStamp = yts;
		end

		local ts = ((historicalData.scanTime - yts) / 3600); -- + (24 * (i - 1))

		tinsert(lowestBuy, { ts, historicalData.lowestBuy / 10000 });
		tinsert(averageBuy, { ts, historicalData.averageBuy / 10000 });
		tinsert(highestBuy, { ts, historicalData.highestBuy / 10000 });

		tinsert(X, ts);
		tinsert(YAvg, historicalData.averageBuy / 10000);
		tinsert(YLow, historicalData.lowestBuy / 10000);

		result.stats.maxLowestBuy = math.max(result.stats.maxLowestBuy, historicalData.lowestBuy);
		result.stats.minLowestBuy = math.min(result.stats.minLowestBuy, historicalData.lowestBuy);
	end

	trendLowest = AuctionFaster:TrendLine(X, YLow);
	trendAverage = AuctionFaster:TrendLine(X, YAvg);

	result.data = {
		{ text = L['Lowest Buy'],        color = { 0.0, 1.0, 0.0, 0.8 }, series = lowestBuy },
		{ text = L['Trend Lowest Buy'],  color = { 0.0, 1.0, 0.0, 0.5 }, series = trendLowest },

		{ text = L['Average Buy'],       color = { 1.0, 1.0, 0.0, 0.8 }, series = averageBuy },
		{ text = L['Trend Average Buy'], color = { 1.0, 1.0, 0.0, 0.5 }, series = trendAverage },

		{ text = L['Highest Buy'],       color = { 1.0, 0.0, 0.0, 0.8 }, series = highestBuy },
	}

	return result;
end


function Sell:RescaleLines(historicalData)
	local g = self.historicalWindow.g;
	local horizontalDivs = self.historicalWindow.horizontalDivs;
	local verticalDivs = self.historicalWindow.verticalDivs;

	local yStep = (g.YMax - g.YMin) / 7;

	for i = 1, #verticalDivs do
		local moneyValue = math.floor((g.YMax - ((i - 1) * yStep)) * 10000);

		verticalDivs[i]:SetText(StdUi.Util.formatMoney(moneyValue));
	end

	local xTotal = g:GetWidth() / (g.XMax - g.XMin);
	local xOffset = g.XMin * -1 * xTotal;
	local xStep = 48 * xTotal;

	local s = historicalData.data[1].series;
	local diff = s[#s][1] - s[1][1];
	local numLines = math.ceil(diff / 48);

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

function Sell:UpdateHistoricalWindowLegend(historicalData)
	local historicalWindow = self.historicalWindow;
	local legend = historicalWindow.legend;
	if not legend.items then
		legend.items = {};
	end

	local function createLegendLabel(parent, data, key)
		if key == 'stats' then
			return nil;
		end

		local panel = StdUi:Panel(parent, 200, 20);
		panel.texture = StdUi:Texture(panel, 16, 16);
		panel.text = StdUi:Label(panel, '');

		StdUi:GlueLeft(panel.texture, panel, 5, 0, true);
		StdUi:GlueRight(panel.text, panel.texture, 5, 0);

		return panel;
	end

	local function updateLegendLabel(parent, panel, data, key)
		if key == 'stats' then
			return nil;
		end

		panel.texture:SetColorTexture(unpack(data.color));
		panel.text:SetText(data.text);
	end

	StdUi:ObjectList(legend, legend.items, createLegendLabel, updateLegendLabel, historicalData.data);
end

function Sell:ShowHistoricalWindow(historicalData)
	local historicalWindow, g;
	if not self.historicalWindow then
		historicalWindow = StdUi:Window(UIParent, 600, 500, L['Test Line']);
		historicalWindow:SetPoint('CENTER');
		historicalWindow:Show();

		historicalWindow.legend = StdUi:Panel(historicalWindow, 200, 100);

		StdUi:GlueTop(historicalWindow.legend, historicalWindow, 10, -30, 'LEFT');

		local graphWidth = 480;
		local graphHeight = 300;

		g = Graph:CreateGraphLine(nil, historicalWindow, 'TOPLEFT', 'TOPLEFT', 100, -160,
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

	historicalWindow.titlePanel.label:SetText(L['Historical Data: '] .. historicalData.stats.itemRecord.itemName);

	g:ResetData();

	for k, val in ipairs(historicalData.data) do
		g:AddDataSeries(val.series, val.color, nil, 'line');
	end

	--UIParentLoadAddOn('Blizzard_DebugTools')
	--DisplayTableInspectorWindow(g)

	C_Timer.After(0.1, function()
		self:RescaleLines(historicalData);
		self:UpdateHistoricalWindowLegend(historicalData);
	end);

	historicalWindow:Show();
end
