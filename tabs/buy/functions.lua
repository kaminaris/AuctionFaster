--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

----------------------------------------------------------------------------
--- Searching functions
----------------------------------------------------------------------------

function AuctionFaster:SearchAuctions(name, exact, page)
	if self.currentlyQuerying or not self:CanSendAuctionQuery() then
		return ;
	end

	self:SetAuctionSort();

	self.currentlyQuerying = true;
	self.afScan = 'SearchAuctions';

	self.currentQuery = {
		name = name,
		page = page or 0,
		exact = exact or false,
	};

	--QueryAuctionItems("name", minLevel, maxLevel, page, isUsable, qualityIndex, getAll, exactMatch, filterData)
	QueryAuctionItems(name, nil, nil, page or 0, 0, 0, false, exact or false);
	self.currentlyQuerying = false;
end

function AuctionFaster:SearchNextPage()
	-- if last page is not yet defined or it would be over last page, just abandon
	if not self.currentQuery.lastPage or self.currentQuery.page + 1 > self.currentQuery.lastPage then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page + 1);
end

function AuctionFaster:SearchPreviousPage()
	-- just in case there are no search results abort
	if not self.currentQuery.lastPage or self.currentQuery.page - 1 < 0 then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page - 1);
end

----------------------------------------------------------------------------
--- Searching callback function
----------------------------------------------------------------------------

function AuctionFaster:SearchAuctionsCallback()
	local shown, total = GetNumAuctionItems('list');

	self.currentQuery.lastPage = ceil(total / 50) - 1;

	local auctions = {}
	for i = 1, shown do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', i);

		local _, itemLink = GetItemInfo(itemId);

		tinsert(auctions, {
			owner     = owner,
			count     = count,
			icon      = texture,
			itemId    = itemId,
			itemName  = name,
			itemLink  = itemLink,
			itemIndex = i,
			bid       = floor(minBid / count),
			buy       = floor(buyoutPrice / count),
		});
	end

	table.sort(auctions, function(a, b)
		return a.buy < b.buy;
	end);

	self.buyTab.auctions = auctions;

	self:UpdateSearchAuctions();
	self:UpdateStateText();
	self:UpdatePager();
end

function AuctionFaster:UpdateStateText()
	if #self.buyTab.auctions == 0 then
		self.buyTab.stateLabel:SetText('Nothing was found for query:');
		self.buyTab.stateLabel:Show();
	else
		self.buyTab.stateLabel:Hide();
	end
end

function AuctionFaster:UpdatePager()
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

function AuctionFaster:AddToFavorites()
	local searchBox = self.buyTab.searchBox;
	local text = searchBox:GetText();

	if not text or strlen(text) < 2 then
		--show error or something
		return ;
	end

	local favorites = self.db.global.favorites;
	for i = 1, #favorites do
		if favorites[i].text == text then
			--already exists - no error
			return ;
		end
	end

	tinsert(favorites, { text = text });
	self:DrawFavorites();
end

function AuctionFaster:RemoveFromFavorites(i)
	local favorites = self.db.global.favorites;

	if favorites[i] then
		tremove(favorites, i);
	end

	self:DrawFavorites();
end

function AuctionFaster:SetFavoriteAsSearch(i)
	local favorites = self.db.global.favorites;

	if favorites[i] then
		self.buyTab.searchBox:SetText(favorites[i].text);
	end
end

function AuctionFaster:RemoveCurrentSearchAuction()
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

function AuctionFaster:UpdateSearchAuctions()
	self.buyTab.searchResults:SetData(self.buyTab.auctions, true);
end

local alreadyBought = 0;
function AuctionFaster:BuySelectedItem(boughtSoFar, fresh)
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

	local auctionIndex, name, count = self:FindAuctionIndex(auctionData);

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

				AuctionFaster:BuyItemByIndex(index);
				AuctionFaster:RemoveCurrentSearchAuction();

				AuctionFaster:BuySelectedItem(self:GetParent().count);

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

function AuctionFaster:InterceptLinkClick()
	local origChatEdit_InsertLink = ChatEdit_InsertLink;
	local origHandleModifiedItemClick = HandleModifiedItemClick;
	local function SearchItemLink(origMethod, link)
		if self.buyTab.searchBox:HasFocus() then
			local itemName = GetItemInfo(link);
			self.buyTab.searchBox:SetText(itemName);
			return true;
		else
			return origMethod(link);
		end
	end

	AuctionFaster:RawHook('HandleModifiedItemClick', function(link)
		return SearchItemLink(origHandleModifiedItemClick, link);
	end, true);

	AuctionFaster:RawHook('ChatEdit_InsertLink', function(link)
		return SearchItemLink(origChatEdit_InsertLink, link);
	end, true);
end