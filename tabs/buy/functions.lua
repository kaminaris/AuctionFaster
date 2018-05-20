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