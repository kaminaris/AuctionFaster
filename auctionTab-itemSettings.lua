
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

	local rememberStack = StdUi:Checkbox(pane, 'Remember Stack Settings', 'ttoooltip');
	StdUi:GlueBelow(rememberStack, itemName, 0, -10, 'LEFT');


end

function AuctionFaster:ToggleItemSettingsPane()
	if self.auctionTab.itemSettingsPane:IsShown() then
		self.auctionTab.itemSettingsPane:Hide();
	else
		self.auctionTab.itemSettingsPane:Show();
	end
end
