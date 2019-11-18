---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

local TableInsert = tinsert;

function Buy:DrawFilterFrame()
	local buyTab = self.buyTab;

	local filtersPane = StdUi:Window(buyTab, 200, 100, L['Filters']);
	filtersPane:Hide();
	StdUi:GlueAfter(filtersPane, buyTab, 0, 0, 0, 0);

	local exactMatch = StdUi:Checkbox(filtersPane, L['Exact Match']);
	local usableItems = StdUi:Checkbox(filtersPane, USABLE_ITEMS);

	local minLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, minLevel, L['Level from'], 'TOP');

	local maxLevel = StdUi:NumericBox(filtersPane, 80, 20, '');
	StdUi:AddLabel(filtersPane, maxLevel, L['Level to'], 'TOP');

	self:GetSearchCategories();
	local rarityTable = {
		{value = -1, text = ALL},
	};

	for i = 0, #ITEM_QUALITY_COLORS - 2 do
		TableInsert(
			rarityTable, {
				value = i,
				text = ITEM_QUALITY_COLORS[i].hex .. _G['ITEM_QUALITY' .. i .. '_DESC']
			}
		)
	end

	local rarity = StdUi:Dropdown(filtersPane, 170, 20, rarityTable, -1);
	StdUi:AddLabel(filtersPane, rarity, RARITY, 'TOP');

	local category = StdUi:Dropdown(filtersPane, 170, 20, self.categories, 0);
	StdUi:AddLabel(filtersPane, category, L['Category'], 'TOP');

	local subCategory = StdUi:Dropdown(filtersPane, 170, 20, {}, 0);
	StdUi:AddLabel(filtersPane, subCategory, L['Sub Category'], 'TOP');
	subCategory:Disable();

	StdUi:GlueTop(exactMatch, filtersPane, 10, -40, 'LEFT');
	StdUi:GlueBelow(usableItems, exactMatch, 0, -10, 'LEFT');
	StdUi:GlueBelow(minLevel, usableItems, 0, -30, 'LEFT');
	StdUi:GlueRight(maxLevel, minLevel, 10, 0);
	StdUi:GlueBelow(rarity, minLevel, 0, -30, 'LEFT');
	StdUi:GlueBelow(category, rarity, 0, -30, 'LEFT');
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
	self.filtersPane.usableItems = usableItems;
	self.filtersPane.minLevel = minLevel;
	self.filtersPane.maxLevel = maxLevel;
	self.filtersPane.rarity = rarity;
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
