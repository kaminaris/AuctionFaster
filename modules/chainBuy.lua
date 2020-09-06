---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');
--- @class ChainBuy
local ChainBuy = AuctionFaster:NewModule('ChainBuy', 'AceEvent-3.0', 'AceTimer-3.0');

local format = string.format;

ChainBuy.requests = {};
ChainBuy.currentIndex = 0;
ChainBuy.currentRequest = nil;
ChainBuy.isPaused = true;
ChainBuy.fastMode = false;

local fastModeExplanation = L['Fast Mode - AuctionFaster will NOT wait until you actually buy an item.\n\n'..
'This may result in inaccurate amount of bought items and some missed auctions.\n' ..
'|cFFFF0000Use this only if you don\'t care about how much you will buy and want to buy fast.|r'];

function ChainBuy:OnEnable()
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
end

function ChainBuy:OnDisable()
	self:UnregisterEvent('AUCTION_HOUSE_CLOSED');
end

function ChainBuy:AUCTION_HOUSE_CLOSED()
	self:Cancel();
end

function ChainBuy:CHAT_MSG_SYSTEM(event, msg)
	if string.match(msg, ERR_AUCTION_WON_S:gsub('%%s', '(.*)')) then
		self:UnregisterEvent('UI_ERROR_MESSAGE');
		self:UnregisterEvent('CHAT_MSG_SYSTEM');
		self:ProcessNext(); -- we can move to next request
	end
end

function ChainBuy:UI_ERROR_MESSAGE(msg, err)
	self:UnregisterEvent('UI_ERROR_MESSAGE');
	self:UnregisterEvent('CHAT_MSG_SYSTEM');

	if err == 443 then
		self.isPaused = false;
		self:ShowWindow();
	end
end


function ChainBuy:AddBuyRequest(request)
	tinsert(self.requests, request);
	self:UpdateWindow();

	if self.progressCallback then
		self:progressCallback();
	end
end

---- Queue Processing

function ChainBuy:Start(initialQueue, progressCallback, closeCallback)
	if initialQueue then
		self.requests = initialQueue;
		self.initialQueue = initialQueue;
		self.currentRequest = initialQueue[1];
		self.boughtSoFar = 0;
	end

	if self.currentIndex == 0 then
		self.isPaused = false;
		self.boughtSoFar = 0;
		self:ProcessNext();
	end

	if progressCallback then
		self.progressCallback = progressCallback;
		self:progressCallback();
	end

	self.closeCallback = closeCallback;
end

function ChainBuy:Cancel()
	self:Pause();
	self.requests = {};
	self.currentIndex = 0;
	self.boughtSoFar = 0;
	self.currentRequest = nil;
	if self.window then
		self.window:Hide();
	end
end

function ChainBuy:Pause()
	self.isPaused = true;
	self:UpdateWindow();
end

function ChainBuy:ProcessNext()
	if self.currentIndex + 1 <= #self.requests then
		self.currentIndex = self.currentIndex + 1;
		self.currentRequest = self.requests[self.currentIndex];
		self.isPaused = false;
		self:ShowWindow();
		self:UpdateWindow();
	else
		self:Cancel();
	end

	if self.progressCallback then
		self:progressCallback();
	end
end

function ChainBuy:ShowWindow()
	if self.window then
		self.window:Show();
		self:UpdateWindow();
		return;
	end

	local window = StdUi:Window(UIParent, 400, 300, L['Chain Buy']);
	if AuctionFaster.db.chainBuy.moved then
		local settings = AuctionFaster.db.chainBuy;
		window:SetPoint(settings.point, nil, settings.relativePoint, settings.xOfs, settings.yOfs);
	else
		StdUi:GlueBelow(window, AuctionFrame, 0, -40, 'CENTER');
	end

	window:SetScript('OnDragStop', function(self)
		local settings = {};
		self:StopMovingOrSizing();
		settings.point, _, settings.relativePoint, settings.xOfs, settings.yOfs = self:GetPoint();
		settings.moved = true;
		AuctionFaster.db.chainBuy = settings;
	end);

	window.resetBtn = StdUi:Button(window, 100, 16, 'Reset Pos');
	window.itemIcon = StdUi:Texture(window, 32, 32, '');
	window.itemName = StdUi:Label(window, '', 14);
	window.qty = StdUi:Label(window, '', 20);
	window.pricePerItem = StdUi:Label(window, '', 14);
	window.priceTotal = StdUi:Label(window, '', 14);
	window.boughtSoFar = StdUi:Label(window, '', 20);

	window.buyButton = StdUi:Button(window, 70, 24, L['Buy']);
	window.skipButton = StdUi:Button(window, 70, 24, L['Skip']);
	window.closeButton = StdUi:Button(window, 150, 24, L['Close']);
	window.fastMode = StdUi:Checkbox(window, 'Fast Mode', 100, 24);

	window.buyButton:SetScript('OnClick', function()
		ChainBuy:PerformBuy();
	end);

	window.skipButton:SetScript('OnClick', function()
		ChainBuy:ProcessNext();
	end);

	window.resetBtn:SetScript('OnClick', function()
		AuctionFaster.db.chainBuy = {};
		window:ClearAllPoints();
		StdUi:GlueBelow(window, AuctionFrame, 0, -40, 'CENTER');
	end);

	local closeHandler = function()
		ChainBuy.window:Hide();
		self:Cancel();

		if ChainBuy.closeCallback then
			ChainBuy.closeCallback();
		end
	end

	window.closeButton:SetScript('OnClick', closeHandler);
	window.closeBtn:SetScript('OnClick', closeHandler);

	window:SetScript('OnHide', function()
	end);

	window.fastMode.OnValueChanged = function(_, flag)
		self.fastMode = flag;
	end

	--- @type StatusBar
	window.progressBar = StdUi:ProgressBar(window, 400, 20);
	window.progressBar.TextUpdate = function(self, min, max, value)
		return value .. ' / ' .. max;
	end;

	StdUi:GlueTop(window.resetBtn, window, -40, -10, 'RIGHT');
	StdUi:GlueTop(window.itemIcon, window, 40, -40, 'LEFT');
	StdUi:GlueRight(window.itemName, window.itemIcon, 10, 0);

	StdUi:GlueTop(window.qty, window, 0, -80, 'CENTER');
	StdUi:GlueBelow(window.pricePerItem, window.itemIcon, 0, -50, 'LEFT');
	StdUi:GlueBelow(window.priceTotal, window.pricePerItem, 0, -10, 'LEFT');
	StdUi:GlueBelow(window.boughtSoFar, window.qty, 0, -80, 'CENTER');

	StdUi:GlueBottom(window.buyButton, window, 20, 40, 'LEFT');
	StdUi:GlueRight(window.skipButton, window.buyButton, 10, 0);
	StdUi:GlueBottom(window.closeButton, window, -20, 40, 'RIGHT');
	StdUi:GlueBottom(window.progressBar, window, 0, 0, 'CENTER');

	StdUi:GlueBottom(window.fastMode, window, -10, 70, 'RIGHT');

	StdUi:FrameTooltip(window.fastMode, fastModeExplanation, 'afCbFastMode', 'TOPRIGHT', true);

	self.window = window;
	self.window:Show();
end

function ChainBuy:UpdateWindow()
	if not self.currentRequest or not self.window then return; end

	local window = self.window;
	local req = self.currentRequest;

	window.itemIcon:SetTexture(req.texture);
	window.itemName:SetText(req.itemLink);
	window.qty:SetText(format(L['Qty: %d'], req.count));
	window.pricePerItem:SetText(format(L['Per Item: %s'], StdUi.Util.formatMoney(req.buy)));
	window.priceTotal:SetText(format(L['Total: %s'], StdUi.Util.formatMoney(req.buy * req.count)));
	window.boughtSoFar:SetText(format(L['Bought so far: %d'], self.boughtSoFar));

	window.progressBar:SetMinMaxValues(0, #self.requests);
	window.progressBar:SetValue(self.currentIndex);

	if self.initialQueue then
		window:SetWindowTitle(L['Chain Buy']);
	else
		window:SetWindowTitle(L['Queue']);
	end


	if self.isPaused and not self.fastMode then
		self.window.buyButton:Disable();
	else
		self.window.buyButton:Enable();
	end
end

function ChainBuy:PerformBuy()
	-- We should get either of those 2 events
	if not self.fastMode then
		self:RegisterEvent('CHAT_MSG_SYSTEM');
		self:RegisterEvent('UI_ERROR_MESSAGE');
	end

	local result = Auctions:BuyItem(self.currentRequest, self.fastMode);
	if not result then
		-- auction is no longer on the list, go to next one.
		self:ProcessNext();
		return;
	end

	self.boughtSoFar = self.boughtSoFar + self.currentRequest.count;
	if not self.fastMode then
		self:Pause(); -- wait until the buy event
	else
		self:ProcessNext();
	end
end

function ChainBuy:CalcRemainingQty()
	local total = 0;
	if not self.requests or #self.requests == 0 then
		return 0;
	end

	local start = self.currentIndex == 0 and 1 or self.currentIndex;
	for i = start, #self.requests do
		total = total + self.requests[i].count;
	end

	return total;
end

