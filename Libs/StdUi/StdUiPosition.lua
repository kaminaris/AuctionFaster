local StdUi = LibStub and LibStub('StdUi', true);

function StdUi:GlueBelow(object, referencedObject, x, y)
	object:SetPoint('TOPLEFT', referencedObject, 'BOTTOMLEFT', x, y);
end

function StdUi:GlueAbove(object, referencedObject, x, y)
	object:SetPoint('BOTTOMLEFT', referencedObject, 'TOPLEFT', x, y);
end


function StdUi:GlueTop(object, referencedObject, x, y)
	object:SetPoint('TOP', referencedObject, 'TOP', x, y);
end

function StdUi:GlueBottom(object, referencedObject, x, y)
	object:SetPoint('BOTTOM', referencedObject, 'BOTTOM', x, y);
end


function StdUi:GlueTopRight(object, referencedObject, x, y)
	object:SetPoint('TOPLEFT', referencedObject, 'BOTTOMLEFT', x, y);
end


function StdUi:GlueBottomRight(object, referencedObject, x, y)
	object:SetPoint('BOTTOMRIGHT', referencedObject, 'BOTTOMRIGHT', x, y);
end


function StdUi:GlueRight(object, referencedObject, x, y)
	object:SetPoint('LEFT', referencedObject, 'RIGHT', x, y);
end

function StdUi:GlueLeft(object, referencedObject, x, y)
	object:SetPoint('RIGHT', referencedObject, 'LEFT', x, y);
end
