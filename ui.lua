local MAJOR, MINOR = 'StdUi-1.0', 1;
local StdUi = LibStub:NewLibrary(MAJOR, MINOR)

if not StdUi then
	return;
end

StdUi.config = {
	font = 'Fonts\\FRIZQT__.TTF',
	fontSize = 12,
	fontEffect = 'OUTLINE',
	fontStrata = 'OVERLAY'
};

function StdUi:SetDefaultFont(font, size)
	self.config.font = font;
	self.config.fontSize = size;
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

--
-- Positioning functions
--
function StdUi:GlueBelow(object, referencedObject, x, y)
	object:SetPoint('TOPLEFT', referencedObject, 'BOTTOMLEFT', x, y);
end

function StdUi:GlueAbove(object, referencedObject, x, y)
	object:SetPoint('BOTTOMLEFT', referencedObject, 'TOPLEFT', x, y);
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

function StdUi:Label(parent, size, text, inherit, width, height)

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

	if normalTexture then
		local normTex = 'Interface/Buttons/UI-Panel-Button-Up';
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
	local editBox = CreateFrame('EditBox', nil, parent, 'InputBoxTemplate');
	editBox:SetAutoFocus(false);
	self:SetObjSize(editBox, width, height);
	if text then
		editBox:SetText(text);
	end

	return editBox;
end

function StdUi:EditBoxWithLabel(parent, width, height, text, label, labelFontSize, labelPosition, labelWidth)
	local editBox = CreateFrame('EditBox', nil, parent, 'InputBoxTemplate');
	editBox:SetAutoFocus(false);
	self:SetObjSize(editBox, width, height);
	if text then
		editBox:SetText(text);
	end

	local labelHeight = (labelFontSize or 12) + 4;
	local label = self:Label(parent, labelFontSize or 12, label, nil, labelWidth, labelHeight);

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
	local scrollFrame = CreateFrame('ScrollFrame', name, parent, 'UIPanelScrollFrameTemplate');
	scrollFrame:SetSize(width, height);

	local scrollBar = _G[name .. 'ScrollBar'];

	local scrollChild = CreateFrame('Frame', name .. 'ScrollChild', scrollFrame);
	scrollChild:SetWidth(scrollFrame:GetWidth());
	scrollChild:SetHeight(scrollFrame:GetHeight());

	scrollFrame:SetScrollChild(scrollChild);
	scrollFrame:EnableMouse(true);
	scrollFrame:SetClampedToScreen(true);

	return scrollFrame, scrollChild, scrollBar;
end

