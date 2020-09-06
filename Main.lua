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

	if self.db.enableToolTips then
		self:EnableModule('Tooltip');
	end

	-- These modules must be enabled on start, they handle events themselves
	-- Update, this automatically enabled
	--self:EnableModule('ItemCache');
	--self:EnableModule('Inventory');
	--self:EnableModule('Auctions');
	--self:EnableModule('ConfirmBuy');
	--self:EnableModule('Tutorial');

	self.buyModule = self:GetModule('Buy');
	self.sellModule = self:GetModule('Sell');

	-- TODO: COMMENT THIS OUT
	--UIParentLoadAddOn('Blizzard_DebugTools')
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	if self.db.enabled then
		self.buyModule:Attach();
		self.sellModule:Attach();

		if not self.onTabClickHooked then
			self:Hook(AuctionHouseFrame, 'SetDisplayMode', 'SetDisplayModeHook', true);
			self.onTabClickHooked = true;
		end

		if self.db.defaultTab == 'SELL' then
			AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.AFSellMode);
		elseif self.db.defaultTab == 'BUY' then
			AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.AFBuyMode);
		end
	end
end

function AuctionFaster:AUCTION_HOUSE_CLOSED()
	self.buyModule:Detach();
	self.sellModule:Detach();
end

local function stripFrameTextures(frame, strip)
	for i = 1, frame:GetNumRegions() do
		---@type Region
		local region = select(i, frame:GetRegions());

		if region and region:GetObjectType() == 'Texture' then
			if strip then
				region:Hide();
			else
				region:Show()
			end
		end
	end
end

function AuctionFaster:StripAhTextures()
	if not IsAddOnLoaded('ElvUI') then
		stripFrameTextures(AuctionHouseFrame, true);
		stripFrameTextures(AuctionHouseFrame.NineSlice, true);
	end
end

function AuctionFaster:RestoreAhTextures()
	if not IsAddOnLoaded('ElvUI') then
		stripFrameTextures(AuctionHouseFrame, false);
		stripFrameTextures(AuctionHouseFrame.NineSlice, false);
	end
end

function AuctionFaster:SetDisplayModeHook(_, displayMode)
	if displayMode and displayMode[1] and displayMode[1]:find('AF') == 1 then
		self:StripAhTextures();
	else
		self:RestoreAhTextures();
	end
end

function AuctionFaster:GetDefaultItemSettings()
	return {
		rememberStack     = true,
		rememberLastPrice = false,
		alwaysUndercut    = true,
		useCustomDuration = false,
		priceModel        = 'Simple',
		duration          = self.db.auctionDuration,
	}
end

AuctionFaster.auctionTabs = {};
function AuctionFaster:AddAuctionHouseTab(buttonText, title, module, displayMode)
	local n = #AuctionHouseFrame.Tabs + 1;

	local auctionTab = StdUi:PanelWithTitle(AuctionHouseFrame, nil, nil, title, 160);
	auctionTab.titlePanel:SetBackdrop(nil);
	auctionTab:Hide();
	auctionTab:SetAllPoints();
	auctionTab.tabId = n;

	local tabButton = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionHouseFrame, 'AuctionHouseFrameDisplayModeTabTemplate');
	tabButton.displayMode = displayMode;
	StdUi:StripTextures(tabButton);
	tabButton.backdrop = StdUi:Panel(tabButton);
	tabButton.backdrop:SetFrameLevel(tabButton:GetFrameLevel() - 1);
	StdUi:GlueAcross(tabButton.backdrop, tabButton, 10, -3, -10, 3);

	tabButton:Hide();
	tabButton:SetID(n);
	tabButton:SetText(buttonText);
	tabButton:SetNormalFontObject(GameFontHighlightSmall);
	tabButton:SetPoint('LEFT', AuctionHouseFrame.Tabs[n - 1], 'RIGHT', -15, 0);
	tabButton:Show();
	-- reference the actual tab
	tabButton.auctionFasterTab = auctionTab;
	tabButton.auctionFasterTab.module = module;

	auctionTab.tabButton = tabButton;

	PanelTemplates_SetNumTabs(AuctionHouseFrame, n);
	tinsert(self.auctionTabs, auctionTab);
	tinsert(AuctionHouseFrame.Tabs, tabButton);

	AuctionHouseFrame.tabsForDisplayMode[displayMode] = n;
	AuctionHouseFrame[displayMode[1]] = auctionTab;

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