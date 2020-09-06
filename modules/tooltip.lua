---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
local Tooltip = AuctionFaster:NewModule('Tooltip', 'AceHook-3.0');
local ItemCache = AuctionFaster:GetModule('ItemCache');

--- @var StdUi StdUi
local StdUi = LibStub('StdUi');
local L = LibStub('AceLocale-3.0'):GetLocale('AuctionFaster');

function Tooltip:Attach()
	if not self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:HookScript(GameTooltip, 'OnTooltipSetItem', 'UpdateTooltip');
		if BattlePetTooltipTemplate_SetBattlePet then
			if BPBID_SetBreedTooltip then
				self:HookBattlePetBreedId();
			else
				self:SecureHook('BattlePetTooltipTemplate_SetBattlePet', 'UpdateBattlePetTooltip');
			end
		end

		AuctionFaster:Echo(2, L['Tooltips enabled']);
	end
end

function Tooltip:Detach()
	if self:IsHooked(GameTooltip, 'OnTooltipSetItem') then
		self:Unhook(GameTooltip, 'OnTooltipSetItem');
		if BattlePetTooltipTemplate_SetBattlePet then
			self:Unhook('BattlePetTooltipTemplate_SetBattlePet');
		end

		AuctionFaster:Echo(2, L['Tooltips disabled']);
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
		tooltip:AddLine(L['AuctionFaster']);
		tooltip:AddDoubleLine(L['Lowest Bid: '], StdUi.Util.formatMoney(cacheItem.bid));
		tooltip:AddDoubleLine(L['Lowest Buy: '], StdUi.Util.formatMoney(cacheItem.buy));

		-- @TODO: looks like its not needed
		--tooltip:Show();
	end
end

function Tooltip:FixTSM()
	if IsAddOnLoaded('TradeSkillMaster') then
		for i = 1, 10 do
			local t = _G['TSMExtraTip' .. i];
			if t then
				if t:GetParent() == BattlePetTooltip or t:GetParent() == FloatingBattlePetTooltip then
					t:ClearAllPoints();
					t:SetPoint('TOP', AFBattlePetTooltip, 'BOTTOM', 0, -1);
				end
			end
		end
	end
end

function Tooltip:HookBattlePetBreedId()
	-- keep original function reference
	BPBID_SetBreedTooltipOrig = BPBID_SetBreedTooltip;
	local internal = BPBID_Internal;
	local BPBID_Options = BPBID_Options;
	local BPBID_Arrays = BPBID_Arrays;

	BPBID_SetBreedTooltip = function(parent, speciesID, tblBreedID, rareness, tooltipDistance)
		-- Impossible checks (if missing parent, speciesID, or 'rareness')
		if not parent or not speciesID then
			return;
		end
		local petName = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
		local afPane = Tooltip:UpdateBattlePetTooltip(parent, {name = petName});
		local origWidth = afPane:GetWidth();
		afPane:AddLine('');

		local rarity = rareness or 4;

		-- Arrays are now initialized if they weren't before
		if not BPBID_Arrays.BasePetStats then
			BPBID_Arrays.InitializeArrays();
		end

		-- Set line for 'Current pet's breed'
		if BPBID_Options.Breedtip.Current and tblBreedID then
			local current = '\124cFFD4A017Current Breed:\124r ';
			local numBreeds = #tblBreedID;

			for i = 1, numBreeds do
				if i == 1 then
					current = current .. internal.RetrieveBreedName(tblBreedID[i])
				elseif i == 2 and i == numBreeds then
					current = current .. ' or ' .. internal.RetrieveBreedName(tblBreedID[i])
				elseif i == numBreeds then
					current = current .. ', or ' .. internal.RetrieveBreedName(tblBreedID[i])
				else
					current = current .. ', ' .. internal.RetrieveBreedName(tblBreedID[i])
				end
			end

			afPane:AddLine(current);
		end

		-- Set line for 'Current pet's possible breeds'
		if BPBID_Options.Breedtip.Possible then
			local possible = '\124cFFD4A017Possible Breed';

			if speciesID and BPBID_Arrays.BreedsPerSpecies[speciesID] then
				local breeds = BPBID_Arrays.BreedsPerSpecies[speciesID];
				local numBreeds = #breeds;

				if numBreeds == internal.MAX_BREEDS then
					possible = possible .. 's:\124r All';
				else
					for i = 1, numBreeds do
						if numBreeds == 1 then
							possible = possible .. ':\124r ' .. internal.RetrieveBreedName(breeds[i]);
						elseif i == 1 then
							possible = possible .. 's:\124r ' .. internal.RetrieveBreedName(breeds[i]);
						elseif i == 2 and i == numBreeds then
							possible = possible .. ' and ' .. internal.RetrieveBreedName(breeds[i]);
						elseif i == numBreeds then
							possible = possible .. ', and ' .. internal.RetrieveBreedName(breeds[i]);
						else
							possible = possible .. ', ' .. internal.RetrieveBreedName(breeds[i]);
						end
					end
				end
			else
				possible = possible .. 's:\124r Unknown';
			end

			afPane:AddLine(possible, 1, 1, 1);
		end

		-- Have to have BasePetStats from here on out
		if BPBID_Arrays.BasePetStats[speciesID] then
			local stats = BPBID_Arrays.BasePetStats[speciesID];

			-- Set line for 'Pet species' base stats'
			if BPBID_Options.Breedtip.SpeciesBase then
				local speciesBase = format('\124cFFD4A017Base Stats:\124r %d/%d/%d', stats[1], stats[2], stats[3]);
				afPane:AddLine(speciesBase);
			end

			local breeds = BPBID_Arrays.BreedsPerSpecies[speciesID];
			local extraBreeds;

			-- Check duplicates (have to have BreedsPerSpecies and tblBreedID for this)
			if breeds and tblBreedID then
				extraBreeds = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

				-- 'inspection' time! if the breed is not found in the array,
				-- it doesn't get passed on to extrabreeds and is effectively discarded
				for q = 1, #tblBreedID do
					for i = 1, #breeds do
						local j = breeds[i];

						-- If the breed is found in both tables, flag it as false
						if tblBreedID[q] == j then
							extraBreeds[j - 2] = false;
						end

						if extraBreeds[j - 2] then
							extraBreeds[j - 2] = j;
						end
					end
				end
			end

			-- Set line for 'Current breed's base stats (level 1 Poor)' (have to have tblBreedID for this)
			if BPBID_Options.Breedtip.CurrentStats and tblBreedID then
				for i = 1, #tblBreedID do
					local currentBreed = tblBreedID[i];
					local breedStats = BPBID_Arrays.BreedStats[currentBreed];
					local currentStats = format(
						'\124cFFD4A017Breed %s*:\124r %d/%d/%d',
						internal.RetrieveBreedName(currentBreed),
						(stats[1] + breedStats[1]),
						(stats[2] + breedStats[2]),
						(stats[3] + breedStats[3])
					);

					afPane:AddLine(currentStats)
				end
			end

			-- Set line for 'All breeds' base stats (level 1 Poor)' (have to have BreedsPerSpecies for this)
			if BPBID_Options.Breedtip.AllStats and breeds then
				if not BPBID_Options.Breedtip.CurrentStats or not extraBreeds then
					for i = 1, #breeds do
						local currentBreed = breeds[i];
						local breedStats = BPBID_Arrays.BreedStats[currentBreed];

						local allStatsP1 = '\124cFFD4A017Breed ' .. internal.RetrieveBreedName(currentBreed);
						local allStatsP2 = format(
							':\124r %d/%d/%d',
							(stats[1] + breedStats[1]),
							(stats[2] + breedStats[2]),
							(stats[3] + breedStats[3])
						);

						-- Will be defined by the if statement below to see the asterisk needs to be added
						local allStats;

						if not extraBreeds or (extraBreeds[currentBreed - 2] and extraBreeds[currentBreed - 2] > 2) then
							allStats = allStatsP1 .. allStatsP2;
						else
							allStats = allStatsP1 .. '*' .. allStatsP2;
						end

						afPane:AddLine(allStats);
					end
				else
					for i = 1, 10 do
						if (extraBreeds[i]) and (extraBreeds[i] > 2) then
							local currentBreed = i + 2;
							local breedStats = BPBID_Arrays.BreedStats[currentBreed];

							local allStats = format('\124cFFD4A017Breed %s:\124r %d/%d/%d',
								internal.RetrieveBreedName(currentBreed),
								(stats[1] + breedStats[1]),
								(stats[2] + breedStats[2]),
								(stats[3] + breedStats[3])
							);

							afPane:AddLine(allStats);
						end
					end
				end
			end

			-- Set line for 'Current breed's stats at level 25' (have to have tblBreedID for this)
			if BPBID_Options.Breedtip.CurrentStats25 and tblBreedID then
				for i = 1, #tblBreedID do
					local currentBreed = tblBreedID[i];
					local breedStats = BPBID_Arrays.BreedStats[currentBreed];

					-- Always use rare color by default
					local hex = '\124cFF0070DD';
					-- Always use rare pet quality by default
					local quality = 4;

					-- Unless the user specifies they want the real color OR the pet is epic/legendary quality
					if not BPBID_Options.Breedtip.AllStats25Rare or rarity > 4 then
						hex = ITEM_QUALITY_COLORS[rarity - 1].hex;
						quality = rarity;
					end

					local rarityV = BPBID_Arrays.RealRarityValues[quality];

					local currentStats25 = format(
						'%s%s* at 25:\124r %d/%d/%d',
						hex,
						internal.RetrieveBreedName(currentBreed),
						ceil((stats[1] + breedStats[1]) * 25 * ((rarityV - 0.5) * 2 + 1) * 5 + 100 - 0.5),
						ceil((stats[2] + breedStats[2]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5),
						ceil((stats[3] + breedStats[3]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5)
					);

					afPane:AddLine(currentStats25);
				end
			end

			-- Set line for 'All breeds' stats at level 25' (have to have BreedsPerSpecies for this)
			if BPBID_Options.Breedtip.AllStats25 and breeds then
				-- Always use rare color by default
				local hex = '\124cFF0070DD';
				-- Always use rare pet quality by default
				local quality = 4;

				-- Unless the user specifies they want the real color OR the pet is epic/legendary quality
				if not BPBID_Options.Breedtip.AllStats25Rare or rarity > 4 then
					hex = ITEM_QUALITY_COLORS[rarity - 1].hex;
					quality = rarity;
				end

				-- Choose loop (whether I have to show ALL breeds including the one I am looking at or just the other breeds besides the one I'm looking at)
				if (rarity == 4 and BPBID_Options.Breedtip.CurrentStats25Rare ~= BPBID_Options.Breedtip.AllStats25Rare) or
					not BPBID_Options.Breedtip.CurrentStats25 or
					not extraBreeds
				then
					for i = 1, #breeds do
						local currentBreed = breeds[i];
						local breedStats = BPBID_Arrays.BreedStats[currentBreed];
						local rarityV = BPBID_Arrays.RealRarityValues[quality];

						local asterisk = not extraBreeds or (extraBreeds[currentBreed - 2] and
							extraBreeds[currentBreed - 2] > 2);

						local allStats25 = format(
							'%s%s%s at 25:\124r %d/%d/%d',
							hex,
							internal.RetrieveBreedName(currentBreed),
							asterisk and '*' or '',
							ceil((stats[1] + breedStats[1]) * 25 * ((rarityV - 0.5) * 2 + 1) * 5 + 100 - 0.5),
							ceil((stats[2] + breedStats[2]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5),
							ceil((stats[3] + breedStats[3]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5)
						);

						afPane:AddLine(allStats25, 1, 1, 1, 1)
					end
				else
					for i = 1, 10 do
						if extraBreeds[i] and extraBreeds[i] > 2 then
							local currentBreed = i + 2;
							local breedStats = BPBID_Arrays.BreedStats[currentBreed];
							local rarityV = BPBID_Arrays.RealRarityValues[quality];

							local allStats25 = format(
								'%s%s at 25:\124r %d/%d/%d',
								hex,
								internal.RetrieveBreedName(currentBreed),
								ceil((stats[1] + breedStats[1]) * 25 * ((rarityV - 0.5) * 2 + 1) * 5 + 100 - 0.5),
								ceil((stats[2] + breedStats[2]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5),
								ceil((stats[3] + breedStats[3]) * 25 * ((rarityV - 0.5) * 2 + 1) - 0.5)
							);
							afPane:AddLine(allStats25, 1, 1, 1, 1)
						end
					end
				end
			end
		end

		afPane:SetWidth(origWidth);
		Tooltip:FixTSM();
	end
end

function Tooltip:UpdateBattlePetTooltip(tooltip, petData)
	if not tooltip.afPane then
		tooltip.afPane = StdUi:FrameTooltip(tooltip, '', 'AFBattlePetTooltip', 'BOTTOM', false, false);
	end

	tooltip.afPane:SetText('');
	local cacheItem = ItemCache:GetItemFromCache(82800, petData.name, true);
	if not cacheItem then
		return tooltip.afPane;
	end

	tooltip.afPane:AddLine(L['AuctionFaster']);
	tooltip.afPane:AddLine(L['Lowest Bid: '] .. StdUi.Util.formatMoney(cacheItem.bid));
	tooltip.afPane:AddLine(L['Lowest Buy: '] .. StdUi.Util.formatMoney(cacheItem.buy));

	tooltip.afPane:Show();
	tooltip.afPane:SetWidth(tooltip:GetWidth());
	Tooltip:FixTSM();
	return tooltip.afPane;
end
