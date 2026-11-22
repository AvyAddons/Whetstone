---@type string
local addonName = ...
---@class Whetstone
local ns = select(2, ...)

ns.inCombat = false
ns.playerLevel = 1
---@type string?
ns.faction = nil

function ns.Print(...) print("|cff33ccff" .. addonName .. ":|r", ...) end

local frame = CreateFrame("Frame")
---@type table<string, fun(...)>
local events = {}

local function RegisterRuntimeEvents()
	for event in pairs(events) do
		frame:RegisterEvent(event)
	end
end

function events.PLAYER_LOGIN()
	ns.InitProfile()
	ns.playerLevel = UnitLevel("player")
	ns.faction = UnitFactionGroup("player")
	ns.Bar:Init()
	ns.Options:Init()
	RegisterRuntimeEvents()
	ns.StartScanning()
end

events.SKILL_LINES_CHANGED = ns.OnSkillLinesChanged

-- Rank gains. SKILL_LINES_CHANGED is only documented for learning, unlearning and new caps.
events.CHAT_MSG_SKILL = ns.RequestScan

-- UnitLevel still returns the old level while this event fires.
function events.PLAYER_LEVEL_UP(level)
	ns.playerLevel = level
	ns.RequestScan()
end

---@param slot number
function events.PLAYER_EQUIPMENT_CHANGED(slot)
	if slot == INVSLOT_MAINHAND or slot == INVSLOT_OFFHAND or slot == INVSLOT_RANGED then ns.InvalidateEquipped() end
	ns.RequestScan()
end

function events.UPDATE_SHAPESHIFT_FORM() ns.Bar:Refresh() end

---@param inCombat boolean
local function SetCombat(inCombat)
	ns.inCombat = inCombat
	ns.Bar:Refresh()
	ns.Bar:UpdateVisibility()
end

function events.PLAYER_REGEN_DISABLED() SetCombat(true) end

function events.PLAYER_REGEN_ENABLED() SetCombat(false) end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...) events[event](...) end)

---@param key string
---@param value boolean
local function Set(key, value)
	ns.db[key] = value
	ns.Bar:Apply()
end

local COMMANDS = {
	{ "lock", "stop the bar from being dragged", function() Set("locked", true) end },
	{ "unlock", "let the bar be dragged", function() Set("locked", false) end },
	{ "show", "show the bar", function() Set("shown", true) end },
	{ "hide", "hide the bar", function() Set("shown", false) end },
	{ "reset", "move the bar back to its default position", function() ns.Bar:ResetPosition() end },
	{ "scan", "rescan skills", ns.RequestScan },
}

SLASH_WHETSTONE1 = "/whet"
SLASH_WHETSTONE2 = "/whetstone"
SlashCmdList.WHETSTONE = function(input)
	local cmd = strlower(strtrim(input))
	if cmd == "" then return ns.Options:Open() end
	for _, command in ipairs(COMMANDS) do
		if command[1] == cmd then return command[3]() end
	end
	ns.Print("/whet opens the options.")
	for _, command in ipairs(COMMANDS) do
		ns.Print(("/whet %s: %s"):format(command[1], command[2]))
	end
end
