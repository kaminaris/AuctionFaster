
--- @type StdUi
local StdUi = LibStub('StdUi');

AuctionFaster.defaults = {
	enabled = true,
	fastMode = true,
	enableToolTips = true,
	auctionDuration = 3,
};

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
	enabled.OnValueChanged = function(_, flag) AuctionFaster.db.enabled = flag; print(flag) end;

	local fastMode = StdUi:Checkbox(self.optionsFrame, 'Fast Mode');
	StdUi:GlueBelow(fastMode, enabled, 0, -10, 'LEFT');
	if self.db.fastMode then fastMode:SetChecked(true); end
	fastMode.OnValueChanged = function(_, flag) AuctionFaster.db.fastMode = flag; print(flag) end;

	local enableToolTips = StdUi:Checkbox(self.optionsFrame, 'Enable ToolTips');
	StdUi:GlueBelow(enableToolTips, fastMode, 0, -10, 'LEFT');
	if self.db.enableToolTips then enableToolTips:SetChecked(true); end
	enableToolTips.OnValueChanged = function(_, flag) AuctionFaster.db.enableToolTips = flag; print(flag) end;


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
		print('AuctionFaster: Item cache wiped!');
	end);

	InterfaceOptions_AddCategory(self.optionsFrame);
end