---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

local timerCount = 0;
local timerInterval = 5;

function Buy:DrawSniperFrame()
	if self.sniperPane then
		return;
	end

	local buyTab = self.buyTab;

	local sniperPane = StdUi:Window(buyTab, 200, 100, L['Sniper']);
	sniperPane:Hide();

	StdUi:GlueAfter(sniperPane, buyTab, 0, 0, 0, 0);

	local autoRefresh = StdUi:Checkbox(sniperPane, L['Auto Refresh']);

	local refreshInterval = StdUi:NumericBox(sniperPane, 180, 20);
	refreshInterval:SetValue(AuctionFaster.db.sniper.refreshInterval);
	refreshInterval:SetMinMaxValue(5, 2000);

	StdUi:AddLabel(sniperPane, refreshInterval, L['Refresh Interval'], 'TOP');

	local refreshProgressBar = StdUi:ProgressBar(sniperPane, 200, 10);
	refreshProgressBar.TextUpdate = function(self, min, max, value) -- custom text
		return value .. 's / ' .. max .. 's';
	end;

	local more = StdUi:Header(sniperPane, L['More features\ncoming soon']);

	StdUi:GlueTop(autoRefresh, sniperPane, 10, -40, 'LEFT');
	StdUi:GlueBelow(refreshInterval, autoRefresh, 0, -30, 'LEFT');
	StdUi:GlueTop(more, sniperPane, 0, -160, 'CENTER');
	StdUi:GlueBottom(refreshProgressBar, sniperPane, 0, 0, 'CENTER');

	autoRefresh.OnValueChanged = function() self:UpdateSniperTimer(); end;
	refreshInterval.OnValueChanged = function() self:UpdateSniperTimer(); end;


	self.sniperPane = sniperPane;
	self.sniperPane.autoRefresh = autoRefresh;
	self.sniperPane.refreshInterval = refreshInterval;
	self.sniperPane.refreshProgressBar = refreshProgressBar;
end

function Buy:ToggleSniperFrame()
	if self.sniperPane:IsVisible() then
		self.sniperPane:Hide();
	else
		self.sniperPane:Show();
		self.filtersPane:Hide();
	end
end

function Buy:UpdateSniperTimer()
	local isEnabled = self.sniperPane.autoRefresh:GetChecked();
	timerInterval = tonumber(self.sniperPane.refreshInterval:GetValue());

	if isEnabled then
		if not self.sniperTimer then
			self.sniperTimer = self:ScheduleRepeatingTimer('SniperTimerFeedback', 1);
		end
	else
		if self.sniperTimer then
			self:CancelTimer(self.sniperTimer);
			self.sniperTimer = nil;
		end
	end

	self.sniperPane.refreshProgressBar:SetMinMaxValues(0, timerInterval);
end

function Buy:SniperTimerFeedback()
	timerCount = timerCount + 1;
	self.sniperPane.refreshProgressBar:SetValue(timerCount);

	if timerCount >= timerInterval then
		timerCount = 0;
		self:RefreshSearchAuctions();
	end
end
