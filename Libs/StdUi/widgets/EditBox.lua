local StdUi = LibStub and LibStub('StdUi', true);

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

function StdUi:MoneyBox(parent, width, height, text)
	local validator = self.Util.moneyBoxValidator;

	local editBox = self:EditBox(parent, width, height, text);
	local button = self:Button(editBox, 40, height - 4, 'OK');

	button:SetPoint('RIGHT', -2, 0);
	button:Hide();
	button.editBox = editBox;
	
	button:SetScript('OnClick', function(self)
		self.editBox:Validate(self.editBox);
	end);

	editBox.button = button;
	editBox:SetMaxLetters(20);
	

	editBox:SetScript('OnTextChanged', function(self)
		local value = StdUi.Util.stripColors(self:GetText());
		if tostring(value) ~= tostring(self.lastValue) then
			self.lastValue = value;
			if not self.isValidated then
				self.button:Show();
			end
			self.isValidated = false;
		end
	end);

	function editBox:GetValue()
		return self.value;
	end;

	local formatMoney = StdUi.Util.formatMoney;
	function editBox:SetValue(value)
		self.value = value;
		local formatted = formatMoney(value);
		self:SetText(formatted);
		self:Validate();
	end;

	function editBox:IsValid()
		return self.isValid;
	end;

	function editBox:Validate()
		self.isValidated = true;
		validator(self);
	end;

	return editBox;
end

function StdUi:EditBoxWithLabel(parent, width, height, text, label, labelPosition, labelWidth)
	local editBox = self:EditBox(parent, width, height, text);
	self:AddLabel(parent, editBox, label, labelPosition, labelWidth);

	return editBox;
end

function StdUi:MoneyBoxWithLabel(parent, width, height, text, label, labelPosition, labelWidth)
	local editBox = self:MoneyBox(parent, width, height, text);
	self:AddLabel(parent, editBox, label, labelPosition, labelWidth);

	return editBox;
end