--[[-----------------------------------------------------------------------------
lib-st Beta Wrapper Widget

lib-st does not recycle the objects (called "ST" here) that it creates and
returns.  We therefore do not try to hold onto an ST when the widget is
being recycled.  This means that Constructor() does very little work, and
does not actually construct an ST.

OnAcquire cannot construct an ST either, because we don't yet have any
creation parameters from the user to feed to CreateST.  (Allowing such to
be passed along from AceGUI:Create() would require changes to core AceGUI
code, and I don't feel like trying to overcome that inertia.)

The upshot is that the widget returned from Create is broken and useless
until its CreateST member has been called.  This means that correct behavior
depends entirely on the user remembering to do so.

"The gods do not protect fools.  Fools are protected by more capable fools."
- Ringworld


Version 1 initial functioning implementation
Version 2 reshuffle to follow new AceGUI widget coding style
Version 3 add .tail_offset, defaulting to same absolute value as .head_offset
Version 4 restore original frame methods, as fortold by ancient prophecy
Version 5 don't bogart the widget object
-farmbuyer
-------------------------------------------------------------------------------]]
local Type, Version = "lib-st", 4
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local ipairs, error = ipairs, error

-- WoW APIs
local debugstack = debugstack
local CreateFrame = CreateFrame


--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

-- Some AceGUI functions simply Won't Work in this context.  Name them
-- here, and code calling them will get a somewhat informative error().
local oopsfuncs = {
	'SetRelativeWidth', 'SetRelativeHeight',
	'SetFullWidth', 'SetFullHeight',
}
local err = "Oops!  The AceGUI function you tried to call (%s) does not "
            .. "make sense with lib-st and has not been implemented."

local function Oops(self)
	-- if you ever wanted an example of "brown paper bag" code, here it is
	local ds = debugstack(0)
	local func = ds:match("AceGUIWidget%-lib%-st%.lua:%d+:%s+in function `(%a+)'")
	error(err:format(func or "?"))
end


--[[
	Users with an ST already constructed can drop it into a widget directly
	using this routine.  It must be safe to call this more than once with
	new widgets on the same ST.

	This is where most of the intelligence of the wrapper is located.  That
	is, if you can call my code "intelligent" with a straight face.  Lemme
	try again.

	Think of the widget wrapper as a brain.  When ALL THREE neurons manage
	to fire at the same time and produce a thought, this function represents
	the thought.  Sigh.
]]
local ShiftingSetPoint, ShiftingSetAllPoints
local function WrapST (self, st)
	if not st.frame then
		error"lib-st instance has no '.frame' field... wtf did you pass to this function?"
	end
	--if st.frame.obj and (st.frame.obj ~= self) then
	--	error"lib-st instance already has an '.obj' field from a different widget, cannot use with AceGUI!"
	--end
	self.st = st
	if not st.head then
		error"lib-st instance has no '.head' field, must use either ScrollingTable:CreateST or this widget's CreateST first"
	end
	self.frame = st.frame   -- gutsy, but looks doable

	-- Possibly have already wrapped this ST in a previous widget, careful.
	--if st.frame.obj ~= self then
		self.frame.customSetPoint = rawget(self.frame,"SetPoint")
		self.frame.realSetPoint = self.frame.SetPoint
		self.frame.SetPoint = ShiftingSetPoint
		self.frame.SetAllPoints = ShiftingSetAllPoints
	--end

	-- This needs the .frame field.  This also unconditionally creates .obj
	-- inside that field and calls a SetScript on it as well.
	return AceGUI:RegisterAsWidget(self)
end


--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
--[[
	All of an ST's subframes are attached to its main frame, which we have in
	the st.frame link, and that's what AceGUI uses for all positioning.  Except
	that ST:SetDisplayCols creates its "head" row /above/ the main frame, and
	so the row of labels eats into whatever upper border space AceGUI calculates,
	often overlapping other elements.

	We get around this by replacing ST's main frame's SetPoint with a custom
	version that just moves everything down a few pixels to allow room for the
	head row.

	FIXME this may need to be a secure hook (ugh, would end up calling the real
	setpoint twice) rather than a replacement.
]]
local DEFAULT_OFFSET = 7
function ShiftingSetPoint(frame,anchor,other,otheranchor,xoff,yoff)
	local ho,to = frame.obj.head_offset, frame.obj.tail_offset
	yoff = yoff or 0
	if anchor:sub(1,3) == "TOP" then
		yoff = yoff - ho
	elseif anchor:sub(1,6) == "BOTTOM" then
		yoff = yoff + to
	end
	return frame.realSetPoint(frame,anchor,other,otheranchor,xoff,yoff)
end
function ShiftingSetAllPoints(frame,other)
	ShiftingSetPoint(frame,"TOPLEFT",other,"TOPLEFT",0,0)
	ShiftingSetPoint(frame,"BOTTOMRIGHT",other,"BOTTOMRIGHT",0,0)
end


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	-- --------------------------------------------------------------
	-- These are expected by AceGUI containers (and AceGUI users)
	--
	["OnAcquire"] = function (self)
		-- Almost nothing can usefully be done here.
		self.head_offset = DEFAULT_OFFSET
		self.tail_offset = DEFAULT_OFFSET
	end,

	["OnRelease"] = function (self)
		if self.st then
			self.st.frame:ClearAllPoints()
			self.st:Hide()
		end
		self.st = nil
		self.frame.realSetPoint = nil
		self.frame.SetAllPoints = nil
		self.frame.SetPoint = self.frame.customSetPoint
		self.frame.customSetPoint = nil
	end,

	--[[
		STs don't use a "normal" SetWidth, if we define "normal" to be the
		behavior of the blizzard :SetWidth.  Column width is passed in during
		creation of the whole ST.  The SetWidth defined by an ST takes no
		arguments; "ReCalculateWidth" would be a more precise description of
		what it does.
		
		Parts of AceGUI look for a .width field because a widget's SetWidth
		sets such.  ST calculates a total width and dispatches it to its member
		frame...  but doesn't store a local copy.  We need to bridge these
		differences.

		This widget wrapper does not make use of On{Width,Height}Set hooks,
		but the acegui widget base functions do.  Since we're not inheriting
		them, we may as well supply them.
	]]
	["SetWidth"] = function (self)
		self.st:SetWidth()                    -- re-total the columns
		local w = self.st.frame:GetWidth()    -- fetch the answer back
		self.frame.width = w                  -- store it for acegui
		if self.OnWidthSet then
			self:OnWidthSet(w)
		end
	end,

	-- Everything said about SetWidth applies here too.
	["SetHeight"] = function (self)
		self.st:SetHeight()
		local h = self.st.frame:GetHeight()
		self.frame.height = h
		if self.OnHeightSet then
			self:OnHeightSet(h)
		end
	end,

	-- Some of the container layouts call Show/Hide on the innermost frame
	-- directly.  We need to make sure the slightly-higher-level routine is
	-- also called.
	["LayoutFinished"] = function (self)
		if self.frame:IsShown() then
			self.st:Show()
		else
			self.st:Hide()
		end
	end,

	-- --------------------------------------------------------------
	-- Functions specific to this widget
	--

	["GetSTLibrary"] = function (self)   -- Purely for convenience
		return LibST
	end,

	--[[
		Replacement wrapper, so that instead of
		   st = ScrollingTable:CreateST( args )
		the user should be able to do
		   st = AceGUI:Create("lib-st"):CreateST( args )
		instead, without needing to get a lib-st handle.
	]]
	["CreateST"] = function (self, ...)
		return self:WrapST( LibST:CreateST(...) )
	end,

	["WrapST"] = WrapST,
}


--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	-- .frame not done here, see WrapST
	local widget = {
		type   = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	for _,func in ipairs(oopsfuncs) do
		widget[func] = Oops
	end

	-- AceGUI:RegisterAsWidget needs .frame
	return widget
end

AceGUI:RegisterWidgetType(Type,Constructor,Version)

