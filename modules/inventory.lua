---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
local Gratuity = LibStub('LibGratuity-3.0');
---@type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
---@class Inventory
local Inventory = AuctionFaster:NewModule('Inventory', 'AceEvent-3.0');

local battlePetId = 82800;

--- Enable is a must so we know when AH has been closed or opened, all events are handled in this module
function Inventory:OnEnable()
	self.inventoryItems = {};
	self:RegisterEvent('AUCTION_HOUSE_CLOSED');
	self:RegisterEvent('AUCTION_HOUSE_SHOW');
end

function Inventory:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('BAG_UPDATE_DELAYED');
end

function Inventory:AUCTION_HOUSE_CLOSED()
	self:UnregisterEvent('BAG_UPDATE_DELAYED');
end

function Inventory:BAG_UPDATE_DELAYED()
	self:ScanInventory();
end

function Inventory:ScanInventory()
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

	self:SendMessage('AFTER_INVENTORY_SCAN', self.inventoryItems);
end

function Inventory:UpdateItemInventory(itemId, itemName)
	local totalQty = 0;

	local index = false;
	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.itemName == itemName then
			index = i;
			totalQty = ii.count + totalQty;
			break ;
		end
	end

	if index then
		self.inventoryItems[index].count = totalQty;
	end

	return totalQty;
end

function Inventory:AddItemToInventory(itemId, count, link, bag, slot)
	local canSell = false;

	if itemId == battlePetId then
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
					break ;
				end
			end

			if not canSell then
				return false;
			end
		end
	end

	local itemName, itemIcon, itemStackCount, additionalInfo, quality, level;

	if itemId == battlePetId then
		local n, icon, speciesId, petLevel, breedQuality = AuctionFaster:ParseBattlePetLink(link);
		itemName = n;
		quality = breedQuality;
		itemIcon = icon;
		level = petLevel;
		itemStackCount = 1;
	else
		local n, _, q, _, _, _, _, c, _, _, itemSellPrice = GetItemInfo(link);
		level = GetDetailedItemLevelInfo(link);

		itemName = n;
		itemStackCount = c;
		quality = q;
		itemIcon = GetItemIcon(itemId);
	end


	local found = false;
	-- don't stack battle pets
	if itemId ~= battlePetId then
		for i = 1, #self.inventoryItems do
			local ii = self.inventoryItems[i];
			if ii.itemId == itemId and ii.itemName == itemName then
				found = true;
				self.inventoryItems[i].count = self.inventoryItems[i].count + count;
				break ;
			end
		end
	end

	if not found then
		local scanPrice = ItemCache:GetLastScanPrice(itemId, itemName);
		if not scanPrice then
			scanPrice = '---';
		end

		tinsert(self.inventoryItems, {
			itemName       = itemName,
			link           = link,
			quality        = quality,
			level          = level,
			count          = count,
			maxStackSize   = itemStackCount,
			icon           = itemIcon,
			additionalInfo = additionalInfo,
			itemId         = itemId,
			price          = scanPrice
		});
	end
end

function Inventory:UpdateInventoryItemPrice(itemId, itemName, newPrice)
	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.itemName == itemName then
			self.inventoryItems[i].price = newPrice;
			break ;
		end
	end
end

function Inventory:GetItemFromInventory(itemId, itemName, itemQuality, itemLevel)
	local firstBag, firstSlot, remainingQty;

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot);
			if id then
				local link = GetContainerItemLink(bag, slot);
				local _, count = GetContainerItemInfo(bag, slot);

				if id == battlePetId then
					local name, icon, speciesId, petLevel, breedQuality = AuctionFaster:ParseBattlePetLink(link);
					if id == itemId and
						name == itemName and
						breedQuality == itemQuality and
						petLevel == itemLevel
					then
						return bag, slot;
					end
				else
					local name, _, quality, _, _, _, _, itemStackCount = GetItemInfo(link);
					local level = GetDetailedItemLevelInfo(link);
					if id == itemId and
						name == itemName and
						quality == itemQuality and
						level == itemLevel
					then
						return bag, slot;
					end
				end
			end
		end
	end

	return nil, nil;
end

function Inventory:GetInventoryItemQuantity(itemId, itemName)
	local qty = 0;

	for i = 1, #self.inventoryItems do
		local ii = self.inventoryItems[i];
		if ii.itemId == itemId and ii.name == itemName then
			found = true;
			qty = qty + self.inventoryItems[i].count;
			break ;
		end
	end

	return qty;
end


--AuctionFaster.freeInventorySlot = { bag = 0, slot = 1 };
--function AuctionFaster:FindFirstFreeInventorySlot()
--	local itemId = GetContainerItemID(self.freeInventorySlot.bag, self.freeInventorySlot.slot);
--	if not itemId then
--		return self.freeInventorySlot.bag, self.freeInventorySlot.slot;
--	end
--
--	-- cached free slot is not available anymore, find another one
--	for bag = 0, 4 do
--		for slot = 1, GetContainerNumSlots(bag) do
--			local itemId = GetContainerItemID(bag, slot);
--			if not itemId then
--				self.freeInventorySlot = { bag = bag, slot = slot };
--				return bag, slot;
--			end
--		end
--	end
--
--	return nil, nil;
--end

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