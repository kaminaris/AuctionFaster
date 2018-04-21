AuctionFaster = LibStub('AceAddon-3.0'):NewAddon('AuctionFaster', 'AceConsole-3.0', 'AceEvent-3.0', 'AceHook-3.0');
local AceGUI = LibStub('AceGUI-3.0');
local ScrollingTable = LibStub('ScrollingTable');
local Gratuity = LibStub('LibGratuity-3.0');
local StdUi = LibStub('StdUi-1.0');

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


	local cols = {
		{
			['name'] = 'Icon',
			['width'] = 30,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Name',
			['width'] = 120,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Price',
			['width'] = 80,
			['align'] = 'RIGHT',
		},
	}
	--auctionTab.scrollTable = ScrollingTable:CreateST(cols, 16, 20, nil, auctionTab);

	self:ScanInventory();
	--self:UpdateInventoryTable();
	self:DrawItemsFrame(auctionTab);



	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:DrawItemsFrame(auctionTab)
	auctionTab.scrollframe = CreateFrame('ScrollFrame', 'ANewScrollFrame', auctionTab, 'UIPanelScrollFrameTemplate');
	auctionTab.scrollframe:SetSize(300, 300);
	auctionTab.scrollframe:SetPoint('TOPLEFT', 5, -25);
	auctionTab.scrollframe:SetPoint('BOTTOMLEFT', 300, 35);

	local scrollBar = _G['ANewScrollFrameScrollBar'];

	local tex = auctionTab.scrollframe:CreateTexture(nil, 'BACKGROUND', nil, -6)
	tex:SetPoint('TOP', auctionTab.scrollframe)
	tex:SetPoint('RIGHT', scrollBar, 3.7, 0)
	tex:SetPoint('BOTTOM', auctionTab.scrollframe)
	tex:SetWidth(scrollBar:GetWidth() + 10)
	tex:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar')
	tex:SetTexCoord(0, 0.45, 0.1640625, 1)

	local scrollChild = CreateFrame('Frame', '$parentScrollChild1', auctionTab.scrollframe)
	scrollChild:SetWidth(auctionTab.scrollframe:GetWidth())
	scrollChild:SetHeight(900);

	auctionTab.scrollframe:SetScrollChild(scrollChild)
	auctionTab.scrollframe:EnableMouse(true)

	--make sure you cannot move the panel out of the screen
	auctionTab.scrollframe:SetClampedToScreen(true)

	self:DrawItems(scrollChild);
	self:DrawRightPane(auctionTab);
end

function AuctionFaster:HighlightFrame(frame, highlight)
	if highlight then
		frame.highlightTexture:Show()
	else
		frame.highlightTexture:Hide()
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

function AuctionFaster:DrawItems(scrollChild)
	local lineHeight = 30;

	scrollChild:SetHeight(lineHeight * #self.inventoryItems);

	for i = 1, #self.inventoryItems do
		local holdingFrame = CreateFrame('Button', 'ASScrollItem' .. i, scrollChild);
		holdingFrame:SetPoint('TOPLEFT', 0, -(i - 1) * lineHeight);
		holdingFrame:SetSize(scrollChild:GetWidth(), lineHeight);

		holdingFrame.highlightTexture = holdingFrame:CreateTexture(nil, 'BACKGROUND')
		holdingFrame.highlightTexture:SetAllPoints(true)
		holdingFrame.highlightTexture:SetColorTexture(1, 0.9, 0, 0.5)
		holdingFrame.highlightTexture:Hide();
		holdingFrame.itemLink = self.inventoryItems[i].link;
		holdingFrame.itemIndex = i;


		holdingFrame:EnableMouse();
		holdingFrame:RegisterForClicks('AnyUp');
		holdingFrame:SetScript('OnEnter', function(self)
			AuctionFaster:HighlightFrame(self, true);
			AuctionFaster:ShowTooltip(self, self.itemLink, true);
		end)
		holdingFrame:SetScript('OnLeave', function(self)
			AuctionFaster:HighlightFrame(self, false);
			AuctionFaster:ShowTooltip(self, nil, false);
		end)
		holdingFrame:SetScript('OnClick', function(self)
			AuctionFaster:SelectItem(self.itemIndex);
		end)


		local texx = holdingFrame:CreateTexture(nil, 'ARTWORK')
		texx:SetPoint('TOPLEFT', holdingFrame, 1, -1)
		texx:SetSize(lineHeight - 2, lineHeight - 2);
		texx:SetTexture(self.inventoryItems[i].icon)

		local name = holdingFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
		name:SetText(self.inventoryItems[i].name);
		name:SetSize(150, 20);
		name:SetPoint('TOPLEFT', 35, -5);
		name:SetJustifyH('LEFT');

		local price = StdUi:Label(holdingFrame, nil, GetMoneyString(self.inventoryItems[i].price), nil, 80, 20);
		price:SetJustifyH('RIGHT');
		price:SetPoint('TOPRIGHT', 0, -5);

--		local price = holdingFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
--		price:SetText(GetMoneyString(self.inventoryItems[i].price));
--		price:SetSize(80, 20);
--		price:SetPoint('TOPRIGHT', holdingFrame, 0, -5);
--		price:SetJustifyH('RIGHT');
	end
end

function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];


	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.name);
end

function AuctionFaster:DrawRightPane(auctionTab)
	local leftMargin = 340;
	local iconSize = 48;
	auctionTab.itemIcon = auctionTab:CreateTexture(nil, 'ARTWORK')
	auctionTab.itemIcon:SetPoint('TOPLEFT', leftMargin, -25)
	auctionTab.itemIcon:SetSize(iconSize, iconSize);
	auctionTab.itemIcon:SetTexture('')

	auctionTab.itemName = auctionTab:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	auctionTab.itemName:SetText('No item selected');
	auctionTab.itemName:SetSize(300, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -25);
	auctionTab.itemName:SetJustifyH('LEFT');

	auctionTab.itemQty = auctionTab:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	auctionTab.itemName:SetText('No item selected');
	auctionTab.itemName:SetSize(300, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -25);
	auctionTab.itemName:SetJustifyH('LEFT');

end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	if tab.auctionFaster then
		self.auctionTab:Show();
	else
		self.auctionTab:Hide();
	end
end

function AuctionFaster:UpdateInventoryTable()
	local tableData = {};

	for char, item in pairs(self.inventoryItems) do
		tinsert(tableData, {
			item.icon,
			item.name,
			GetMoneyString(item.price),
		});
	end

	self.auctionTab.scrollTable:SetData(tableData, true);
end

function AuctionFaster:ScanInventory()
	if self.inventoryItems then
		table.wipe(self.inventoryItems);
	else
		self.inventoryItems = {};
	end

	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag);

		if numSlots ~= 0 then
			for slot = 1, numSlots do
				local itemId = GetContainerItemID(bag, slot);
				local link = GetContainerItemLink(bag, slot);

				self:AddItemToInventory(itemId, link, bag, slot);
			end
		end
	end
end

function AuctionFaster:AddItemToInventory(itemId, link, bag, slot)
	local canSell = false;

	if itemId == 82800 then
		canSell = true;
	else
		Gratuity:SetBagItem(bag, slot);

		local n = Gratuity:NumLines();
		local firstLine = Gratuity:GetLine(1);

		if not firstLine or strfind(tostring(firstLine), RETRIEVING_ITEM_INFO) then
			return false
		end

		for i = 1, n do
			local line = Gratuity:GetLine(i);

			if line then
				canSell = not (strfind(line, ITEM_BIND_ON_PICKUP) or strfind(line, ITEM_BIND_TO_BNETACCOUNT)
						or strfind(line, ITEM_BNETACCOUNTBOUND) or strfind(line, ITEM_SOULBOUND)
						or strfind(line, ITEM_BIND_QUEST) or strfind(line, ITEM_CONJURED));
				print(line, canSell);

				if strfind(line, USE_COLON) then
					break;
				end
			end

			if not canSell then
				return false;
			end
		end
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
	itemSubType, itemStackCount, _, _, itemSellPrice = GetItemInfo(link);

	local itemIcon = GetItemIcon(itemId);

	tinsert(self.inventoryItems, {
		icon = itemIcon,
		count = itemStackCount,
		name = itemName,
		link = itemLink,
		price = itemSellPrice or 0
	});
end

function AuctionFaster:FormatMoney(money)

	local money = tonumber(money)

	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(money % COPPER_PER_SILVER)

	local output = '';

	if gold > 0 then
		output = format('%s%s ', color .. gold .. '|r', 'g')
	end

	if gold > 0 or silver > 0 then
		output = format('%s%s%s ', output, color .. silver .. '|r', 's')
	end

	output = format('%s%s%s ', output, color .. copper .. '|r', 'c')

	return output:trim();
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	self:AddAuctionHouseTab();
end

function AuctionFaster:BAG_UPDATE_DELAYED()
end