---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

--- @class Pricing
local Pricing = AuctionFaster:NewModule('Pricing');

local TableInsert = tinsert;
local floor = math.floor;
local pow = math.pow;
local sqrt = math.sqrt;
local format = string.format;
local pairs = pairs;
local UnitName = UnitName;

Pricing.models = {};

function Pricing:RegisterPricingModel(name, method)
	self.models[name] = method;
end

function Pricing:GetPricingModels()
	local builtFunctions = {
		{ text = L['LowestPrice'], value = 'Simple' },
		{ text = L['WeightedAverage'], value = 'WeightedAverage' },
		{ text = L['StackAware'], value = 'Stack' },
		{ text = L['StandardDeviation'], value = 'StandardDeviation' },
	}

	for name, v in pairs(self.models) do
		TableInsert(builtFunctions, { text = name, value = name });
	end

	return builtFunctions;
end

function Pricing:CalculateStatData(auctions)
	local auctionInfo = {
		totalQty           = 0,
		totalQtyWithBuy    = 0,
		totalBuy           = 0,
		averageQty         = 0,
		totalBuy           = 0, -- Total price without quantity
		totalBid           = 0,
		weightedTotalBuy   = 0, -- Total price including quantity
		weightedTotalBid   = 0,
		averageBuy         = 0, -- Average price without quantity
		averageBid         = 0,
		weightedAverageBuy = 0, -- Average price including quantity
		weightedAverageBid = 0,
		lowestBuy          = nil,
		lowestBid          = nil,
		highestBuy         = nil,
		highestBid         = nil,
		estimatedVolume    = 0
	}

	for _, auction in pairs(auctions) do
		local bid, buy = auction.bid, auction.buy;
		auctionInfo.totalQty = auctionInfo.totalQty + auction.count;

		if buy and buy > 0 then
			auctionInfo.weightedTotalBuy = auctionInfo.weightedTotalBuy + (auction.count * buy);
			auctionInfo.totalQtyWithBuy = auctionInfo.totalQtyWithBuy + auction.count;
			auctionInfo.totalBuy = auctionInfo.totalBuy + 1;
		end

		if bid and bid > 0 then
			auctionInfo.weightedTotalBid = auctionInfo.weightedTotalBid + (auction.count * bid);
		end

		if buy and buy > 0 then
			auctionInfo.totalBuy = auctionInfo.totalBuy + buy;
		end

		if bid and bid > 0 then
			auctionInfo.totalBid = auctionInfo.totalBid + bid;
		end

		if buy and buy > 0 and (not auctionInfo.lowestBuy or auctionInfo.lowestBuy > buy) then
			auctionInfo.lowestBuy = buy;
		end

		if bid and (not auctionInfo.lowestBid or auctionInfo.lowestBid > bid) then
			auctionInfo.lowestBid = bid;
		end

		if buy and buy > 0 and (not auctionInfo.highestBuy or auctionInfo.highestBuy < buy) then
			auctionInfo.highestBuy = buy;
		end

		if bid and (not auctionInfo.highestBid or auctionInfo.highestBid < bid) then
			auctionInfo.highestBid = bid;
		end
	end

	local averageQty = auctionInfo.totalQty / #auctions;
	if auctionInfo.totalBuy > 0 then
		auctionInfo.averageBuy = floor(auctionInfo.totalBuy / auctionInfo.totalBuy);
	end
	auctionInfo.averageBid = floor(auctionInfo.totalBid / #auctions);

	if auctionInfo.totalQtyWithBuy > 0 then
		auctionInfo.weightedAverageBuy = floor(auctionInfo.weightedTotalBuy / auctionInfo.totalQtyWithBuy);
	end
	auctionInfo.weightedAverageBid = floor(auctionInfo.weightedTotalBid / auctionInfo.totalQty);

	auctionInfo.estimatedVolume = averageQty * #auctions;

	return auctionInfo;
end

function Pricing:RoundPrice(p)
	return Round(Round(p / 100) * 100);
end

function Pricing:CalculatePrice(priceModel, auctions)
	local auctionInfo = self:CalculateStatData(auctions);
	local bid, buy, success;

	if self[priceModel] then
		bid, buy, success = self[priceModel](self, auctionInfo);
	elseif self.models[priceModel] then
		bid, buy, success = self.models[priceModel](self, auctionInfo);
	end

	if bid then
		bid = self:RoundPrice(bid);
	end

	if buy then
		buy = self:RoundPrice(buy);
	end

	return bid, buy, success;
end

function Pricing:ClampBid(bid, buy)
	local maxBidDeviation = AuctionFaster.db.pricing.maxBidDeviation;
	if not maxBidDeviation then
		maxBidDeviation = 20;
	end

	local limit = ((100 - maxBidDeviation) / 100) * buy;
	return Clamp(bid, limit, buy);
end

--- This function should return calculated bid, buy and boolean if there was some issue with calculations
---@return number, number, boolean
function Pricing:Simple(auctionInfo)
	if auctionInfo.totalQty == 0 then
		return nil, nil, true, L['No auctions found'];
	end

	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid;
	end

	return self:ClampBid(lowestBid, lowestBuy), lowestBuy, false;
end

function Pricing:WeightedAverage(auctionInfo)
	if auctionInfo.totalQty == 0 then
		return nil, nil, true, L['No auctions found'];
	end

	local lowestBid, lowestBuy = auctionInfo.weightedAverageBid, auctionInfo.weightedAverageBuy;

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid;
	end

	return self:ClampBid(lowestBid, lowestBuy), lowestBuy, false;
end

function Pricing:StandardDeviation(auctionInfo)
	local buyVariance, bidVariance = 0, 0;

	for i = 1, #auctionInfo.auctions do
		local auction = auctionInfo.auctions[i];
		buyVariance = buyVariance + (pow(auction.buy - auctionInfo.weightedAverageBuy, 2) * auction.count);
		bidVariance = bidVariance + (pow(auction.bid - auctionInfo.weightedAverageBid, 2) * auction.count);
	end

	local buyStdDev = sqrt(buyVariance / auctionInfo.totalQty);
	local bidStdDev = sqrt(bidVariance / auctionInfo.totalQty);

	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	lowestBuy = floor(lowestBuy + buyStdDev);
	lowestBid = floor(lowestBid + bidStdDev);

	lowestBid = self:ClampBid(lowestBid, lowestBuy);

	return lowestBid, lowestBuy, false;
end

function Pricing:Stack(auctionInfo)
	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	local minQty = floor(auctionInfo.stackSize * 0.5);

	for i = 1, #auctionInfo.auctions do
		local auction = auctionInfo.auctions[i];
		if auction.count >= minQty then
			lowestBid, lowestBuy = auction.bid, auction.buy;
			lowestBid = self:ClampBid(lowestBid, lowestBuy);

			return lowestBid, lowestBuy, false;
		end
	end

	lowestBid = self:ClampBid(lowestBid, lowestBuy);
	return lowestBid, lowestBuy, true, format(L['No auction found with minimum quantity: %d'], minQty);
end