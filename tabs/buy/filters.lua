---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local TableInsert = tinsert;

local HardFilters = {
	[Enum.AuctionHouseFilter.UncollectedOnly] = false,
	[Enum.AuctionHouseFilter.UsableOnly] = false,
	[Enum.AuctionHouseFilter.UpgradesOnly] = false,
}

local RarityFilters = {
	[Enum.AuctionHouseFilter.PoorQuality] = true,
	[Enum.AuctionHouseFilter.CommonQuality] = true,
	[Enum.AuctionHouseFilter.UncommonQuality] = true,
	[Enum.AuctionHouseFilter.RareQuality] = true,
	[Enum.AuctionHouseFilter.EpicQuality] = true,
	[Enum.AuctionHouseFilter.LegendaryQuality] = true,
	[Enum.AuctionHouseFilter.ArtifactQuality] = true,
}

local checkboxes = {};
function Buy:DrawFilterFrame()
	local buyTab = self.buyTab;

	local filtersPane = StdUi:Window(buyTab, 200, 100, L['Filters']);
	filtersPane:Hide();
	StdUi:GlueAfter(filtersPane, buyTab, 0, 0, 0, 0);

	local minLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, minLevel, L['Level from'], 'TOP');

	local maxLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, maxLevel, L['Level to'], 'TOP');

	StdUi:GlueTop(minLevel, filtersPane, 10, -60, 'LEFT');
	StdUi:GlueRight(maxLevel, minLevel, 10, 0);

	local lastCheckbox;
	for filterId, checked in pairs(HardFilters) do
		local checkbox = StdUi:Checkbox(filtersPane, AUCTION_HOUSE_FILTER_STRINGS[filterId]);
		checkbox.filterId = filterId;
		checkbox:SetChecked(checked);

		if not lastCheckbox then
			StdUi:GlueBelow(checkbox, minLevel, 0, -10, 'LEFT')
		else
			StdUi:GlueBelow(checkbox, lastCheckbox, 0, -5, 'LEFT')
		end

		lastCheckbox = checkbox;
		tinsert(checkboxes, checkbox);
	end

	local rarityLabel = StdUi:Label(filtersPane, AUCTION_HOUSE_FILTER_CATEGORY_RARITY);
	StdUi:GlueBelow(rarityLabel, lastCheckbox, 0, -20, 'LEFT')

	lastCheckbox = nil;

	for filterId, checked in pairs(RarityFilters) do
		local checkbox = StdUi:Checkbox(filtersPane, AUCTION_HOUSE_FILTER_STRINGS[filterId]);
		checkbox.filterId = filterId;
		checkbox:SetChecked(checked);

		if not lastCheckbox then
			StdUi:GlueBelow(checkbox, rarityLabel, 0, -10, 'LEFT')
		else
			StdUi:GlueBelow(checkbox, lastCheckbox, 0, -5, 'LEFT')
		end

		lastCheckbox = checkbox;
		tinsert(checkboxes, checkbox);
	end

	self:GetSearchCategories();

	local category = StdUi:Dropdown(filtersPane, 170, 20, self.categories, 0);
	StdUi:AddLabel(filtersPane, category, L['Category'], 'TOP');
	StdUi:GlueBelow(category, lastCheckbox, 0, -30, 'LEFT');

	local subCategory = StdUi:Dropdown(filtersPane, 170, 20, {}, 0);
	StdUi:AddLabel(filtersPane, subCategory, L['Sub Category'], 'TOP');
	subCategory:Disable();
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

----------------------------------------------------------------------------
--- Filters functions
----------------------------------------------------------------------------

function Buy:GetSearchCategories()
	if self.categories and self.subCategories then
		return self.categories, self.subCategories;
	end

	local categories = {
		{value = 0, text = ALL}
	};

	local subCategories = {
		[0] = {
			{value = 0, text = ALL}
		}
	};

	for i, categoryInfo in ipairs(AuctionCategories) do
		local children = categoryInfo.subCategories;

		TableInsert(categories, { value = i, text = categoryInfo.name});

		subCategories[i] = {};
		if children then
			TableInsert(subCategories[i], {value = 0, text = 'All'});
			for x = 1, #children do
				TableInsert(subCategories[i], {value = x, text = children[x].name});
			end
		end
	end

	self.categories = categories;
	self.subCategories = subCategories;
end

function Buy:GetFilters()
	local filters = {};
	for _, checkbox in pairs(checkboxes) do
		local checked = checkbox:GetChecked();
		if checked then
			tinsert(filters, checkbox.filterId);
		end
	end

	return filters;
end

function Buy:ApplyFilters(query)
	local filters = self.filtersPane;

	query.filters = self:GetFilters();

	local minLevel = filters.minLevel:GetValue();
	local maxLevel = filters.maxLevel:GetValue();

	query.minLevel = minLevel or 0;
	query.maxLevel = maxLevel or 0;

	local categoryIndex = filters.category:GetValue();
	local subCategoryIndex = filters.subCategory:GetValue();

	if categoryIndex > 0 and subCategoryIndex > 0 then
		query.itemClassFilters = AuctionCategories[categoryIndex].subCategories[subCategoryIndex].filters;
	elseif categoryIndex > 0 then
		query.itemClassFilters = AuctionCategories[categoryIndex].filters;
	end
end