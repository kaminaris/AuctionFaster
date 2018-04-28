local StdUi = LibStub and LibStub('StdUi', true);

StdUi.config = {};

function StdUi:ResetConfig()
	self.config = {
		font = {
			familly = 'Fonts\\FRIZQT__.TTF',
			size = 12,
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