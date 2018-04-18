AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');
AceGUI = LibStub('AceGUI-3.0');


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
	LibStub('AceConfig-3.0'):RegisterOptionsTable('AuctionFaster', options, {'/afconf'});

	self.db = LibStub('AceDB-3.0'):New('AuctionFasterDb', defaults);

	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('AuctionFaster', 'AuctionFaster');
--	self:RegisterChatCommand('keystonemanager', 'ShowWindow');
--	self:RegisterChatCommand('keylist', 'ShowWindow');
--	self:RegisterChatCommand('keyprint', 'PrintKeystone');
	self:RegisterEvent('BAG_UPDATE_DELAYED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');

end

function AuctionFaster:AddAuctionHouseTab()
	if self.TabAdded then
		return;
	end

	local auctionTab = CreateFrame('Frame', nil, AuctionFrame);
	auctionTab:Hide();
	auctionTab:SetAllPoints();

	self.auctionTab = auctionTab;

	local n = AuctionFrame.numTabs + 1;

	local tab = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame, 'AuctionTabTemplate')
	tab:Hide()
	tab:SetID(n)
	tab:SetText('|cfffe6000Sell Items')
	tab:SetNormalFontObject(GameFontHighlightSmall)
	tab:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0)
	tab:Show();
	tab.auctionFaster = true;

	PanelTemplates_SetNumTabs(AuctionFrame, n);
	PanelTemplates_EnableTab(AuctionFrame, n);

	self.TabAdded = true;

	local closeBtn = CreateFrame('Button', nil, auctionTab, 'UIPanelButtonTemplate')
	closeBtn:SetPoint('BOTTOMRIGHT', -5, 5)
	closeBtn:SetWidth(75)
	closeBtn:SetHeight(24)
	closeBtn:SetText('dziaua')

	local b = CreateFrame('Button', 'MyButton', auctionTab, 'UIPanelButtonTemplate')
	b:SetSize(80 ,22) -- width, height
	b:SetText('Button!')
	b:SetPoint('CENTER')

	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:AuctionFrameTab_OnClick(tab, b, c)

	DevTools_Dump(AuctionFaster.auctionTab);
	DevTools_Dump(b);
	DevTools_Dump(c);

	if tab.auctionFaster then
		AuctionFaster.auctionTab:Show();
	end
end

function AuctionFaster:ScanInventory()
	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag);

		if numSlots ~= 0 then
			for slot = 1, numSlots do
				local itemId = GetContainerItemID(bag, slot);
				local link = GetContainerItemLink(bag, slot);
			end
		end

	end

end

function AuctionFaster:AddItemToList(link)
	local canSell = false;

	if itemId == 82800 then
		canSell = true;
	else
		Gratuity:SetBagItem(bag, slot);
		local n = Gratuity:NumLines();
		if strfind(tostring(Gratuity:GetLine(1)), RETRIEVING_ITEM_INFO) then
			return false
		end


		for i = 1, n do
			local line = Gratuity:GetLine(i)
			if line then
				isBop = isBop or strfind(line, ITEM_BIND_ON_PICKUP)
				isBoa = isBoa or strfind(line, ITEM_BIND_TO_BNETACCOUNT)
				isBoa = isBoa or strfind(line, ITEM_BNETACCOUNTBOUND)
				isBound = isBound or strfind(line, ITEM_SOULBOUND)
				isBound = isBound or strfind(line, ITEM_BIND_QUEST)
				isBound = isBound or strfind(line, ITEM_CONJURED)

				-- if we found use clause, we are past possible points of binding, stop looking
				if strfind(line, USE_COLON) then break end
			end
		end
	end
	BagSlot_BindCache[bag][slot] = { isBop = isBop, isBoa = isBoa, isBound = isBound }
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	self:AddAuctionHouseTab();
end

function AuctionFaster:BAG_UPDATE_DELAYED()

end