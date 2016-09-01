--RESPAWN SCRIPT; MISSION START -> DO SCRIPT
--http://forums.eagle.ru/showthread.php?t=112170
local oldGroupRemovalTime = 600 -- Time (seconds) after which old groups are removed

barons_respawn_script = {}
barons_respawn_script.predicate = function(groupName, lowFuelThreshold, lowHealthThreshold)
	if barons_respawn_script and barons_respawn_script[groupName] then
		groupName = groupName .. barons_respawn_script[groupName]
	end
	local group = Group.getByName(groupName)
	if not group then
		return true
	end

	group = group:getUnits()[1]
	if not group or Unit.inAir(group) == false then
		return true
	end
	if group:getFuel() < lowFuelThreshold or group:getLife() / group:getLife0() < lowHealthThreshold then
		return true
	end
return false
end

barons_respawn_script.removeGroup = function(group)
	group = Group.getByName(group)
	if group then
		trigger.action.deactivateGroup(group)
	end
end

barons_respawn_script.action = function(groupName)
	local oldName = groupName
	if barons_respawn_script[groupName] == nil then
		barons_respawn_script[groupName] = 0
	else
		oldName = groupName .. barons_respawn_script[groupName]
	end
	barons_respawn_script[groupName] = barons_respawn_script[groupName] + 1
	local newName = groupName .. barons_respawn_script[groupName]

	mist.scheduleFunction(barons_respawn_script.removeGroup, {oldName}, timer.getTime() + oldGroupRemovalTime)
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
	group.category = 'AIRPLANE'

	mist.dynAdd(group)

	group = Group.getByName(newName)
	group = group:getController()
end

barons_respawn_script.checkstate = function(groupName, lowFuelThreshold, lowHealthThreshold, oldresult)
	local newresult = barons_respawn_script.predicate(groupName, lowFuelThreshold, lowHealthThreshold)
	if oldresult == false and newresult == true then
		barons_respawn_script.action(groupName)
	end
	
	mist.scheduleFunction(barons_respawn_script.checkstate, {groupName, lowFuelThreshold, lowHealthThreshold, newresult},  timer.getTime() + 1)
end