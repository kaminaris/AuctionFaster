--[[
	Original code borrowed from ChampionCommander:
	https://wow.curseforge.com/projects/championcommander
--]]

---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @class Tutorial
local Tutorial = AuctionFaster:NewModule('Tutorial', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');


local KEY_BUTTON1 = '\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t' -- left mouse button
local KEY_BUTTON2 = '\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t' -- right mouse button


local HelpPlateXTooltip = HelpPlateXTooltip;
local HelpPlateX_TooltipHide = function()
	HelpPlateXTooltip.ArrowUP:Hide();
	HelpPlateXTooltip.ArrowGlowUP:Hide();
	HelpPlateXTooltip.ArrowDOWN:Hide();
	HelpPlateXTooltip.ArrowGlowDOWN:Hide();
	HelpPlateXTooltip.ArrowLEFT:Hide();
	HelpPlateXTooltip.ArrowGlowLEFT:Hide();
	HelpPlateXTooltip.ArrowRIGHT:Hide();
	HelpPlateXTooltip.ArrowGlowRIGHT:Hide();
	HelpPlateXTooltip:ClearAllPoints();
	HelpPlateXTooltip:Hide();
end

local plateStrata = HelpPlateXTooltip:GetFrameStrata();
local currentTutorialIndex;

local Clicker;
local Enhancer;

Tutorial.tutorials = {};
Tutorial.callback = nil;

local function callOrUse(data)
	if type(data) == 'function' then
		return data();
	else
		return data;
	end
end


local function plate(self, tutorial)
	local text;
	local rc = false;

	if type(tutorial) == 'table' then
		if type(tutorial.action) == 'function' then
			tutorial.action();
		end

		text = callOrUse(tutorial.text);
		local anchor1 = callOrUse(tutorial.anchor);
		local owner, o2 = callOrUse(tutorial.parent);
		local customAnchor = callOrUse(tutorial.customAnchor);
		self:Hide();

		local arrow = 'ArrowRIGHT';
		local glow = 'ArrowGlowRIGHT';
		local x = 20;
		local y = 0;
		local anchor2 = 'RIGHT';

		if not owner then
			anchor1 = 'CENTER';
		end

		if anchor1 == 'RIGHT' then
			anchor2 = 'LEFT';
			arrow = 'ArrowLEFT';
			glow = 'ArrowGlowLEFT';
			x = -20;
			y = 0;
		elseif anchor1 == 'BOTTOM' then
			anchor2 = 'TOP';
			arrow = 'ArrowUP';
			glow = 'ArrowGlowUP';
			x = 0;
			y = 20;
		elseif anchor1 == 'TOP' then
			anchor2 = 'BOTTOM';
			arrow = 'ArrowDOWN';
			glow = 'ArrowGlowDOWN';
			x = 0;
			y = -20;
		elseif anchor1 == 'CENTER' then
			anchor2 = 'CENTER';
			arrow = false;
			glow = false;
			x = 0;
			y = 0;
		end

		plateStrata = HelpPlateXTooltip:GetFrameStrata();
		HelpPlateXTooltip.HookedByBFA = true;

		if arrow then
			HelpPlateXTooltip[arrow]:Show();
		end

		if glow then
			HelpPlateXTooltip[glow]:Show();
		end

		HelpPlateXTooltip:SetPoint(anchor1, customAnchor or owner, anchor2, x, y);
		HelpPlateXTooltip:SetParent(owner);
		HelpPlateXTooltip:SetFrameStrata('TOOLTIP');
		Clicker:SetParent(HelpPlateXTooltip);
		Clicker:Show();

		if tutorial.noglow then
			Enhancer:Hide();
		else
			if owner then
				Enhancer:SetParent(owner);
				Enhancer:ClearAllPoints();

				if o2 then
					if o2:GetTop() >= owner:GetTop() and o2:GetLeft() <= owner:GetLeft() then
						Enhancer:SetPoint('TOPLEFT', owner, 'TOPLEFT');
						Enhancer:SetPoint('BOTTOMRIGHT', o2, 'BOTTOMRIGHT');
					elseif o2:GetTop() <= owner:GetTop() and o2:GetLeft() >= owner:GetLeft() then
						Enhancer:SetPoint('TOPLEFT', owner, 'TOPLEFT');
						Enhancer:SetPoint('BOTTOMRIGHT', o2, 'BOTTOMRIGHT');
					else
						Enhancer:SetAllPoints();
					end
				else
					if customAnchor then
						Enhancer:SetAllPoints(customAnchor);
					else
						Enhancer:SetAllPoints();
					end
				end

				Enhancer:SetFrameStrata(owner:GetFrameStrata());
				Enhancer:SetFrameLevel(owner:GetFrameLevel() + (tutorial.level or 0));


				Enhancer:Show();
			else
				Enhancer:Hide();
				text = tutorial.onmissing;
				rc = true;
			end
		end
	else
		text = tutorial;
	end

	HelpPlateXTooltip.Text:SetText(text .. '\n\n');
	HelpPlateXTooltip:Show();

	return rc;
end

function Tutorial:SetTutorials(tutorials)
	self.tutorials = tutorials;
	currentTutorialIndex = 1;
end

function Tutorial:Refresh()
	if HelpPlateXTooltip.HookedByBFA then
		local tutorial = self.tutorials[currentTutorialIndex];

		if tutorial then
			local text = type(tutorial.text) == 'function' and tutorial.text() or tutorial.text;
			plate(self, text);
			return;
		end
	end
end

function Tutorial:Hide(this)
	HelpPlateXTooltip.HookedByBFA = nil;
	HelpPlateXTooltip:SetFrameStrata(plateStrata);
	HelpPlateX_TooltipHide();
	HelpPlateXTooltip:SetParent(UIParent);

	Clicker:SetParent(nil);
	Clicker:Hide();

	Enhancer:SetParent(nil);
	Enhancer:Hide();
end

function Tutorial:Backward()
	currentTutorialIndex = math.max(currentTutorialIndex - 1, 1);
	self:Show();
end

function Tutorial:Forward()
	currentTutorialIndex = currentTutorialIndex + 1;
	self:Show();
end

function Tutorial:Home()
	currentTutorialIndex = 1;
	self:Show();
end

function Tutorial:Show(opening, callback)
	self.callback = callback;

	HelpPlateXTooltip.HookedByBFA = nil;
	if not currentTutorialIndex then
		currentTutorialIndex = 1;
	end

	local tutorial = self.tutorials[currentTutorialIndex];

	if tutorial then
		if opening and tutorial.back then
			currentTutorialIndex = currentTutorialIndex - tutorial.back;
			return self:Show();
		end

		if plate(self, tutorial) then
			Clicker.Forward:Hide();
		elseif currentTutorialIndex < #self.tutorials then
			Clicker.Forward:Show();
		else
			Clicker.Forward:Hide();
		end

		if currentTutorialIndex > 1 then
			Clicker.Backward:Show();
			Clicker.Home:Show();
		else
			Clicker.Backward:Hide();
			Clicker.Home:Hide();
		end
	else
		self:Terminate();
	end
end

function Tutorial:Terminate()
	self:Hide();
	if self.callback then
		self.callback();
	end
end

function Tutorial:OnEnable()
	if not Clicker then
		Clicker = CreateFrame('Frame', nil, HelpPlateXTooltip);

		Clicker.Close = CreateFrame('Button', nil, Clicker, 'UIPanelCloseButton');
		Clicker.Close:SetSize(32, 32);
		Clicker.Close:SetPoint('TOPRIGHT', 5, 5);
		Clicker.Close.tooltip = 'CLOSE';
		--Clicker.Close.SetScript('OnLeave', GameTooltip_Hide);
		--Clicker.Close.SetScript('OnEnter', OnEnter);

		Clicker.Home = CreateFrame('Button', nil, Clicker, 'UIPanelCloseButton');
		Clicker.Home:SetSize(16, 16);
		Clicker.Home:SetPoint('TOPLEFT', 0, 0);
		Clicker.Home.tooltip = 'HOME';
		Clicker.Home:SetNormalTexture([[Interface\BUTTONS\UI-HomeButton]]);
		Clicker.Home:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]]); --alphaMode ADD

		Clicker.Forward = CreateFrame('Button', nil, Clicker);
		Clicker.Forward:SetSize(32, 32);
		Clicker.Forward:SetPoint('BOTTOMRIGHT');
		Clicker.Forward:SetNormalTexture([[Interface\Glues\Common\Glue-RightArrow-Button-Up]]);
		Clicker.Forward:SetHighlightTexture([[Interface\Glues\Common\Glue-RightArrow-Button-Highlight]]); --alphaMode ADD
		Clicker.Forward:SetPushedTexture([[Interface\Glues\Common\Glue-RightArrow-Button-Down]]);

		Clicker.Backward = CreateFrame('Button', nil, Clicker);
		Clicker.Backward:SetSize(32, 32);
		Clicker.Backward:SetPoint('BOTTOMLEFT');
		Clicker.Backward:SetNormalTexture([[Interface\Glues\Common\Glue-LeftArrow-Button-Up]]);
		Clicker.Backward:SetHighlightTexture([[Interface\Glues\Common\Glue-LeftArrow-Button-Highlight]]); --alphaMode ADD
		Clicker.Backward:SetPushedTexture([[Interface\Glues\Common\Glue-LeftArrow-Button-Down]]);


		Clicker:SetAllPoints();
		self:RawHookScript(Clicker.Forward, 'OnClick', 'Forward');
		self:RawHookScript(Clicker.Backward, 'OnClick', 'Backward');
		self:RawHookScript(Clicker.Close, 'OnClick', 'Terminate');
		self:RawHookScript(Clicker.Home, 'OnClick', 'Home');

		Clicker.Home.tooltip = 'Restart the tutorial';
		Clicker.Close.tooltip = 'Terminate the tutorial';
	end

	if not Enhancer then
		Enhancer = CreateFrame('Frame', nil, nil, 'GlowBoxTemplate');
	end

	self:Hide();
end

