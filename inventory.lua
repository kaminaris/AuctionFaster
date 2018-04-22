local Gratuity = LibStub('LibGratuity-3.0');

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

	self:DrawItems();
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

	local itemName, itemLink, _, _, _, _, _, itemStackCount, _, _, itemSellPrice = GetItemInfo(link);
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
		local cacheKey = itemId .. itemName;
		local scanPrice = '---';
		if (AuctionFaster.auctionDb[cacheKey]) then
			scanPrice = AuctionFaster.auctionDb[cacheKey].auctions[1][4];
		end

		tinsert(self.inventoryItems, {
			icon = itemIcon,
			count = count,
			maxStack = itemStackCount,
			name = itemName,
			link = itemLink,
			itemId = itemId,
			price = scanPrice
		});
	end
end

function AuctionFaster:UpdateInventoryItemPrice(itemId, itemName, newPrice)
	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.name == itemName then
			self.inventoryItems[i].price = newPrice;
			break;
		end
	end

	self:DrawItems();
end


function AuctionFaster:BAG_UPDATE_DELAYED()
	self:ScanInventory();
end