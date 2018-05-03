--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:DrawItemSettingsPane()
	local auctionTab = self.auctionTab;

	local pane = StdUi:PanelWithTitle(auctionTab, 300, 100, 'Item Settings');
	pane:Hide();
	StdUi:GlueAfter(pane, auctionTab, 0, 0, 0, 0);

	auctionTab.itemSettingsPane = pane;
	self:DrawItemSettingsIcon()
end

function AuctionFaster:DrawItemSettingsIcon()
	local pane = self.auctionTab.itemSettingsPane;

	local icon = StdUi:Texture(pane, 30, 30, nil);
	StdUi:GlueTop(icon, pane, 10, -20, 'LEFT');

	local itemName = StdUi:Label(pane, 'No Item selected', 14);
	StdUi:GlueAfter(itemName, icon, 10, 0);

	local rememberStack = StdUi:Checkbox(pane, 'Remember Stack Settings');
	StdUi:GlueBelow(rememberStack, icon, 0, -10, 'LEFT');
	rememberStack:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('rememberStack', self:GetChecked());
	end);

	local rememberLastPrice = StdUi:Checkbox(pane, 'Remember Last Price');
	StdUi:GlueBelow(rememberLastPrice, rememberStack, 0, -10, 'LEFT');
	rememberLastPrice:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('rememberLastPrice', self:GetChecked());
	end);

	local alwaysUndercut = StdUi:Checkbox(pane, 'Always Undercut');
	StdUi:GlueBelow(alwaysUndercut, rememberLastPrice, 0, -10, 'LEFT');
	alwaysUndercut:SetScript('OnClick', function(self)
		AuctionFaster:UpdateItemSettings('alwaysUndercut', self:GetChecked());
	end);

	pane.icon = icon;
	pane.itemName = itemName;
	pane.rememberStack = rememberStack;
	pane.rememberLastPrice = rememberLastPrice;
	pane.alwaysUndercut = alwaysUndercut;

	self:InitItemSettingsTooltips();
end

function AuctionFaster:InitItemSettingsTooltips()
	local pane = self.auctionTab.itemSettingsPane;

	StdUi:Tooltip(
		pane.rememberStack,
		'Checking this option will make\nAuctionFaster remember how much\n' ..
		'stacks you wish to sell at once\nand how big is stack',
		'', 'AFRememberStackTT', 'TOPLEFT', true
	);

	StdUi:Tooltip(
		pane.rememberLastPrice,
		'If there is no auctions of this item,\n remember last price.\n\n' ..
		'|cffff0000Your price will be overriden if "Always Undercut" options is checked!|r',
		'', 'AFRememberStackTT', 'TOPLEFT', true
	);

	StdUi:Tooltip(
		pane.alwaysUndercut,
		'By default, AuctionFaster always undercuts price,\neven if you toggle "Remember Last Price"\n'..
		'If you uncheck this option AuctionFaster\nwill never undercut items for you',
		'', 'AFRememberStackTT', 'TOPLEFT', true
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
	end

	local item = self:GetSelectedItemFromCache();

	pane.icon:SetTexture(self.selectedItem.icon);
	pane.itemName:SetText(self.selectedItem.name);
	pane.rememberStack:SetChecked(item.settings.rememberStack);
	pane.rememberLastPrice:SetChecked(item.settings.rememberLastPrice);
	pane.alwaysUndercut:SetChecked(item.settings.alwaysUndercut);
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
