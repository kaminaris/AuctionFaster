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
	StdUi:GlueTop(enabled, self.optionsFrame, 10, -40, 'LEFT');
	if self.db.enabled then enabled:SetChecked(true); end
	enabled.OnValueChanged = function(_, flag) AuctionFaster.db.enabled = flag; end;

	local fastMode = StdUi:Checkbox(self.optionsFrame, 'Fast Mode');
	StdUi:GlueBelow(fastMode, enabled, 0, -10, 'LEFT');
	if self.db.fastMode then fastMode:SetChecked(true); end
	fastMode.OnValueChanged = function(_, flag) AuctionFaster.db.fastMode = flag; end;

	local enableToolTips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips');
	StdUi:GlueBelow(enableToolTips, fastMode, 0, -10, 'LEFT');
	if self.db.enableToolTips then enableToolTips:SetChecked(true); end
	enableToolTips.OnValueChanged = function(_, flag) AuctionFaster.db.enableToolTips = flag; end;


	local durations = {
		{text = '12 Hours', value = 1},
		{text = '24 Hours', value = 2},
		{text = '48 Hours', value = 3},
	};
	local auctionDuration = StdUi:Dropdown(self.optionsFrame, 160, 24, durations, self.db.auctionDuration);
	StdUi:AddLabel(self.optionsFrame, auctionDuration, 'Auction Duration', 'TOP');
	StdUi:GlueTop(auctionDuration, self.optionsFrame, 300, -60, 'LEFT');
	auctionDuration.OnValueChanged = function(_, value) AuctionFaster.db.auctionDuration = value; end;

	local wipeSettings = StdUi:Button(self.optionsFrame, 200, 24, 'Wipe Item Cache');
	StdUi:GlueBelow(wipeSettings, auctionDuration, 0, -20, 'LEFT');
	wipeSettings:SetScript('OnClick', function()
		AuctionFaster:GetModule('ItemCache'):WipeItemCache();
		self:Echo(1, 'Item cache wiped!');
	end);

	local resetTutorials = StdUi:Button(self.optionsFrame, 200, 24, 'Reset Tutorials');
	StdUi:GlueBelow(resetTutorials, wipeSettings, 0, -20, 'LEFT');
	resetTutorials:SetScript('OnClick', function()
		self.db.tutorials = {
			buy = true,
			sell = true,
			chain = true
		};

		self:Echo(1, 'Tutorials reset!');
	end);

	InterfaceOptions_AddCategory(self.optionsFrame);
end

function AuctionFaster:OpenSettingsWindow()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame); -- fix for blizzard issues
end