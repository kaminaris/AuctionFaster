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

function AuctionFaster:UpdateItemInventory(itemId, itemName)
	local totalQty = 0;

	local index = false;
	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.name == itemName then
			index = i;
			totalQty = ii.count + totalQty;
			break;
		end
	end

	if index then
		self.inventoryItems[index].count = totalQty;
	end

	return totalQty;
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
		local scanPrice = self:GetLowestPrice(itemId, itemName);
		if not scanPrice then
			scanPrice = '---';
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

	-- update the UI
	self:UpdateItemsTabPrice(itemId, itemName, newPrice);
end


function AuctionFaster:BAG_UPDATE_DELAYED()
	self:ScanInventory();
end

AuctionFaster.freeInventorySlot = { bag = 0, slot = 1 };
function AuctionFaster:FindFirstFreeInventorySlot()
	local itemId = GetContainerItemID(self.freeInventorySlot.bag, self.freeInventorySlot.slot);
	if not itemId then
		return self.freeInventorySlot.bag, self.freeInventorySlot.slot;
	end

	-- cached free slot is not available anymore, find another one
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot);
			if not itemId then
				self.freeInventorySlot = { bag = bag, slot = slot };
				return bag, slot;
			end
		end
	end

	return nil, nil;
end

function AuctionFaster:GetItemFromInventory(id, name, qty)
	local firstBag, firstSlot, remainingQty;

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot);
			if itemId then
				local link = GetContainerItemLink(bag, slot);
				local _, count = GetContainerItemInfo(bag, slot);
				local itemName, _, _, _, _, _, _, itemStackCount = GetItemInfo(link);

				if id == itemId and name == itemName then
					return bag, slot;
				end
			end
		end
	end

	return nil, nil;
end

function AuctionFaster:GetInventoryItemQuantity(itemId, itemName)
	local qty = 0;

	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.name == itemName then
			found = true;
			qty = qty + self.inventoryItems[i].count;
			break;
		end
	end

	return qty;
end

--
--function AuctionFaster:GetItemFromInventory(id, name, qty)
--	local firstBag, firstSlot, remainingQty;
--
--	for bag = 0, 4 do
--		for slot = 1, GetContainerNumSlots(bag) do
--			local itemId = GetContainerItemID(bag, slot);
--			local link = GetContainerItemLink(bag, slot);
--			local _, count = GetContainerItemInfo(bag, slot);
--			local itemName, _, _, _, _, _, _, itemStackCount = GetItemInfo(link);
--
--			if id == itemId and name == itemName then
--				if qty > itemStackCount then
--					-- Not possible to stack this item as requested quantity
--					return nil, nil, false;
--				end
--
--				if qty == count then
--					-- full stack or equals the quantity, no need to split anything
--					return bag, slot, true;
--				else
--					if firstBag and firstSlot then
--						-- we already found item previously
--						if count >= remainingQty then
--							-- this stack will suffice
--							PickupContainerItem(bag, slot);
--							SplitContainerItem(bag, slot, remainingQty);
--						else
--							-- we should merge it to first one and keep going
--						end
--					else
--						-- this is just first stack
--						firstBag = bag;
--						firstSlot = slot;
--						remainingQty = qty - count;
--					end
--				end
--			end
--		end
--	end
--
--	-- Item not found or
--	return nil, nil;
--end