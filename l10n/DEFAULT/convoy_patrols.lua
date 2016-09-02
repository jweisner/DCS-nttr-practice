-- set patrols
mist.ground.patrol('Medium Convoy #002', 'doubleBack')

-- group dead flags
--[[
Flags:
 1001 - Easy Convoy #001 Dead
 1002 - Easy Convoy #002 Dead
 1011 - Medium Convoy #001 Dead
 1012 - Medium Convoy #002 Dead
 1021 - Tank Convoy #001 Dead
]]
mist.flagFunc.group_dead {
	groupName = 'Easy Convoy #001',
	flag = 1001,
	toggle = true,
}

mist.flagFunc.group_dead {
	groupName = 'Easy Convoy #002',
	flag = 1002,
	toggle = true,
}

mist.flagFunc.group_dead {
	groupName = 'Medium Convoy #001',
	flag = 1011,
	toggle = true,
}

mist.flagFunc.group_dead {
	groupName = 'Medium Convoy #002',
	flag = 1012,
	toggle = true,
}


mist.flagFunc.group_dead {
	groupName = 'Tank Convoy #001',
	flag = 1021,
	toggle = true,
}