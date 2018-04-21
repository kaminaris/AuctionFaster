local MAJOR, MINOR = "StdUi-1.0", 1;
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

function StdUi:Label(parent, size, text, inherit, width, height)

	local fs = parent:CreateFontString(nil, self.config.fontStrata, inherit);

	fs:SetFont(self.config.font, size or self.config.fontSize, self.config.fontEffect);
	fs:SetText(text);
	if width then
		fs:SetWidth(width);
	end
	if height then
		fs:SetHeight(height);
	end

	fs:SetJustifyH('LEFT');
	fs:SetJustifyV('MIDDLE');

	return fs;
end