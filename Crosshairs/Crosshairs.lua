local LibNameplates = LibStub("LibNameplates-1.0")
if not LibNameplates then return end

local alpha = 0.5 -- Overall alpha
local speed = 0.1 -- seconds to fade textures in and out
local lineAlpha = 0.2 -- Set to 0 to hide lines but keep the circle

local UIFrameFadeIn = UIFrameFadeIn
local CreateFrame = CreateFrame
local tonumber = tonumber
local strmatch = strmatch or string.match
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsUnit = UnitIsUnit
local UnitSelectionColor = UnitSelectionColor
local GetScreenResolutions = GetScreenResolutions
local GetCurrentResolution = GetCurrentResolution

local function GetPhysicalScreenSize()
	local width, height = strmatch(({GetScreenResolutions()})[GetCurrentResolution()], "(%d+)x(%d+)")
	return tonumber(width), tonumber(height)
end

local f = CreateFrame("frame", "Crosshairs", UIParent)
f:SetFrameLevel(0)
f:SetFrameStrata("BACKGROUND")
f:SetPoint("CENTER")

local uiScale = 1
local screen_size = {GetPhysicalScreenSize()}
if screen_size and screen_size[2] then
	uiScale = 768 / screen_size[2]
end
local lineWidth = uiScale * 2
f:SetSize(64 * uiScale, 64 * uiScale)

local circle = UIParent:CreateTexture(nil, "ARTWORK")
circle:SetTexture([[Interface\AddOns\Crosshairs\circle]])
circle:SetAllPoints(f)
circle:SetAlpha(alpha)

local left = f:CreateTexture(nil, "ARTWORK")
left:SetTexture([[Interface\Buttons\WHITE8X8]])
left:SetVertexColor(1, 1, 1, alpha)
left:SetPoint("RIGHT", f, "LEFT", 8, 0)
left:SetSize(2000, lineWidth)

local right = f:CreateTexture(nil, "ARTWORK")
right:SetTexture([[Interface\Buttons\WHITE8X8]])
right:SetVertexColor(1, 1, 1, alpha)
right:SetPoint("LEFT", f, "RIGHT", -8, 0)
right:SetSize(2000, lineWidth)

local top = f:CreateTexture(nil, "ARTWORK")
top:SetTexture([[Interface\Buttons\WHITE8X8]])
top:SetVertexColor(1, 1, 1, alpha)
top:SetPoint("BOTTOM", f, "TOP", 0, -8)
top:SetSize(lineWidth, 2000)

local bottom = f:CreateTexture(nil, "ARTWORK")
bottom:SetTexture([[Interface\Buttons\WHITE8X8]])
bottom:SetVertexColor(1, 1, 1, alpha)
bottom:SetPoint("TOP", f, "BOTTOM", 0, 8)
bottom:SetSize(lineWidth, 2000)

circle:SetBlendMode("ADD")
left:SetBlendMode("ADD")
right:SetBlendMode("ADD")
top:SetBlendMode("ADD")
bottom:SetBlendMode("ADD")

local tx = UIParent:CreateTexture(nil, "ARTWORK")
tx:SetTexture([[Interface\AddOns\Crosshairs\arrows]])
tx:SetAllPoints(f)

local ag = tx:CreateAnimationGroup()
local rotation = ag:CreateAnimation("Rotation")
rotation:SetDegrees(-360)
rotation:SetDuration(5)
ag:SetLooping("REPEAT")

local function HideEverything()
	UIFrameFadeIn(circle, speed, alpha, 0)
	UIFrameFadeIn(left, speed, lineAlpha, 0)
	UIFrameFadeIn(right, speed, lineAlpha, 0)
	UIFrameFadeIn(top, speed, lineAlpha, 0)
	UIFrameFadeIn(bottom, speed, lineAlpha, 0)
	UIFrameFadeIn(tx, speed, alpha, 0)
	ag:Stop()
	f.plate = nil
end

local function ShowEverything()
	UIFrameFadeIn(circle, speed, 0, alpha)
	UIFrameFadeIn(left, speed, 0, lineAlpha)
	UIFrameFadeIn(right, speed, 0, lineAlpha)
	UIFrameFadeIn(top, speed, 0, lineAlpha)
	UIFrameFadeIn(bottom, speed, 0, lineAlpha)
	UIFrameFadeIn(tx, speed, 0, alpha)
	ag:Play()
end

f:HookScript("OnHide", HideEverything)
f:HookScript("OnShow", ShowEverything)
f:Hide()

local function SetColor(r, g, b)
	circle:SetVertexColor(r, g, b)
	left:SetVertexColor(r, g, b)
	right:SetVertexColor(r, g, b)
	top:SetVertexColor(r, g, b)
	bottom:SetVertexColor(r, g, b)
	tx:SetVertexColor(r, g, b)
end

-- Adjust line alpha based on combat status
local function SetLineAlpha(alpha)
	left:SetAlpha(alpha)
	right:SetAlpha(alpha)
	top:SetAlpha(alpha)
	bottom:SetAlpha(alpha)
end

-- Initial state
SetLineAlpha(lineAlpha)

-- fade in if our crosshairs weren't visible
local function FocusPlate(plate)
	f:ClearAllPoints()
	f:SetPoint("CENTER", plate)
	f:Show()
	f.plate = plate

	local r, g, b = 1, 1, 1
	if UnitIsTapped("target") and not UnitIsTappedByPlayer("target") then
		r, g, b = 0.5, 0.5, 0.5
	elseif UnitIsPlayer("target") then
		local _, class = UnitClass("target")
		if class and RAID_CLASS_COLORS[class] then
			local colors = RAID_CLASS_COLORS[class]
			r, g, b = colors.r, colors.g, colors.b
		else
			r, g, b = 0.274, 0.705, 0.392
		end
	else
		r, g, b = UnitSelectionColor("target")
	end
	SetColor(r, g, b)
end

function f:PLAYER_TARGET_CHANGED()
	if UnitExists("target") then
		local nameplate = LibNameplates:GetNameplateByGUID(UnitGUID("target"))
		if nameplate then
			FocusPlate(nameplate)
			return
		end
	end
	self.plate = nil
	self:Hide()
end

function f:LibNameplates_FoundGUID(_, nameplate, guid, unit)
	if nameplate and UnitIsUnit("target", unit) then
		FocusPlate(nameplate)
	end
end
LibNameplates.RegisterCallback(f, "LibNameplates_FoundGUID")

function f:LibNameplates_RecycleNameplate(_, nameplate)
	if nameplate and self.plate == nameplate then
		self.plate = nil
		self:Hide()
	end
end
LibNameplates.RegisterCallback(f, "LibNameplates_RecycleNameplate")

function f:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:PLAYER_TARGET_CHANGED()
end
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, ...) return self[event] and self[event](self, ...) end)