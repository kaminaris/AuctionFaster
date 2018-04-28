local StdUi = LibStub and LibStub('StdUi', true);
local ScrollingTable = LibStub('ScrollingTable');

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

function StdUi:ScrollTable(parent, columns, visibleRows, rowHeight)
	local scrollingTable = ScrollingTable:CreateST(columns, visibleRows, rowHeight, nil, parent);
	self:ApplyBackdrop(scrollingTable.frame, 'panel');

	return scrollingTable;
end