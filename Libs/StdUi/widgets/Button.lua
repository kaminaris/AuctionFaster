--- @type StdUi
local StdUi = LibStub and LibStub('StdUi', true);


function StdUi:PanelButton(parent, width, height, text)
	local button = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate');
	self:SetObjSize(button, width, height);
	if text then
		button:SetText(text);
	end

	return button;
end

--- @return Button
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


function StdUi:ActionButton(parent)
	-- NYI
end