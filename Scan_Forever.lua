---@class Whetstone
local ns = select(2, ...)

local DEFENSE_SKILL_ID = 95

---@class SkillLineAttributes
---@field rank number
---@field modifier number
---@field maxRank number

---@return table<string, SkillEntry> found
function ns.Scan()
	---@type table<string, SkillEntry>
	local found = {}
	for _, skill in ipairs(ns.SKILLS) do
		local info = C_SkillInfo.GetSkillLineInfoByID(skill.id)
		if info then
			local bonus = info.modifier
			-- The skill line reports no modifier for Defense.
			if skill.id == DEFENSE_SKILL_ID then
				bonus = select(2, UnitDefenseSkill("player"))
				-- Unit stats are secret in combat. Gear is locked then, so the last known bonus still holds.
				if issecretvalue(bonus) then
					local old = ns.snapshot[skill.name]
					bonus = old and old.bonus or 0
				end
			end
			found[skill.name] = ns.NewEntry(skill, info.rank, bonus, info.maxRank)
		end
	end
	return found
end

ns.OnSkillLinesChanged = ns.RequestScan
ns.StartScanning = ns.RequestScan
