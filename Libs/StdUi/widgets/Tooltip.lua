--- @type StdUi
local StdUi = LibStub and LibStub('StdUi', true);


StdUi.tooltips = {}
function StdUi:Tooltip(owner, text, tooltipName, anchor, automatic)
	--- @type GameTooltip
	local tip;
	if tooltipName and StdUi.tooltips[tooltipName] then
		tip = StdUi.tooltips[tooltipName];
	else
		tip = CreateFrame('GameTooltip', tooltipName, UIParent, 'GameTooltipTemplate');
		tip:SetOwner(owner or UIParent, anchor or 'ANCHOR_NONE');
		self:ApplyBackdrop(tip, 'panel');
	end

	if automatic then
		owner:SetScript('OnEnter', function ()
			tip:SetOwner(owner);
			tip:SetPoint(anchor);
			if type(text) == 'string' then
				tip:SetText(text,
						StdUi.config.font.color.r,
						StdUi.config.font.color.g,
						StdUi.config.font.color.b,
						StdUi.config.font.color.a
				);
			elseif type(text) == 'function' then
				text(tip);
			end

			tip:Show();
		end);
		owner:SetScript('OnLeave', function ()
			tip:Hide();
		end);
	end

	return tip;
end
