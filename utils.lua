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

function AuctionFaster:ShowTooltip(frame, link, show, itemId, anchor)
	if show then

		GameTooltip:SetOwner(frame);

		if itemId == 82800 then
			local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(':', link);

			BattlePetToolTip_Show(
				tonumber(speciesID),
				tonumber(level),
				tonumber(breedQuality),
				tonumber(maxHealth),
				tonumber(power),
				tonumber(speed),
				string.gsub(string.gsub(link, '^(.*)%[', ''), '%](.*)$', '')
			);
			BattlePetTooltip:ClearAllPoints();
			StdUi:GlueOpposite(BattlePetTooltip, frame, 0, 0, anchor);
		else
			GameTooltip:SetHyperlink(link);
			GameTooltip:Show();
			GameTooltip:ClearAllPoints();
			StdUi:GlueOpposite(GameTooltip, frame, 0, 0, anchor);
		end
	else
		GameTooltip:Hide();
		if BattlePetTooltip then
			BattlePetTooltip:Hide();
		end
	end
end