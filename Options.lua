---@type string
local addonName = ...
---@class Whetstone
local ns = select(2, ...)

---@class WhetstoneOptions
local Options = {}
ns.Options = Options

ns.DEFAULTS = {
	shown = true,
	locked = false,
	hideInCombat = false,
	point = "CENTER",
	relPoint = "CENTER",
	x = 0,
	y = -150,
	showIcon = true,
	showNames = true,
	fullBar = false,
	showBar = true,
	showBonus = true,
	showSecondary = true,
	showWeapons = true,
	allWeapons = false,
	hideMaxed = false,
	vertical = false,
	perLine = 6,
	scale = 1,
	spacing = 4,
	bgAlpha = 0.6,
	border = true,
	texture = "Blizzard",
	font = "Default",
	fontSize = 10,
	flash = true,
	sound = true,
	chatAlerts = true,
}

---@class OptionRow
---@field header string?
---@field key string?
---@field label string?
---@field tooltip string?
---@field slider SliderRange?
---@field media MediaKind?

---@class SliderRange
---@field min number
---@field max number
---@field step number
---@field format string

---@type OptionRow[]
local LAYOUT = {
	{ header = "Display" },
	{ key = "showIcon", label = "Show skill icons" },
	{ key = "showNames", label = "Show skill names" },
	{
		key = "fullBar",
		label = "Full-height bars",
		tooltip = "The progress bar fills the tile, with the text drawn on top of it.",
	},
	{ key = "showBar", label = "Show progress bar" },
	{ key = "showBonus", label = "Show skill bonuses", tooltip = "Racial and gear bonuses, such as (+5)." },
	{ key = "showSecondary", label = "Show secondary skills" },
	{ key = "showWeapons", label = "Show weapon skills" },
	{
		key = "allWeapons",
		label = "Show every weapon skill",
		tooltip = "Otherwise a weapon skill shows while its weapon is equipped or after it gains a point this session.",
	},
	{ key = "hideMaxed", label = "Hide maxed skills" },
	{ key = "vertical", label = "Vertical layout" },
	{ key = "perLine", label = "Tiles per line", slider = { min = 1, max = 20, step = 1, format = "%d" } },

	{ header = "Behaviour" },
	{ key = "shown", label = "Show bar" },
	{ key = "locked", label = "Lock position" },
	{ key = "hideInCombat", label = "Hide in combat" },

	{ header = "Alerts" },
	{ key = "flash", label = "Flash on skill-up" },
	{ key = "sound", label = "Sound when capped or ready to train" },
	{ key = "chatAlerts", label = "Chat message when capped or ready to train" },

	{ header = "Appearance" },
	{ key = "scale", label = "Scale", slider = { min = 0.5, max = 2, step = 0.05, format = "%.2f" } },
	{ key = "spacing", label = "Tile spacing", slider = { min = 0, max = 20, step = 1, format = "%d" } },
	{ key = "bgAlpha", label = "Background opacity", slider = { min = 0, max = 1, step = 0.05, format = "%.2f" } },
	{ key = "border", label = "Show border" },
	{ key = "texture", label = "Bar texture", media = "statusbar" },
	{ key = "font", label = "Font", media = "font" },
	{ key = "fontSize", label = "Font size", slider = { min = 8, max = 14, step = 1, format = "%d" } },
}

local VAR_TYPES = {
	boolean = Settings.VarType.Boolean,
	number = Settings.VarType.Number,
	string = Settings.VarType.String,
}

function Options:Init()
	local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
	self.category = category

	for _, row in ipairs(LAYOUT) do
		if row.header then
			layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(row.header))
		else
			local default = ns.DEFAULTS[row.key]
			local setting = Settings.RegisterProxySetting(
				category,
				addonName .. "_" .. row.key,
				VAR_TYPES[type(default)],
				row.label,
				default,
				function() return ns.db[row.key] end,
				function(value)
					ns.db[row.key] = value
					ns.Bar:Apply()
				end
			)
			local slider, media = row.slider, row.media
			if media then
				Settings.CreateDropdown(category, setting, function()
					local container = Settings.CreateControlTextContainer()
					for _, name in ipairs(ns.Media.List(media)) do
						container:Add(name, name)
					end
					return container:GetData()
				end, row.tooltip)
			elseif slider then
				local options = Settings.CreateSliderOptions(slider.min, slider.max, slider.step)
				options:SetLabelFormatter(
					MinimalSliderWithSteppersMixin.Label.Right,
					function(value) return slider.format:format(value) end
				)
				Settings.CreateSlider(category, setting, options, row.tooltip)
			else
				Settings.CreateCheckbox(category, setting, row.tooltip)
			end
		end
	end

	layout:AddInitializer(
		CreateSettingsButtonInitializer("Position", "Reset position", function() ns.Bar:ResetPosition() end, nil, true)
	)

	for _, kind in ipairs(ns.KIND_ORDER) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(ns.KINDS[kind].label))
		for _, skill in ipairs(ns.SKILLS) do
			if skill.kind == kind then self:AddSkillCheckbox(category, skill) end
		end
	end

	Settings.RegisterAddOnCategory(category)
end

---@param skill Skill
function Options:AddSkillCheckbox(category, skill)
	local setting = Settings.RegisterProxySetting(
		category,
		addonName .. "_skill_" .. skill.name,
		Settings.VarType.Boolean,
		skill.name,
		true,
		function() return not ns.db.hidden[skill.name] end,
		function(value)
			ns.db.hidden[skill.name] = not value or nil
			ns.Bar:Refresh()
		end
	)
	Settings.CreateCheckbox(category, setting)
end

function Options:Open()
	-- OpenSettingsPanel is protected, so addon code cannot call it in combat.
	if InCombatLockdown() then return ns.Print(ERR_NOT_IN_COMBAT) end
	Settings.OpenToCategory(self.category:GetID())
end
