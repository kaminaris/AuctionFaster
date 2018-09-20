---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');

AuctionFaster.defaults = {
	enabled = true,
	fastMode = true,
	enableToolTips = true,
	auctionDuration = 3,
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
		}
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
end

function AuctionFaster:IsFastMode()
	return self.db.fastMode;
end

function AuctionFaster:RegisterOptionWindow()
	if self.optionsFrame then
		return;
	end

	self.optionsFrame = StdUi:PanelWithTitle(UIParent, 100, 100, 'Auction Faster Options');
	self.optionsFrame.name = 'Auction Faster';

	local enabled = StdUi:Checkbox(self.optionsFrame, 'Enable Auction Faster');
	local fastMode = StdUi:Checkbox(self.optionsFrame, 'Fast Mode');
	local enableToolTips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips');

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
		{text = '12 Hours', value = 1},
		{text = '24 Hours', value = 2},
		{text = '48 Hours', value = 3},
	};

	local auctionDuration = StdUi:Dropdown(self.optionsFrame, 160, 20, durations, self.db.auctionDuration);
	local wipeSettings = StdUi:Button(self.optionsFrame, 140, 20, 'Wipe Item Cache');
	local resetTutorials = StdUi:Button(self.optionsFrame, 140, 20, 'Reset Tutorials');

	StdUi:AddLabel(self.optionsFrame, auctionDuration, 'Auction Duration', 'TOP');

	auctionDuration.OnValueChanged = function(_, value) AuctionFaster.db.auctionDuration = value; end;

	wipeSettings:SetScript('OnClick', function()
		AuctionFaster:GetModule('ItemCache'):WipeItemCache();
		self:Echo(1, 'Item cache wiped!');
	end);

	resetTutorials:SetScript('OnClick', function()
		self.db.tutorials = {
			buy = true,
			sell = true,
			chain = true
		};

		self:Echo(1, 'Tutorials reset!');
	end);

	StdUi:GlueTop(auctionDuration, self.optionsFrame, 300, -60, 'LEFT');
	StdUi:GlueBelow(wipeSettings, auctionDuration, 0, -10, 'LEFT');
	StdUi:GlueRight(resetTutorials, wipeSettings, 10, 0);

	local anchors = {
		{text = 'Top', value = 'TOP'},
		{text = 'Top Right', value = 'TOPRIGHT'},
		{text = 'Right', value = 'RIGHT'},
		{text = 'Bottom Right', value = 'BOTTOMRIGHT'},
		{text = 'Bottom', value = 'BOTTOM'},
		{text = 'Bottom Left', value = 'BOTTOMLEFT'},
		{text = 'Left', value = 'LEFT'},
		{text = 'Top Left', value = 'TOPLEFT'},
	};

	-- Sell tab settings
	local sellTabLabel = StdUi:Header(self.optionsFrame, 'Sell Tab Settings');
	local sellTooltips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips');
	local sellTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.sell.tooltips.anchor);
	local sellItemTooltips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips for Items');
	local sellItemTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.sell.tooltips.itemAnchor);

	StdUi:AddLabel(self.optionsFrame, sellTooltipAnchor, 'Tooltip Anchor', 'TOP');
	StdUi:AddLabel(self.optionsFrame, sellItemTooltipAnchor, 'Item Tooltip Anchor', 'TOP');

	StdUi:GlueTop(sellTabLabel, self.optionsFrame, 10, -160, 'LEFT');
	StdUi:GlueBelow(sellTooltips, sellTabLabel, 0, -10, 'LEFT');
	StdUi:GlueBelow(sellTooltipAnchor, sellTooltips, 0, -30, 'LEFT');
	StdUi:GlueBelow(sellItemTooltips, sellTooltipAnchor, 0, -10, 'LEFT');
	StdUi:GlueBelow(sellItemTooltipAnchor, sellItemTooltips, 0, -30, 'LEFT');

	-- Buy tab settings
	local buyTabLabel = StdUi:Header(self.optionsFrame, 'Buy Tab Settings');
	local buyTooltips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips');
	local buyTooltipAnchor = StdUi:Dropdown(self.optionsFrame, 160, 20, anchors, self.db.buy.tooltips.anchor);

	StdUi:AddLabel(self.optionsFrame, buyTooltipAnchor, 'Tooltip Anchor', 'TOP');

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
end

function AuctionFaster:OpenSettingsWindow()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame); -- fix for blizzard issues
end