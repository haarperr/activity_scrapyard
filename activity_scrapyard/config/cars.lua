-- == Junkify car settings ==
-- Deformation
impacts = {
	primary = {
		front = vector3(0.0, 2.2, 0.1),
		back = vector3(0.0, -1.0, 0.0),
	},
	secondary = {
		frontleft = vector3(-0.5, 0.7, 0.1),
		frontright = vector3(0.3, 0.5, 0.1),
		backleft = vector3(-0.5, -0.7, 0.1),
		backright = vector3(0.3, -0.5, 0.1),
	}
}

frontWreckPercent = 0.6
frontBackDamageMultiplier = 5
secondaryWreckPercent = 0.7
secondaryWreckMultiplier = 3

-- Tires
tireMissingPercent = .5

-- Doors
doorBrokenPercent = .6

-- Health
minEngineHealth = 400.0 -- Keep above 400 so vehicle doesn't smoke
maxEngineHealth = 700.0	-- 1000 is max

minTankHealth = 0.0
maxTankHealth = 1000.0

minBodyHealth = 0.0
maxBodyHealth = 1000.0

-- Misc
convertibleRoofLoweredPercent = 0.6
plateMissingPercent = 0.8


-- == Vehicle Scrapping ==
vehiclePartData = {
	doors = {
		left = {
			{ bone = "door_dside_f", index = 0 },
			{ bone = "door_dside_r", index = 2 },
		},
		right = {
			{ bone = "door_pside_f", index = 1 },
			{ bone = "door_pside_r", index = 3 },
		},
		boot = { bone = "boot", index = 5 }
	},
	wheels = {
		left = {
			{ bone = "wheel_lf", index = 0 },
			{ bone = "wheel_lr", index = 4 },
		},
		right = {
			{ bone = "wheel_rf", index = 2 },
			{ bone = "wheel_rr", index = 5 },
		},
	},
}

wheelScrapRange = 1.0
doorScrapRange = 1.0
bootScrapRange = 2.65
engineScrapRange = 1.0

playerScrapPointOffset = vector3(0.0, 0.35, 0.0)

-- == Junk car models/spawn rates == 
carModels = {
	{hash = "EMPEROR2", spawnRate = 7},
	{hash = "ASEA", spawnRate = 5},
	{hash = "FELON", spawnRate = 4},
	{hash = "EMPEROR", spawnRate = 3},
}