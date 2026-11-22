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

---@class Trainer
---@field name string
---@field map number
---@field x number
---@field y number

---@alias ByFaction table<string, Trainer>

---@class NextRank
---@field name string
---@field requiredSkill number
---@field requiredLevel number
---@field cap number
---@field hint string
---@field where ByFaction?

---@class Specialization
---@field requiredSkill number
---@field requiredLevel number
---@field Alliance string
---@field Horde string

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

---@param name string
---@param map number uiMapID
---@param x number
---@param y number
---@return Trainer
local function Trainer(name, map, x, y) return { name = name, map = map, x = x, y = y } end

---@param trainer Trainer
---@return ByFaction
local function Both(trainer) return { Alliance = trainer, Horde = trainer } end

-- Every capital city trainer teaches Expert and Artisan on TBC.
local TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

---@param overrides table<number, table>
---@return table<number, NextRank>
local function CraftingRanks(overrides)
	if TBC then return NEXT_RANK_BY_CAP end
	return OverrideRanks(overrides)
end

---@param expert ByFaction
---@param artisan ByFaction
---@return table<number, NextRank>
local function TrainerRanks(expert, artisan)
	return CraftingRanks({ [150] = { where = expert }, [225] = { where = artisan } })
end

---@class Skill
---@field name string
---@field id number
---@field kind SkillKindName
---@field iconSpell number
---@field ranks table<number, NextRank>?
---@field specialization Specialization?
---@field weapon Enum.ItemWeaponSubclass?
---@field emptyHanded boolean?
---@field shapeshifted boolean?
---@field alwaysShown boolean?

---@type Skill[]
ns.SKILLS = {
	{
		name = "Alchemy",
		id = 171,
		kind = "primary",
		iconSpell = 2259,
		ranks = TrainerRanks(
			{ Alliance = Trainer("Ainethil", 1457, 54.9, 24.0), Horde = Trainer("Doctor Herbert Halsey", 1458, 47.8, 73.3) },
			{ Alliance = Trainer("Kylanna Windwhisper", 1444, 32.6, 43.8), Horde = Trainer("Rogvar", 1435, 48.5, 55.9) }
		),
	},
	{
		name = "Blacksmithing",
		id = 164,
		kind = "primary",
		iconSpell = 2018,
		ranks = TrainerRanks(
			{ Alliance = Trainer("Bengus Deepforge", 1455, 52.5, 41.5), Horde = Trainer("Saru Steelfury", 1454, 82.3, 23.0) },
			Both(Trainer("Brikk Keencraft", 1434, 29.0, 75.6))
		),
		specialization = {
			requiredSkill = 200,
			requiredLevel = 40,
			Alliance = "Armorsmith from Grumnus Steelshaper, Weaponsmith from Ironus Coldsteel, both in Ironforge.",
			Horde = "Armorsmith from Okothos Ironrager, Weaponsmith from Borgosh Corebender, both in Orgrimmar.",
		},
	},
	{
		name = "Enchanting",
		id = 333,
		kind = "primary",
		iconSpell = 7411,
		ranks = CraftingRanks({
			[150] = {
				where = {
					Alliance = Trainer("Kitta Firewind", 1429, 64.9, 70.7),
					Horde = Trainer("Hgarth", 1442, 49.2, 57.2),
				},
			},
			[225] = { hint = "Train with Annora, inside the Uldaman dungeon in the Badlands." },
		}),
	},
	{
		name = "Engineering",
		id = 202,
		kind = "primary",
		iconSpell = 4036,
		ranks = TrainerRanks(
			{ Alliance = Trainer("Springspindle Fizzlegear", 1455, 68.5, 43.5), Horde = Trainer("Roxxik", 1454, 76.2, 25.2) },
			Both(Trainer("Buzzek Bracketswing", 1446, 52.3, 27.7))
		),
		specialization = {
			requiredSkill = 200,
			requiredLevel = 30,
			Alliance = "Gnomish from Tinkmaster Overspark in Ironforge, Goblin from Nixx Sprocketspring in Gadgetzan.",
			Horde = "Gnomish from Oglethorpe Obnoticus in Booty Bay, Goblin from Nixx Sprocketspring in Gadgetzan.",
		},
	},
	{ name = "Herbalism", id = 182, kind = "primary", iconSpell = 2366, ranks = NEXT_RANK_BY_CAP },
	{
		name = "Leatherworking",
		id = 165,
		kind = "primary",
		iconSpell = 2108,
		ranks = TrainerRanks(
			{ Alliance = Trainer("Telonis", 1457, 64.4, 21.4), Horde = Trainer("Una", 1456, 41.3, 42.6) },
			{ Alliance = Trainer("Drakk Stonehand", 1425, 13.4, 43.5), Horde = Trainer("Hahrana Ironhide", 1444, 74.4, 43.1) }
		),
		specialization = {
			requiredSkill = 225,
			requiredLevel = 40,
			Alliance = "Dragonscale from Peter Galen in Azshara, Elemental from Sarah Tanner in Searing Gorge, "
				.. "Tribal from Caryssia Moonhunter in Feralas.",
			Horde = "Dragonscale from Thorkaf Dragoneye in the Badlands, Elemental from Brumn Winterhoof in Arathi Highlands, "
				.. "Tribal from Se'Jib in Stranglethorn Vale.",
		},
	},
	{ name = "Mining", id = 186, kind = "primary", iconSpell = 2575, ranks = NEXT_RANK_BY_CAP },
	{ name = "Skinning", id = 393, kind = "primary", iconSpell = 8613, ranks = NEXT_RANK_BY_CAP },
	{
		name = "Tailoring",
		id = 197,
		kind = "primary",
		iconSpell = 3908,
		ranks = TrainerRanks(
			{ Alliance = Trainer("Georgio Bolero", 1453, 43.4, 73.6), Horde = Trainer("Josef Gregorian", 1458, 70.7, 30.7) },
			{ Alliance = Trainer("Timothy Worthington", 1445, 66.2, 51.8), Horde = Trainer("Daryl Stack", 1424, 63.8, 20.8) }
		),
	},

	{
		name = "Cooking",
		id = 185,
		kind = "secondary",
		iconSpell = 2550,
		ranks = OverrideRanks({
			[150] = {
				hint = "Buy Expert Cookbook.",
				where = {
					Alliance = Trainer("Shandrina", 1440, 49.5, 67.1),
					Horde = Trainer("Wulan", 1443, 26.2, 69.7),
				},
			},
			[225] = {
				requiredSkill = 225,
				hint = 'Quest "Clamlette Surprise".',
				where = Both(Trainer("Dirge Quikcleave", 1446, 52.6, 28.1)),
			},
		}),
	},
	{
		name = "First Aid",
		id = 129,
		kind = "secondary",
		iconSpell = 3273,
		ranks = OverrideRanks({
			[150] = {
				hint = "Buy Expert First Aid - Under Wraps.",
				where = {
					Alliance = Trainer("Deneb Walker", 1417, 27.0, 58.8),
					Horde = Trainer("Balai Lok'Wein", 1445, 36.5, 30.4),
				},
			},
			[225] = {
				requiredSkill = 225,
				hint = 'Quest "Triage".',
				where = {
					Alliance = Trainer("Doctor Gustaf VanHowzen", 1445, 67.8, 49.0),
					Horde = Trainer("Doctor Gregory Victor", 1417, 73.4, 36.9),
				},
			},
		}),
	},
	{
		name = "Fishing",
		id = 356,
		kind = "secondary",
		iconSpell = 7620,
		ranks = OverrideRanks({
			[150] = {
				hint = "Buy Expert Fishing - The Bass and You.",
				where = Both(Trainer("Old Man Heming", 1434, 27.4, 77.2)),
			},
			[225] = {
				requiredSkill = 225,
				hint = 'Quest "Nat Pagle, Angler Extreme".',
				where = Both(Trainer("Nat Pagle", 1445, 58.6, 60.1)),
			},
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
	{ name = "Feral Combat", id = 3014, kind = "weapon", iconSpell = 5487, shapeshifted = true },
}

---@type table<string, Skill>
ns.SKILL_BY_ENUS_NAME = {}
for _, skill in ipairs(ns.SKILLS) do
	ns.SKILL_BY_ENUS_NAME[skill.name] = skill
end
