---@class Whetstone
local ns = select(2, ...)

-- Forever moved Georgio Bolero within Stormwind.
local ranks = ns.SKILL_BY_ENUS_NAME.Tailoring.ranks --[[@as table<number, NextRank>]]
local where = ranks[150].where --[[@as ByFaction]]
where.Alliance.x, where.Alliance.y = 53.1, 81.3
