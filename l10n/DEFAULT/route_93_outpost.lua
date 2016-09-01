--[[
	Route 93 Outpost control script for Pb's Playhouse
	Mission: NTTR Practice
]]

route93outpost = {}

-- *** START CONFIG ***

-- name of trigger zone
route93outpost.triggerZone = "Route 93 Outpost"

-- which group's destruction will trigger a respawn of all units
route93outpost.triggerGroup = "Route 93 Outpost Command Post"
route93outpost.triggerUnit  = Group.getByName(route93outpost.triggerGroup):getUnits()[1]:getName()

-- blue AI FAC Pilot Name
route93outpost.bluefac = "FAC #8"

-- respawn check interval
route93outpost.interval = 5

-- *** END CONFIG ***

-- Store Blue AI FAC group data as a template
if Unit.getByName(route93outpost.bluefac) == nil then
    env.error("route93outpost: MISSING FAC unit \""..route93outpost.bluefac.."\"")
end

route93outpost.blueFacGroupName = Unit.getByName(route93outpost.bluefac):getGroup():getName()
route93outpost.blueFacGroupTemplate = mist.getGroupData(route93outpost.blueFacGroupName)

-- FUNCTIONS
function route93outpost.isGroupAlive(_groupName)
	if Group.getByName(_groupName) and Group.getByName(_groupName):isExist() == true and #Group.getByName(_groupName):getUnits() > 0 then
		return true
	else
		return false
	end
end

function route93outpost.isHelicopterGroupAlive(_groupName)
	if Group.getByName(_groupName) and Group.getByName(_groupName):isExist() == true and #Group.getByName(_groupName):getUnits() > 0 then
		return true
	else
		return false
	end
end

function route93outpost.checkTriggerGroup()

	--env.info("route93outpost: Scheduling next route93outpost.checkTriggerGroup")
    timer.scheduleFunction(route93outpost.checkTriggerGroup, nil, timer.getTime() + route93outpost.interval)

	--env.info("route93outpost: route93outpost.checkTriggerGroup")
	if not route93outpost.isGroupAlive(route93outpost.triggerGroup) then
		--env.info("route93outpost: RESPAWN Outpost")
		trigger.action.outText("Route 93 Outpost Command Center Destroyed!\nRespawning all outpost groups...",10)
		for g, _ in pairs(route93outpost.redGroups) do
			--env.info("... respawning "..g)
			mist.respawnGroup(g)
		end
	end
end

function route93outpost.checkHelicopterGroup(groupName)
    timer.scheduleFunction(route93outpost.checkHelicopterGroup, groupName, timer.getTime() + route93outpost.interval)
    
    if route93outpost.isHelicopterGroupAlive(groupName) then
        -- helicopter group is still alive, schedule next check
        --env.info("route93outpost: Scheduling next route93outpost.checkHelicopterGroup(\""..groupName.."\")")
    else
        env.info("route93outpost: helicopter group \""..groupName.."\" dead, respawning")
        route93outpost.respawnHelicopter(groupName)
        trigger.action.outText("Route 93 Outpost helicopter group \""..groupName.."\" destroyed!\nRespawning...",10)
    end
end

function route93outpost.respawnHelicopter(groupName)
    --env.info("route93outpost: respawning helicopter group \""..groupName.."\"")
	local oldName = groupName
	if helicopterRespawn == nil then
		helicopterRespawn = {[groupName] = 0}
	elseif helicopterRespawn[groupName] == nil then
		helicopterRespawn[groupName] = 0
	else
		oldName = groupName .. helicopterRespawn[groupName]
	end
	helicopterRespawn[groupName] = helicopterRespawn[groupName] + 1
	local newName = groupName .. helicopterRespawn[groupName]
    
	local group = Group.getByName(oldName)
	if group then
		group = group:getController()
		Controller.setCommand(group, {id = 'DeactivateBeacon', params = {}})
		Controller.setTask(group, {id = 'NoTask', params = {}})
	end

	group = mist.getGroupData(groupName)
	group.route = { points = mist.getGroupRoute(groupName, true) }
	group.groupName = newName
	group.groupId = nil
	group.units[1].unitId = nil
	group.units[1].unitName = newName
	--group.country = country
	--group.category = 'HELICOPTER'

	mist.dynAdd(group)
    route93outpost.checkHelicopterGroup(newName)
end

function route93outpost.destroyHelicopters()
	env.info("route93outpost: route93outpost.destroyHelicopters")
    
    for _, u in pairs(mist.getUnitsInZones(mist.makeUnitTable({'[red][helicopter]'}), {route93outpost.triggerZone})) do
        local unitID = tonumber(u:getID())
        trigger.action.explosion(u:getPosition().p, 100)
    end

end

function route93outpost.destroyTriggerUnit()
	trigger.action.explosion(Unit.getByName(route93outpost.triggerUnit):getPosition().p, 100)
end

function route93outpost.destroyFac(unitName)
    trigger.action.explosion(Unit.getByName(unitName):getPosition().p, 100)
end

function route93outpost.checkBlueFac(unitName)
    timer.scheduleFunction(route93outpost.checkBlueFac, unitName, timer.getTime() + route93outpost.interval)
    
    local _facUnit = Unit.getByName(unitName)
    
    if _facUnit ~= nil and _facUnit:inAir() == true and _facUnit:getLife() > 0 and _facUnit:isActive() == true then
        -- FAC still active
    else
        mist.respawnGroup(route93outpost.blueFacGroupName, true)
    end
end

--env.info("route93outpost: Outpost trigger group: \""..route93outpost.triggerGroup.."\"")
--env.info("route93outpost: Outpost trigger unit: \""..route93outpost.triggerUnit.."\"")

-- STARTEH TIMARS
--env.info("route93outpost: Scheduling command center check")
timer.scheduleFunction(route93outpost.checkTriggerGroup, nil, timer.getTime() + 5)
--env.info("route93outpost: Scheduling blue FAC check")
timer.scheduleFunction(route93outpost.checkBlueFac, route93outpost.bluefac, timer.getTime() + 5)

-- DEBUG: schedule bunker demolition
--env.info("route93outpost: DEBUG: Scheduling bunker death")
--timer.scheduleFunction(route93outpost.destroyTriggerUnit, nil, timer.getTime() + 10)

--	env.info("route93outpost: DEBUG: Scheduling next helicopter death")
--timer.scheduleFunction(route93outpost.destroyHelicopters, nil, timer.getTime() + 20)

-- populate a list of Red coalition groups inside the trigger zone
--env.info("route93outpost: Counting ground units in "..route93outpost.triggerZone)
route93outpost.redGroups = {}
for _, u in pairs(mist.getUnitsInZones(mist.makeUnitTable({'[red][vehicle]'}), {route93outpost.triggerZone})) do
	local unitID = tonumber(u:getID())
	local groupName = tostring(mist.DBs.unitsById[unitID]["groupName"])
	route93outpost.redGroups[groupName] = true
end
--env.info("route93outpost: Red groups in Route 93 Outpost zone: "..mist.utils.tableShow(route93outpost.redGroups))
--env.info("route93outpost: Finished counting groups in "..route93outpost.triggerZone)

-- make sure the trigger group exists
if not route93outpost.redGroups[route93outpost.triggerGroup] then
	env.error("route93outpost: There is no red group \""..route93outpost.triggerGroup.."\" in zone \""..route93outpost.triggerZone.."\"")
end

-- populate a list of Red coalition helicopter groups inside the trigger zone
--env.info("route93outpost: Counting helicopters in "..route93outpost.triggerZone)
route93outpost.redHelicopterGroups = {}
for _, u in pairs(mist.getUnitsInZones(mist.makeUnitTable({'[red][helicopter]'}), {route93outpost.triggerZone})) do
	local unitID = tonumber(u:getID())
	local groupName = tostring(mist.DBs.unitsById[unitID]["groupName"])
	route93outpost.redHelicopterGroups[groupName] = true
end
--env.info("route93outpost: Red helicopter groups in Route 93 Outpost zone: "..mist.utils.tableShow(route93outpost.redHelicopterGroups))
--env.info("route93outpost: Finished counting helicopters in "..route93outpost.triggerZone)
--for g, _ in pairs(route93outpost.redHelicopterGroups) do
--    --env.info("route93outpost: Initializing respawning helicopter group \""..g.."\"")
--    route93outpost.checkHelicopterGroup(g)
--end

env.info("Loaded Route 93 Outpost")