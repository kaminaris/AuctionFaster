---@class AuctionFaster
AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');

--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:OnInitialize()
	LibStub('AceConfig-3.0'):RegisterOptionsTable('AuctionFaster', self.options, { '/afconf' });

	self.db = LibStub('AceDB-3.0'):New('AuctionFasterDb', self.defaults);

	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('AuctionFaster', 'AuctionFaster');

	self:RegisterEvent('AUCTION_HOUSE_SHOW');

	if not self.db.global.auctionDb then
		self.db.global.auctionDb = {};
	end

	if self.db.global.tooltipsEnabled then
		self:EnableModule('Tooltip');
	end

	-- These modules must be enabled on start, they handle events themselves
	self:EnableModule('Inventory');
	self:EnableModule('Auctions');
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	if self.db.global.enabled then
		self:EnableModule('Sell');
		self:EnableModule('Buy');

		if not self.onTabClickHooked then
			self:Hook('AuctionFrameTab_OnClick', true);
			self.onTabClickHooked = true;
		end
	end
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	for i = 1, #self.auctionTabs do
		self.auctionTabs[i]:Hide();
	end

	if tab.auctionFasterTab then
		tab.auctionFasterTab:Show();
	end
end

function AuctionFaster:GetDefaultItemSettings()
	return {
		rememberStack = true,
		rememberLastPrice = false,
		alwaysUndercut = true,
		useCustomDuration = false,
		duration = self.db.global.auctionDuration,
	}
end

AuctionFaster.auctionTabs = {};
function AuctionFaster:AddAuctionHouseTab(buttonText, title)
	local auctionTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, title, 160);
	auctionTab.titlePanel:SetBackdrop(nil);
	auctionTab:Hide();
	auctionTab:SetAllPoints();

	local n = AuctionFrame.numTabs + 1;

	local tabButton = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate');
	StdUi:StripTextures(tabButton);
	tabButton.backdrop = StdUi:Panel(tabButton);
	tabButton.backdrop:SetFrameLevel(tabButton:GetFrameLevel() - 1);
	StdUi:GlueAcross(tabButton.backdrop, tabButton, 10, -3, -10, 3);

	tabButton:Hide();
	tabButton:SetID(n);
	tabButton:SetText(buttonText);
	tabButton:SetNormalFontObject(GameFontHighlightSmall);
	tabButton:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0);
	tabButton:Show();
	-- reference the actual tab
	tabButton.auctionFasterTab = auctionTab;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);
	tinsert(self.auctionTabs, auctionTab);
	return auctionTab;
end
