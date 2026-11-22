---@class Whetstone
local ns = select(2, ...)

-- Forever's Stormwind map has different bounds from Era's.
local ranks = ns.SKILL_BY_ENUS_NAME.Tailoring.ranks --[[@as table<number, NextRank>]]
local where = ranks[150].where --[[@as ByFaction]]
where.Alliance.x, where.Alliance.y = 53.1, 81.3

-- Forever's gathering trainers ask for no character level. Mining and Skinning share Herbalism's ranks.
for _, rank in pairs(ns.SKILL_BY_ENUS_NAME.Herbalism.ranks --[[@as table<number, NextRank>]]) do
	rank.requiredLevel = 0
end
