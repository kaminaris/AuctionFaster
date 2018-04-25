AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');
local AceGUI = LibStub('AceGUI-3.0');

local options = {
	type = 'group',
	name = 'AuctionFaster Options',
	inline = false,
	args = {
		enableIcon = {
			name = 'Enable AuctionFaster',
			desc = 'Enable AuctionFaster',
			type = 'toggle',
			width = 'full',
			set = function(info, val)
				AuctionFaster.db.global.enabled = not val;
			end,
			get = function(info) return not AuctionFaster.db.global.enabled end
		},
	},
}

local defaults = {
	global = {
		enabled = true,
	}
};

function AuctionFaster:OnInitialize()
	LibStub('AceConfig-3.0'):RegisterOptionsTable('AuctionFaster', options, { '/afconf' });

	self.db = LibStub('AceDB-3.0'):New('AuctionFasterDb', defaults);

	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('AuctionFaster', 'AuctionFaster');
	--	self:RegisterChatCommand('keystonemanager', 'ShowWindow');
	--	self:RegisterChatCommand('keylist', 'ShowWindow');
	--	self:RegisterChatCommand('keyprint', 'PrintKeystone');
	self:RegisterEvent('BAG_UPDATE_DELAYED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');

	if not self.db.global.auctionDb then
		self.db.global.auctionDb = {};
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

function AuctionFaster:AUCTION_HOUSE_SHOW()
	self:AddAuctionHouseTab();
end
