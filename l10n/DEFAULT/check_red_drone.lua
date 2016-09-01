--RESPAWN SCRIPT; MISSION START -> DO SCRIPT
local lowFuelThreshold = 0.08 -- RTB when less then this amount of fuel
local lowHealthThreshold = 0.75 -- RTB when less then this amount of health

local group1Name = 'Red Drone #001' -- Name of the group in the ME
barons_respawn_script.checkstate(group1Name, lowFuelThreshold, lowHealthThreshold, true)
env.info("Baron's respawn group: \""..group1Name.."\"")

local group2Name = 'Red Drone #002' -- Name of the group in the ME
barons_respawn_script.checkstate(group2Name, lowFuelThreshold, lowHealthThreshold, true)
env.info("Baron's respawn group: \""..group2Name.."\"")

local group3Name = 'Red Drone #003' -- Name of the group in the ME
barons_respawn_script.checkstate(group3Name, lowFuelThreshold, lowHealthThreshold, true)
env.info("Baron's respawn group: \""..group3Name.."\"")

local group4Name = 'Red Drone #004' -- Name of the group in the ME
barons_respawn_script.checkstate(group4Name, lowFuelThreshold, lowHealthThreshold, true)
env.info("Baron's respawn group: \""..group4Name.."\"")