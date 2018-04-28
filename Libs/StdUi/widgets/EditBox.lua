local StdUi = LibStub and LibStub('StdUi', true);

function StdUi:Panel(parent, width, height, inherits)
	local frame = CreateFrame('Frame', nil, parent, inherits);
	self:SetObjSize(frame, width, height);
	self:ApplyBackdrop(frame, 'panel');

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