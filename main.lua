local addonName, addonTable = ...;

---@class AuctionFaster
local AuctionFaster = LibStub('AceAddon-3.0'):NewAddon(
	'AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0'
);
AuctionFaster.Version = GetAddOnMetadata(addonName, 'Version');
addonTable[1] = AuctionFaster;

_G[addonName] = AuctionFaster;

--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:OnInitialize()
	self:InitDatabase();
	self:RegisterOptionWindow();

	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');

	if not self.db.auctionDb then
		self.db.auctionDb = {};
	end

	if not self.db.enableToolTips then
		local tooltips = self:GetModule('Tooltips');
		tooltips:Attach();
	end

	-- These modules must be enabled on start, they handle events themselves
	--self:EnableModule('ItemCache');
	--self:EnableModule('Inventory');
	--self:EnableModule('Auctions');
	--self:EnableModule('ChainBuy');
	--self:EnableModule('Tutorial');
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	if self.db.enabled then
		if not self.onTabClickHooked then
			self:Hook('AuctionFrameTab_OnClick', true);
			self.onTabClickHooked = true;
		end
	end
end

function AuctionFaster:AUCTION_HOUSE_CLOSED()
	self:DisableModule('Sell');
	self:DisableModule('Buy');
end

function AuctionFaster:StripAhTextures()
	if not IsAddOnLoaded('ElvUI') then
		for i = 1, AuctionFrame:GetNumRegions() do
			---@type Region
			local region = select(i, AuctionFrame:GetRegions());

			if region and region:GetObjectType() == 'Texture' then
				if region:GetName() ~= 'AuctionPortraitTexture' then
					region:SetTexture(nil);
				else
					region:Hide();
				end
			end
		end
	end
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	AuctionPortraitTexture:Show();
	for i = 1, #self.auctionTabs do
		self.auctionTabs[i]:Hide();
	end

	if tab.auctionFasterTab then
		self:StripAhTextures();
		tab.auctionFasterTab:Show();
	end
end

function AuctionFaster:GetDefaultItemSettings()
	return {
		rememberStack = true,
		rememberLastPrice = false,
		alwaysUndercut = true,
		useCustomDuration = false,
		priceModel = 'Simple',
		duration = self.db.auctionDuration,
	}
end

AuctionFaster.auctionTabs = {};
function AuctionFaster:AddAuctionHouseTab(buttonText, title, module)
	local n = AuctionFrame.numTabs + 1;

	local auctionTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, title, 160);
	auctionTab.titlePanel:SetBackdrop(nil);
	auctionTab:Hide();
	auctionTab:SetAllPoints();
	auctionTab.tabId = n;

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
	tabButton.auctionFasterTab.module = module;

	auctionTab.tabButton = tabButton;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);
	tinsert(self.auctionTabs, auctionTab);
	return auctionTab;
end

AuctionFaster.Colors = {
	[1] = 'FFBCCF02', -- Success
	[2] = 'FF1394CC', -- Info
	[3] = 'FFF0563D', -- Error
};

function AuctionFaster:Echo(type, message)
	self:Print(WrapTextInColorCode(message, self.Colors[type]));
end