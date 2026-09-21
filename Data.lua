---@class Whetstone
local ns = select(2, ...)

ns.MAX_RANK = 300

---@alias SkillKindName "primary"|"secondary"|"weapon"

---@class SkillKind
---@field label string
---@field cappedUntil string
---@field visibilitySetting string?

---@type SkillKindName[]
ns.KIND_ORDER = { "primary", "secondary", "weapon" }

---@type table<SkillKindName, SkillKind>
ns.KINDS = {
	primary = { label = "Professions", cappedUntil = "you train the next rank" },
	secondary = {
		label = "Secondary skills",
		cappedUntil = "you learn the next rank",
		visibilitySetting = "showSecondary",
	},
	weapon = { label = "Weapon skills", cappedUntil = "you level up", visibilitySetting = "showWeapons" },
}

---@class NextRank
---@field name string
---@field requiredSkill number
---@field requiredLevel number
---@field cap number
---@field hint string

---@type table<number, NextRank>
local NEXT_RANK_BY_CAP = {
	[75] = {
		name = "Journeyman",
		requiredSkill = 50,
		requiredLevel = 10,
		cap = 150,
		hint = "Train at a profession trainer.",
	},
	[150] = {
		name = "Expert",
		requiredSkill = 125,
		requiredLevel = 20,
		cap = 225,
		hint = "Train at an Expert trainer.",
	},
	[225] = {
		name = "Artisan",
		requiredSkill = 200,
		requiredLevel = 35,
		cap = 300,
		hint = "Train at an Artisan trainer.",
	},
}

ns.RANK_NAMES = { [75] = "Apprentice" }
for _, rank in pairs(NEXT_RANK_BY_CAP) do
	ns.RANK_NAMES[rank.cap] = rank.name
end

---@param overrides table<number, table>
---@return table<number, NextRank>
local function OverrideRanks(overrides)
	for cap, rank in pairs(overrides) do
		setmetatable(rank, { __index = NEXT_RANK_BY_CAP[cap] })
	end
	return setmetatable(overrides, { __index = NEXT_RANK_BY_CAP })
end

---@class Skill
---@field name string
---@field id number
---@field kind SkillKindName
---@field iconSpell number
---@field ranks table<number, NextRank>?
---@field weapon Enum.ItemWeaponSubclass?
---@field emptyHanded boolean?
---@field alwaysShown boolean?

---@type Skill[]
ns.SKILLS = {
	{ name = "Alchemy", id = 171, kind = "primary", iconSpell = 2259, ranks = NEXT_RANK_BY_CAP },
	{ name = "Blacksmithing", id = 164, kind = "primary", iconSpell = 2018, ranks = NEXT_RANK_BY_CAP },
	{ name = "Enchanting", id = 333, kind = "primary", iconSpell = 7411, ranks = NEXT_RANK_BY_CAP },
	{ name = "Engineering", id = 202, kind = "primary", iconSpell = 4036, ranks = NEXT_RANK_BY_CAP },
	{ name = "Herbalism", id = 182, kind = "primary", iconSpell = 2366, ranks = NEXT_RANK_BY_CAP },
	{ name = "Leatherworking", id = 165, kind = "primary", iconSpell = 2108, ranks = NEXT_RANK_BY_CAP },
	{ name = "Mining", id = 186, kind = "primary", iconSpell = 2575, ranks = NEXT_RANK_BY_CAP },
	{ name = "Skinning", id = 393, kind = "primary", iconSpell = 8613, ranks = NEXT_RANK_BY_CAP },
	{ name = "Tailoring", id = 197, kind = "primary", iconSpell = 3908, ranks = NEXT_RANK_BY_CAP },

	{
		name = "Cooking",
		id = 185,
		kind = "secondary",
		iconSpell = 2550,
		ranks = OverrideRanks({
			[150] = { hint = "Expert Cookbook, sold by vendors." },
			[225] = { requiredSkill = 225, hint = "Quest from Dirge Quikcleave in Gadgetzan." },
		}),
	},
	{
		name = "First Aid",
		id = 129,
		kind = "secondary",
		iconSpell = 3273,
		ranks = OverrideRanks({
			[150] = { hint = "Expert First Aid - Under Wraps, sold by vendors." },
			[225] = { requiredSkill = 225, hint = 'Quest "Triage" in Theramore or Hammerfall.' },
		}),
	},
	{
		name = "Fishing",
		id = 356,
		kind = "secondary",
		iconSpell = 7620,
		ranks = OverrideRanks({
			[150] = { hint = "Expert Fishing - The Bass and You, sold by Old Man Heming in Booty Bay." },
			[225] = { requiredSkill = 225, hint = "Quest from Nat Pagle in Dustwallow Marsh." },
		}),
	},

	{ name = "Defense", id = 95, kind = "weapon", iconSpell = 204, alwaysShown = true },
	{ name = "Unarmed", id = 162, kind = "weapon", iconSpell = 203, emptyHanded = true },
	{ name = "Daggers", id = 173, kind = "weapon", iconSpell = 1180, weapon = Enum.ItemWeaponSubclass.Dagger },
	{ name = "Fist Weapons", id = 473, kind = "weapon", iconSpell = 15590, weapon = Enum.ItemWeaponSubclass.Unarmed },
	{ name = "Swords", id = 43, kind = "weapon", iconSpell = 201, weapon = Enum.ItemWeaponSubclass.Sword1H },
	{ name = "Two-Handed Swords", id = 55, kind = "weapon", iconSpell = 202, weapon = Enum.ItemWeaponSubclass.Sword2H },
	{ name = "Axes", id = 44, kind = "weapon", iconSpell = 196, weapon = Enum.ItemWeaponSubclass.Axe1H },
	{ name = "Two-Handed Axes", id = 172, kind = "weapon", iconSpell = 197, weapon = Enum.ItemWeaponSubclass.Axe2H },
	{ name = "Maces", id = 54, kind = "weapon", iconSpell = 198, weapon = Enum.ItemWeaponSubclass.Mace1H },
	{ name = "Two-Handed Maces", id = 160, kind = "weapon", iconSpell = 199, weapon = Enum.ItemWeaponSubclass.Mace2H },
	{ name = "Polearms", id = 229, kind = "weapon", iconSpell = 200, weapon = Enum.ItemWeaponSubclass.Polearm },
	{ name = "Staves", id = 136, kind = "weapon", iconSpell = 227, weapon = Enum.ItemWeaponSubclass.Staff },
	{ name = "Bows", id = 45, kind = "weapon", iconSpell = 264, weapon = Enum.ItemWeaponSubclass.Bows },
	{ name = "Guns", id = 46, kind = "weapon", iconSpell = 266, weapon = Enum.ItemWeaponSubclass.Guns },
	{ name = "Crossbows", id = 226, kind = "weapon", iconSpell = 5011, weapon = Enum.ItemWeaponSubclass.Crossbow },
	{ name = "Thrown", id = 176, kind = "weapon", iconSpell = 2567, weapon = Enum.ItemWeaponSubclass.Thrown },
	{ name = "Wands", id = 228, kind = "weapon", iconSpell = 5009, weapon = Enum.ItemWeaponSubclass.Wand },
}

---@type table<string, Skill>
ns.SKILL_BY_ENUS_NAME = {}
for _, skill in ipairs(ns.SKILLS) do
	ns.SKILL_BY_ENUS_NAME[skill.name] = skill
end
