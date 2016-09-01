--[[
    LAS VEGAS MOTOR SPEEDWAY
    
    Authors: Jesse Weisner (Pb_Magnet)
]]

-- UAZ Racer #001
-- Line Zone #001

lvms = {}

lvms.cars = {
    "UAZ Racer #001",
    "UAZ Racer #002",
    "UAZ Racer #003",
    "UAZ Racer #004",
    "UAZ Racer #005",
}

lvms.startingLine = {
    "Line Zone #001",
    "Line Zone #002",
    "Line Zone #003",
    "Line Zone #004",
    "Line Zone #005",
}

lvms.carData = {}

-- Creates a permanent smoke marker in a zone
--
-- arguments: "zone name", "smoke colour"
--Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4, NO SMOKE = -1
--
function lvms.smokeZone(_zone, _smoke)
    local _triggerZone = trigger.misc.getZone(_zone) -- trigger to use as reference position

    local _pos2 = { x = _triggerZone.point.x, y = _triggerZone.point.z }
    local _alt = land.getHeight(_pos2)
    local _pos3 = { x = _pos2.x, y = _alt, z = _pos2.y }
    
    local _details = { point = _pos3, name = _zone, smoke = _smoke, flag = _flagNumber, radius = _triggerZone.radius}
    
    if _triggerZone == nil then
        trigger.action.outText("lvms.lua ERROR: Cant find zone called " .. _zone, 10)
        return
    end

    if _smoke ~= nil and _smoke > -1 then

        local _smokeFunction

        _smokeFunction = function(_args)
            trigger.action.smoke(_args.point, _args.smoke)
            --refresh in 5 minutes
            timer.scheduleFunction(_smokeFunction, _args, timer.getTime() + 300)
        end

        --run local function
        _smokeFunction(_details)
    end
end

function lvms.carHandler(_car)
    local _carUnit = Unit.getByName(_car)
    
    -- skip cars not added to the mission
    if _carUnit == nil then
        env.info("lvms.lua: Car not found \"".._car.."\"")
        return nil
    end
    
    _groupName = tostring(mist.DBs.unitsByName[_car]["groupName"])
    
    -- initialize new car
    if lvms.carData[_car] == nil then
        env.info("lvms.lua: Found new race car: ".._car)
        lvms.resetCarData(_car)
    end
    
    _newPlayer = _carUnit:getPlayerName()
    _oldPlayer = lvms.carData[_car]['player']
    if _car == "UAZ Racer #001" then
        env.info("lvms.lua DEBUG: _oldPlayer: "..tostring(_oldPlayer)..", _newPlayer: "..tostring(_newPlayer))
    end
    
    -- handle new player-in-car event
    if _newPlayer ~= nil and _oldPlayer == nil then
        env.info("lvms.lua DEBUG: Player \"".._newPlayer.."\" detected in car: ".._car)
        trigger.action.outText("lvms.lua DEBUG: Player detected in car: " .. _car, 10)
        lvms.carData[_car]["player"] = _newPlayer
    end

    -- handle player-exited-car event
    if _newPlayer == nil and _oldPlayer ~= nil then
        env.info("lvms.lua DEBUG: Player \"".._oldPlayer.."\" exited car: ".._car)
        mist.respawnGroup(_groupName)
        lvms.carData[_car]["player"] = nil
    end
    timer.scheduleFunction(lvms.carHandler, _car, timer.getTime() + 1)
end

function lvms.resetCarData(_car)
    lvms.carData[_car] = {}
    lvms.carData[_car]['currentLap'] = 0
    lvms.carData[_car]['currentLapStart'] = timer.getTime()
    lvms.carData[_car]['player'] = nil
    lvms.carData[_car]['lapTimes'] = {}
end
--------------------

-- start the smoke
for _, _z in pairs(lvms.startingLine) do
    lvms.smokeZone(_z, 2)
end

-- initialize the car handlers
for _, _c in pairs(lvms.cars) do
    lvms.carHandler(_c)
end

env.info("LVMS READY")