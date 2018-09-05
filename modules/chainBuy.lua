--- @type StdUi
local StdUi = LibStub('StdUi');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @class ChainBuy
local ChainBuy = AuctionFaster:NewModule('ChainBuy', 'AceEvent-3.0', 'AceTimer-3.0');

ChainBuy.requests = {};
ChainBuy.currentIndex = 0;
ChainBuy.currentRequest = nil;
ChainBuy.isPaused = true;
ChainBuy.fastMode = true;

function ChainBuy:Enable()
end

function ChainBuy:Disable()
end

function ChainBuy:CHAT_MSG_SYSTEM(event, msg)
	if strfind(msg, 'You won an auction') then
		self:UnregisterEvent('UI_ERROR_MESSAGE');
		self:UnregisterEvent('CHAT_MSG_SYSTEM');
		--print(GetTime(), 'CHAT_MSG_SYSTEM');
		self:ProcessNext(); -- we can move to next request
	end
end

function ChainBuy:UI_ERROR_MESSAGE(msg, err)
	self:UnregisterEvent('UI_ERROR_MESSAGE');
	self:UnregisterEvent('CHAT_MSG_SYSTEM');
	--print(GetTime(), 'UI_ERROR_MESSAGE', err);
	if err == 443 then
		--print('unlocking button')
		-- last time we failed to buy so we reset
		self.isPaused = false;
		self:ShowWindow();
	end
end


function ChainBuy:AddBuyRequest(request)
	tinsert(self.requests, request);
	self:UpdateWindow();
end

---- Queue Processing

function ChainBuy:Start(initialQueue, progressCallback)
	if initialQueue then
		self.requests = initialQueue;
		self.initialQueue = initialQueue;
		self.currentRequest = initialQueue[1];
		self.boughtSoFar = 0;
	end

	if progressCallback then
		self.progressCallback = progressCallback;
	end

	if self.currentIndex == 0 then
		self.isPaused = false;
		self.boughtSoFar = 0;
		self:ProcessNext();
	end
end

function ChainBuy:Cancel()
	self:Pause();
	wipe(self.requests);
	self.currentIndex = 0;
	self.boughtSoFar = 0;
	self.currentRequest = nil;
	self.window:Hide();
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
end

function ChainBuy:ShowWindow()
	if self.window then
		self.window:Show();
		self:UpdateWindow();
		return;
	end

	local window = StdUi:Window(UIParent, 'Chain Buy', 400, 300);
	window:SetPoint('CENTER');

	window.itemIcon = StdUi:Texture(window, 32, 32, '');
	window.itemName = StdUi:Label(window, '', 14);
	window.qty = StdUi:Label(window, '', 20);
	window.pricePerItem = StdUi:Label(window, '', 14);
	window.priceTotal = StdUi:Label(window, '', 14);
	window.boughtSoFar = StdUi:Label(window, '', 20);

	window.buyButton = StdUi:Button(window, 70, 24, 'Buy');
	window.skipButton = StdUi:Button(window, 70, 24, 'Skip');
	window.closeButton = StdUi:Button(window, 150, 24, 'Close');

	window.buyButton:SetScript('OnClick', function()
		ChainBuy:PerformBuy();
	end);

	window.skipButton:SetScript('OnClick', function()
		ChainBuy:ProcessNext();
	end);

	window.closeButton:SetScript('OnClick', function()
		ChainBuy.window:Hide();
		self:Cancel();
	end);

	window.closeBtn:SetScript('OnClick', function()
		ChainBuy.window:Hide();
		self:Cancel();
	end);

	--- @type StatusBar
	window.progressBar = StdUi:ProgressBar(window, 400, 20);
	window.progressBar.TextUpdate = function(self, min, max, value)
		return value .. ' / ' .. max;
	end;

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

	self.window = window;
	self.window:Show();
end

function ChainBuy:UpdateWindow()
	if not self.currentRequest or not self.window then return; end

	local window = self.window;
	local req = self.currentRequest;
	--UIParentLoadAddOn("Blizzard_DebugTools")
	--DevTools_Dump(req);
	window.itemIcon:SetTexture(req.texture);
	window.itemName:SetText(req.itemLink);
	window.qty:SetText('Qty: ' .. req.count);
	window.pricePerItem:SetText('Per Item: ' .. StdUi.Util.formatMoney(req.buy));
	window.priceTotal:SetText('Total: ' .. StdUi.Util.formatMoney(req.buy * req.count));
	window.boughtSoFar:SetText('Bought so far: ' .. self.boughtSoFar);

	window.progressBar:SetMinMaxValues(0, #self.requests);
	window.progressBar:SetValue(self.currentIndex);

	if self.initialQueue then
		window:SetWindowTitle('Chain Buy');
	else
		window:SetWindowTitle('Queue');
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

