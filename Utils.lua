---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

function AuctionFaster:FormatDuration(duration)
	if duration >= 172800 then
		return format('%.1f %s', duration/86400, L['days ago'])
	elseif duration >= 7200 then
		return format('%.1f %s', duration/3600, L['hours ago'] )
	elseif duration <= 60 then
		return '0' .. L['minutes ago']
	else
		return format('%.1f %s', duration/60, L['minutes ago'])
	end
end

function AuctionFaster:FormatAuctionDuration(duration)
	if duration == 1 then
		return L['12h'];
	elseif duration == 2 then
		return L['24h'];
	elseif duration == 3 then
		return L['48h'];
	else
		return '---';
	end
end

function AuctionFaster:TableCombine(keys, values)
	local result = {};
	for i = 1, #keys do
		result[keys[i]] = values[i];
	end

	return result;
end

function AuctionFaster:TableMap(func, array)
	local newArray = {};

	for i, v in ipairs(array) do
		newArray[i] = func(v);
	end

	return newArray;
end

function AuctionFaster:TableMapN(func, ...)
	local newArray = {};
	local i = 1;

	local arg = {...};
	local argLength = #arg;

	while true do
		local argList = self:TableMap(function(arr)
			return arr[i];
		end, arg);

		if #argList < argLength then
			return newArray;
		end

		newArray[i] = func(unpack(argList));
		i = i + 1;
	end
end

function AuctionFaster:TableSum(t)
	local sum = 0;

	for k, v in pairs(t) do
		sum = sum + v;
	end

	return sum;
end

function AuctionFaster:TrendLine(X, Y)
	-- assuming its a table with {{X, Y}, {X, Y}}

	-- Now convert to log-scale for X
	local logX = self:TableMap(math.log, X);

	local function square(x)
		return math.pow(x, 2);
	end

	local function multi(x, y)
		return x * y;
	end

	-- Now estimate a and b using equations from Math World

	local xSquared = self:TableSum(self:TableMap(square, logX));
	local xy = self:TableSum(self:TableMapN(multi, logX, Y));

	local bFit = (#X * xy - self:TableSum(Y) * self:TableSum(logX)) /
		(#X * xSquared - math.pow(self:TableSum(logX), 2));
	local aFit = (self:TableSum(Y) - bFit * self:TableSum(logX)) / #X;

	local trendData = {};

	for i = 1, #X do
		trendData[i] = {X[i], aFit + bFit * math.log(X[i])};
	end

	return trendData;
end

function AuctionFaster:ParseBattlePetLink(link)
	local _, speciesId, petLevel, breedQuality = strsplit(":", link);
	speciesId = tonumber(speciesId);
	petLevel = tonumber(petLevel);
	breedQuality = tonumber(breedQuality);

	local itemName, icon, _, _, tooltipSource = C_PetJournal.GetPetInfoBySpeciesID(speciesId);

	return itemName, icon, speciesId, petLevel, breedQuality;
end

local AuctionHouseTooltipType = {
	PetLink = 1;
	ItemLink = 2;
	ItemKey = 3;
};

local function GetAuctionHouseTooltipType(rowData)
	if rowData.itemLinkProper then
		local linkType = LinkUtil.ExtractLink(rowData.itemLink);
		if linkType == 'battlepet' then
			return AuctionHouseTooltipType.PetLink, rowData.itemLink;
		elseif linkType == "item" then
			return AuctionHouseTooltipType.ItemLink, rowData.itemLink;
		end
	elseif rowData.itemKey then
		local restrictQualityToFilter = true;
		local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(rowData.itemKey, restrictQualityToFilter);
		if itemKeyInfo and itemKeyInfo.battlePetLink then
			return AuctionHouseTooltipType.PetLink, itemKeyInfo.battlePetLink;
		end

		return AuctionHouseTooltipType.ItemKey, rowData.itemKey;
	end

	return nil;
end

function AuctionFaster:ShowTooltip(frame, rowData, show, anchor)
	GameTooltip_Hide();

	if show then
		local tooltip;

		local tooltipType, data = GetAuctionHouseTooltipType(rowData);
		if not tooltipType then
			return;
		end

		GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT');

		if tooltipType == AuctionHouseTooltipType.PetLink then
			BattlePetToolTip_ShowLink(data);
			tooltip = BattlePetTooltip;
		else
			tooltip = GameTooltip;
			if tooltipType == AuctionHouseTooltipType.ItemLink then
				local hideVendorPrice = true;
				GameTooltip:SetHyperlink(rowData.itemLink, nil, nil, nil, hideVendorPrice);
			elseif tooltipType == AuctionHouseTooltipType.ItemKey then
				GameTooltip:SetItemKey(data.itemID, data.itemLevel, data.itemSuffix);
			end
		end

		if rowData.owners then
			--local methodFound, auctionHouseFrame = CallMethodOnNearestAncestor(owner, "GetAuctionHouseFrame");
			--local bidStatus = auctionHouseFrame and auctionHouseFrame:GetBidStatus(rowData) or nil;
			--AuctionHouseUtil.AddAuctionHouseTooltipInfo(tooltip, rowData, bidStatus);
		end

		if tooltip == GameTooltip then
			GameTooltip:Show();
			GameTooltip:ClearAllPoints();
			StdUi:GlueOpposite(GameTooltip, frame, 0, 0, anchor);
		else
			BattlePetTooltip:ClearAllPoints();
			StdUi:GlueOpposite(BattlePetTooltip, frame, 0, 0, anchor);
		end
	else
		GameTooltip:Hide();
		if BattlePetTooltip then
			BattlePetTooltip:Hide();
		end
	end
end