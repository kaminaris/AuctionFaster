
function AuctionFaster:FormatMoney(money)
	if type(money) ~= 'number' then
		return money;
	end
	
	local money = tonumber(money);
	local goldColor = '|cfffff209';
	local silverColor = '|cff7b7b7a';
	local copperColor = '|cffac7248';

	local gold = floor(money / COPPER_PER_GOLD);
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = floor(money % COPPER_PER_SILVER);

	local output = '';

	if gold > 0 then
		output = format('%s%i%s ', goldColor, gold, '|rg')
	end

	if gold > 0 or silver > 0 then
		output = format('%s%s%02i%s ', output, silverColor, silver, '|rs')
	end

	output = format('%s%s%02i%s ', output, copperColor, copper, '|rc')

	return output:trim();
end

function AuctionFaster:FormatMoneyNoColor(money)
	if type(money) ~= 'number' then
		return money;
	end

	local money = tonumber(money);

	local gold = floor(money / COPPER_PER_GOLD);
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = floor(money % COPPER_PER_SILVER);

	return gold .. 'g ' .. silver .. 's ' .. copper .. 'c';
end

function AuctionFaster:ParseMoney(text)
	local _, _, gold, silver, copper = string.find(text, '(%d+)g (%d+)s (%d+)c');

	gold = tonumber(gold);
	silver = tonumber(silver);
	copper = tonumber(copper);
	local total = floor(copper + (silver * COPPER_PER_SILVER) + (gold * COPPER_PER_GOLD));

	return total, gold, silver, copper;
end

function AuctionFaster:FormatDuration(duration)
	if duration >= 172800 then
		return format('%.1f %s', duration/86400, 'days ago')
	elseif duration >= 7200 then
		return format('%.1f %s', duration/3600, 'hours ago')
	else
		return format('%.1f %s', duration/60, 'minutes ago')
	end
end

function AuctionFaster:FormatAuctionDuration(duration)
	if duration == 1 then
		return '12h';
	elseif duration == 2 then
		return '24h';
	elseif duration == 3 then
		return '48h';
	else
		return '---';
	end
end