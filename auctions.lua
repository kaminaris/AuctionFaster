--- @type StdUi
local StdUi = LibStub('StdUi');

function AuctionFaster:AUCTION_MULTISELL_UPDATE(_, current, max)
	if current == max then
		C_Timer.After(0.5, function()
			AuctionFaster:CheckEverythingSold();
		end);
	end
end

--- Check if all items has been sold, if not, propose to sell last incomplete stack
function AuctionFaster:CheckEverythingSold()
	local sellSettings = self:GetSellSettings();

	--- DISABLED FOR TEST
	--if sellSettings.realMaxStacks ~= 0 then
	--	return;
	--end

	local selectedItem = self.selectedItem;
	if not selectedItem then
		return ;
	end

	local itemId, itemName = selectedItem.itemId, selectedItem.itemName;

	local currentItemName = GetAuctionSellItemInfo();

	if not currentItemName or currentItemName ~= itemName then
		self:PutItemInSellBox(itemId, itemName);
	end

	local qtyLeft = self:UpdateItemInventory(itemId, itemName);

	if qtyLeft == 0 then
		return ;
	end

	self:UpdateItemQtyText();
	self:GetCurrentAuctions();
	self:DrawItems();

	local btns = {
		yes = {
			text    = 'Yes',
			onClick = function(self)
				-- todo: make it
				self:GetParent():Hide();
			end,
		},
		no  = {
			text    = 'No',
			onClick = function(self)
				self:GetParent():Hide();
			end,
		}
	}

	StdUi:Confirm('Incomplete sell', 'You still have ' .. qtyLeft .. ' of ' .. itemName ..
			' Do you wish to sell rest?', btns, 'incomplete_sell');
end


function AuctionFaster:GetCurrentAuctions(force)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	local cacheItem = self:GetItemFromCache(itemId, itemName);
	-- We still have pretty recent results from auction house, no need to scan again
	if not force and cacheItem and cacheItem.auctions and #cacheItem.auctions > 0 then
		self:UpdateAuctionTable(cacheItem);
		self:UpdateInfoPaneText();
		return ;
	end

	if not CanSendAuctionQuery() then
		StdUi:Dialog('Error', 'Cannot query auction house, please reload UI', 'AFError');
		return ;
	end

	self.currentlySorting = true;
	SortAuctionItems('list', 'buyout')
	if IsAuctionSortReversed('list', 'buyout') then
		SortAuctionItems('list', 'buyout')
	end
	self.currentlySorting = false;

	self.currentlyQuerying = true;
	self.afScan = true;
	QueryAuctionItems(itemName, nil, nil, 0, 0, 0, false, true);
	self.currentlyQuerying = false;
end

function AuctionFaster:AUCTION_ITEM_LIST_UPDATE()
	if self.currentlySorting or not self.afScan then
		return ;
	end

	local selectedId, selectedName = self:GetSelectedItemIdName();

	if not selectedId then
		-- Not our scan, ignore it
		return ;
	end ;

	local shown, total = GetNumAuctionItems('list');

	-- since we did scan anyway, put it in cache
	local cacheKey;

	local auctions = {}
	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		-- this function runs for every AH scan so make sure to ignore it if item does not match selected one
		if name == selectedName and itemId == selectedId then
			if not cacheKey then
				cacheKey = itemId .. name;
			end

			tinsert(auctions, {
				owner    = owner,
				count    = count,
				itemId   = itemId,
				itemName = name,
				bid      = floor(minBid / count),
				buy      = floor(buyoutPrice / count),
			});
		end
	end

	-- we skip any auctions that are not the same as selected item so no problem
	local cacheItem = self:FindOrCreateCacheItem(selectedId, selectedName);

	table.sort(auctions, function(a, b)
		return a.buy < b.buy;
	end);

	cacheItem.scanTime = GetServerTime();
	cacheItem.auctions = auctions;
	cacheItem.totalItems = #auctions;

	self:UpdateAuctionTable(cacheItem);
	self:UpdateInfoPaneText();

	-- no longer our scan
	self.afScan = false;
end



function AuctionFaster:UpdateAuctionTable(cacheItem)
	self.auctionTab.currentAuctions:SetData(cacheItem.auctions, true);
	self.auctionTab.lastScan:SetText('Last Scan: ' .. self:FormatDuration(GetServerTime() - cacheItem.scanTime));

	local minBid, minBuy = self:FindLowestBidBuy(cacheItem);

	if cacheItem.settings.alwaysUndercut then
		self:UnderCutPrices(cacheItem, minBid, minBuy);
	elseif cacheItem.settings.rememberLastPrice then
		self:UpdateTabPrices(cacheItem.bid, cacheItem.buy);
	end

	self:UpdateInventoryItemPrice(cacheItem.itemId, cacheItem.itemName, minBuy);
end

function AuctionFaster:UnderCutPrices(cacheItem, lowestBid, lowestBuy)
	if #cacheItem.auctions < 1 then
		return ;
	end

	if not lowestBid or not lowestBuy then
		lowestBid, lowestBuy = self:FindLowestBidBuy(cacheItem);
	end

	cacheItem.bid = lowestBid - 1;
	cacheItem.buy = lowestBuy - 1;

	self:UpdateTabPrices(lowestBid - 1, lowestBuy - 1);
end

function AuctionFaster:GetLowestPrice(itemId, itemName)
	local cacheKey = itemId .. itemName;

	if not self.db.global.auctionDb[cacheKey] then
		return nil, nil;
	end

	local cacheItem = self.db.global.auctionDb[cacheKey];

	return self:FindLowestBidBuy(cacheItem);
end

function AuctionFaster:FindLowestBidBuy(cacheItem)
	if #cacheItem.auctions < 1 then
		return nil, nil;
	end

	local lowestBid, lowestBuy;
	for i = 1, #cacheItem.auctions do
		local auc = cacheItem.auctions[i];
		if auc.bid > 0 and (not lowestBid or lowestBid > auc.bid) then
			lowestBid = auc.bid;
		end

		if auc.buy > 0 and (not lowestBuy or lowestBuy > auc.buy) then
			lowestBuy = auc.buy;
		end
	end

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy - 1;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid + 1;
	end

	return lowestBid, lowestBuy;
end

function AuctionFaster:PutItemInSellBox(itemId, itemName)
	local currentItemName = GetAuctionSellItemInfo();
	if currentItemName and currentItemName == itemName then
		return true;
	end

	local bag, slot = self:GetItemFromInventory(itemId, itemName);
	if not bag or not slot then
		return false;
	end

	PickupContainerItem(bag, slot);
	if not CursorHasItem() then
		return false;
	end

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = 2;
	end

	-- This only puts item in sell slot despite name
	ClickAuctionSellItemButton();
	ClearCursor();

	return true;
end

function AuctionFaster:CalculateDeposit(itemId, itemName)
	local sellSettings = self:GetSellSettings();
	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = sellSettings.duration;
	end

	if not self:PutItemInSellBox(itemId, itemName) then
		return 0;
	end

	return CalculateAuctionDeposit(sellSettings.duration);
end

function AuctionFaster:SellItem(singleStack)
	local selectedItem = self.selectedItem;
	local itemId = selectedItem.itemId;
	local itemName = selectedItem.itemName;

	if not self:PutItemInSellBox(itemId, itemName) then
		return false;
	end

	local sellSettings = self:GetSellSettings();

	if not AuctionFrameAuctions.duration then
		AuctionFrameAuctions.duration = sellSettings.duration;
	end

	local maxStacks = sellSettings.maxStacks;
	if singleStack then
		maxStacks = 1;
	end

	StartAuction(sellSettings.bidPerItem * sellSettings.stackSize,
			sellSettings.buyPerItem * sellSettings.stackSize,
			sellSettings.duration,
			sellSettings.stackSize,
			maxStacks);

	return true;
end

function AuctionFaster:BuyItem()
	local selectedId, selectedName = self:GetSelectedItemIdName();
	if not selectedId then
		return ;
	end

	local index = self.auctionTab.currentAuctions:GetSelection();
	if not index then
		return ;
	end
	local auctionData = self.auctionTab.currentAuctions:GetRow(index);

	-- maybe index is the same
	local name, texture, count, quality, canUse, level, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', index);

	local bid = floor(minBid / count);
	local buy = floor(buyoutPrice / count);

	if name == auctionData.itemName and itemId == auctionData.itemId and owner == auctionData.owner
			and bid == auctionData.bid and buy == auctionData.buy and count == auctionData.count then
		-- same index, we can buy it
		self:BuyItemByIndex(index);
		-- we need to refresh the auctions
		self:GetCurrentAuctions();
	end

	-- item was not found but lets check if it still exists
	-- todo: need to check it
end

function AuctionFaster:BuyItemByIndex(index)
	local buyPrice = select(10, GetAuctionItemInfo('list', index))

	PlaceAuctionBid('list', index, buyPrice)
	CloseAuctionStaticPopups();
end