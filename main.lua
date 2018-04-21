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
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');
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

	self:ScanInventory();
	--self:UpdateInventoryTable();
	self:DrawItemsFrame(auctionTab);
	self:DrawRightPane(auctionTab);
	self:DrawTabButtons();

	self:Hook('AuctionFrameTab_OnClick', true);
end

function AuctionFaster:DrawItemsFrame(auctionTab)
	local scrollFrame, scrollChild = StdUi:ScrollFrame(auctionTab, 'AFLeftScroll', 300, 300);
	scrollFrame:SetPoint('TOPLEFT', 5, -25);
	scrollFrame:SetPoint('BOTTOMLEFT', 300, 35);

	auctionTab.scrollFrame = scrollFrame;
	auctionTab.scrollChild = scrollChild;

	self:DrawItems(scrollChild);

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

		local holdingFrame = StdUi:Button(scrollChild, scrollChild:GetWidth(), lineHeight, nil, false, true, false);
		holdingFrame.highlightTexture:SetColorTexture(1, 0.9, 0, 0.5);
		holdingFrame:SetPoint('TOPLEFT', 0, -(i - 1) * lineHeight);
		holdingFrame.itemLink = self.inventoryItems[i].link;
		holdingFrame.itemIndex = i;

		holdingFrame:EnableMouse();
		holdingFrame:RegisterForClicks('AnyUp');
		holdingFrame:SetScript('OnEnter', function(self)
			AuctionFaster:ShowTooltip(self, self.itemLink, true);
		end)
		holdingFrame:SetScript('OnLeave', function(self)
			AuctionFaster:ShowTooltip(self, nil, false);
		end)
		holdingFrame:SetScript('OnClick', function(self)
			AuctionFaster:SelectItem(self.itemIndex);
		end)

		local texx = StdUi:Texture(holdingFrame, lineHeight - 2, lineHeight - 2, self.inventoryItems[i].icon);
		texx:SetPoint('TOPLEFT', holdingFrame, 1, -1)

		local name = StdUi:Label(holdingFrame, nil, self.inventoryItems[i].name, nil, 150, 20);
		name:SetPoint('TOPLEFT', 35, -5);

		local price = StdUi:Label(holdingFrame, nil, AuctionFaster:FormatMoney(self.inventoryItems[i].price), nil, 80, 20);
		price:SetJustifyH('RIGHT');
		price:SetPoint('TOPRIGHT', 0, -5);
	end
end

function AuctionFaster:SelectItem(index)
	local auctionTab = self.auctionTab;
	self.selectedItem = self.inventoryItems[index];

	auctionTab.itemIcon:SetTexture(self.selectedItem.icon);
	auctionTab.itemName:SetText(self.selectedItem.name);
	auctionTab.itemQty:SetText('Qty: ' .. self.selectedItem.count);

	self:GetCurrentAuctions();
end

function AuctionFaster:DrawRightPane(auctionTab)
	local leftMargin = 340;
	local iconSize = 48;

	local rightMargin = leftMargin + 200;

	auctionTab.itemIcon = StdUi:Texture(auctionTab, iconSize, iconSize, '');
	auctionTab.itemIcon:SetPoint('TOPLEFT', leftMargin, -25)

	auctionTab.itemName = StdUi:Label(auctionTab, 16, 'No item selected', nil, 300, 20);
	auctionTab.itemName:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -25);

	auctionTab.itemQty = StdUi:Label(auctionTab, 14, 'Qty: O', nil, 300, 20);
	auctionTab.itemQty:SetPoint('TOPLEFT', leftMargin + iconSize + 5, -45);


	-- Bid per item edit box
	auctionTab.bidPerItem = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '10g 6s 6c',
		'Bid Per Item', nil, 'TOP');
	StdUi:GlueBelow(auctionTab.bidPerItem, auctionTab.itemIcon, 0, -25);

	-- Buy per item edit box
	auctionTab.buyPerItem = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '12g 10s 10c',
		'Buy Per Item', nil, 'TOP');
	StdUi:GlueBelow(auctionTab.buyPerItem, auctionTab.bidPerItem, 0, -25);


	-- Stack Size
	auctionTab.stackSize = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '1',
		'Stack Size (Max: 20)', nil, 'TOP');
	auctionTab.stackSize:SetNumeric(true);
	StdUi:GlueRight(auctionTab.stackSize, auctionTab.bidPerItem, 120, 0);

	auctionTab.maxStacks = StdUi:EditBoxWithLabel(auctionTab, 150, 20, '-1',
		'Limit of stacks (-1 means everything)', nil, 'TOP');
	auctionTab.maxStacks:SetNumeric(true);
	StdUi:GlueRight(auctionTab.maxStacks, auctionTab.buyPerItem, 120, 0);

	self:DrawRightPaneCurrentAuctionsTable();
end

function AuctionFaster:DrawTabButtons()
	local auctionTab = self.auctionTab;

	auctionTab.postButton = StdUi:PanelButton(auctionTab, 60, 20, 'Post All');
	auctionTab.postButton:SetPoint('BOTTOMRIGHT', -5, 5)

	auctionTab.postOneButton = StdUi:PanelButton(auctionTab, 60, 20, 'Post One');
	StdUi:GlueLeft(auctionTab.postOneButton, auctionTab.postButton, 5);

	auctionTab.buyItemButton = StdUi:PanelButton(auctionTab, 60, 20, 'Buy Item');
	StdUi:GlueLeft(auctionTab.buyItemButton, auctionTab.postOneButton, 5);
end

function AuctionFaster:DrawRightPaneCurrentAuctionsTable()
	local auctionTab = self.auctionTab;


	local cols = {
		{
			['name'] = 'Seller',
			['width'] = 150,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Qty',
			['width'] = 40,
			['align'] = 'LEFT',
		},

		{
			['name'] = 'Bid',
			['width'] = 120,
			['align'] = 'RIGHT',
		},

		{
			['name'] = 'Buy',
			['width'] = 120,
			['align'] = 'RIGHT',
		},
	}

	local leftMargin = 340;
	auctionTab.currentAuctions = ScrollingTable:CreateST(cols, 12, 18, nil, auctionTab);
	auctionTab.currentAuctions.frame:SetPoint('TOPLEFT', leftMargin, -200);
	auctionTab.currentAuctions.frame:SetPoint('BOTTOMRIGHT', 0, 25);
end

function AuctionFaster:AuctionFrameTab_OnClick(tab)
	if tab.auctionFaster then
		self.auctionTab:Show();
	else
		self.auctionTab:Hide();
	end
end

function AuctionFaster:GetCurrentAuctions()
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local name = selectedItem.name;

	if not CanSendAuctionQuery() then
		print('cant wut');
		return;
	end

	local result = QueryAuctionItems(name, nil, nil, 0, 0, 0, false, true);
end

function AuctionFaster:AUCTION_ITEM_LIST_UPDATE()

	local shown, total = GetNumAuctionItems('list');

	local tableData = {};
	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		tinsert(tableData, {
			owner,
			count,
			GetMoneyString(floor(minBid / count)),
			GetMoneyString(floor(buyoutPrice / count)),
		});
	end

	self.auctionTab.currentAuctions:SetData(tableData, true);
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
				local _, count = GetContainerItemInfo(bag, slot);

				self:AddItemToInventory(itemId, count, link, bag, slot);
			end
		end
	end
end

function AuctionFaster:AddItemToInventory(itemId, count, link, bag, slot)
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

	local found = false;
	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.name == itemName then
			found = true;
			self.inventoryItems[i].count = self.inventoryItems[i].count + count;
			break;
		end
	end

	if not found then
		tinsert(self.inventoryItems, {
			icon = itemIcon,
			count = count,
			maxStack = itemStackCount,
			name = itemName,
			link = itemLink,
			itemId = itemId,
			price = itemSellPrice or 0
		});
	end
end

function AuctionFaster:FormatMoney(money)

	local money = tonumber(money);
	local goldColor = '|cfffff209';
	local silverColor = '|cff7b7b7a';
	local copperColor = '|cffac7248';

	local gold = floor(money / COPPER_PER_GOLD);
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = floor(money % COPPER_PER_SILVER);

	local output = '';

	if gold > 0 then
		output = format('%s%s ', goldColor .. gold .. '|r', 'g')
	end

	if gold > 0 or silver > 0 then
		output = format('%s%s%s ', output, silverColor .. silver .. '|r', 's')
	end

	output = format('%s%s%s ', output, copperColor .. copper .. '|r', 'c')

	return output:trim();
end

function AuctionFaster:AUCTION_HOUSE_SHOW()
	self:AddAuctionHouseTab();
end

function AuctionFaster:BAG_UPDATE_DELAYED()
end