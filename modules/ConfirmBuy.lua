---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local C_AuctionHouse = C_AuctionHouse;
local format = string.format;

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @class ConfirmBuy
local ConfirmBuy = AuctionFaster:NewModule('ConfirmBuy', 'AceEvent-3.0', 'AceTimer-3.0');

function ConfirmBuy:OnEnable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
end

function ConfirmBuy:OnDisable()
	self:UnregisterEvent('AUCTION_HOUSE_CLOSED');
	self:UnregisterEvent('AUCTION_HOUSE_SHOW');
end

function ConfirmBuy:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:RegisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
	--self:RegisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
end

function ConfirmBuy:AUCTION_HOUSE_CLOSED()
	if self.window then
		self.window:Hide();
	end

	self:UnregisterEvent('COMMODITY_SEARCH_RESULTS_UPDATED');
	self:UnregisterEvent('ITEM_SEARCH_RESULTS_UPDATED');
	--self:UnregisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED');
end

function ConfirmBuy:COMMODITY_PURCHASE_SUCCEEDED()
	if not self.window then
		return ;
	end

	self:RefreshAuctions();
end

function ConfirmBuy:COMMODITY_SEARCH_RESULTS_UPDATED(_, itemId)
	local items = Auctions:ScanCommodityResults(itemId);
	self:SetItems(items);
end

function ConfirmBuy:ITEM_SEARCH_RESULTS_UPDATED(_, itemKey)
	local items = Auctions:ScanItemResults(itemKey);
	self:SetItems(items);
end

function ConfirmBuy:RefreshAuctions()
	Auctions:QueryItem(self.itemKey);
end

function ConfirmBuy:EnableBuyButtonTimeout()
	self.window.buy:Enable();
end

function ConfirmBuy:ConfirmPurchase(itemKey, isCommodity)
	local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(itemKey);

	self.isCommodity = isCommodity;
	self.itemKey = itemKey;
	self.itemKeyInfo = itemKeyInfo;
	self.items = {};
	self.boughtSoFar = 0;
	self.itemsReady = false;

	self:CreateUpdateWindow();
	self.window:Show();
	self.window.buy:Disable();

	Auctions:QueryItem(itemKey);
end

function ConfirmBuy:SetItems(items)
	if not self.window or not self.window:IsVisible() then
		return;
	end

	self.items = items;
	self.itemsReady = true;
	self.window.searchResults:SetData(items, true);
	self:UpdatePrices();
end

function ConfirmBuy:CreateUpdateWindow()
	if not self.window then
		local window = StdUi:Window(UIParent, 600, 500, 'Confirm Buy');
		window:SetPoint('LEFT', AuctionHouseFrame, 'RIGHT', 100, 0);

		window.itemIcon = StdUi:Texture(window, 32, 32, '');
		window.itemName = StdUi:Label(window, '', 14);

		window.qty = StdUi:Label(window, L['Qty'], 18);
		window.qtyBox = StdUi:SimpleEditBox(window, 100, 40, 1);
		window.qtyBox:SetNumeric(true);
		window.qtyBox:SetFontSize(18);
		window.qtyBox:SetJustifyH('CENTER');
		window.buy = StdUi:Button(window, 100, 40, L['Buy']);
		window.buy:SetFontSize(18);

		window.pricePerItem = StdUi:Label(window, '', 14);
		window.priceTotal = StdUi:Label(window, '', 14);
		window.boughtSoFar = StdUi:Label(window, '', 14);

		local cols = {
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
				width    = 280,
				align    = 'LEFT',
				index    = 'itemLink',
				format   = 'string',
				sortable = false,
			},
			{
				name     = L['Qty'],
				width    = 60,
				align    = 'LEFT',
				index    = 'count',
				format   = 'number',
				sortable = false,
			},
			{
				name     = L['Buy'],
				width    = 140,
				align    = 'RIGHT',
				index    = 'buy',
				format   = 'moneyShort',
				sortable = false,
			},
		}

		window.searchResults = StdUi:ScrollTable(window, cols, 8, 16);
		window.searchResults:RegisterEvents({
			OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				if self.isCommodity then return true end ;
				table:SetHighLightColor(rowFrame, table.stdUi.config.highlight.color);
				return true;
			end,

			OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				if self.isCommodity then return true end ;
				if rowIndex ~= table.selected or not table.selectionEnabled then
					table:SetHighLightColor(rowFrame, nil);
				end

				return true;
			end,

			OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
				if self.isCommodity then return true end ;
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

		StdUi:GlueTop(window.pricePerItem, window, 20, -90, 'LEFT');
		StdUi:GlueRight(window.priceTotal, window.pricePerItem, 20, 0);
		StdUi:GlueRight(window.boughtSoFar, window.priceTotal, 20, 0);

		window.qtyBox:SetScript('OnTextChanged', function(self, isUserInput)
			ConfirmBuy:UpdatePrices();
		end);

		window.buy:SetScript('OnClick', function()
			window.buy:Disable();
			if self.isCommodity then
				local qty = ConfirmBuy.window.qtyBox:GetText();
				if qty == nil then
					qty = 0;
				end

				qty = tonumber(qty);
				if qty > 0 then
					Auctions:BuyCommodity(ConfirmBuy.itemKey.itemID, qty); --, self.lowestPrice
					self:ScheduleTimer('EnableBuyButtonTimeout', 2);
				end
			else
				local item = self.window.searchResults:GetSelectedItem();
				Auctions:BuyItem(item);
				self:ScheduleTimer('RefreshAuctions', 0.7);
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

	local qty = self.window.qtyBox:GetText();
	if qty == nil then
		qty = 0;
	end
	qty = tonumber(qty);

	if not qty or qty <= 0 then
		self.window.buy:Disable();
		return ;
	end

	self.window.buy:Enable();

	local total = 0;
	local qtyLeft = qty;
	local rowsToHighlight = {};
	self.lowestPrice = nil;
	for idx, item in pairs(self.items) do
		if not self.lowestPrice then
			self.lowestPrice = item.buy;
		end

		if qtyLeft == 0 then
			break ;
		end

		if item.count > qtyLeft then
			total = total + (qtyLeft * item.buy);
			qtyLeft = 0;
		else
			total = total + (item.count * item.buy);
			qtyLeft = qtyLeft - item.count;
		end
		tinsert(rowsToHighlight, idx);

		if qtyLeft == 0 then
			break ;
		end
	end

	self.window.searchResults:HighlightRows(rowsToHighlight);

	if qtyLeft > 0 then
		--AuctionFaster:Print('Not enough quantity on market');
		self.window.buy:Disable();
	end

	local perItem = qty > 0 and total / qty or 0;

	self.window.pricePerItem:SetText(format(L['Per Item: %s'], StdUi.Util.formatMoney(perItem, true)));
	self.window.priceTotal:SetText(format(L['Total: %s'], StdUi.Util.formatMoney(total, true)));
	self.window.boughtSoFar:SetText(format(L['Bought so far: %d'], self.boughtSoFar));
end
