---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

function Sell:DrawItemSettingsPane()
	local sellTab = self.sellTab;

	local pane = StdUi:Window(sellTab, 200, 100,  L['Item Settings']);
	StdUi:GlueAfter(pane, sellTab, 0, -150, 0, 0);

	if AuctionFaster.db.itemSettingsOpened then
		pane:Show();
	else
		pane:Hide();
	end

	pane:SetScript('OnShow', function() AuctionFaster.db.itemSettingsOpened = true end);
	pane:SetScript('OnHide', function() AuctionFaster.db.itemSettingsOpened = false end);

	sellTab.itemSettingsPane = pane;
	self:DrawItemSettings();
end

function Sell:DrawItemSettings()
	local pane = self.sellTab.itemSettingsPane;

	local icon = StdUi:Texture(pane, 30, 30, nil);

	local itemName = StdUi:Label(pane, L['No Item selected'], nil, 'GameFontNormalLarge', 150);
	local rememberStack = StdUi:Checkbox(pane, L['Remember Stack Settings']);
	local rememberLastPrice = StdUi:Checkbox(pane, L['Remember Last Price']);
	local alwaysUndercut = StdUi:Checkbox(pane, L['Always Undercut']);
	local useCustomDuration = StdUi:Checkbox(pane, L['Use Custom Duration']);

	local options = {
		{text = L['12h'], value = 1},
		{text = L['24h'], value = 2},
		{text = L['48h'], value = 3}
	}
	local duration = StdUi:Dropdown(pane, 150, 20, options);
	StdUi:AddLabel(pane, duration, L['Auction Duration'], 'TOP');

	local priceModels = AuctionFaster:GetModule('Pricing'):GetPricingModels();
	local priceModel = StdUi:Dropdown(pane, 150, 20, priceModels);
	StdUi:AddLabel(pane, priceModel, L['Pricing Model'], 'TOP');

	StdUi:GlueTop(icon, pane, 10, -40, 'LEFT');
	StdUi:GlueAfter(itemName, icon, 10, 0);
	StdUi:GlueBelow(rememberStack, icon, 0, -10, 'LEFT');
	StdUi:GlueBelow(rememberLastPrice, rememberStack, 0, -10, 'LEFT');
	StdUi:GlueBelow(alwaysUndercut, rememberLastPrice, 0, -10, 'LEFT');
	StdUi:GlueBelow(useCustomDuration, alwaysUndercut, 0, -10, 'LEFT');
	StdUi:GlueBelow(duration, useCustomDuration, 0, -30, 'LEFT');
	StdUi:GlueBelow(priceModel, duration, 0, -30, 'LEFT');

	pane.icon = icon;
	pane.itemName = itemName;
	pane.rememberStack = rememberStack;
	pane.rememberLastPrice = rememberLastPrice;
	pane.alwaysUndercut = alwaysUndercut;
	pane.useCustomDuration = useCustomDuration;
	pane.duration = duration;
	pane.priceModel = priceModel;

	self:LoadItemSettings();
	self:InitItemSettingsScripts();
	self:InitItemSettingsTooltips();
	-- this will mark all settings disabled
end

function Sell:InitItemSettingsScripts()
	local pane = self.sellTab.itemSettingsPane;

	pane.rememberStack.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('rememberStack', flag);
	end;

	pane.rememberLastPrice.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('rememberLastPrice', flag);
	end;

	pane.alwaysUndercut.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('alwaysUndercut', flag);
	end;

	pane.useCustomDuration.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('useCustomDuration', flag);
		Sell:UpdateItemSettingsCustomDuration(flag);
	end;

	pane.duration.OnValueChanged = function(self, value)
		Sell:UpdateItemSettings('duration', value);
	end;

	pane.priceModel.OnValueChanged = function(_, value)
		if not self.loadingItemSettings then
			self:UpdateItemSettings('priceModel', value);
			self:RecalculateCurrentPrice();
		end
	end
end

function Sell:UpdateItemSettingsCustomDuration(useCustomDuration)
	local pane = self.sellTab.itemSettingsPane;

	if useCustomDuration then
		pane.duration:Enable();
	else
		pane.duration:Disable();
	end
end

function Sell:InitItemSettingsTooltips()
	local pane = self.sellTab.itemSettingsPane;

	StdUi:FrameTooltip(
		pane.rememberStack,
		L['Checking this option will make\nAuctionFaster remember how much\n' ..
		'stacks you wish to sell at once\nand how big is stack'],
		'AFInfoTT', 'TOPLEFT', true
	);

	StdUi:FrameTooltip(
		pane.rememberLastPrice, function(tip)
			tip:AddLine(L['If there is no auctions of this item,']);
			tip:AddLine(L['remember last price.']);
			tip:AddLine('');
			tip:AddLine(L['Your price will be overriden'], 1, 0, 0);
			tip:AddLine(L['if "Always Undercut" options is checked!'], 1, 0, 0);
		end,
		'AFInfoTTX', 'TOPLEFT', true
	);

	StdUi:FrameTooltip(
		pane.alwaysUndercut,
		L['By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
		'If you uncheck this option AuctionFaster\nwill never undercut items for you'],
		'AFInfoTT', 'TOPLEFT', true
	);
end

function Sell:LoadItemSettings()
	local pane = self.sellTab.itemSettingsPane;
	self.loadingItemSettings = true;

	if not self.selectedItem then
		pane.icon:SetTexture(nil);

		pane.itemName:SetText(L['No Item selected']);
		pane.rememberStack:SetChecked(true);
		pane.rememberLastPrice:SetChecked(false);
		pane.alwaysUndercut:SetChecked(true);
		pane.useCustomDuration:SetChecked(false);
		pane.duration:SetValue(2);
		pane.priceModel:SetValue('Simple');

		self:EnableDisableItemSettings(false);

		self.loadingItemSettings = false;
		return;
	end

	local item = self:GetSelectedItemRecord();

	self:EnableDisableItemSettings(true);
	pane.icon:SetTexture(self.selectedItem.icon);
	pane.itemName:SetText(self.selectedItem.link);
	pane.rememberStack:SetChecked(item.settings.rememberStack);
	pane.rememberLastPrice:SetChecked(item.settings.rememberLastPrice);
	pane.alwaysUndercut:SetChecked(item.settings.alwaysUndercut);
	pane.useCustomDuration:SetChecked(item.settings.useCustomDuration);
	pane.duration:SetValue(item.settings.duration);
	if not item.settings.priceModel then
		item.settings.priceModel = 'Simple';
	end
	pane.priceModel:SetValue(item.settings.priceModel);

	Sell:UpdateItemSettingsCustomDuration(item.settings.useCustomDuration);

	self.loadingItemSettings = false;
end

function Sell:EnableDisableItemSettings(enable)
	local pane = self.sellTab.itemSettingsPane;
	if enable then
		pane.rememberStack:Enable();
		pane.rememberLastPrice:Enable();
		pane.alwaysUndercut:Enable();
		pane.useCustomDuration:Enable();
		pane.duration:Enable();
		pane.priceModel:Enable();
	else
		pane.rememberStack:Disable();
		pane.rememberLastPrice:Disable();
		pane.alwaysUndercut:Disable();
		pane.useCustomDuration:Disable();
		pane.duration:Disable();
		pane.priceModel:Disable();
	end
end

function Sell:UpdateItemSettings(settingName, settingValue)
	if not self.selectedItem or self.loadingItemSettings then
		return;
	end

	local cacheKey = self.selectedItem.itemId .. self.selectedItem.itemName;
	ItemCache:UpdateItemSettingsInCache(cacheKey, settingName, settingValue);
end

function Sell:ToggleItemSettingsPane()
	if self.sellTab.itemSettingsPane:IsShown() then
		self.sellTab.itemSettingsPane:Hide();
	else
		self.sellTab.itemSettingsPane:Show();
	end
end
