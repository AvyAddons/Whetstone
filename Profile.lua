---@class Whetstone
local ns = select(2, ...)

---@class OverrideGroup
---@field key string
---@field label string
---@field tooltip string
---@field keys string[]

-- Settings a character can keep for itself instead of using the account-wide profile.
---@type OverrideGroup[]
ns.OVERRIDE_GROUPS = {
	{
		key = "position",
		label = "Character-specific position",
		tooltip = "This character keeps its own bar position.",
		keys = { "point", "relPoint", "x", "y" },
	},
	{
		key = "visibility",
		label = "Character-specific visibility",
		tooltip = "This character keeps its own Show bar and Hide in combat settings.",
		keys = { "shown", "hideInCombat" },
	},
	{
		key = "skills",
		label = "Character-specific skills",
		tooltip = "This character keeps its own skill list and skill filters.",
		keys = { "hidden", "showSecondary", "showWeapons", "allWeapons", "combatFocus", "hideMaxed", "hideCapped" },
	},
}

---@param key string
local function Default(key)
	if key == "hidden" then return {} end
	return ns.DEFAULTS[key]
end

local function Copy(value)
	if type(value) == "table" then return CopyTable(value) end
	return value
end

local function Equal(a, b)
	if type(a) == "table" and type(b) == "table" then return tCompare(a, b) and tCompare(b, a) end
	return a == b
end

-- GLOBAL_STEPS[v] and CHAR_STEPS[v] upgrade a store from version v - 1 to v. A store without a version is version 0.
-- Global steps run first, so a character step sees a complete global profile at the latest version.
local GLOBAL_STEPS = {
	-- The first character to log in after settings became account-wide seeds the global profile.
	---@param global table
	---@param legacy table?
	function(global, legacy)
		if not legacy then return end
		for key, value in pairs(legacy) do
			if Default(key) ~= nil then global[key] = Copy(value) end
		end
	end,
}

local CHAR_STEPS = {
	-- Per-character settings become overrides for the groups whose values differ from the global profile.
	---@param char table
	---@param global table
	function(char, global)
		local legacy = CopyTable(char)
		wipe(char)
		char.overrides = {}
		for _, group in ipairs(ns.OVERRIDE_GROUPS) do
			local differs = false
			for _, key in ipairs(group.keys) do
				if legacy[key] ~= nil and not Equal(legacy[key], global[key]) then differs = true end
			end
			if differs then
				for _, key in ipairs(group.keys) do
					local value = legacy[key]
					if value == nil then value = global[key] end
					char.overrides[key] = Copy(value)
				end
			end
		end
	end,
}

---@param store table
---@param steps (fun(store: table, arg: table?))[]
---@param arg table?
local function Upgrade(store, steps, arg)
	for version = (store.version or 0) + 1, #steps do
		steps[version](store, arg)
		store.version = version
	end
end

---@param tbl table
local function DropInvalid(tbl)
	for key, value in pairs(tbl) do
		local default = Default(key)
		if default ~= nil and type(value) ~= type(default) then tbl[key] = nil end
	end
end

local global, char

function ns.InitProfile()
	WhetstoneGlobalDB = WhetstoneGlobalDB or {}
	WhetstoneDB = WhetstoneDB or {}
	global, char = WhetstoneGlobalDB, WhetstoneDB

	Upgrade(global, GLOBAL_STEPS, char.version == nil and char or nil)
	DropInvalid(global)
	for key in pairs(ns.DEFAULTS) do
		if global[key] == nil then global[key] = Default(key) end
	end
	global.hidden = global.hidden or {}

	Upgrade(char, CHAR_STEPS, global)
	char.overrides = char.overrides or {}
	DropInvalid(char.overrides)
	-- A key added to an overridden group starts from the global value.
	for _, group in ipairs(ns.OVERRIDE_GROUPS) do
		if ns.IsOverridden(group) then
			for _, key in ipairs(group.keys) do
				if char.overrides[key] == nil then char.overrides[key] = Copy(global[key]) end
			end
		end
	end

	-- Reads prefer the character's override, and writes go wherever the value was read from.
	ns.db = setmetatable({}, {
		__index = function(_, key)
			local value = char.overrides[key]
			if value == nil then value = global[key] end
			return value
		end,
		__newindex = function(_, key, value)
			if char.overrides[key] ~= nil then
				char.overrides[key] = value
			else
				global[key] = value
			end
		end,
	})
end

---@param group OverrideGroup
---@return boolean
function ns.IsOverridden(group)
	for _, key in ipairs(group.keys) do
		if char.overrides[key] ~= nil then return true end
	end
	return false
end

-- Enabling copies the global values so the character starts from what it already shows.
---@param group OverrideGroup
---@param enabled boolean
function ns.SetOverridden(group, enabled)
	for _, key in ipairs(group.keys) do
		char.overrides[key] = enabled and Copy(global[key]) or nil
	end
end
