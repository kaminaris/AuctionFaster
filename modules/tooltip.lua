
local Tooltip = AuctionFaster:NewModule('Tooltip', 'AceHook-3.0');
local ItemCache = AuctionFaster:GetModule('ItemCache');

--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function Tooltip:Enable()
	if not self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:HookScript(GameTooltip, 'OnTooltipSetItem', 'UpdateTooltip');
		print('Tooltips enabled');
	end
end

function Tooltip:Disable()
	if self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:Unhook(GameTooltip, 'OnTooltipSetItem');
		print('Tooltips disabled');
	end
end

function Tooltip:UpdateTooltip(tooltip, ...)
	local name, link = tooltip:GetItem();
	local itemId = GetItemInfoInstant(link);

	local cacheItem = ItemCache:GetItemFromCache(itemId, name, true);
	if cacheItem then
		tooltip:AddLine('---');
		tooltip:AddLine('AuctionFaster:');
		tooltip:AddDoubleLine('Lowest Bid: ', StdUi.Util.formatMoney(cacheItem.bid));
		tooltip:AddDoubleLine('Lowest Buy: ', StdUi.Util.formatMoney(cacheItem.buy));

		-- @TODO: looks like its not needed
		--tooltip:Show();
	end
end