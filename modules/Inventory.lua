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
				local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot);

				self:AddItemToInventory(itemLocation, bag, slot);
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

function Inventory:AddItemToInventory(itemLocation, bag, slot)
	if not itemLocation:IsValid() or C_Item.IsBound(itemLocation) then
		return false;
	end

	local canSell = C_AuctionHouse.IsSellItemValid(itemLocation);
	local itemId = C_Item.GetItemID(itemLocation);
	local link = C_Item.GetItemLink(itemLocation);
	local count = GetItemCount(link);

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
				canSell = not (
					strfind(line, ITEM_BIND_ON_PICKUP) or
						strfind(line, ITEM_BIND_TO_BNETACCOUNT) or
						strfind(line, ITEM_BNETACCOUNTBOUND) or
						strfind(line, ITEM_SOULBOUND) or
						strfind(line, ITEM_BIND_QUEST) or
						strfind(line, ITEM_CONJURED)
				);

				if strfind(line, USE_COLON) then
					break ;
				end
			end

			if not canSell then
				return false;
			end
		end
	end

	local itemName, itemIcon, additionalInfo, quality, level;

	local itemKey = C_AuctionHouse.GetItemKeyFromItem(itemLocation);
	local isCommodity = C_AuctionHouse.GetItemCommodityStatus(itemLocation) == 2;

	if itemId == battlePetId then
		local n, icon, speciesId, petLevel, breedQuality = AuctionFaster:ParseBattlePetLink(link);
		itemName = n;
		quality = breedQuality;
		itemIcon = icon;
		level = petLevel;
		count = 1;
	else

		level = C_Item.GetCurrentItemLevel(itemLocation);
		itemName = C_Item.GetItemName(itemLocation);
		quality = C_Item.GetItemQuality(itemLocation);
		itemIcon = C_Item.GetItemIcon(itemLocation);
	end

	local found = false;
	-- don't stack battle pets
	if itemId ~= battlePetId then
		for i = 1, #self.inventoryItems do
			local ii = self.inventoryItems[i];
			if self:ItemKeyEqual(ii.itemKey, itemKey) then
				found = true;
				break ;
			end
		end
	end

	if not found then
		local scanPrice = ItemCache:GetLastScanPrice(itemKey);
		if not scanPrice then
			scanPrice = '---';
		end

		tinsert(self.inventoryItems, {
			itemKey        = itemKey,
			itemLocation   = itemLocation,
			itemName       = itemName,
			isCommodity    = isCommodity,
			link           = link,
			quality        = quality,
			level          = level,
			count          = count,
			icon           = itemIcon,
			additionalInfo = additionalInfo,
			itemId         = itemId,
			price          = scanPrice
		});
	end
end

function Inventory:ItemKeyEqual(a, b)
	return a.itemID == b.itemID and
		a.itemLevel == b.itemLevel and
		a.itemSuffix == b.itemSuffix and
		a.battlePetSpeciesID == b.battlePetSpeciesID;
end

function Inventory:UpdateInventoryItemPrice(itemKey, newPrice)
	for _, ii in pairs(self.inventoryItems) do
		if self:ItemKeyEqual(ii.itemKey, itemKey) then
			ii.price = newPrice;
			break ;
		end
	end
end