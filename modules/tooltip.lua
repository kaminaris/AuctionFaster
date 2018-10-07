---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
local Tooltip = AuctionFaster:NewModule('Tooltip', 'AceHook-3.0');
local ItemCache = AuctionFaster:GetModule('ItemCache');

--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

function Tooltip:Enable()
	if not self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:HookScript(GameTooltip, 'OnTooltipSetItem', 'UpdateTooltip');
		self:SecureHook('BattlePetTooltipTemplate_SetBattlePet', 'UpdateBattlePetTooltip');

		AuctionFaster:Echo(2, 'Tooltips enabled');
	end
end

function Tooltip:Disable()
	if self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:Unhook(GameTooltip, 'OnTooltipSetItem');
		self:Unhook('BattlePetTooltipTemplate_SetBattlePet');
		AuctionFaster:Echo(2, 'Tooltips disabled');
	end
end

function Tooltip:UpdateTooltip(tooltip, ...)
	local name, link = tooltip:GetItem();
	if not link then
		return ;
	end

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

function Tooltip:UpdateBattlePetTooltip(tooltip, petData)
	if not tooltip.afPane then
		tooltip.afPane = StdUi:Panel(tooltip, 150, 70);
		tooltip.afPane.header = StdUi:Label(tooltip.afPane, 'AuctionFaster:');

		tooltip.afPane.bidLabel = StdUi:Label(tooltip.afPane, 'Lowest Bid: ');
		tooltip.afPane.bid = StdUi:Label(tooltip.afPane, '');

		tooltip.afPane.buyLabel = StdUi:Label(tooltip.afPane, 'Lowest Buy: ');
		tooltip.afPane.buy = StdUi:Label(tooltip.afPane, '');

		StdUi:GlueTop(tooltip.afPane.header, tooltip.afPane, 10, -5, 'LEFT');

		StdUi:GlueBelow(tooltip.afPane.bidLabel, tooltip.afPane.header, 0, -15, 'LEFT');
		StdUi:GlueRight(tooltip.afPane.bid, tooltip.afPane.bidLabel, 20, 0);

		StdUi:GlueBelow(tooltip.afPane.buyLabel, tooltip.afPane.bidLabel, 0, -5, 'LEFT');
		StdUi:GlueBelow(tooltip.afPane.buy, tooltip.afPane.bid, 0, -5, 'LEFT');

		StdUi:GlueBelow(tooltip.afPane, tooltip, 0, 0, 'CENTER');
	end

	local cacheItem = ItemCache:GetItemFromCache(82800, petData.name, true);
	if not cacheItem then
		return;
	end

	tooltip.afPane.bid:SetText(StdUi.Util.formatMoney(cacheItem.bid));
	tooltip.afPane.buy:SetText(StdUi.Util.formatMoney(cacheItem.buy));

	tooltip.afPane:SetWidth(tooltip:GetWidth());
end