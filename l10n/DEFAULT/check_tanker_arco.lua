--RESPAWN SCRIPT; MISSION START -> DO SCRIPT
local groupName = 'Blue IL-78M Tanker #001' -- Name of the group in the ME
local lowFuelThreshold = 0.08 -- RTB when less then this amount of fuel
local lowHealthThreshold = 0.75 -- RTB when less then this amount of health
barons_respawn_script.checkstate(groupName, lowFuelThreshold, lowHealthThreshold, true)
env.info("Baron's respawn group: \""..groupName.."\"")