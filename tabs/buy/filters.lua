---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');


function Buy:DrawFilterFrame()
	local buyTab = self.buyTab;

	local filtersPane = StdUi:Window(buyTab, L['Filters'], 200, 100);
	filtersPane:Hide();
	StdUi:GlueAfter(filtersPane, buyTab, 0, 0, 0, 0);

	local exactMatch = StdUi:Checkbox(filtersPane, L['Exact Match']);

	local minLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, minLevel, L['Level from'], 'TOP');

	local maxLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, maxLevel, L['Level to'], 'TOP');

	self:GetSearchCategories();
	local category = StdUi:Dropdown(filtersPane, 150, 20, self.categories, 0);
	StdUi:GlueBelow(category, minLevel, 0, -30, 'LEFT');

	local subCategory = StdUi:Dropdown(filtersPane, 150, 20, {}, 0);
	StdUi:AddLabel(filtersPane, subCategory, L['Sub Category'], 'TOP');
	subCategory:Disable();


	StdUi:GlueTop(exactMatch, filtersPane, 10, -40, 'LEFT');
	StdUi:GlueBelow(minLevel, exactMatch, 0, -30, 'LEFT');
	StdUi:GlueRight(maxLevel, minLevel, 10, 0);
	StdUi:AddLabel(filtersPane, category, L['Category'], 'TOP');
	StdUi:GlueBelow(subCategory, category, 0, -30, 'LEFT');

	category.OnValueChanged = function(dropdown, value, text)
		local subCategories = Buy.subCategories[value];

		if #subCategories > 0 then
			subCategory:SetOptions(subCategories);
			subCategory:SetValue(0);
			subCategory:Enable();
		else
			subCategory:SetOptions({});
			subCategory:SetValue(0);
			subCategory:Disable();
		end
	end;

	self.filtersPane = filtersPane;
	self.filtersPane.exactMatch = exactMatch;
	self.filtersPane.minLevel = minLevel;
	self.filtersPane.maxLevel = maxLevel;
	self.filtersPane.category = category;
	self.filtersPane.subCategory = subCategory;
end

function Buy:ToggleFilterFrame()
	if self.filtersPane:IsVisible() then
		self.filtersPane:Hide();
	else
		self.filtersPane:Show();
		self.sniperPane:Hide();
	end
end
