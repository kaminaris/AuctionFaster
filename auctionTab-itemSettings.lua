--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:DrawItemSettingsPane()
	local auctionTab = self.auctionTab;

	local pane = StdUi:PanelWithTitle(auctionTab, 300, 100, 'Item Settings');
	StdUi:GlueAfter(pane, auctionTab, 0, 0, 0, 0);
	pane:Hide();

	auctionTab.itemSettingsPane = pane;
	self:DrawItemSettings();
end

function AuctionFaster:DrawItemSettings()
	local pane = self.auctionTab.itemSettingsPane;

	local icon = StdUi:Texture(pane, 30, 30, nil);
	StdUi:GlueTop(icon, pane, 10, -20, 'LEFT');

	local itemName = StdUi:Label(pane, 'No Item selected', 14);
	StdUi:GlueAfter(itemName, icon, 10, 0);

	local rememberStack = StdUi:Checkbox(pane, 'Remember Stack Settings');
	StdUi:GlueBelow(rememberStack, icon, 0, -10, 'LEFT');

	local rememberLastPrice = StdUi:Checkbox(pane, 'Remember Last Price');
	StdUi:GlueBelow(rememberLastPrice, rememberStack, 0, -10, 'LEFT');

	local alwaysUndercut = StdUi:Checkbox(pane, 'Always Undercut');
	StdUi:GlueBelow(alwaysUndercut, rememberLastPrice, 0, -10, 'LEFT');

	local useCustomDuration = StdUi:Checkbox(pane, 'Use Custom Duration');
	StdUi:GlueBelow(useCustomDuration, alwaysUndercut, 0, -10, 'LEFT');

	local options = {
		{text = '12h', value = 1},
		{text = '24h', value = 2},
		{text = '48h', value = 3},
	}
	local duration = StdUi:Dropdown(pane, 'AFDuration', 150, 20, options);
	StdUi:GlueBelow(duration, useCustomDuration, 0, -30, 'LEFT');
	StdUi:AddLabel(pane, duration, 'Auction Duration', 'TOP');

	pane.icon = icon;
	pane.itemName = itemName;
	pane.rememberStack = rememberStack;
	pane.rememberLastPrice = rememberLastPrice;
	pane.alwaysUndercut = alwaysUndercut;
	pane.useCustomDuration = useCustomDuration;
	pane.duration = duration;

	self:InitItemSettingsScripts();
	self:InitItemSettingsTooltips();
end

function AuctionFaster:InitItemSettingsScripts()
	local pane = self.auctionTab.itemSettingsPane;

	pane.rememberStack:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('rememberStack', self:GetChecked());
	end);

	pane.rememberLastPrice:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('rememberLastPrice', self:GetChecked());
	end);

	pane.alwaysUndercut:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('alwaysUndercut', self:GetChecked());
	end);

	pane.useCustomDuration:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('useCustomDuration', self:GetChecked());
		AuctionFaster:UpdateItemSettingsCustomDuration(self:GetChecked());
	end);

	pane.duration.OnValueChanged = function(self, value)
		AuctionFaster:UpdateItemSettings('duration', value);
	end;
end

function AuctionFaster:UpdateItemSettingsCustomDuration(useCustomDuration)
	local pane = self.auctionTab.itemSettingsPane;

	if useCustomDuration then
		pane.duration:Enable();
	else
		pane.duration:Disable();
	end
end

function AuctionFaster:InitItemSettingsTooltips()
	local pane = self.auctionTab.itemSettingsPane;

	StdUi:Tooltip(
		pane.rememberStack,
		'Checking this option will make\nAuctionFaster remember how much\n' ..
		'stacks you wish to sell at once\nand how big is stack',
		'AFInfoTT', 'TOPLEFT', true
	);

	StdUi:Tooltip(
		pane.rememberLastPrice, function(tip)
			tip:AddLine('If there is no auctions of this item,');
			tip:AddLine('remember last price.');
			tip:AddLine('');
			tip:AddLine('Your price will be overriden', 1, 0, 0);
			tip:AddLine('if "Always Undercut" options is checked!', 1, 0, 0);
		end,
		'AFInfoTTX', 'TOPLEFT', true
	);

	StdUi:Tooltip(
		pane.alwaysUndercut,
		'By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
		'If you uncheck this option AuctionFaster\nwill never undercut items for you',
		'AFInfoTT', 'TOPLEFT', true
	);
end

function AuctionFaster:LoadItemSettings()
	local pane = self.auctionTab.itemSettingsPane;

	if not self.selectedItem then
		pane.icon:SetTexture(nil);
		pane.itemName:SetText('No Item selected');
		pane.rememberStack:SetChecked(true);
		pane.rememberLastPrice:SetChecked(false);
		pane.alwaysUndercut:SetChecked(true);
		pane.useCustomDuration:SetChecked(false);
		pane.duration:SetValue(2);
	end

	local item = self:GetSelectedItemFromCache();

	pane.icon:SetTexture(self.selectedItem.icon);
	pane.itemName:SetText(self.selectedItem.name);
	pane.rememberStack:SetChecked(item.settings.rememberStack);
	pane.rememberLastPrice:SetChecked(item.settings.rememberLastPrice);
	pane.alwaysUndercut:SetChecked(item.settings.alwaysUndercut);
	pane.useCustomDuration:SetChecked(item.settings.useCustomDuration);
	pane.duration:SetValue(item.settings.duration);

	AuctionFaster:UpdateItemSettingsCustomDuration(item.settings.useCustomDuration);
end

function AuctionFaster:UpdateItemSettings(settingName, settingValue)
	if not self.selectedItem then
		return;
	end

	local itemId, itemName = self.selectedItem.itemId, self.selectedItem.name;
	local cacheKey = itemId .. itemName;

	self:UpdateItemSettingsInCache(cacheKey, settingName, settingValue);
end

function AuctionFaster:ToggleItemSettingsPane()
	if self.auctionTab.itemSettingsPane:IsShown() then
		self.auctionTab.itemSettingsPane:Hide();
	else
		self.auctionTab.itemSettingsPane:Show();
	end
end

function AuctionFaster:GetDefaultItemSettings()
	return {
		rememberStack = true,
		rememberLastPrice = false,
		alwaysUndercut = true
	}
end
