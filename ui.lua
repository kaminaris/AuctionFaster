local MAJOR, MINOR = 'StdUi-1.0', 1;
local StdUi = LibStub:NewLibrary(MAJOR, MINOR);

if not StdUi then
	return;
end

local ScrollingTable = LibStub('ScrollingTable');

StdUi.config = {};

function StdUi:ResetConfig()
	self.config = {
		font = {
			familly = 'Fonts\\FRIZQT__.TTF',
			sizeize = 12,
			effect = 'OUTLINE',
			strata = 'OVERLAY',
		},

		backdrop = {
			panel = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
			button = { r = 0.25, g = 0.25, b = 0.25, a = 1 },
			border = { r = 0.8, g = 0.8, b = 0.8, a = 1 }
		}
	};
end
StdUi:ResetConfig();

function StdUi:SetDefaultFont(font, size, effect, strata)
	self.config.font.familly = font;
	self.config.font.size = size;
	self.config.font.effect = effect;
	self.config.font.strata = strata;
end

--
-- Conditionally set object width and height
--
function StdUi:SetObjSize(obj, width, height)
	if width then
		obj:SetWidth(width);
	end

	if height then
		obj:SetHeight(height);
	end
end

function StdUi:ApplyBackdrop(frame, type)
	frame:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
	});

	type = type or 'button';

	frame:SetBackdropColor(
		self.config.backdrop[type].r,
		self.config.backdrop[type].g,
		self.config.backdrop[type].b,
		self.config.backdrop[type].a
	);
	frame:SetBackdropBorderColor(
		self.config.backdrop.border.r,
		self.config.backdrop.border.g,
		self.config.backdrop.border.b,
		self.config.backdrop.border.a
	);
end

--
-- Positioning functions
--
function StdUi:GlueBelow(object, referencedObject, x, y)
	object:SetPoint('TOPLEFT', referencedObject, 'BOTTOMLEFT', x, y);
end

function StdUi:GlueAbove(object, referencedObject, x, y)
	object:SetPoint('BOTTOMLEFT', referencedObject, 'TOPLEFT', x, y);
end

function StdUi:GlueTop(object, referencedObject, x, y)
	object:SetPoint('TOP', referencedObject, 'TOP', x, y);
end

function StdUi:GlueTopRight(object, referencedObject, x, y)
	object:SetPoint('TOPLEFT', referencedObject, 'BOTTOMLEFT', x, y);
end

function StdUi:GlueRight(object, referencedObject, x, y)
	object:SetPoint('LEFT', referencedObject, 'RIGHT', x, y);
end

function StdUi:GlueLeft(object, referencedObject, x, y)
	object:SetPoint('RIGHT', referencedObject, 'LEFT', x, y);
end


--[[
-- Simple frame panel
 ]]
function StdUi:Panel(parent, width, height, inherits)
	local frame = CreateFrame('Frame', nil, parent, inherits);
	self:SetObjSize(frame, width, height);
	self:ApplyBackdrop(frame, 'panel');

	return frame;
end

function StdUi:Label(parent, text, size, inherit, width, height)

	local fs = parent:CreateFontString(nil, self.config.fontStrata, inherit);

	fs:SetFont(self.config.font, size or self.config.fontSize, self.config.fontEffect);
	fs:SetText(text);
	self:SetObjSize(fs, width, height);

	fs:SetJustifyH('LEFT');
	fs:SetJustifyV('MIDDLE');

	return fs;
end

function StdUi:Texture(parent, width, height, texture)
	local tex = parent:CreateTexture(nil, 'ARTWORK');

	self:SetObjSize(tex, width, height);
	if texture then
		tex:SetTexture(texture);
	end

	return tex;
end

function StdUi:PanelButton(parent, width, height, text)
	local button = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate');
	self:SetObjSize(button, width, height);
	if text then
		button:SetText(text);
	end

	return button;
end

function StdUi:Button(parent, width, height, text, normalTexture, highlightTexture, pushTexture)
	local button = CreateFrame('Button', nil, parent)
	self:SetObjSize(button, width, height);

	if text then
		button:SetText(text);
		button:SetNormalFontObject('GameFontNormal');
	end

	self:ApplyBackdrop(button);

	if normalTexture then
		local normTex; --'Interface/Buttons/UI-Panel-Button-Up';
		if normalTexture ~= true then
			normTex = normalTexture;
		end


		local ntex = self:Texture(button, nil, nil, normTex);
		ntex:SetTexCoord(0, 0.625, 0, 0.6875);
		ntex:SetAllPoints();

		button:SetNormalTexture(ntex);
		button.normalTexture = ntex;
	end

	if highlightTexture then
		local highTex = 'Interface/Buttons/UI-Panel-Button-Highlight';
		if highlightTexture ~= true then
			highTex = highlightTexture;
		end
		local htex = self:Texture(button, nil, nil, highTex);
		htex:SetTexCoord(0, 0.625, 0, 0.6875)
		htex:SetAllPoints();
		button:SetHighlightTexture(htex);
		button.highlightTexture = htex;
	end

	if pushTexture then
		local pushTex = 'Interface/Buttons/UI-Panel-Button-Down';
		if pushTexture ~= true then
			pushTex = pushTexture;
		end
		local ptex = self:Texture(button, nil, nil, pushTex);

		ptex:SetTexCoord(0, 0.625, 0, 0.6875)
		ptex:SetAllPoints()
		button:SetPushedTexture(ptex)
		button.pushedTexture = ptex;
	end

	return button;
end

function StdUi:EditBox(parent, width, height, text)
	local editBox = CreateFrame('EditBox', nil, parent);
	editBox:SetTextInsets(3, 3, 3, 3);
	editBox:SetMaxLetters(256);
	editBox:SetFontObject(ChatFontNormal);
	editBox:SetAutoFocus(false);
	editBox:SetScript('OnEscapePressed', function (self)
		self:ClearFocus();
	end);
	self:ApplyBackdrop(editBox);

	self:SetObjSize(editBox, width, height);
	if text then
		editBox:SetText(text);
	end

	return editBox;
end

function StdUi:EditBoxWithLabel(parent, width, height, text, label, labelFontSize, labelPosition, labelWidth)
	local editBox = self:EditBox(parent, width, height, text);

	local labelHeight = (labelFontSize or 12) + 4;
	local label = self:Label(parent, label, labelFontSize or 12, nil, labelWidth, labelHeight);

	if labelPosition == 'TOP' or labelPosition == nil then
		self:GlueAbove(label, editBox, 0, 4)
	else -- labelPosition == 'LEFT'
		label:SetWidth(labelWidth or label:GetStringWidth())
		self:GlueLeft(label, editBox, 4, 0);
	end

	editBox.label = label;

	return editBox;
end

function StdUi:ActionButton(parent)
end


function StdUi:ScrollFrame(parent, name, width, height)
	local panel = self:Panel(parent, width, height);

	local scrollFrame = CreateFrame('ScrollFrame', name, panel, 'UIPanelScrollFrameTemplate');
	scrollFrame.panel = panel;
	scrollFrame:SetSize(width - 20, height - 4); -- scrollbar width and margins
	scrollFrame:SetPoint('TOPLEFT', 0, -2);
	scrollFrame:SetPoint('BOTTOMRIGHT', -20, 2);

	local scrollBar = _G[name .. 'ScrollBar'];
	scrollBar:ClearAllPoints();
	scrollBar:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, -20);
	scrollBar:SetPoint('BOTTOMLEFT', panel, 'BOTTOMRIGHT', -20, 20);

	local scrollChild = CreateFrame('Frame', name .. 'ScrollChild', scrollFrame);
	scrollChild:SetWidth(scrollFrame:GetWidth());
	scrollChild:SetHeight(scrollFrame:GetHeight());

	scrollFrame:SetScrollChild(scrollChild);
	scrollFrame:EnableMouse(true);
	scrollFrame:SetClampedToScreen(true);

	return panel, scrollFrame, scrollChild, scrollBar;
end

function StdUi:ScrollingTable(parent, columns, visibleRows, rowHeight)
	local scrollingTable = ScrollingTable:CreateST(columns, visibleRows, rowHeight, nil, parent);
	self:ApplyBackdrop(scrollingTable.frame, 'panel');

	return scrollingTable;
end
