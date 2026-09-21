---@class Whetstone
local ns = select(2, ...)

-- SKILL_LINES_CHANGED fires inside ExpandSkillHeader and CollapseSkillHeader, before they return.
local togglingHeaders = false

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

-- Collapsed headers hide their skill lines from the list API, so the scan
-- opens them all and puts them back afterwards.
---@return table<string, SkillEntry>? found
function ns.Scan()
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
		if skill and not isHeader then found[name] = ns.NewEntry(skill, rank, bonus, max) end
	end

	if collapsed then
		CollapseBottomUp(collapsed)
		togglingHeaders = false
	end
	return found
end

function ns.OnSkillLinesChanged()
	if not togglingHeaders then ns.RequestScan() end
end

function ns.StartScanning()
	SkillFrame:HookScript("OnHide", ns.RequestScan)
	ns.RequestScan()
end
