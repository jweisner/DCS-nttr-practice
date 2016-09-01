--[[
TODO:
    * combined JTAC and FAC laser target table? This would keep JTAC and FAC from lasing the same target...?
]]

-- ***************** FAC CONFIGURATION *****************

ctld.FAC_maxDistance = 10000 -- How far a FAC can "see" in meters (with Line of Sight)

ctld.FAC_smokeOn_RED  = true -- enables marking of target with smoke for RED forces
ctld.FAC_smokeOn_BLUE = true -- enables marking of target with smoke for BLUE forces

ctld.FAC_smokeColour_RED  = 4 -- RED  side smoke colour -- Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4
ctld.FAC_smokeColour_BLUE = 1 -- BLUE side smoke colour -- Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4

ctld.FAC_FACStatusF10 = true -- enables F10 FAC Status menu

ctld.FAC_location = true -- shows location of target in FAC message

ctld.FAC_lock = "all" -- "vehicle" OR "troop" OR "all" forces FAC to only lock vehicles or troops or all ground units

ctld.FAC_laser_codes = { '1688', '1677', '1666', '1113' }

-- ******************** FAC names **********************

-- Use any of the predefined names or set your own ones
ctld.facPilotNames = {
    "FAC #1",
    "FAC #2",
    "FAC #3",
    "FAC #4",
    "FAC #5",
    "FAC #6",
    "FAC #7",
    "FAC #8",
}


------------ FAC -----------


ctld.facLaserPoints = {}
ctld.facIRPoints = {}
ctld.facSmokeMarks = {}
ctld.facUnits = {} -- list of FAC units for f10 command
ctld.facCurrentTargets = {}
ctld.facAddedTo = {} -- keeps track of who's had the fac command menu added
ctld.facRadioAdded = {} -- keeps track of who's had the radio command added
ctld.facLaserPointCodes = {} -- keeps track of what laser code is used by each fac
ctld.facOnStation = {} -- keeps track of which facs are on station

-- search for activated FAC units and schedule facAutoLase
function ctld.checkFacStatus()
    --env.info("CTLD FAC checkFacStatus")
    timer.scheduleFunction(ctld.checkFacStatus, nil, timer.getTime() + 1.0)

    local _status, _result = pcall(function()

        for _, _facUnitName in ipairs(ctld.facPilotNames) do

            local _facUnit = ctld.getFacUnit(_facUnitName)
            
            if _facUnit ~= nil then
        
                --[[
                if ctld.facOnStation[_facUnitName] == true then
                    env.info("CTLD FAC DEBUG: ctld.checkFacStatus() " .. _facUnitName .. " on-station")
                end
                
                if ctld.facOnStation[_facUnitName] == nil then
                    env.info("CTLD FAC DEBUG: ctld.checkFacStatus() " .. _facUnitName .. " off-station")
                end
                ]]
                
                -- if fac is off-station and is AI, set onStation
                if ctld.facUnits[_facUnitName] == nil and _facUnit:getPlayerName() == nil then
                    --env.info("CTLD FAC: setting onStation for AI fac unit " .. _facUnitName)
                    ctld.setFacOnStation({_facUnitName, true})
                end
                
                -- start facAutoLase if the FAC is on station and not already scheduled
                if ctld.facUnits[_facUnitName] == nil and ctld.facOnStation[_facUnitName] == true then
                    env.info("CTLD FAC: found new FAC unit. Starting facAutoLase for " .. _facUnitName)
                    ctld.facAutoLase(_facUnitName) --(_facUnitName, _laserCode, _smoke, _lock, _colour)
                end
            end
        end
    end)

    if (not _status) then
        env.error(string.format("CTLD FAC ERROR: %s", _result))
    end
end

-- gets the FAC status and displays to coalition units
function ctld.getFacStatus(_args)

    --returns the status of all FAC units

    local _playerUnit = ctld.getFacUnit(_args[1])

    if _playerUnit == nil then
        return
    end

    local _side = _playerUnit:getCoalition()

    local _facUnit = nil

    local _message = "FAC STATUS: \n\n"

    for _facUnitName, _facDetails in pairs(ctld.facUnits) do

        --look up units
        _facUnit = Unit.getByName(_facDetails.name)

        if _facUnit ~= nil and _facUnit:getLife() > 0 and _facUnit:isActive() == true and _facUnit:getCoalition() == _side and ctld.facOnStation[_facUnitName] == true then

            local _enemyUnit = ctld.getCurrentFacUnit(_facUnit, _facUnitName)

            local _laserCode = ctld.facLaserPointCodes[_facUnitName]

            if _laserCode == nil then
                _laserCode = "UNKNOWN"
            end

            -- get player name if available
            local _facName = _facUnitName
            if _facUnit:getPlayerName() ~= nil then
                _facName = _facUnit:getPlayerName()
            end

            if _enemyUnit ~= nil and _enemyUnit:getLife() > 0 and _enemyUnit:isActive() == true then
                _message = _message .. "" .. _facName .. " targeting " .. _enemyUnit:getTypeName() .. " CODE: " .. _laserCode .. ctld.getFacPositionString(_enemyUnit) .. "\n"
            else
                _message = _message .. "" .. _facName .. " on-station and searching for targets" .. " CODE: " .. _laserCode .. "\n"
            end
        end
    end

    if _message == "FAC STATUS: \n\n" then
        _message = "No Active FACs"
    end

    ctld.notifyCoalition(_message, 10, _side)
end

function ctld.getFacPositionString(_unit)

    if ctld.FAC_location == false then
        return ""
    end

    local _lat, _lon = coord.LOtoLL(_unit:getPosition().p)

    local _latLngStr = mist.tostringLL(_lat, _lon, 3, false)

    local _mgrsString = mist.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(_unit:getPosition().p)), 5)

    return " @ " .. _latLngStr .. " - MGRS " .. _mgrsString
end

-- get currently selected unit and check if the FAC is still in range
function ctld.getCurrentFacUnit(_facUnit, _facUnitName)


    local _unit = nil

    if ctld.facCurrentTargets[_facUnitName] ~= nil then
        _unit = Unit.getByName(ctld.facCurrentTargets[_facUnitName].name)
    end

    local _tempPoint = nil
    local _tempDist = nil
    local _tempPosition = nil

    local _facPosition = _facUnit:getPosition()
    local _facPoint = _facUnit:getPoint()

    if _unit ~= nil and _unit:getLife() > 0 and _unit:isActive() == true then

        -- calc distance
        _tempPoint = _unit:getPoint()
        --   tempPosition = unit:getPosition()

        _tempDist = ctld.getDistance(_unit:getPoint(), _facUnit:getPoint())
        if _tempDist < ctld.FAC_maxDistance then
            -- calc visible

            -- check slightly above the target as rounding errors can cause issues, plus the unit has some height anyways
            local _offsetEnemyPos = { x = _tempPoint.x, y = _tempPoint.y + 2.0, z = _tempPoint.z }
            local _offsetFacPos = { x = _facPoint.x, y = _facPoint.y + 2.0, z = _facPoint.z }

            if land.isVisible(_offsetEnemyPos, _offsetFacPos) then
                return _unit
            end
        end
    end
    return nil
end

function ctld.getFacUnit(_facUnitName)

    if _facUnitName == nil then
        return nil
    end

    local _fac = Unit.getByName(_facUnitName)

    if _fac ~= nil and _fac:isActive() and _fac:getLife() > 0 then

        return _fac
    end

    return nil
end

-- gets the FAC player name if available
function ctld.getFacName(_facUnitName)
    local _facUnit = Unit.getByName(_facUnitName)
    local _facName = _facUnitName
    
    if _facUnit == nil then
        --env.info('CTLD FAC: ctld.getFacName: unit not found: '.._facUnitName)
        return _facUnitName
    end
    
    if _facUnit:getPlayerName() ~= nil then
        _facName = _facUnit:getPlayerName()
    end
    
    return _facName
end

function ctld.facAutoLase(_facUnitName, _laserCode, _smoke, _lock, _colour)
    
    --env.info('CTLD FAC DEBUG: ' .. _facUnitName .. ' autolase')
    if _lock == nil then

        _lock = ctld.FAC_lock
    end
        
    local _facUnit = Unit.getByName(_facUnitName)

    if _facUnit == nil then
        --env.info('CTLD FAC: ' .. _facUnitName .. ' dead.')
        -- FAC was in the list, now the unit is missing: probably dead
        if ctld.facUnits[_facUnitName] ~= nil then
            ctld.notifyCoalition("Forward Air Controller \"" ..ctld.getFacName(_facUnitName).. "\" MIA.", 10, ctld.facUnits[_facUnitName].side)
        end

        --remove fac
        ctld.cleanupFac(_facUnitName)

        return
    end
    
    -- stop fac activity if fac is marked off-station CANCELS AUTO-LASE
    if ctld.facOnStation[_facUnitName] == nil then
        env.info('CTLD FAC: ' .. _facUnitName .. ' is marked off-station, stopping autolase')
        ctld.cancelFacLase(_facUnitName)
        ctld.facCurrentTargets[_facUnitName] = nil
        return
    end

    if ctld.facLaserPointCodes[_facUnitName] == nil then
        --env.info('CTLD FAC: ctld.facAutoLase() ' .. _facUnitName .. ' has no laserCode, setting default')
        ctld.facLaserPointCodes[_facUnitName] = ctld.FAC_laser_codes[1]
    end
    _laserCode = ctld.facLaserPointCodes[_facUnitName]
    --env.info('CTLD FAC: ' .. _facUnitName .. ' laser code: ' .. _laserCode)
    
    if ctld.facUnits[_facUnitName] == nil then
        --env.info('CTLD FAC: ' .. _facUnitName .. ' not in ctld.facUnits list, adding')
        --add to list
        ctld.facUnits[_facUnitName] = { name = _facUnit:getName(), side = _facUnit:getCoalition() }
        
        -- work out smoke colour
        if _colour == nil then

            if _facUnit:getCoalition() == 1 then
                _colour = ctld.FAC_smokeColour_RED
            else
                _colour = ctld.FAC_smokeColour_BLUE
            end
        end


        if _smoke == nil then

            if _facUnit:getCoalition() == 1 then
                _smoke = ctld.FAC_smokeOn_RED
            else
                _smoke = ctld.FAC_smokeOn_BLUE
            end
        end
    end


    -- search for current unit

    if _facUnit:isActive() == false then

        ctld.cleanupFac(_facUnitName)

        env.info('CTLD FAC: ' .. _facUnitName .. ' Not Active - Waiting 30 seconds')
        timer.scheduleFunction(ctld.timerFacAutoLase, { _facUnitName, _laserCode, _smoke, _lock, _colour }, timer.getTime() + 30)

        return
    end

    local _enemyUnit = ctld.getCurrentFacUnit(_facUnit, _facUnitName)

    if _enemyUnit == nil and ctld.facCurrentTargets[_facUnitName] ~= nil then

        local _tempUnitInfo = ctld.facCurrentTargets[_facUnitName]

        local _tempUnit = Unit.getByName(_tempUnitInfo.name)

        if _tempUnit ~= nil and _tempUnit:getLife() > 0 and _tempUnit:isActive() == true then
            ctld.notifyCoalition(ctld.getFacName(_facUnitName) .. " target " .. _tempUnitInfo.unitType .. " lost. Scanning for Targets. ", 10, _facUnit:getCoalition())
        else
            ctld.notifyCoalition(ctld.getFacName(_facUnitName) .. " target " .. _tempUnitInfo.unitType .. " KIA. Good Job! Scanning for Targets. ", 10, _facUnit:getCoalition())
        end

        --remove from smoke list
        ctld.facSmokeMarks[_tempUnitInfo.name] = nil

        -- remove from target list
        ctld.facCurrentTargets[_facUnitName] = nil

        --stop lasing
        ctld.cancelFacLase(_facUnitName)
    end


    if _enemyUnit == nil then
        _enemyUnit = ctld.findFacNearestVisibleEnemy(_facUnit, _lock)

        if _enemyUnit ~= nil then

            -- store current target for easy lookup
            ctld.facCurrentTargets[_facUnitName] = { name = _enemyUnit:getName(), unitType = _enemyUnit:getTypeName(), unitId = _enemyUnit:getID() }

            ctld.notifyCoalition(ctld.getFacName(_facUnitName) .. " lasing new target " .. _enemyUnit:getTypeName() .. '. CODE: ' .. _laserCode .. ctld.getFacPositionString(_enemyUnit), 10, _facUnit:getCoalition())

            -- create smoke
            if _smoke == true then

                --create first smoke
                ctld.createSmokeMarker(_enemyUnit, _colour)
            end
        end
    end

    if _enemyUnit ~= nil then

        ctld.facLaseUnit(_enemyUnit, _facUnit, _facUnitName, _laserCode)

        -- DEBUG
        --env.info('CTLD FAC: Timer timerSparkleLase '.._facUnitName.." ".._laserCode.." ".._enemyUnit:getName())
        --
        timer.scheduleFunction(ctld.timerFacAutoLase, { _facUnitName, _laserCode, _smoke, _lock, _colour }, timer.getTime() + 1)


        if _smoke == true then
            local _nextSmokeTime = ctld.facSmokeMarks[_enemyUnit:getName()]

            --recreate smoke marker after 5 mins
            if _nextSmokeTime ~= nil and _nextSmokeTime < timer.getTime() then

                ctld.createSmokeMarker(_enemyUnit, _colour)
            end
        end

    else
        --env.info('CTLD FAC: LASE: No Enemies Nearby')

        -- stop lazing the old spot
        ctld.cancelFacLase(_facUnitName)

        timer.scheduleFunction(ctld.timerFacAutoLase, { _facUnitName, _laserCode, _smoke, _lock, _colour }, timer.getTime() + 5)
    end
end

-- used by the timer function
function ctld.timerFacAutoLase(_args)

    ctld.facAutoLase(_args[1], _args[2], _args[3], _args[4], _args[5])
end

function ctld.cleanupFac(_facUnitName)
    -- clear laser - just in case
    ctld.cancelFacLase(_facUnitName)

    -- Cleanup
    ctld.facLaserPoints[_facUnitName] = nil
    ctld.facIRPoints[_facUnitName] = nil
    ctld.facSmokeMarks[_facUnitName] = nil
    ctld.facUnits[_facUnitName] = nil
    ctld.facCurrentTargets[_facUnitName] = nil
    ctld.facAddedTo[_facUnitName] = nil
    ctld.facRadioAdded[_facUnitName] = nil
    ctld.facLaserPointCodes[_facUnitName] = nil
    ctld.facOnStation[_facUnitName] = nil
end

function ctld.createFacSmokeMarker(_enemyUnit, _colour)

    --recreate in 5 mins
    ctld.facSmokeMarks[_enemyUnit:getName()] = timer.getTime() + 300.0

    -- move smoke 2 meters above target for ease
    local _enemyPoint = _enemyUnit:getPoint()
    trigger.action.smoke({ x = _enemyPoint.x, y = _enemyPoint.y + 2.0, z = _enemyPoint.z }, _colour)
end

function ctld.cancelFacLase(_facUnitName)

    local _tempLase = ctld.facLaserPoints[_facUnitName]

    if _tempLase ~= nil then
        Spot.destroy(_tempLase)
        ctld.facLaserPoints[_facUnitName] = nil

        _tempLase = nil
    end

    local _tempIR = ctld.facIRPoints[_facUnitName]

    if _tempIR ~= nil then
        Spot.destroy(_tempIR)
        ctld.facIRPoints[_facUnitName] = nil

        _tempIR = nil
    end
end

function ctld.facLaseUnit(_enemyUnit, _facUnit, _facUnitName, _laserCode)

    --cancelLase(_facUnitName)

    local _spots = {}

    local _enemyVector = _enemyUnit:getPoint()
    local _enemyVectorUpdated = { x = _enemyVector.x, y = _enemyVector.y + 2.0, z = _enemyVector.z }

    local _oldLase = ctld.facLaserPoints[_facUnitName]
    local _oldIR = ctld.facIRPoints[_facUnitName]

    if _oldLase == nil or _oldIR == nil then

        -- create lase

        local _status, _result = pcall(function()
            _spots['irPoint'] = Spot.createInfraRed(_facUnit, { x = 0, y = 2.0, z = 0 }, _enemyVectorUpdated)
            _spots['laserPoint'] = Spot.createLaser(_facUnit, { x = 0, y = 2.0, z = 0 }, _enemyVectorUpdated, _laserCode)
            return _spots
        end)

        if not _status then
            env.error('CTLD FAC: ERROR: ' .. _result, false)
        else
            if _result.irPoint then

                -- DEBUG
                --env.info('CTLD FAC:' .. _facUnitName .. ' placed IR Pointer on '.._enemyUnit:getName())

                ctld.facIRPoints[_facUnitName] = _result.irPoint --store so we can remove after
            end
            if _result.laserPoint then

                --  DEBUG
                --env.info('CTLD FAC:' .. _facUnitName .. ' is Lasing '.._enemyUnit:getName()..'. CODE:'.._laserCode)

                ctld.facLaserPoints[_facUnitName] = _result.laserPoint
            end
        end

    else

        -- update lase

        if _oldLase ~= nil then
            _oldLase:setPoint(_enemyVectorUpdated)
        end

        if _oldIR ~= nil then
            _oldIR:setPoint(_enemyVectorUpdated)
        end
    end
end

-- Find nearest enemy to FAC that isn't blocked by terrain
function ctld.findFacNearestVisibleEnemy(_facUnit, _targetType,_distance)

    -- DEBUG
    --local _facUnitName = _facUnit:getName()
    --env.info('CTLD FAC:' .. _facUnitName .. ' ctld.findFacNearestVisibleEnemy() ')

    local _maxDistance = _distance or ctld.FAC_maxDistance
    local _x = 1
    local _i = 1

    local _units = nil
    local _groupName = nil

    local _nearestUnit = nil
    local _nearestDistance = _maxDistance

    local _enemyGroups

    if _facUnit:getCoalition() == 1 then
        _enemyGroups = coalition.getGroups(2, Group.Category.GROUND)
    else
        _enemyGroups = coalition.getGroups(1, Group.Category.GROUND)
    end

    local _facPoint = _facUnit:getPoint()
    local _facPosition = _facUnit:getPosition()

    local _tempPoint = nil
    local _tempPosition = nil

    local _tempDist = nil

    -- finish this function
    local _vhpriority = false
    local _vpriority = false
    local _thpriority = false
    local _tpriority = false
    for _i = 1, #_enemyGroups do
        if _enemyGroups[_i] ~= nil then
            _groupName = _enemyGroups[_i]:getName()
            _units = ctld.getGroup(_groupName)
            if #_units > 0 then
                for _y = 1, #_units do
                    local _targeted = false
                    local _targetedJTAC = false
                    if not _distance then
                        _targeted = ctld.alreadyFacTarget(_facUnit, _units[_x])
                        _targetedJTAC = ctld.alreadyTarget(_facUnit, _units[_x])
                    end

                    -- calc distance
                    _tempPoint = _units[_y]:getPoint()
                    _tempDist = ctld.getDistance(_tempPoint, _facPoint)

                    if _tempDist < _maxDistance and _tempDist < _nearestDistance then

                        local _offsetEnemyPos = { x = _tempPoint.x, y = _tempPoint.y + 2.0, z = _tempPoint.z }
                        local _offsetFacPos = { x = _facPoint.x, y = _facPoint.y + 2.0, z = _facPoint.z }
                        -- calc visible

                        if land.isVisible(_offsetEnemyPos, _offsetFacPos) and _targeted == false and _targetedJTAC == false then
                            if (string.match(_units[_y]:getName(), "hpriority") ~= nil) and ctld.isVehicle(_units[_y]) then
                                _vhpriority = true
                            elseif (string.match(_units[_y]:getName(), "priority") ~= nil) and ctld.isVehicle(_units[_y]) then
                                _vpriority = true
                            elseif (string.match(_units[_y]:getName(), "hpriority") ~= nil) and ctld.isInfantry(_units[_y]) then
                                _thpriority = true
                            elseif (string.match(_units[_y]:getName(), "priority") ~= nil) and ctld.isInfantry(_units[_y]) then
                                _tpriority = true
                            end
                        end
                    end
                end
            end
        end
    end

    for _i = 1, #_enemyGroups do
        if _enemyGroups[_i] ~= nil then
            _groupName = _enemyGroups[_i]:getName()
            _units = ctld.getGroup(_groupName)
            if #_units > 0 then

                for _x = 1, #_units do

                    --check to see if a FAC has already targeted this unit only if a distance
                    --wasnt passed in
                    local _targeted = false
                    if not _distance then
                        _targeted = ctld.alreadyFacTarget(_facUnit, _units[_x])
                    end

                    local _allowedTarget = true

                    if _targetType == "vehicle" and _vhpriority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "hpriority") ~= nil) and ctld.isVehicle(_units[_x])
                    elseif _targetType == "vehicle" and _vpriority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "priority") ~= nil) and ctld.isVehicle(_units[_x])
                    elseif _targetType == "vehicle" then
                        _allowedTarget = ctld.isVehicle(_units[_x])
                    elseif _targetType == "troop" and _hpriority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "hpriority") ~= nil) and ctld.isInfantry(_units[_x])
                    elseif _targetType == "troop" and _priority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "priority") ~= nil) and ctld.isInfantry(_units[_x])
                    elseif _targetType == "troop" then
                        _allowedTarget = ctld.isInfantry(_units[_x])
                    elseif _vhpriority == true or _thpriority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "hpriority") ~= nil)
                    elseif _vpriority == true or _tpriority == true then
                        _allowedTarget = (string.match(_units[_x]:getName(), "priority") ~= nil)
                    else
                        _allowedTarget = true
                    end

                    if _units[_x]:isActive() == true and _targeted == false and _allowedTarget == true then

                        -- calc distance
                        _tempPoint = _units[_x]:getPoint()
                        _tempDist = ctld.getDistance(_tempPoint, _facPoint)

                        if _tempDist < _maxDistance and _tempDist < _nearestDistance then

                            local _offsetEnemyPos = { x = _tempPoint.x, y = _tempPoint.y + 2.0, z = _tempPoint.z }
                            local _offsetFacPos = { x = _facPoint.x, y = _facPoint.y + 2.0, z = _facPoint.z }


                            -- calc visible
                            if land.isVisible(_offsetEnemyPos, _offsetFacPos) then

                                _nearestDistance = _tempDist
                                _nearestUnit = _units[_x]
                            end
                        end
                    end
                end
            end
        end
    end

    if _nearestUnit == nil then
        return nil
    end


    return _nearestUnit
end

-- tests whether the unit is targeted by another FAC
function ctld.alreadyFacTarget(_facUnit, _enemyUnit)

    for _, _facTarget in pairs(ctld.facCurrentTargets) do

        if _facTarget.unitId == _enemyUnit:getID() then
            -- env.info("CTLD FAC: ALREADY TARGET")
            return true
        end
    end

    return false
end

-- Adds menuitem to all FAC units that are active
function ctld.addFacF10MenuOptions()
    -- Loop through all FAC units

    timer.scheduleFunction(ctld.addFacF10MenuOptions, nil, timer.getTime() + 10)

    for _, _facUnitName in pairs(ctld.facPilotNames) do

        local status, error = pcall(function()

            local _unit = ctld.getFacUnit(_facUnitName)

            if _unit ~= nil then

                local _groupId = ctld.getGroupId(_unit)

                if _groupId then

                    if ctld.facAddedTo[tostring(_groupId)] == nil then
                        local _rootPath = missionCommands.addSubMenuForGroup(_groupId, "FAC")
                        
                        missionCommands.addCommandForGroup(_groupId, "Go On-Station",  _rootPath, ctld.setFacOnStation, { _facUnitName, true})
                        missionCommands.addCommandForGroup(_groupId, "Go Off-Station", _rootPath, ctld.setFacOnStation, { _facUnitName, nil})
                        
                        -- add each possible laser code as a menu option
                        for _, _laserCode in pairs(ctld.FAC_laser_codes) do
                            missionCommands.addCommandForGroup(_groupId, string.format("Laser code: %s", _laserCode), _rootPath, ctld.setFacLaserCode, { _facUnitName, _laserCode})
                        end
                        
                        ctld.facAddedTo[tostring(_groupId)] = true
                    end
                    
                end
            --[[else
                env.info(string.format("CTLD FAC DEBUG: unit nil %s",_facUnitName)) ]]
            end
        end)

        if (not status) then
            env.error(string.format("Error adding f10 to FAC: %s", error), false)
        end
    end

    local status, error = pcall(function()

        -- now do any player controlled aircraft that ARENT FAC units
        if ctld.FAC_FACStatusF10 then
            -- get all BLUE players
            ctld.addFacRadioCommand(2)

            -- get all RED players
            ctld.addFacRadioCommand(1)
        end

    end)

    if (not status) then
        env.error(string.format("Error adding f10 to other players: %s", error), false)
    end


end

function ctld.addFacRadioCommand(_side)

    local _players = coalition.getPlayers(_side)

    if _players ~= nil then

        for _, _playerUnit in pairs(_players) do

            local _groupId = ctld.getGroupId(_playerUnit)

            if _groupId then
                --   env.info("adding command for "..index)
                if ctld.facRadioAdded[tostring(_groupId)] == nil then
                    -- env.info("about command for "..index)
                    missionCommands.addCommandForGroup(_groupId, "FAC Status", nil, ctld.getFacStatus, { _playerUnit:getName() })
                    ctld.facRadioAdded[tostring(_groupId)] = true
                    -- env.info("Added command for " .. index)
                end
            end


        end
    end
end

function ctld.setFacLaserCode(_args)
    local _facUnitName  = _args[1]
    local _laserCode = _args[2]
    local _facUnit = ctld.getFacUnit(_facUnitName)
   
    if _facUnit == nil then
        --env.info('CTLD FAC DEBUG: ctld.setFacLaserCode() _facUnit is null, aborting.')
        return
    end
    
    ctld.facLaserPointCodes[_facUnitName] = _laserCode

    if ctld.facOnStation[_facUnitName] == true then
        ctld.notifyCoalition("Forward Air Controller \"" .. ctld.getFacName(_facUnitName) .. "\" on-station using CODE: "..ctld.facLaserPointCodes[_facUnitName]..".", 10, _facUnit:getCoalition())
    end    
end

function ctld.setFacOnStation(_args)
    local _facUnitName  = _args[1]
    local _onStation = _args[2]
    local _facUnit = ctld.getFacUnit(_facUnitName)
    
    -- going on-station
    if _facUnit == nil then
        --env.info('CTLD FAC DEBUG: ctld.setFacOnStation() _facUnit is null, aborting.')
        return
    end

    if ctld.facLaserPointCodes[_facUnitName] == nil then
        -- set default laser code
        --env.info('CTLD FAC: ' .. _facUnitName .. ' no laser code, assigning default ' .. ctld.FAC_laser_codes[1])
        ctld.setFacLaserCode( {_facUnitName, ctld.FAC_laser_codes[1]} )
    end

    -- going on-station from off-station
    if ctld.facOnStation[_facUnitName] == nil and _onStation == true then
        env.info('CTLD FAC: ' .. _facUnitName .. ' going on-station')
        ctld.notifyCoalition("Forward Air Controller \"" .. ctld.getFacName(_facUnitName) .. "\" on-station using CODE: "..ctld.facLaserPointCodes[_facUnitName]..".", 10, _facUnit:getCoalition())
        ctld.setFacLaserCode( {_facUnitName, ctld.facLaserPointCodes[_facUnitName]} )
    end
    
    -- going off-station from on-station
    if ctld.facOnStation[_facUnitName] == true and _onStation == nil then
        env.info('CTLD FAC: ' .. _facUnitName .. ' going off-station')
        ctld.notifyCoalition("Forward Air Controller \"" .. ctld.getFacName(_facUnitName) .. "\" off-station.", 10, _facUnit:getCoalition())
        ctld.cancelFacLase(_facUnitName)
        ctld.facUnits[_facUnitName] = nil
    end
    
    ctld.facOnStation[_facUnitName] = _onStation
end

-- Scheduled functions (run cyclically)

timer.scheduleFunction(ctld.addFacF10MenuOptions, nil, timer.getTime() + 5)
timer.scheduleFunction(ctld.checkFacStatus, nil, timer.getTime() + 5)
