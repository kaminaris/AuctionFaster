---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));

--- @class Pricing
local Pricing = AuctionFaster:NewModule('Pricing');

Pricing.models = {};

function Pricing:RegisterPricingModel(name, method)
	self.models[name] = method;
end

function Pricing:GetPricingModels()
	local builtFunctions = {
		{ text = 'LowestPrice', value = 'Simple' },
		{ text = 'WeightedAverage', value = 'WeightedAverage' },
		{ text = 'StackAware', value = 'Stack' },
		{ text = 'StandardDeviation', value = 'StandardDeviation' },
	}

	for name, v in pairs(self.models) do
		tinsert(builtFunctions, { text = name, value = name });
	end

	return builtFunctions;
end

function Pricing:CalculateStatData(itemRecord, auctions, stackSize, total, filter)
	local maxBidDeviation = AuctionFaster.db.pricing.maxBidDeviation;
	if not maxBidDeviation then
		maxBidDeviation = 20;
	end

	local auctionInfo = {
		itemRecord         = itemRecord,
		auctions           = {},
		stackSize          = stackSize,
		maxBidDeviation    = maxBidDeviation,
		totalItems         = total,
		totalQty           = 0,
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

	local playerName = UnitName('player');

	for i = 1, #auctions do
		local auction = auctions[i];
		if auction.owner ~= playerName and (not filter or filter(auction)) then
			tinsert(auctionInfo.auctions, auction);
			auctionInfo.totalQty = auctionInfo.totalQty + auction.count;

			auctionInfo.weightedTotalBuy = auctionInfo.weightedTotalBuy + (auction.count * auction.buy);
			auctionInfo.weightedTotalBid = auctionInfo.weightedTotalBid + (auction.count * auction.bid);

			auctionInfo.totalBuy = auctionInfo.totalBuy + auction.buy;
			auctionInfo.totalBid = auctionInfo.totalBid + auction.bid;

			if not auctionInfo.lowestBuy or auctionInfo.lowestBuy > auction.buy then
				auctionInfo.lowestBuy = auction.buy;
			end

			if not auctionInfo.lowestBid or auctionInfo.lowestBid > auction.bid then
				auctionInfo.lowestBid = auction.bid;
			end

			if not auctionInfo.highestBuy or auctionInfo.highestBuy < auction.buy then
				auctionInfo.highestBuy = auction.buy;
			end

			if not auctionInfo.highestBid or auctionInfo.highestBid < auction.bid then
				auctionInfo.highestBid = auction.bid;
			end
		end
	end

	local averageQty = auctionInfo.totalQty / #auctions;
	auctionInfo.averageBuy = math.floor(auctionInfo.totalBuy / #auctionInfo.auctions);
	auctionInfo.averageBid = math.floor(auctionInfo.totalBid / #auctionInfo.auctions);

	auctionInfo.weightedAverageBuy = math.floor(auctionInfo.weightedTotalBuy / auctionInfo.totalQty);
	auctionInfo.weightedAverageBid = math.floor(auctionInfo.weightedTotalBid / auctionInfo.totalQty);

	auctionInfo.estimatedVolume = averageQty * total;

	return auctionInfo;
end

function Pricing:CalculatePrice(priceModel, itemRecord, auctions, stackSize, total)
	local auctionInfo = self:CalculateStatData(itemRecord, auctions, stackSize, total);

	if self[priceModel] then
		return self[priceModel](self, auctionInfo);
	end

	if self.models[priceModel] then
		return self.models[priceModel](self, auctionInfo);
	end
end

function Pricing:ClampBid(bid, buy, maxBidDeviation)
	local limit = ((100 - maxBidDeviation) / 100) * buy;
	return Clamp(bid, limit, buy);
end

--- This function should return calculated bid, buy and boolean if there was some issue with calculations
---@return number, number, boolean
function Pricing:Simple(auctionInfo)
	if auctionInfo.totalQty == 0 then
		return nil, nil, true, 'No auctions found';
	end

	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid;
	end

	return self:ClampBid(lowestBid, lowestBuy, auctionInfo.maxBidDeviation), lowestBuy - 1, false;
end

function Pricing:WeightedAverage(auctionInfo)
	if auctionInfo.totalQty == 0 then
		return nil, nil, true, 'No auctions found';
	end

	local lowestBid, lowestBuy = auctionInfo.weightedAverageBid, auctionInfo.weightedAverageBuy;

	if lowestBuy and not lowestBid then
		lowestBid = lowestBuy;
	end

	if lowestBid and not lowestBuy then
		lowestBuy = lowestBid;
	end

	return self:ClampBid(lowestBid, lowestBuy, auctionInfo.maxBidDeviation), lowestBuy, false;
end

function Pricing:StandardDeviation(auctionInfo)
	local buyVariance, bidVariance = 0, 0;

	for i = 1, #auctionInfo.auctions do
		local auction = auctionInfo.auctions[i];
		buyVariance = buyVariance + (math.pow(auction.buy - auctionInfo.weightedAverageBuy, 2) * auction.count);
		bidVariance = bidVariance + (math.pow(auction.bid - auctionInfo.weightedAverageBid, 2) * auction.count);
	end

	local buyStdDev = math.sqrt(buyVariance / auctionInfo.totalQty);
	local bidStdDev = math.sqrt(bidVariance / auctionInfo.totalQty);

	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	lowestBuy = math.floor(lowestBuy + buyStdDev);
	lowestBid = math.floor(lowestBid + bidStdDev);

	lowestBid = self:ClampBid(lowestBid, lowestBuy, auctionInfo.maxBidDeviation);

	return lowestBid, lowestBuy, false;
end

function Pricing:Stack(auctionInfo)
	local lowestBid, lowestBuy = auctionInfo.lowestBid, auctionInfo.lowestBuy;

	local minQty = math.floor(auctionInfo.stackSize * 0.5);

	for i = 1, #auctionInfo.auctions do
		local auction = auctionInfo.auctions[i];
		if auction.count >= minQty then
			lowestBid, lowestBuy = auction.bid, auction.buy;
			lowestBid = self:ClampBid(lowestBid, lowestBuy, auctionInfo.maxBidDeviation);

			return lowestBid, lowestBuy - 1, false;
		end
	end

	lowestBid = self:ClampBid(lowestBid, lowestBuy, auctionInfo.maxBidDeviation);
	return lowestBid, lowestBuy, true, 'No auction found with minimum quantity: ' .. minQty;
end