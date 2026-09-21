---@class Whetstone
local ns = select(2, ...)

---@class WhetstoneBar
local Bar = {}
ns.Bar = Bar

local INSET = 3
local PAD = INSET + 3
local TEXT_PAD = 4
local ICON_SIZE = 22
local ICON_GAP = 5
local FULL_BAR_HEIGHT = 18
local FULL_BAR_DIM = 0.6
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local GOLD = { 1, 0.82, 0 }
local GREEN = { 0.25, 1, 0.25 }
local RED = { 1, 0.25, 0.25 }
local GREY = { 0.7, 0.7, 0.7 }
local WHITE = { 1, 1, 1 }

---@class StateStyle
---@field textColour number[]
---@field barColour number[]
---@field tooltip string?

---@type table<SkillState, StateStyle>
local STATES = {
	LEVELLING = { textColour = { 1, 1, 1 }, barColour = { 0.25, 0.6, 1 } },
	READY = { textColour = { 1, 0.7, 0.1 }, barColour = { 1, 0.7, 0.1 }, tooltip = "Ready to learn the next rank" },
	CAPPED = { textColour = RED, barColour = { 0.9, 0.2, 0.2 }, tooltip = "Capped until %s" },
	MAXED = { textColour = GOLD, barColour = GOLD, tooltip = "Maxed" },
}

-- SetBackdrop skips its nine-slice rebuild only when handed the same table again.
local BACKDROP = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = INSET, right = INSET, top = INSET, bottom = INSET },
}
local BACKDROP_NO_BORDER = {
	bgFile = BACKDROP.bgFile,
	tile = true,
	tileSize = 16,
	insets = BACKDROP.insets,
}

---@class SkillTile : Button
---@field skillName string
---@field icon Texture
---@field name FontString
---@field value FontString
---@field bar StatusBar
---@field text Frame
---@field flashAnim AnimationGroup
---@field needsRedraw boolean
---@field rank number
---@field bonus number
---@field max number
---@field state SkillState

---@type SkillTile[]
local tiles = {}
---@type table<string, SkillTile>
local tileByName = {}
---@type SkillEntry[]
local visible = {}
---@type string[]
local laidOut = {}
local layoutDirty = true
local laidOutScanned = false
---@type table<Skill, number>
local icons = {}

local nameFont = CreateFont("WhetstoneNameFont")
nameFont:CopyFontObject(GameFontNormalSmall)
local valueFont = CreateFont("WhetstoneValueFont")
valueFont:CopyFontObject(GameFontHighlightSmall)

---@param label string
---@param value string
---@param colour number[]?
local function AddRow(label, value, colour)
	colour = colour or { 1, 1, 1 }
	GameTooltip:AddDoubleLine(label, value, GOLD[1], GOLD[2], GOLD[3], colour[1], colour[2], colour[3])
end

---@param text string
---@param met boolean
local function AddRequirement(text, met)
	local c = met and GREEN or RED
	GameTooltip:AddLine(text, c[1], c[2], c[3])
end

---@param tile SkillTile
local function ShowTooltip(tile)
	local entry = ns.snapshot[tile.skillName]
	if not entry then return end
	local skill = entry.skill

	GameTooltip:SetOwner(tile, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", tile.bar, "BOTTOMLEFT", 0, -2)
	GameTooltip:AddLine(skill.name, 1, 1, 1)
	local rankName = skill.ranks and ns.RANK_NAMES[entry.max]
	if rankName then GameTooltip:AddLine(rankName, GREY[1], GREY[2], GREY[3]) end

	AddRow("Skill", ("%d / %d"):format(entry.rank, entry.max))
	if entry.bonus ~= 0 then
		AddRow("Bonus", ("%+d (effective %d)"):format(entry.bonus, entry.rank + entry.bonus), GREEN)
	end
	if entry.max > entry.rank then AddRow("Points to cap", tostring(entry.max - entry.rank)) end
	local gain = ns.SessionGain(entry)
	if gain > 0 then AddRow("This session", "+" .. gain, GREEN) end

	local style = STATES[entry.state]
	if style.tooltip then
		local c = style.textColour
		GameTooltip:AddLine(style.tooltip:format(ns.KINDS[skill.kind].cappedUntil), c[1], c[2], c[3])
	end

	local nextRank = entry.nextRank
	if nextRank then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(("Next: %s (cap %d)"):format(nextRank.name, nextRank.cap), GOLD[1], GOLD[2], GOLD[3])
		AddRequirement(("Requires skill %d"):format(nextRank.requiredSkill), entry.rank >= nextRank.requiredSkill)
		AddRequirement(("Requires level %d"):format(nextRank.requiredLevel), ns.playerLevel >= nextRank.requiredLevel)
		GameTooltip:AddLine(nextRank.hint, 0.8, 0.8, 0.8, true)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(ns.db.locked and "Right-click: options" or "Drag: move   Right-click: options", 0.5, 0.5, 0.5)
	GameTooltip:Show()
end

---@param parent Frame
---@return SkillTile
local function CreateTile(parent)
	local t = CreateFrame("Button", nil, parent) --[[@as SkillTile]]
	t:RegisterForClicks("RightButtonUp")
	t:RegisterForDrag("LeftButton")

	t.icon = t:CreateTexture(nil, "ARTWORK")
	t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	t.bar = CreateFrame("StatusBar", nil, t)
	local barBg = t.bar:CreateTexture(nil, "BACKGROUND")
	barBg:SetAllPoints()
	barBg:SetColorTexture(0, 0, 0, 0.6)

	-- Child frames draw above their parent's regions, so text on the tile itself would sit under a full bar.
	t.text = CreateFrame("Frame", nil, t)
	t.text:SetAllPoints()
	t.text:SetFrameLevel(t.bar:GetFrameLevel() + 1)
	t.name = t.text:CreateFontString(nil, "OVERLAY")
	t.name:SetFontObject(nameFont)
	t.name:SetJustifyH("LEFT")
	t.name:SetWordWrap(false)
	t.value = t.text:CreateFontString(nil, "OVERLAY")
	t.value:SetFontObject(valueFont)

	local flash = t.text:CreateTexture(nil, "OVERLAY")
	flash:SetAllPoints()
	flash:SetColorTexture(1, 1, 1, 1)
	flash:SetBlendMode("ADD")
	flash:SetAlpha(0)
	t.flashAnim = flash:CreateAnimationGroup()
	local fadeIn = t.flashAnim:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(0.35)
	fadeIn:SetDuration(0.12)
	fadeIn:SetOrder(1)
	local fadeOut = t.flashAnim:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(0.35)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(0.6)
	fadeOut:SetOrder(2)

	t:SetScript("OnEnter", ShowTooltip)
	t:SetScript("OnLeave", function() GameTooltip:Hide() end)
	t:SetScript("OnClick", function() ns.Options:Open() end)
	t:SetScript("OnDragStart", function() Bar:StartMove() end)
	t:SetScript("OnDragStop", function() Bar:StopMove() end)
	return t
end

---@param t SkillTile
local function LayoutCompact(t, db)
	-- A hidden icon still anchors the text, so it moves off the tile's left edge instead.
	local iconX = db.showIcon and 3 or 3 - ICON_SIZE - ICON_GAP
	t.icon:SetSize(ICON_SIZE, ICON_SIZE)
	t.icon:SetPoint("LEFT", iconX, db.showBar and 2.5 or 0)
	t.value:SetJustifyH("LEFT")
	if db.showNames then
		t.name:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", ICON_GAP, 1)
		t.name:SetPoint("RIGHT", t, "RIGHT", -3, 0)
		t.value:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", ICON_GAP, -1)
	else
		t.value:SetPoint("LEFT", t.icon, "RIGHT", ICON_GAP, 0)
	end

	t.bar:SetShown(db.showBar)
	t.bar:SetHeight(3)
	t.bar:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 3, 2)
	t.bar:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -3, 2)
end

---@param t SkillTile
local function LayoutFullBar(t, db)
	t.icon:SetSize(FULL_BAR_HEIGHT, FULL_BAR_HEIGHT)
	t.icon:SetPoint("LEFT")

	t.bar:Show()
	t.bar:SetPoint("TOPRIGHT")
	t.bar:SetPoint("BOTTOMRIGHT")
	if db.showIcon then
		t.bar:SetPoint("LEFT", t.icon, "RIGHT", 0, 0)
	else
		t.bar:SetPoint("LEFT")
	end

	if db.showNames then
		t.value:SetJustifyH("RIGHT")
		t.value:SetPoint("RIGHT", t.bar, "RIGHT", -TEXT_PAD, 0)
		t.name:SetPoint("LEFT", t.bar, "LEFT", TEXT_PAD, 0)
		t.name:SetPoint("RIGHT", t.value, "LEFT", -TEXT_PAD, 0)
	else
		t.value:SetJustifyH("CENTER")
		t.value:SetPoint("CENTER", t.bar, "CENTER")
	end
end

---@param t SkillTile
local function LayoutTile(t, w, h, db)
	t:SetSize(w, h)
	t.icon:ClearAllPoints()
	t.name:ClearAllPoints()
	t.value:ClearAllPoints()
	t.bar:ClearAllPoints()
	t.icon:SetShown(db.showIcon)
	t.name:SetShown(db.showNames)
	if db.fullBar then
		LayoutFullBar(t, db)
	else
		LayoutCompact(t, db)
	end
end

local function ApplyFont(db)
	local file = ns.Media.Fetch("font", db.font)
	for _, font in ipairs({ nameFont, valueFont }) do
		font:SetFont(file, db.fontSize, "")
		-- Not every client returns a success flag from SetFont. A file that fails to load leaves the object without a face.
		if not font:GetFont() then font:SetFont(STANDARD_TEXT_FONT, db.fontSize, "") end
	end
end

---@return number width
---@return number height
local function TileSize(db)
	local iconWidth = db.showIcon and ICON_SIZE + ICON_GAP or 0
	if db.fullBar then return (db.showNames and 160 or 82) + iconWidth, FULL_BAR_HEIGHT end
	return (db.showNames and 105 or 77) + iconWidth, db.showNames and 34 or (db.showBar and 30 or 28)
end

---@param entry SkillEntry
local function FormatValue(entry, db)
	local bonus = ""
	if db.showBonus and entry.bonus ~= 0 then bonus = (" |cff40ff40(%+d)|r"):format(entry.bonus) end
	return ("%d%s / %d"):format(entry.rank, bonus, entry.max)
end

---@param entry SkillEntry
local function IsVisible(entry, db)
	local skill = entry.skill
	local visibilitySetting = ns.KINDS[skill.kind].visibilitySetting
	if db.hidden[skill.name] or (visibilitySetting and not db[visibilitySetting]) then return false end
	if db.hideMaxed and entry.state == "MAXED" then return false end
	return skill.kind ~= "weapon" or ns.WeaponEarnsTile(entry)
end

function Bar:Init()
	local f = CreateFrame("Frame", "WhetstoneBar", UIParent, "BackdropTemplate")
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function() self:StartMove() end)
	f:SetScript("OnDragStop", function() self:StopMove() end)
	f:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then ns.Options:Open() end
	end)

	f.empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.empty:SetPoint("CENTER")

	self.frame = f
	self:ApplyPosition()
	self:Apply()
end

function Bar:Apply()
	local db = ns.db
	self.frame:SetBackdrop(db.border and BACKDROP or BACKDROP_NO_BORDER)
	self.frame:SetBackdropColor(0, 0, 0, db.bgAlpha)
	self.frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	self.frame:SetScale(db.scale)
	ApplyFont(db)
	layoutDirty = true
	self:Refresh()
	self:UpdateVisibility()
end

function Bar:StartMove()
	if not ns.db.locked then self.frame:StartMoving() end
end

function Bar:StopMove()
	self.frame:StopMovingOrSizing()
	local db = ns.db
	local _
	db.point, _, db.relPoint, db.x, db.y = self.frame:GetPoint(1)
end

function Bar:ApplyPosition()
	local db = ns.db
	self.frame:ClearAllPoints()
	self.frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

function Bar:ResetPosition()
	local db, d = ns.db, ns.DEFAULTS
	db.point, db.relPoint, db.x, db.y = d.point, d.relPoint, d.x, d.y
	self:ApplyPosition()
end

function Bar:UpdateVisibility()
	local db = ns.db
	self.frame:SetShown(db.shown and not (db.hideInCombat and ns.inCombat))
end

---@param skill Skill
local function Icon(skill)
	icons[skill] = icons[skill] or C_Spell.GetSpellTexture(skill.iconSpell)
	return icons[skill] or UNKNOWN_ICON
end

---@return boolean
local function IsLaidOut()
	if layoutDirty or laidOutScanned ~= ns.scanned or #visible ~= #laidOut then return false end
	for i, entry in ipairs(visible) do
		if entry.skill.name ~= laidOut[i] then return false end
	end
	return true
end

function Bar:Layout()
	local f, db = self.frame, ns.db
	local w, h = TileSize(db)
	local stepX, stepY = w + db.spacing, h + db.spacing
	local texture = ns.Media.Fetch("statusbar", db.texture)

	wipe(tileByName)
	wipe(laidOut)
	for i, entry in ipairs(visible) do
		local t = tiles[i] or CreateTile(f)
		tiles[i] = t
		t.skillName = entry.skill.name
		t.needsRedraw = true
		tileByName[t.skillName] = t
		laidOut[i] = t.skillName

		local along, across = (i - 1) % db.perLine, math.floor((i - 1) / db.perLine)
		local col, row = along, across
		if db.vertical then
			col, row = across, along
		end
		LayoutTile(t, w, h, db)
		t.bar:SetStatusBarTexture(texture)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + col * stepX, -(PAD + row * stepY))
		t.icon:SetTexture(Icon(entry.skill))
		t.name:SetText(entry.skill.name)
		t:Show()
	end
	for i = #visible + 1, #tiles do
		tiles[i]:Hide()
	end

	local n = #visible
	f.empty:SetShown(n == 0)
	if n == 0 then
		f.empty:SetText(ns.scanned and "Whetstone: nothing to show" or "Whetstone: scanning...")
		f:SetSize(170, 26)
	else
		local long, short = math.min(n, db.perLine), math.ceil(n / db.perLine)
		local cols, rows = long, short
		if db.vertical then
			cols, rows = short, long
		end
		f:SetSize(cols * stepX - db.spacing + PAD * 2, rows * stepY - db.spacing + PAD * 2)
	end
	layoutDirty = false
	laidOutScanned = ns.scanned
end

function Bar:Refresh()
	local db = ns.db

	wipe(visible)
	for _, skill in ipairs(ns.SKILLS) do
		local entry = ns.snapshot[skill.name]
		if entry and IsVisible(entry, db) then visible[#visible + 1] = entry end
	end
	if not IsLaidOut() then self:Layout() end

	for i, entry in ipairs(visible) do
		local t = tiles[i]
		if
			t.needsRedraw
			or t.rank ~= entry.rank
			or t.bonus ~= entry.bonus
			or t.max ~= entry.max
			or t.state ~= entry.state
		then
			local style = STATES[entry.state]
			local text, bar, dim = style.textColour, style.barColour, 1
			-- State-coloured text is unreadable on a bar of the same colour.
			if db.fullBar then
				text, dim = WHITE, FULL_BAR_DIM
			end
			t.value:SetText(FormatValue(entry, db))
			t.value:SetTextColor(text[1], text[2], text[3])
			t.bar:SetStatusBarColor(bar[1] * dim, bar[2] * dim, bar[3] * dim)
			t.bar:SetMinMaxValues(0, entry.max)
			t.bar:SetValue(entry.rank)
			t.rank, t.bonus, t.max, t.state = entry.rank, entry.bonus, entry.max, entry.state
			t.needsRedraw = false
		end
	end

	local owner = GameTooltip:IsShown() and GameTooltip:GetOwner() --[[@as SkillTile?]]
	if owner and tileByName[owner.skillName] == owner then ShowTooltip(owner) end
end

---@param skillName string
function Bar:Flash(skillName)
	local t = tileByName[skillName]
	if t and t:IsVisible() then
		t.flashAnim:Stop()
		t.flashAnim:Play()
	end
end
