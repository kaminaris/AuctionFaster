
--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:DrawItemSettingsPane()
	local auctionTab = self.auctionTab;

	local pane = StdUi:InfoPane(auctionTab, 300, 100, 'Item Settings');
	pane:Hide();
	StdUi:GlueAfter(pane, auctionTab, 0, 0, 0, 0);

	auctionTab.itemSettingsPane = pane;
end

function AuctionFaster:ToggleItemSettingsPane()
	if self.auctionTab.itemSettingsPane:IsShown() then
		self.auctionTab.itemSettingsPane:Hide();
	else
		self.auctionTab.itemSettingsPane:Show();
	end
end
