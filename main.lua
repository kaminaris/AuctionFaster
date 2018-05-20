AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');

function AuctionFaster:OnInitialize()
	LibStub('AceConfig-3.0'):RegisterOptionsTable('AuctionFaster', self.options, { '/afconf' });

	self.db = LibStub('AceDB-3.0'):New('AuctionFasterDb', self.defaults);

	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('AuctionFaster', 'AuctionFaster');

	self:RegisterEvent('BAG_UPDATE_DELAYED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');
	self:RegisterEvent('AUCTION_MULTISELL_UPDATE');

	if not self.db.global.auctionDb then
		self.db.global.auctionDb = {};
	end

end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	if self.db.global.enabled then
		self:AddSellAuctionHouseTab();
		self:AddBuyAuctionHouseTab();

		if not self.onTabClickHooked then
			self:Hook('AuctionFrameTab_OnClick', true);
			self.onTabClickHooked = true;
		end
	end
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	self.sellTab:Hide();
	self.buyTab:Hide();
	if tab.auctionFasterTab then
		tab.auctionFasterTab:Show();
	end
end

function AuctionFaster:ShowTooltip(frame, link, show)
	if show then
		GameTooltip:SetOwner(frame);
		GameTooltip:SetPoint('LEFT');
		GameTooltip:SetHyperlink(link);
		GameTooltip:Show();
	else
		GameTooltip:Hide();
	end
end