---@class Whetstone
local ns = select(2, ...)

local DEBOUNCE = 0.2

---@alias SkillState "LEVELLING"|"READY"|"CAPPED"|"MAXED"

---@class SkillEntry
---@field skill Skill
---@field rank number
---@field bonus number
---@field max number
---@field nextRank NextRank?
---@field state SkillState

---@type table<string, SkillEntry>
ns.snapshot = {}
ns.scanned = false

---@type table<string, number>
local sessionStart = {}
local pending = false
-- SKILL_LINES_CHANGED fires inside ExpandSkillHeader and CollapseSkillHeader, before they return.
local togglingHeaders = false

---@param entry SkillEntry
---@return number
function ns.SessionGain(entry) return entry.rank - sessionStart[entry.skill.name] end

local WEAPON_SLOTS = { INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED }

---@type table<number, true>
local equippedWeapons = {}
local mainHandEmpty = true
local equippedDirty = true

function ns.InvalidateEquipped() equippedDirty = true end

---@param skill Skill
---@return boolean
local function IsEquipped(skill)
	if equippedDirty then
		wipe(equippedWeapons)
		for _, slot in ipairs(WEAPON_SLOTS) do
			local item = GetInventoryItemID("player", slot)
			if item then
				local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(item)
				if classID == Enum.ItemClass.Weapon then equippedWeapons[subclassID] = true end
			end
		end
		mainHandEmpty = GetInventoryItemID("player", INVSLOT_MAINHAND) == nil
		equippedDirty = false
	end
	if skill.emptyHanded then return mainHandEmpty end
	return equippedWeapons[skill.weapon] == true
end

---@param entry SkillEntry
---@return boolean
function ns.WeaponEarnsTile(entry)
	local skill = entry.skill
	return ns.db.allWeapons or skill.alwaysShown or ns.SessionGain(entry) > 0 or IsEquipped(skill)
end

---@param rank number
---@param max number
---@param nextRank NextRank?
---@return SkillState
local function GetState(rank, max, nextRank)
	if rank >= ns.MAX_RANK then return "MAXED" end
	if nextRank and rank >= nextRank.requiredSkill and ns.playerLevel >= nextRank.requiredLevel then return "READY" end
	if rank >= max then return "CAPPED" end
	return "LEVELLING"
end

---@param entry SkillEntry
local function Alert(entry)
	local name, nextRank = entry.skill.name, entry.nextRank
	local msg
	if entry.state == "READY" and nextRank then
		msg = ("%s can advance to %s (cap %d). %s"):format(name, nextRank.name, nextRank.cap, nextRank.hint)
	elseif entry.state == "CAPPED" then
		msg = ("%s is capped at %d until %s."):format(name, entry.max, ns.KINDS[entry.skill.kind].cappedUntil)
	elseif entry.state == "MAXED" then
		msg = ("%s is maxed at %d."):format(name, entry.rank)
	else
		return
	end
	if ns.db.chatAlerts then ns.Print(msg) end
	if ns.db.sound then PlaySound(SOUNDKIT.RAID_WARNING) end
end

---@return table<string, boolean>? names
local function CollapsedHeaders()
	local names
	for i = 1, GetNumSkillLines() do
		local name, isHeader, isExpanded = GetSkillLineInfo(i)
		if isHeader and not isExpanded then
			names = names or {}
			names[name] = true
		end
	end
	return names
end

---@param names table<string, boolean>
local function CollapseBottomUp(names)
	for i = GetNumSkillLines(), 1, -1 do
		local name, isHeader = GetSkillLineInfo(i)
		if isHeader and names[name] then CollapseSkillHeader(i) end
	end
end

local function CanToggleHeaders() return not SkillFrame:IsShown() end

-- Collapsed headers hide their skill lines from the API, so the scan opens
-- them all and puts them back afterwards.
---@return table<string, SkillEntry>? found
local function Scan()
	local collapsed = CollapsedHeaders()
	if collapsed then
		if not CanToggleHeaders() then return nil end
		togglingHeaders = true
		ExpandSkillHeader(0)
	end

	---@type table<string, SkillEntry>
	local found = {}
	for i = 1, GetNumSkillLines() do
		local name, isHeader, _, rank, _, bonus, max = GetSkillLineInfo(i)
		local skill = ns.SKILL_BY_ENUS_NAME[name]
		if skill and not isHeader then
			local nextRank = skill.ranks and skill.ranks[max]
			found[name] = {
				skill = skill,
				rank = rank,
				bonus = bonus,
				max = max,
				nextRank = nextRank,
				state = GetState(rank, max, nextRank),
			}
		end
	end

	if collapsed then
		CollapseBottomUp(collapsed)
		togglingHeaders = false
	end
	return found
end

---@type string[]
local gained = {}

local function FlashGained()
	if not ns.db.flash then return end
	for _, name in ipairs(gained) do
		ns.Bar:Flash(name)
	end
end

---@param found table<string, SkillEntry>
local function Update(found)
	wipe(gained)
	for name, entry in pairs(found) do
		sessionStart[name] = sessionStart[name] or entry.rank
		local old = ns.snapshot[name]
		if old then
			if entry.rank > old.rank then gained[#gained + 1] = name end
			if entry.state ~= old.state then Alert(entry) end
		end
	end
	ns.snapshot = found
	ns.scanned = true
	ns.Bar:Refresh()
	FlashGained()
end

local function RunScan()
	pending = false
	local found = Scan()
	if found then Update(found) end
end

function ns.RequestScan()
	if pending then return end
	pending = true
	C_Timer.After(DEBOUNCE, RunScan)
end

function ns.OnSkillLinesChanged()
	if not togglingHeaders then ns.RequestScan() end
end

function ns.StartScanning()
	SkillFrame:HookScript("OnHide", ns.RequestScan)
	ns.RequestScan()
end
