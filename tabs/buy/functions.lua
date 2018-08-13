--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

----------------------------------------------------------------------------
--- Searching functions
----------------------------------------------------------------------------

function Buy:SearchAuctions(name, exact, page)
	self.currentQuery = {
		name = name,
		page = page or 0,
		exact = exact or false,
	};

	self:ApplyFilters(self.currentQuery);

	self:ClearSearchAuctions();
	self:UpdateStateText(true);

	Auctions:QueryAuctions(self.currentQuery, function(shown, total, items)
		Buy:SearchAuctionsCallback(shown, total, items)
	end);
end

function Buy:SearchNextPage()
	-- if last page is not yet defined or it would be over last page, just abandon
	if not self.currentQuery.lastPage or self.currentQuery.page + 1 > self.currentQuery.lastPage then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page + 1);
end

function Buy:SearchPreviousPage()
	-- just in case there are no search results abort
	if not self.currentQuery.lastPage or self.currentQuery.page - 1 < 0 then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page - 1);
end

----------------------------------------------------------------------------
--- Searching callback function
----------------------------------------------------------------------------

function Buy:SearchAuctionsCallback(shown, total, items)
	self.currentQuery.lastPage = ceil(total / 50) - 1;

	self.buyTab.auctions = items;

	self:UpdateSearchAuctions();
	self:UpdateStateText();
	self:UpdatePager();
end

function Buy:UpdateStateText(inProgress)
	if inProgress then
		self.buyTab.stateLabel:SetText('Search in progress...');
		self.buyTab.stateLabel:Show();
	elseif #self.buyTab.auctions == 0 then
		self.buyTab.stateLabel:SetText('Nothing was found for this query.');
		self.buyTab.stateLabel:Show();
	else
		self.buyTab.stateLabel:Hide();
	end
end

function Buy:UpdatePager()
	local p = self.currentQuery.page + 1;
	local lp = self.currentQuery.lastPage + 1;
	self.buyTab.pager.pageText:SetText('Page ' .. p ..' of ' .. lp);

	self.buyTab.pager.leftButton:Enable();
	self.buyTab.pager.rightButton:Enable();

	if p <= 1 then
		self.buyTab.pager.leftButton:Disable();
	end

	if p >= lp then
		self.buyTab.pager.rightButton:Disable();
	end
end

function Buy:AddToFavorites()
	local searchBox = self.buyTab.searchBox;
	local text = searchBox:GetText();

	if not text or strlen(text) < 2 then
		--show error or something
		return ;
	end

	local favorites = AuctionFaster.db.favorites;
	for i = 1, #favorites do
		if favorites[i].text == text then
			--already exists - no error
			return ;
		end
	end

	tinsert(favorites, { text = text });
	self:DrawFavorites();
end

function Buy:RemoveFromFavorites(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		tremove(favorites, i);
	end

	self:DrawFavorites();
end

function Buy:SetFavoriteAsSearch(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		self.buyTab.searchBox:SetText(favorites[i].text);
	end
end

function Buy:RemoveCurrentSearchAuction()
	local index = self.buyTab.searchResults:GetSelection();
	if not index then
		return ;
	end

	if not self.buyTab.auctions[index] then
		return;
	end

	tremove(self.buyTab.auctions, index);
	self:UpdateSearchAuctions();

	if self.buyTab.auctions[index] then
		self.buyTab.searchResults:SetSelection(index);
	end
end

function Buy:UpdateSearchAuctions()
	self.buyTab.searchResults:SetData(self.buyTab.auctions, true);
end

function Buy:ClearSearchAuctions()
	self.buyTab.searchResults:SetData({}, true);
end

function Buy:LockBuyButton(lock)
	local buyButton = self.confirmFrame.buttons['ok'];

	if lock then
		buyButton:Disable();
	else
		buyButton:Enable();
	end
end

function Buy:AUCTION_ITEM_LIST_UPDATE()
	-- this unlocks the button after buying item
	if self.confirmFrame then
		self:LockBuyButton();
	end
end

local alreadyBought = 0;
function Buy:BuySelectedItem(boughtSoFar, fresh)
	local auctionData = self.buyTab.searchResults:GetSelectedItem();
	if not auctionData then
		return ;
	end

	boughtSoFar = boughtSoFar or 0;
	alreadyBought = alreadyBought + boughtSoFar;
	if fresh then
		alreadyBought = 0;
	end

	local auctionIndex, name, count = Auctions:FindAuctionIndex(auctionData);

	if not auctionIndex then
		-- @TODO: show some error
		print('Auction not found');
		return;
	end

	local buttons = {
		ok     = {
			text    = 'Yes',
			onClick = function(self)
				self:GetParent():Hide();

				Auctions:BuyItemByIndex(auctionIndex);
				Buy:LockBuyButton(true);
				Buy:RemoveCurrentSearchAuction();

				Buy:BuySelectedItem(self:GetParent().count);
			end
		},
		cancel = {
			text    = 'No',
			onClick = function(self)
				self:GetParent():Hide();
			end
		}
	};

	self.confirmFrame = StdUi:Confirm(
		'Confirm Buy',
		'Buying ' .. auctionData.itemLink .. '\n'..
			'qty: ' .. count .. '\n\n' ..
			'per item: ' .. StdUi.Util.formatMoney(auctionData.buy) .. '\n' ..
			'Total: ' .. StdUi.Util.formatMoney(auctionData.buy * auctionData.count) .. '\n\n' ..

			'Bought so far: ' .. alreadyBought,
		buttons,
		'afConfirmBuy'
	);

	self.confirmFrame:SetHeight(200);
	self.confirmFrame.count = count;
end

----------------------------------------------------------------------------
--- Filters functions
----------------------------------------------------------------------------

function Buy:GetSearchCategories()
	if self.categories and self.subCategories then
		return self.categories, self.subCategories;
	end

	local categories = {
		{value = 0, text = 'All'}
	};

	local subCategories = {
		[0] = {
			{value = 0, text = 'All'}
		}
	};

	for i = 1, #AuctionCategories do
		local children = AuctionCategories[i].subCategories;

		tinsert(categories, { value = i, text = AuctionCategories[i].name});

		subCategories[i] = {};
		if children then
			tinsert(subCategories[i], {value = 0, text = 'All'});
			for x = 1, #children do
				tinsert(subCategories[i], {value = x, text = children[x].name});
			end
		end
	end

	self.categories = categories;
	self.subCategories = subCategories;
end

function Buy:ApplyFilters(query)
	local filters = self.filtersPane;

	query.exact = filters.exactMatch:GetChecked();
	local minLevel = filters.minLevel:GetValue();
	local maxLevel = filters.maxLevel:GetValue();

	if minLevel then
		query.minLevel = minLevel;
	end

	if maxLevel then
		query.maxLevel = maxLevel;
	end

	local categoryIndex = filters.category:GetValue();
	local subCategoryIndex = filters.subCategory:GetValue();

	if categoryIndex > 0 and subCategoryIndex > 0 then
		query.filterData = AuctionCategories[categoryIndex].subCategories[subCategoryIndex].filters;
	elseif categoryIndex > 0 then
		query.filterData = AuctionCategories[categoryIndex].filters;
	end
end

function Buy:InterceptLinkClick()
	if self.linksIntercepted then
		return;
	end

	local origChatEdit_InsertLink = ChatEdit_InsertLink;
	local origHandleModifiedItemClick = HandleModifiedItemClick;
	local function SearchItemLink(origMethod, link)
		if Buy.buyTab.searchBox:HasFocus() then
			local itemName = GetItemInfo(link);
			Buy.buyTab.searchBox:SetText(itemName);
			return true;
		else
			return origMethod(link);
		end
	end

	Buy:RawHook('HandleModifiedItemClick', function(link)
		return SearchItemLink(origHandleModifiedItemClick, link);
	end, true);

	Buy:RawHook('ChatEdit_InsertLink', function(link)
		return SearchItemLink(origChatEdit_InsertLink, link);
	end, true);

	self.linksIntercepted = true;
end