function route93outpost.destroyHelicopters()
	env.info("route93outpost.destroyHelicopters")
    
    for _, u in pairs(mist.getUnitsInZones(mist.makeUnitTable({'[red][helicopter]'}), {route93outpost.triggerZone})) do
        local unitID = tonumber(u:getID())
        trigger.action.explosion(u:getPosition().p, 100)
    end

--	env.info("Scheduling next route93outpost.destroyHelicopters")
--    timer.scheduleFunction(route93outpost.destroyHelicopters, nil, timer.getTime() + route93outpost.interval)
end