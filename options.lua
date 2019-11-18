---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

AuctionFaster.defaults = {
	enabled = true,
	fastMode = true,
	enableToolTips = true,
	auctionDuration = 3,
	sniper = {
		refreshInterval = 5
	},
	tutorials = {
		buy = true,
		sell = true,
		chain = true
	},
	sell = {
		tooltips = {
			enabled = true,
			anchor = 'TOPRIGHT',
			itemEnabled = true,
			itemAnchor = 'TOPRIGHT',
		}
	},
	buy = {
		tooltips = {
			enabled = true,
			anchor  = 'BOTTOMRIGHT'
		},
		recentSearches = {}
	},
	pricing = {
		maxBidDeviation = 20
	},
	historical = {
		enabled = true,
		keepDays = 20,
	}
};

function AuctionFaster:InitDatabase()
	if not AuctionFasterDb or type(AuctionFasterDb) ~= 'table' or AuctionFasterDb.global then
		AuctionFasterDb = self.defaults;
	end

	self.db = AuctionFasterDb;

	-- Upgrades
	if not self.db.tutorials then
		self.db.tutorials = {
			buy = true,
			sell = true,
			chain = true
		};
	end

	if not self.db.sell then
		self.db.sell = {
			sortInventoryBy = 'itemName',
			sortInventoryOrder = 'asc',
		}
	end

	if not self.db.sell.tooltips then
		self.db.sell.tooltips = {
			enabled = true,
			anchor = 'TOPRIGHT',
			itemEnabled = true,
			itemAnchor = 'TOPRIGHT',
		};

		self.db.buy = {
			tooltips = {
				enabled = true,
				anchor = 'BOTTOMRIGHT'
			}
		};
	end

	if not self.db.chainBuy then
		self.db.chainBuy = {};
	end

	if not self.db.sniper then
		self.db.sniper = { refreshInterval = 5 };
	end

	if not self.db.historical then
		self.db.historical = { enabled = true, keepDays = 20 };
		self.db.pricing = { maxBidDeviation = 20 };
	end

	if not self.db.defaultTab then
		self.db.defaultTab = 'NONE';
	end

	if not self.db.buy.recentSearches then
		self.db.buy.recentSearches = {};
	end
end

function AuctionFaster:IsFastMode()
	return self.db.fastMode;
end

function AuctionFaster:RegisterHistoricalOptionWindow()
	local optionsFrame = self.optionsFrame

	optionsFrame.historicalOptions = StdUi:PanelWithTitle(UIParent, 100, 100, L['AuctionFaster - Historical Options']);
	local historicalOptions = optionsFrame.historicalOptions;
	historicalOptions.name = L['Historical Options'];
	historicalOptions.parent = optionsFrame.name;
	historicalOptions:Hide();

	local enabled = StdUi:Checkbox(historicalOptions, L['Enable Historical Data Collection']);
	local keepDays = StdUi:NumericBox(historicalOptions, 160, 20);
	keepDays:SetMinMaxValue(5, 50);
	keepDays:SetValue(self.db.historical.keepDays);

	StdUi:AddLabel(historicalOptions, keepDays, L['Days to keep data (5-50)'], 'TOP');

	StdUi:GlueTop(enabled, historicalOptions, 10, -40, 'LEFT');
	StdUi:GlueBelow(keepDays, enabled, 0, -30, 'LEFT');

	if self.db.historical.enabled then enabled:SetChecked(true); end

	enabled.OnValueChanged = function(_, flag) self.db.historical.enabled = flag; end;
	keepDays.OnValueChanged = function(_, value) self.db.historical.keepDays = value; end;

	InterfaceOptions_AddCategory(historicalOptions);
end

function AuctionFaster:RegisterPricingOptionWindow()
	local optionsFrame = self.optionsFrame

	optionsFrame.pricingOptions = StdUi:PanelWithTitle(UIParent, 100, 100, L['AuctionFaster - Pricing Options']);
	local pricingOptions = optionsFrame.pricingOptions;
	pricingOptions.name = L['Pricing Options'];
	pricingOptions.parent = optionsFrame.name;
	pricingOptions:Hide();

	local maxBidDeviation = StdUi:NumericBox(pricingOptions, 160, 20);
	maxBidDeviation:SetMinMaxValue(1, 100);
	maxBidDeviation:SetValue(self.db.pricing.maxBidDeviation);

	StdUi:AddLabel(pricingOptions, maxBidDeviation, L['Maximum difference bid to buy (1-100%)'], 'TOP');

	StdUi:GlueTop(maxBidDeviation, pricingOptions, 10, -60, 'LEFT');

	maxBidDeviation.OnValueChanged = function(_, value) self.db.pricing.maxBidDeviation = value; end;

	InterfaceOptions_AddCategory(pricingOptions);
end

function AuctionFaster:RegisterOptionWindow()
	if self.optionsFrame then
		return;
	end

	self.optionsFrame = StdUi:PanelWithTitle(UIParent, 100, 100, L['AuctionFaster Options']);
	self.optionsFrame.name = L['AuctionFaster'];
	self.optionsFrame:Hide();

	local enabled = StdUi:Checkbox(self.optionsFrame, L['Enable AuctionFaster']);
	local fastMode = StdUi:Checkbox(self.optionsFrame, L['Fast Mode']);
	local enableToolTips = StdUi:Checkbox(self.optionsFrame, L['Enable ToolTips']);

	if self.db.enabled then enabled:SetChecked(true); end
	if self.db.fastMode then fastMode:SetChecked(true); end
	if self.db.enableToolTips then enableToolTips:SetChecked(true); end

	enabled.OnValueChanged = function(_, flag) AuctionFaster.db.enabled = flag; end;
	fastMode.OnValueChanged = function(_, flag) AuctionFaster.db.fastMode = flag; end;
	enableToolTips.OnValueChanged = function(_, flag) AuctionFaster.db.enableToolTips = flag; end;

	StdUi:GlueTop(enabled, self.optionsFrame, 10, -40, 'LEFT');
	StdUi:GlueBelow(fastMode, enabled, 0, -10, 'LEFT');
	StdUi:GlueBelow(enableToolTips, fastMode, 0, -10, 'LEFT');

	local durations = {
		{text = L['12 Hours'], value = 1},
		{text = L['24 Hours'], value = 2},
		{text = L['48 Hours'], value = 3},
	};

	local defaultTabs = {
		{text = L['Do not set'], value = 'NONE'},
		{text = L['Sell Tab'], value = 'SELL'},
		{text = L['Buy Tab'], value = 'BUY'},
	}

	local auctionDuration = StdUi:Dropdown(self.optionsFrame, 140, 20, durations, self.db.auctionDuration);
	local defaultTab = StdUi:Dropdown(self.optionsFrame, 140, 20, defaultTabs, self.db.defaultTab);
	local wipeSettings = StdUi:Button(self.optionsFrame, 140, 20, L['Wipe Item Cache']);
	local resetTutorials = StdUi:Button(self.optionsFrame, 140, 20, L['Reset Tutorials']);

	StdUi:AddLabel(self.optionsFrame, auctionDuration, L['Auction Duration']);
	StdUi:AddLabel(self.optionsFrame, defaultTab, L['Set Default Tab']);

	auctionDuration.OnValueChanged = function(_, value) AuctionFaster.db.auctionDuration = value; end;
	defaultTab.OnValueChanged = function(_, value) AuctionFaster.db.defaultTab = value; end;

	wipeSettings:SetScript('OnClick', function()
		AuctionFaster:GetModule('ItemCache'):WipeItemCache();
		self:Echo(1, L['Item cache wiped!']);
	end);

	resetTutorials:SetScript('OnClick', function()
		self.db.tutorials = {
			buy = true,
			sell = true,
			chain = true
		};

		self:Echo(1, L['Tutorials reset!']);
	end);

	StdUi:GlueTop(auctionDuration, self.optionsFrame, 300, -60, 'LEFT');
	StdUi:GlueRight(defaultTab, auctionDuration, 10, 0);
	StdUi:GlueBelow(wipeSettings, auctionDuration, 0, -10, 'LEFT');
	StdUi:GlueRight(resetTutorials, wipeSettings, 10, 0);

	local anchors = {
		{text = L['Top'], value = 'TOP'},
		{text = L['Top Right'], value = 'TOPRIGHT'},
		{text = L['Right'], value = 'RIGHT'},
		{text = L['Bottom Right'], value = 'BOTTOMRIGHT'},
		{text = L['Bottom'], value = 'BOTTOM'},
		{text = L['Bottom Left'], value = 'BOTTOMLEFT'},
		{text = L['Left'], value = 'LEFT'},
		{text = L['Top Left'], value = 'TOPLEFT'},
	};

	-- Sell tab settings
	local sellTabLabel = StdUi:Header(self.optionsFrame, L['Sell Tab Settings']);
	local sellTooltips = StdUi:Checkbox(self.optionsFrame, L['Enable ToolTips']);
	local sellTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.sell.tooltips.anchor);
	local sellItemTooltips = StdUi:Checkbox(self.optionsFrame, L['Enable ToolTips for Items']);
	local sellItemTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.sell.tooltips.itemAnchor);

	StdUi:AddLabel(self.optionsFrame, sellTooltipAnchor, L['Tooltip Anchor'], 'TOP');
	StdUi:AddLabel(self.optionsFrame, sellItemTooltipAnchor, L['Item Tooltip Anchor'], 'TOP');

	StdUi:GlueTop(sellTabLabel, self.optionsFrame, 10, -160, 'LEFT');
	StdUi:GlueBelow(sellTooltips, sellTabLabel, 0, -10, 'LEFT');
	StdUi:GlueBelow(sellTooltipAnchor, sellTooltips, 0, -30, 'LEFT');
	StdUi:GlueBelow(sellItemTooltips, sellTooltipAnchor, 0, -10, 'LEFT');
	StdUi:GlueBelow(sellItemTooltipAnchor, sellItemTooltips, 0, -30, 'LEFT');

	-- Buy tab settings
	local buyTabLabel = StdUi:Header(self.optionsFrame, L['Buy Tab Settings']);
	local buyTooltips = StdUi:Checkbox(self.optionsFrame, L['Enable ToolTips']);
	local buyTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.buy.tooltips.anchor);

	StdUi:AddLabel(self.optionsFrame, buyTooltipAnchor, L['Tooltip Anchor'], 'TOP');

	StdUi:GlueTop(buyTabLabel, self.optionsFrame, 300, -160, 'LEFT');
	StdUi:GlueBelow(buyTooltips, buyTabLabel, 0, -10, 'LEFT');
	StdUi:GlueBelow(buyTooltipAnchor, buyTooltips, 0, -30, 'LEFT');

	-- Hooks for checkboxes and dropdowns
	if self.db.buy.tooltips.enabled then buyTooltips:SetChecked(true); end
	if self.db.sell.tooltips.enabled then sellTooltips:SetChecked(true); end
	if self.db.sell.tooltips.itemEnabled then sellItemTooltips:SetChecked(true); end

	buyTooltipAnchor.OnValueChanged = function(_, value) self.db.buy.tooltips.anchor = value; end;
	sellTooltipAnchor.OnValueChanged = function(_, value) self.db.sell.tooltips.anchor = value; end;
	sellItemTooltipAnchor.OnValueChanged = function(_, value) self.db.sell.tooltips.itemAnchor = value; end;

	buyTooltips.OnValueChanged = function(_, flag) self.db.buy.tooltips.enabled = flag; end;
	sellTooltips.OnValueChanged = function(_, flag) self.db.sell.tooltips.enabled = flag; end;
	sellItemTooltips.OnValueChanged = function(_, flag) self.db.sell.tooltips.itemEnabled = flag; end;

	InterfaceOptions_AddCategory(self.optionsFrame);
	self:RegisterHistoricalOptionWindow();
	self:RegisterPricingOptionWindow();
end

function AuctionFaster:OpenSettingsWindow()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame); -- fix for blizzard issues
end
