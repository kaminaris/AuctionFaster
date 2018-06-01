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

function Buy:UpdateStateText()
	if #self.buyTab.auctions == 0 then
		self.buyTab.stateLabel:SetText('Nothing was found for query:');
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

	local favorites = AuctionFaster.db.global.favorites;
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
	local favorites = AuctionFaster.db.global.favorites;

	if favorites[i] then
		tremove(favorites, i);
	end

	self:DrawFavorites();
end

function Buy:SetFavoriteAsSearch(i)
	local favorites = AuctionFaster.db.global.favorites;

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

local alreadyBought = 0;
function Buy:BuySelectedItem(boughtSoFar, fresh)
	local index = self.buyTab.searchResults:GetSelection();
	if not index then
		return ;
	end

	boughtSoFar = boughtSoFar or 0;
	alreadyBought = alreadyBought + boughtSoFar;
	if fresh then
		alreadyBought = 0;
	end

	local auctionData = self.buyTab.searchResults:GetRow(index);
	if not auctionData then
		return;
	end

	local auctionIndex, name, count = Auctions:FindAuctionIndex(auctionData);

	if not auctionIndex then
		-- @TODO: show some error
		print('Auction not found');
		DevTools_Dump(auctionData);
		return;
	end

	local buttons = {
		ok     = {
			text    = 'Yes',
			onClick = function(self)
				-- same index, we can buy it
				self:GetParent():Hide();

				Auctions:BuyItemByIndex(index);
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

	local confirmFrame = StdUi:Confirm(
		'Confirm Buy',
		'Buying ' .. name .. '\n#: ' .. count .. '\n\nBought so far: ' .. alreadyBought,
		buttons,
		'afConfirmBuy'
	);
	confirmFrame.count = count;
end

function Buy:InterceptLinkClick()
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
end