--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

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

function AuctionFaster:SearchAuctionsCallback()
	local shown, total = GetNumAuctionItems('list');

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
	local itemIndex = auctionData.itemIndex;

	-- maybe index is the same
	local name, texture, count, quality, canUse, level, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo('list', itemIndex);

	local bid = floor(minBid / count);
	local buy = floor(buyoutPrice / count);

	if name == auctionData.itemName and itemId == auctionData.itemId and owner == auctionData.owner
			and bid == auctionData.bid and buy == auctionData.buy and count == auctionData.count then

		local buttons = {
			ok     = {
				text    = 'Yes',
				onClick = function(self)
					-- same index, we can buy it
					self:GetParent():Hide();

					--Simulate
					AuctionFaster:BuyItemByIndex(itemIndex);
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
		--
		---- same index, we can buy it
		--self:BuyItemByIndex(index);
		---- we need to refresh the auctions
		--self:GetCurrentAuctions();
	end
end