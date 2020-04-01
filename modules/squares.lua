local Squares = {}

LunaUF:RegisterModule(Squares, "squares", LunaUF.L["Squares"])

local lCD = LibStub("LibClassicDurations")

local vex = LibStub("LibVexation-1.0", true)
local canCure = LunaUF.Units.canCure
local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
	tileSize = 16,
	insets = {left = -1, right = -1, top = -1, bottom = -1},
}
local positions = {
	top = "TOP",
	topright = "TOPRIGHT",
	topleft = "TOPLEFT",
	leftcenter = "LEFTCENTER",
	center = "CENTER",
	rightcenter = "RIGHTCENTER",
	bottomright = "BOTTOMRIGHT",
	bottomleft = "BOTTOMLEFT",
	bottom = "BOTTOM",
}
local indicator = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\indicator"

local function SquaresCallback(aggro, GUID, ...)
	for _,frame in pairs(LunaUF.Units.unitFrames) do
		if frame.unitGUID and frame.unitGUID == GUID then
			Squares:Update(frame)
		end
	end
end
vex:RegisterCallback(SquaresCallback)

local function checkAuraInversion(spell)
	local inversion = string.find(spell, "!")
--		print(inversion)
		if inversion == 1 then
			spell = spell.sub(spell, 2);
		end
--		print(spell)
--		print(inversion == 1)
		return spell, inversion == 1
end

local function checkAura(unit, spells, playeronly)
	local spells = {strsplit(";",spells)}
	local foundAtLeastOne = false
	local returnName, returnRank, returnIcon, returnSpellId
	for k,spell in ipairs(spells) do
		local found = false
		local inverted
		spell, inverted = checkAuraInversion(spell)
		if tonumber(spell) then
			local i, casterunit,_,_,spellID = 1, select(7,UnitAura(unit, 1))
			while spellID do
				if spellID == tonumber(spell) and (not playeronly or playeronly and casterunit and UnitIsUnit(casterunit,"player")) then
					found = true
					if not inverted then
						return UnitAura(unit, i)
					end
				end
				i = i + 1
				casterunit,_,_,spellID = select(7, UnitAura(unit, i))
			end
			i, casterunit,_,_,spellID = 1, select(7,UnitAura(unit, 1, "HARMFUL"))
			while spellID do
				if spellID == spell and (not playeronly or playeronly and casterunit and UnitIsUnit(casterunit,"player")) then
					found = true
					if not inverted then
						return UnitAura(unit, i, "HARMFUL")
					end
				end
				i = i + 1
				casterunit,_,_,spellID = select(7, UnitAura(unit, i, "HARMFUL"))
			end
		elseif type(spell) == "string" then
			local i, spellName = 1, UnitAura(unit, 1)
			local casterunit = select(7,UnitAura(unit, 1))
			while spellName do
				if spellName == spell and (not playeronly or playeronly and casterunit and UnitIsUnit(casterunit,"player")) then
					found = true
					if not inverted then
						return UnitAura(unit, i)
					end
				end
				i = i + 1
				spellName = UnitAura(unit, i)
				casterunit = select(7,UnitAura(unit, i))
			end
			i, spellName = 1, UnitAura(unit, 1, "HARMFUL")
			casterunit = select(7,UnitAura(unit, 1, "HARMFUL"))
			while spellName do
				if spellName == spell and (not playeronly or playeronly and casterunit and UnitIsUnit(casterunit,"player")) then
					found = true
					if not inverted then
						return UnitAura(unit, i, "HARMFUL")
					end
				end
				i = i + 1
				spellName = UnitAura(unit, i, "HARMFUL")
				casterunit = select(7,UnitAura(unit, i, "HARMFUL"))
			end
		end
		if found == false and inverted then
			returnName, returnRank, returnIcon, _, _, _, returnSpellId = GetSpellInfo(spell)
		--	print(inverted)
		--	print(returnName)
		end
		if found then
			foundAtLeastOne = true
		end
	end
	if not foundAtLeastOne and returnIcon and returnSpellId then
		return _, returnIcon, _, _, _, _, _, _, _, returnSpellId
	end
end

local function checkDispel(unit)
	local i, name, _, _, debuffType = 1, UnitDebuff(unit, 1)
	while name do
		if canCure[debuffType] then
			return UnitDebuff(unit, i)
		end
		i = i + 1
		name, _, _, debuffType = UnitDebuff(unit, i)
	end
end

function Squares:OnEnable(frame)
	if( not frame.squares ) then
		frame.squares = CreateFrame("Frame", nil, frame)
		frame.squares:SetAllPoints(frame)
		frame.squares:SetFrameLevel(7)
		
		frame.squares.square = {}
		
		for k,v in pairs(positions) do
			frame.squares.square[k] = CreateFrame("Frame", nil, frame.squares)
			frame.squares.square[k]:SetBackdrop(backdrop)
			frame.squares.square[k]:SetBackdropColor(0,0,0)
			frame.squares.square[k].texture = frame.squares.square[k]:CreateTexture(nil, "ARTWORK")
			frame.squares.square[k].texture:SetAllPoints(frame.squares.square[k])
			frame.squares.square[k].cd = CreateFrame("Cooldown", frame:GetName().."CD"..k, frame.squares.square[k] , "CooldownFrameTemplate")
			frame.squares.square[k].cd:ClearAllPoints()
			frame.squares.square[k].cd:SetPoint("TOPLEFT", frame.squares.square[k], "TOPLEFT")
			frame.squares.square[k].cd:SetAllPoints(frame.squares.square[k])
			frame.squares.square[k].cd:SetReverse(true)
			frame.squares.square[k].cd:SetDrawEdge(false)
			frame.squares.square[k].cd:SetDrawSwipe(true)
			frame.squares.square[k].cd:SetSwipeColor(0, 0, 0, 0.8)
			frame.squares.square[k].cd:Hide()
		end
		frame.squares.square["top"]:SetPoint("TOP", frame.squares, "TOP", -1, -1)
		frame.squares.square["topright"]:SetPoint("TOPRIGHT", frame.squares, "TOPRIGHT", -4, -1)
		frame.squares.square["topleft"]:SetPoint("TOPLEFT", frame.squares, "TOPLEFT", 1, -1)
		frame.squares.square["leftcenter"]:SetPoint("LEFT", frame.squares, "LEFT", 1, 0)
		frame.squares.square["center"]:SetPoint("CENTER", frame.squares, "CENTER", -1, 0)
		frame.squares.square["rightcenter"]:SetPoint("RIGHT", frame.squares, "RIGHT", -4, 0)
		frame.squares.square["bottomright"]:SetPoint("BOTTOMRIGHT", frame.squares, "BOTTOMRIGHT", -4, 1)
		frame.squares.square["bottomleft"]:SetPoint("BOTTOMLEFT", frame.squares, "BOTTOMLEFT", 1, 1)
		frame.squares.square["bottom"]:SetPoint("BOTTOM", frame.squares, "BOTTOM", -1, 1)
	end
	
	frame:RegisterUnitEvent("UNIT_AURA", self, "Update")
	frame:RegisterUpdateFunc(self, "Update")
	
end

function Squares:OnDisable(frame)

end

function Squares:OnLayoutApplied(frame, config)
	if not frame.squares then return end
	for pos, frame in pairs(frame.squares.square) do
		frame:SetHeight(config.squares[pos].size)
		frame:SetWidth(config.squares[pos].size)
	end
end

function Squares:Update(frame)
	if not frame.squares then return end
	local aggro = vex:GetUnitAggroByUnitGUID(frame.unitGUID)
	local config = LunaUF.db.profile.units[frame.unitType].squares
	for pos, square in pairs(frame.squares.square) do
		if not config[pos].enabled then
			square:Hide()
		elseif config[pos].type == "aggro" then
			if aggro then
				square:Show()
				square.texture:SetTexture(indicator)
				local color = LunaUF.db.profile.colors.hostile
				square.texture:SetVertexColor(color.r, color.g, color.b,1)
				square.cd:Hide()
			else
				square:Hide()
			end
		elseif config[pos].type == "aura" and config[pos].value then
			local _, icon, _, debuffType, duration, expirationTime, caster, _, _, spellID = checkAura(frame.unit, config[pos].value)
			if (not duration or duration == 0) and spellID then
				local Newduration, NewendTime = lCD:GetAuraDurationByUnit(frame.unit, spellID, caster)
				duration = Newduration or duration
				expirationTime = NewendTime or expirationTime
			end
			if icon then
				square:Show()
				if config[pos].texture then
					square.texture:SetTexture(icon)
					square.texture:SetVertexColor(1,1,1,1)
				else
					local color = DebuffTypeColor[debuffType]
					if not color then
						color = {r = 0, g = 0, b = 0}
					end
					square.texture:SetTexture(indicator)
					square.texture:SetVertexColor(color.r, color.g, color.b, 1)
				end
				if duration and config[pos].timer then
					square.cd:Show()
					square.cd:SetCooldown(expirationTime - duration, duration)
				else
					square.cd:Hide()
				end
			else
				square:Hide()
			end
		elseif config[pos].type == "ownaura" and config[pos].value then
			local _, icon, _, debuffType, duration, expirationTime, caster, _, _, spellID = checkAura(frame.unit, config[pos].value, true)
			if (not duration or duration == 0) and spellID then
				local Newduration, NewendTime = lCD:GetAuraDurationByUnit(frame.unit, spellID, "player")
				duration = Newduration or duration
				expirationTime = NewendTime or expirationTime
			end
			if icon then
				square:Show()
				if config[pos].texture then
					square.texture:SetTexture(icon)
					square.texture:SetVertexColor(1,1,1,1)
				else
					local color = DebuffTypeColor[debuffType]
					if not color then
						color = {r = 0, g = 0, b = 0}
					end
					square.texture:SetTexture(indicator)
					square.texture:SetVertexColor(color.r, color.g, color.b, 1)
				end
				if duration and config[pos].timer then
					square.cd:Show()
					square.cd:SetCooldown(expirationTime - duration, duration)
				else
					square.cd:Hide()
				end
			else
				square:Hide()
			end
		elseif config[pos].type == "dispel" then
			local _, icon, _, debuffType, duration, expirationTime = checkDispel(frame.unit)
			if debuffType then
				square:Show()
				local color = DebuffTypeColor[debuffType]
				if config[pos].texture then
					square.texture:SetTexture(icon)
					square.texture:SetVertexColor(1,1,1,1)
				else
					square.texture:SetTexture(indicator)
					square.texture:SetVertexColor(color.r, color.g, color.b, 1)
				end
				if duration and config[pos].timer then
					square.cd:Show()
					square.cd:SetCooldown(expirationTime - duration, duration)
				else
					square.cd:Hide()
				end
			else
				square:Hide()
			end
		else
			square:Hide()
		end
	end
end