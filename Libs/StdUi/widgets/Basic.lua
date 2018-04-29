local StdUi = LibStub and LibStub('StdUi', true);

function StdUi:Panel(parent, width, height, inherits)
	local frame = CreateFrame('Frame', nil, parent, inherits);
	self:SetObjSize(frame, width, height);
	self:ApplyBackdrop(frame, 'panel');

	return frame;
end

function StdUi:PanelWithLabel(parent, width, height, inherits, text)
	local frame = self:Panel(parent, width, height, inherits);

	frame.label = StdUi:Label(frame, text);
	frame.label:SetAllPoints();
	frame.label:SetJustifyH('MIDDLE');

	return frame;
end

function StdUi:InfoPane(parent, width, height, text)
	local frame = self:Panel(parent, width, height);

	frame.labelPanel = self:PanelWithLabel(frame, 100, 20, nil, text);
	self:GlueTop(frame.labelPanel, frame, 0, 10);

	return frame;
end

function StdUi:Texture(parent, width, height, texture)
	local tex = parent:CreateTexture(nil, 'ARTWORK');

	self:SetObjSize(tex, width, height);
	if texture then
		tex:SetTexture(texture);
	end

	return tex;
end