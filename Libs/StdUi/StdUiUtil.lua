local StdUi = LibStub and LibStub('StdUi', true);


StdUi.Util = {};
StdUi.Util.moneyBoxValidator = function(self)
	local text = self:GetText();
	local textOrig = text;
	text = text:trim();
	local total, gold, silver, copper, isValid = StdUi.Util.parseMoney(text);

	if not isValid or total == 0 then
		return;
	end

	self:SetText(StdUi.Util.formatMoney(total));
	self.value = total;
	if self.button then
		self.button:Hide();
	end
end

StdUi.Util.parseMoney = function(text)
	text = StdUi.Util.stripColors(text);
	local total = 0;
	local cFound, _, copper = string.find(text, '(%d+)c$');
	if cFound then
		text = string.gsub(text, '(%d+)c$', '');
		text = text:trim();
		total = tonumber(copper);
	end

	local sFound, _, silver = string.find(text, '(%d+)s$');
	if sFound then
		text = string.gsub(text,  '(%d+)s$', '');
		text = text:trim();
		total = total + tonumber(silver) * 100;
	end

	local gFound, _, gold = string.find(text, '(%d+)g$');
	if gFound then
		text = string.gsub(text,  '(%d+)g$', '');
		text = text:trim();
		total = total + tonumber(gold) * 100 * 100;
	end

	local left = tonumber(text:len());
	local isValid = (text:len() == 0 and total > 0);

	return total, gold, silver, copper, isValid;
end

StdUi.Util.formatMoney = function(money)
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

StdUi.Util.stripColors = function(text)
	text = string.gsub(text, '|c%x%x%x%x%x%x%x%x', '');
	text = string.gsub(text, '|r', '');
	return text;
end