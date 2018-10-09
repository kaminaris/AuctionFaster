---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Tutorial
local Tutorial = AuctionFaster:GetModule('Tutorial');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local C = WrapTextInColorCode;
local red = 'FFFF0000';
local green = 'FF00FF00';
local orange = 'FFFFFF00';

function Sell:DrawHelpButton()
	local helpBtn = StdUi:SquareButton(self.sellTab, 16, 16);
	helpBtn:SetIcon([[Interface\FriendsFrame\InformationIcon]], 16, 16, true);

	StdUi:GlueLeft(helpBtn, AuctionFrameCloseButton, -10, 0);

	helpBtn:SetScript('OnClick', function ()
		self:InitTutorial(true);
	end);

	local settingsBtn = StdUi:SquareButton(self.sellTab, 16, 16);
	settingsBtn:SetIcon([[Interface\GossipFrame\BinderGossipIcon]], 16, 16, true);

	StdUi:GlueLeft(settingsBtn, helpBtn, -5, 0);

	settingsBtn:SetScript('OnClick', function ()
		AuctionFaster:OpenSettingsWindow();
	end);

	StdUi:FrameTooltip(helpBtn, 'Addon Tutorial', 'afAddonTutorialOne', 'TOPLEFT', true);
	StdUi:FrameTooltip(settingsBtn, 'Addon settings', 'afAddonSettingsOne', 'TOPLEFT', true);

	self.helpBtn = helpBtn;
end

function Sell:InitTutorial(force)
	if not AuctionFaster.db.tutorials.sell and not force then
		return;
	end

	if not self.tutorials then
		local sellTab = self.sellTab;
		self.tutorials = {
			{
				text   = 'Welcome to AuctionFaster.\n\nI recommend checking out sell tutorial at least once before' ..
					' you accidentally sell your precious goods.\n\n:)',
				anchor = 'CENTER',
				parent = sellTab,
				noglow = true
			},
			{
				text   = 'Here is the list of all inventory items you can sell, no need to drag anything.\n\n' ..
					C('After you select item, AuctionFaster will automatically make a scan of first page and undercut'..
					' set bid/buy according to price model selected.', red),
				anchor = 'LEFT',
				parent = sellTab.itemsList,
			},
			{
				text   = 'Here you will see selected item. Max stacks means how much of stacks can you sell according'
					.. ' to your setting. Remaining means how much quantity will still stay in bag after selling item.',
				anchor = 'RIGHT',
				parent = sellTab.iconBackdrop,
			},
			{
				text   = 'AuctionFaster keeps auctions cache for about 10 minutes, you can see when last real scan' ..
					' was performed.\n\n' .. C('You can click Refresh Auctions to scan again', green),
				anchor = 'RIGHT',
				parent = sellTab,
				customAnchor = sellTab.lastScan,
			},
			{
				text   = 'Your bid price ' .. C('per one item.', red) .. '\n\n' ..
					C('AuctionFaster understands a lot of money formats', green) ..
					', for example:\n\n' .. '5g 6s 19c\n5g6s86c\n999s 50c\n3000s\n9000000c',
				anchor = 'LEFT',
				parent = sellTab.bidPerItem,
			},
			{
				text   = 'Your buyout price ' .. C('per one item.', red) .. ' Same money formats as bid per item.',
				anchor = 'LEFT',
				parent = sellTab.buyPerItem,
			},
			{
				text   = 'Maximum number of stacks you wish to sell.\n\n' ..
					C('Set this to 0 to sell everything', orange),
				anchor = 'LEFT',
				parent = sellTab.maxStacks,
			},
			{
				text   = 'This opens up item settings.\nClick again to close.\n\n' ..
					C('Hover over checkboxes to see what the options are.\n\n', green) ..
					C('Those settings are per specific item', orange),
				anchor = 'RIGHT',
				action = function()
					sellTab.itemSettingsPane:Show();
				end,
				parent = sellTab.buttons.itemSettings,
			},
			{
				text   = 'This opens auction informations:\n\n' ..
					'- Total auction buy price.\n' ..
					'- Deposit cost.\n' ..
					'- Number of auctions\n' ..
					'- Auction duration\n\n' ..
					C('This will change dynamically when you change stack size or max stacks.', green),
				anchor = 'RIGHT',
				action = function()
					sellTab.infoPane:Show();
				end,
				parent = sellTab.buttons.infoPane,
			},
			{
				text   = 'Here is a list of auctions of currently selected item.\n'..
					'You can be sure your item will be cheapest.\n' ..
					C('These are always sorted by lowest price per item.', red),
				anchor = 'LEFT',
				parent = sellTab.currentAuctions,
			},
			{
				text   = 'This button allows you to buy selected item. Useful for restocking.',
				anchor = 'LEFT',
				parent = sellTab.buttons.buyItemButton,
			},
			{
				text   = 'Posts ' .. C('one auction', red) .. ' of selected item regardless of your\n"# Stacks" settings',
				anchor = 'RIGHT',
				parent = sellTab.buttons.postOneButton,
			},
			{
				text   = 'Posts ' .. C('all auctions', red) .. ' of selected item according to your\n"# Stacks" settings',
				anchor = 'RIGHT',
				parent = sellTab.buttons.postButton,
			},
			{
				text   = 'Opens this tutorial again.\nHope you liked it\n\n:)\n\n' ..
					C('Once you close this tutorial it won\'t show again unless you click it', orange),
				anchor = 'LEFT',
				parent = self.helpBtn,
			}
		};
	end

	Tutorial:SetTutorials(self.tutorials);
	Tutorial:Show(false, function()
		AuctionFaster.db.tutorials.sell = false;
	end);
end