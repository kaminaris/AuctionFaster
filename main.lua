AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');

function AuctionFaster:OnInitialize()
	LibStub('AceConfig-3.0'):RegisterOptionsTable('AuctionFaster', self.options, { '/afconf' });

	self.db = LibStub('AceDB-3.0'):New('AuctionFasterDb', self.defaults);

	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('AuctionFaster', 'AuctionFaster');

	self:RegisterEvent('AUCTION_HOUSE_SHOW');

	if not self.db.global.auctionDb then
		self.db.global.auctionDb = {};
	end

	if self.db.global.tooltipsEnabled then
		self:EnableModule('Tooltip');
	end

	-- These modules must be enabled on start, they handle events themselves
	self:EnableModule('Inventory');
	self:EnableModule('Auctions');
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

function AuctionFaster:ShowTooltip(frame, link, show, itemId)
	if show then

		GameTooltip:SetOwner(frame);
		GameTooltip:SetPoint('TOPLEFT');

		if itemId == 82800 then
			local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(':', link);

			BattlePetToolTip_Show(
				tonumber(speciesID),
				tonumber(level),
				tonumber(breedQuality),
				tonumber(maxHealth),
				tonumber(power),
				tonumber(speed),
				string.gsub(string.gsub(link, '^(.*)%[', ''), '%](.*)$', '')
			);
			BattlePetTooltip:ClearAllPoints();
			BattlePetTooltip:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 0);
		else
			GameTooltip:SetHyperlink(link);
			GameTooltip:Show();
		end
	else
		GameTooltip:Hide();
	end
end