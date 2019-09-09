---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');
--- @type Tutorial
local Tutorial = AuctionFaster:GetModule('Tutorial');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

local C = WrapTextInColorCode;
local red = 'FFFF0000';
local green = 'FF00FF00';
local orange = 'FFFFFF00';

function Buy:DrawHelpButton()
	local helpBtn = StdUi:SquareButton(self.buyTab, 16, 16);
	helpBtn:SetIcon([[Interface\FriendsFrame\InformationIcon]], 16, 16, true);

	StdUi:GlueLeft(helpBtn, AuctionFrameCloseButton, -5, 0);

	helpBtn:SetScript('OnClick', function ()
		self:InitTutorial(true);
	end);

	local settingsBtn = StdUi:SquareButton(self.buyTab, 16, 16);
	settingsBtn:SetIcon([[Interface\GossipFrame\BinderGossipIcon]], 16, 16, true);

	StdUi:GlueLeft(settingsBtn, helpBtn, -5, 0);

	settingsBtn:SetScript('OnClick', function ()
		AuctionFaster:OpenSettingsWindow();
	end);

	StdUi:FrameTooltip(helpBtn, L['Addon Tutorial'], 'afAddonTutorialTwo', 'TOPLEFT', true);
	StdUi:FrameTooltip(settingsBtn, L['Addon settings'], 'afAddonSettingsTwo', 'TOPLEFT', true);

	self.helpBtn = helpBtn;
end

function Buy:InitTutorial(force)
	if not AuctionFaster.db.tutorials.buy and not force then
		return;
	end

	if not self.tutorials then
		local buyTab = self.buyTab;
		self.tutorials = {
			{
				text   = L['Welcome to AuctionFaster.\n\nI recommend checking out\ntutorial at least once\nbefore you ' ..
					'accidentially\nbuy half of the auction house.\n\n:)'],
				anchor = 'CENTER',
				parent = buyTab,
				noglow = true
			},
			{
				text   = L['Once you enter search query\nthis button will add it to\nthe favorites.'],
				anchor = 'LEFT',
				parent = buyTab.addFavoritesButton,
			},
			{
				text   = L['This button opens up filters.\nClick again to close.'],
				anchor = 'LEFT',
				action = function()
					self.filtersPane:Show();
				end,
				parent = buyTab.filtersButton,
			},
			{
				text   = L['Search results.\n\nThere are 3 major shortcuts:\n\n'] ..
					C(L['Shift + Click - Instant buy\n'], red) ..
					C(L['Alt + Click - Add to queue\n'], green) ..
					C(L['Ctrl + Click - Chain buy\n'], orange),
				anchor = 'LEFT',
				parent = buyTab.searchResults,
			},
			{
				text   = L['Your favorites\nClicking on the name will\ninstanty search for this query.\n\n'] ..
					C(L['Click delete button to remove.'], green),
				anchor = 'LEFT',
				parent = buyTab.favorites,
			},
			{
				text   = L['Chain buy will add all auctions\nfrom the first one you select\nto the bottom '] ..
					L['of the list\nto the Buy Queue.\n\n'] .. C(L['You will still need to confirm them.'], red),
				anchor = 'LEFT',
				parent = buyTab.chainBuyButton,
			},
			{
				text   = L['Status of the current buy queue\n\nQty will show you actual quantity\n'] ..
					L['and progress bar will show\nthe amount of auctions.'],
				anchor = 'LEFT',
				parent = buyTab.queueProgress,
			},
			{
				text   = L['Minimal amount of quantity\nyou are interested in.\n\n'] ..
					C(L['This is used by two buttons on the left.'], orange),
				anchor = 'LEFT',
				parent = buyTab.minStacks,
			},
			{
				text   = L['Adds all auctions to the queue that has at least the amount of quantity entered']..
					L[' in the box on the right'],
				anchor = 'LEFT',
				parent = buyTab.addWithXButton,
			},
			{
				text   = L['Finds the first auction '] .. C(L['across all the pages'], red) ..
					L[' that meets the minimum quantity\n\n'] ..
					C(L['You need to enter a search query first'], orange),
				anchor = 'LEFT',
				parent = buyTab.findXButton,
			},
			{
				text   = L['Opens this tutorial again.\nHope you liked it\n\n:)\n\n'] ..
					C(L['Once you close this tutorial it won\'t show again unless you click it'], orange),
				anchor = 'LEFT',
				parent = self.helpBtn,
			}
		};
	end

	Tutorial:SetTutorials(self.tutorials);
	Tutorial:Show(false, function()
		AuctionFaster.db.tutorials.buy = false;
	end);
end