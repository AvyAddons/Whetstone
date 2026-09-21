---@class Whetstone
local ns = select(2, ...)

---@class WhetstoneMedia
local Media = {}
ns.Media = Media

---@alias MediaKind "statusbar"|"font"

-- Names match LibSharedMedia's, so a saved choice resolves with or without it.
---@type table<MediaKind, table<string, string>>
local BUILTIN = {
	statusbar = {
		["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
		["Blizzard Character Skills Bar"] = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
		["Blizzard Raid Bar"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
		["Solid"] = "Interface\\Buttons\\WHITE8X8",
	},
	font = {
		["Default"] = STANDARD_TEXT_FONT,
		["Arial Narrow"] = "Fonts\\ARIALN.TTF",
		["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
		["Morpheus"] = "Fonts\\MORPHEUS.TTF",
		["Skurri"] = "Fonts\\SKURRI.TTF",
	},
}

---@type table<MediaKind, string>
local FALLBACK = { statusbar = "Blizzard", font = "Default" }

-- Other addons embed the library, so it may load after this file does.
local function SharedMedia() return LibStub and LibStub("LibSharedMedia-3.0", true) end

---@param kind MediaKind
---@return string[]
function Media.List(kind)
	local names, seen = {}, {}
	local function Add(name)
		if not seen[name] then
			seen[name] = true
			names[#names + 1] = name
		end
	end
	for name in pairs(BUILTIN[kind]) do
		Add(name)
	end
	local lsm = SharedMedia()
	if lsm then
		for _, name in ipairs(lsm:List(kind)) do
			Add(name)
		end
	end
	table.sort(names)
	return names
end

---@param kind MediaKind
---@param name string
---@return string path
function Media.Fetch(kind, name)
	local lsm = SharedMedia()
	return BUILTIN[kind][name] or (lsm and lsm:Fetch(kind, name, true)) or BUILTIN[kind][FALLBACK[kind]]
end
