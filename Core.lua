---@type string
local addonName = ...
---@class Whetstone
local ns = select(2, ...)

ns.inCombat = false
ns.playerLevel = 1

function ns.Print(...) print("|cff33ccff" .. addonName .. ":|r", ...) end

local function InitDB()
	WhetstoneDB = WhetstoneDB or {}
	local db = WhetstoneDB
	for key, value in pairs(ns.DEFAULTS) do
		if db[key] == nil then db[key] = value end
	end
	---@type table<string, true>
	db.hidden = db.hidden or {}
	ns.db = db
end

local frame = CreateFrame("Frame")
---@type table<string, fun(...)>
local events = {}

local function RegisterRuntimeEvents()
	for event in pairs(events) do
		frame:RegisterEvent(event)
	end
end

function events.PLAYER_LOGIN()
	InitDB()
	ns.playerLevel = UnitLevel("player")
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

function events.PLAYER_REGEN_DISABLED()
	ns.inCombat = true
	ns.Bar:UpdateVisibility()
end

function events.PLAYER_REGEN_ENABLED()
	ns.inCombat = false
	ns.Bar:UpdateVisibility()
end

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
