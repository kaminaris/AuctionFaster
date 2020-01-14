---@type AuctionFaster
local AuctionFaster  = unpack(select(2, ...));
--- @type StdUi
local StdUi          = LibStub('StdUi');
local L              = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local C_AuctionHouse = C_AuctionHouse;
local format         = string.format;

--- @type Auctions
local Auctions       = AuctionFaster:GetModule('Auctions');

--- @class ConfirmBuy
local ConfirmBuy     = AuctionFaster:NewModule('ConfirmBuy', 'AceEvent-3.0', 'AceTimer-3.0');

function ConfirmBuy:Enable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('COMMODITY_PRICE_UPDATED');
end

function ConfirmBuy:AUCTION_HOUSE_CLOSED()
	if self.window then
		self.window:Hide();
	end
end

function ConfirmBuy:COMMODITY_PRICE_UPDATED()
	if not self.window then
		return ;
	end

	Auctions:QueryItem(self.itemKey, function(items)
		print('did we?')
		self:SetItems(items);
		self.window.buy:Enable();
	end);
	--
	--local items = Auctions:FetchCommodityResults(self.itemKey.itemID);
	--print('NEW ITEMS:', #items)
	--self:SetItems(items);
end

function ConfirmBuy:ConfirmPurchase(itemKey, isCommodity)
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);

	self.isCommodity  = isCommodity;
	self.itemKey      = itemKey;
	self.itemKeyInfo  = itemKeyInfo;
	self.items        = {};
	self.boughtSoFar  = 0;
	self.itemsReady   = false;

	self:CreateUpdateWindow();
	self.window:Show();
	self.window.buy:Disable();

	Auctions:QueryItem(itemKey, function(items)
		ConfirmBuy:SetItems(items);
	end)
end

function ConfirmBuy:SetItems(items)
	self.items      = items;
	self.itemsReady = true;
	self.window.searchResults:SetData(items, true);
	self:UpdatePrices();
end

function ConfirmBuy:CreateUpdateWindow()
	if not self.window then
		local window = StdUi:Window(UIParent, 400, 300, 'Confirm Buy');
		window:SetPoint('CENTER');

		window.itemIcon      = StdUi:Texture(window, 32, 32, '');
		window.itemName      = StdUi:Label(window, '', 14);

		window.qty           = StdUi:Label(window, L['Qty'], 14);
		window.qtyBox        = StdUi:EditBox(window, 100, 20, 0, StdUi.Util.numericBoxValidator);
		window.buy           = StdUi:Button(window, 60, 20, L['Buy']);

		window.pricePerItem  = StdUi:Label(window, '', 12);
		window.priceTotal    = StdUi:Label(window, '', 12);
		window.boughtSoFar   = StdUi:Label(window, '', 12);

		local cols           = {
			{
				name     = '',
				width    = 16,
				align    = 'LEFT',
				index    = 'texture',
				format   = 'icon',
				sortable = false,
			},
			{
				name     = L['Name'],
				width    = 150,
				align    = 'LEFT',
				index    = 'itemLink',
				format   = 'string',
				sortable = false,
			},
			{
				name     = L['Qty'],
				width    = 40,
				align    = 'LEFT',
				index    = 'count',
				format   = 'number',
				sortable = false,
			},
			{
				name     = L['Buy'],
				width    = 120,
				align    = 'RIGHT',
				index    = 'buy',
				format   = 'money',
				sortable = false,
			},
		}

		window.searchResults = StdUi:ScrollTable(window, cols, 8, 16);
		window.searchResults:RegisterEvents({
			OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				if self.isCommodity then return true end;
				table:SetHighLightColor(rowFrame, table.stdUi.config.highlight.color);
				return true;
			end,

			OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				if self.isCommodity then return true end;
				if rowIndex ~= table.selected or not table.selectionEnabled then
					table:SetHighLightColor(rowFrame, nil);
				end

				return true;
			end,

			OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
				if self.isCommodity then return true end;
				if button == 'LeftButton' then
					if table:GetSelection() == rowIndex then
						table:ClearSelection();
						self.window.buy:Disable();
					else
						table:SetSelection(rowIndex);
						self.window.buy:Enable();
					end

					return true;
				end
			end
		});

		StdUi:GlueAcross(window.searchResults, window, 10, -140, -10, 10);

		StdUi:GlueTop(window.itemIcon, window, 20, -40, 'LEFT');
		StdUi:GlueRight(window.itemName, window.itemIcon, 10, 0);

		StdUi:GlueTop(window.buy, window, -20, -40, 'RIGHT');
		StdUi:GlueLeft(window.qtyBox, window.buy, -10, 0);
		StdUi:GlueLeft(window.qty, window.qtyBox, -10, 0);

		StdUi:GlueTop(window.pricePerItem, window, 20, -80, 'LEFT');
		StdUi:GlueRight(window.priceTotal, window.pricePerItem, 20, 0);
		StdUi:GlueRight(window.boughtSoFar, window.priceTotal, 20, 0);

		window.qtyBox.OnValueChanged = function()
			ConfirmBuy:UpdatePrices();
		end

		window.buy:SetScript('OnClick', function()
			window.buy:Disable();
			if self.isCommodity then
				local qty = ConfirmBuy.window.qtyBox:GetValue();
				if qty == nil then
					qty = 0;
				end
				if qty > 0 then
					Auctions:BuyCommodity(ConfirmBuy.itemKey.itemID, qty);
				end
			else
				local item = self.window.searchResults:GetSelectedItem();
				Auctions:BuyItem(item);
			end

		end);

		self.window = window;
	end

	if self.isCommodity then
		self.window.qtyBox:Show();
		self.window.qty:Show();
		self.window.pricePerItem:Show();
		self.window.priceTotal:Show();
		self.window.boughtSoFar:Show();
	else
		self.window.qtyBox:Hide();
		self.window.qty:Hide();
		self.window.pricePerItem:Hide();
		self.window.priceTotal:Hide();
		self.window.boughtSoFar:Hide();
	end
	self.window.searchResults:EnableSelection(not self.isCommodity);

	self.window.itemName:SetText(self.itemKeyInfo.itemName);
	self.window.itemIcon:SetTexture(self.itemKeyInfo.iconFileID);

	self:UpdatePrices();
end

function ConfirmBuy:UpdatePrices()
	if not self.isCommodity then
		return ;
	end

	self.window.searchResults:ClearHighlightedRows();
	if not self.itemsReady then
		self.window.pricePerItem:SetText('');
		self.window.priceTotal:SetText('');
		self.window.boughtSoFar:SetText('');
		return ;
	end

	local qty = self.window.qtyBox:GetValue();
	if qty == nil then
		qty = 0;
	end

	if qty < 0 then
		self.window.buy:Disable();
		return ;
	end

	self.window.buy:Enable();

	local total           = 0;
	local qtyLeft         = qty;
	local rowsToHighlight = {};
	for idx, item in pairs(self.items) do
		if qtyLeft == 0 then
			break ;
		end

		if item.count > qtyLeft then
			total   = total + (qtyLeft * item.buy);
			qtyLeft = 0;
		else
			total   = total + (item.count * item.buy);
			qtyLeft = qtyLeft - item.count;
		end
		tinsert(rowsToHighlight, idx);

		if qtyLeft == 0 then
			break ;
		end
	end

	self.window.searchResults:HighlightRows(rowsToHighlight);

	if qtyLeft > 0 then
		AuctionFaster:Print('Not enough quantity on market');
		self.window.buy:Disable();
	end

	local perItem = qty > 0 and total / qty or 0;

	self.window.pricePerItem:SetText(format(L['Per Item: %s'], StdUi.Util.formatMoney(perItem)));
	self.window.priceTotal:SetText(format(L['Total: %s'], StdUi.Util.formatMoney(total)));
	self.window.boughtSoFar:SetText(format(L['Bought so far: %d'], self.boughtSoFar));
end
