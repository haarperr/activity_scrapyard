function SpawnForklift() -- Spawns forklift at one of the yard's forklift spawnpoints
	for k,spawn in pairs(yard.liftSpawns) do
		if RoomForSpawn("FORKLIFT", spawn.x, spawn.y, spawn.z, spawn.heading, .1) then
			vehicle = SpawnVehicle("FORKLIFT", spawn.x, spawn.y, spawn.z, spawn.heading, true, false, true)
			SetForkliftForkHeight(vehicle, 0.08)

			return vehicle
		end
	end
	local failMessage = Config.forklift_spawn_fail_message
	exports["np-activities"]:activityCompleted(activityName, _playerServerId, false, failMessage)
	return nil
end

function DeleteForklift(_forklift) -- Fades forklift into deletion
	RemoveBlip(forkliftReturnBlip)
	NetworkFadeOutEntity(_forklift, false, true)
	Citizen.Wait(1000)
	DeleteEntity(_forklift)
end

function AwaitSeatForklift() -- Halts main job thread untl player is in forklift
	while jobActive and GetVehiclePedIsIn(player) ~= forklift do
		Citizen.Wait(1000)
	end
end


function IsForkliftInReturnZone(_forklift)
	local returnZone = yard.forkliftReturnZone

	local crd = GetEntityCoords(_forklift)
	local dist = Vdist2(returnZone.x, returnZone.y, returnZone.z, crd.x, crd.y, crd.z)

	return dist < returnZone.radius
end

function CreateForkliftBlip(_forklift) -- Creates and returns forklift blip
	local blip = AddBlipForEntity(_forklift)
	SetBlipSprite(blip, 147)
	SetBlipColour(blip, 5)
	SetBlipDisplay(blip, 2)
	BeginTextCommandSetBlipName("ForkliftBlipName")
	EndTextCommandSetBlipName(blip)
	return blip
end

function CreateForkliftReturnBlip(_zone) -- Creates and returns forklift return point blip
	local blip = AddBlipForCoord(_zone.x, _zone.y, _zone.z)
	SetBlipSprite(blip, 357)
	SetBlipColour(blip, 5)
	SetBlipDisplay(blip, 2)
	BeginTextCommandSetBlipName("ForkliftBlipName")
	EndTextCommandSetBlipName(blip)
	return blip
end

function DisableForkControl(_forklift) -- "Disables" forlift control while car is attached
	Citizen.CreateThread(function()
		forkControlDisabled = true
		while jobActive and forkControlDisabled do
			SetForkliftForkHeight(_forklift, 0.75)
			Citizen.Wait(0)
		end
	end)
end

function AwaitForkliftRequested()
	while not forkliftRequested do
		Wait(1000)
	end
	forkliftRequested = false
end

function AwaitForkliftReturned()
	while forklift do
		if IsForkliftInReturnZone(forklift) and AreAnyVehicleSeatsFree(forklift) then
			DeleteForklift(forklift)

			CompleteTask(tasks[8])
			forklift = nil
		end
		Citizen.Wait(2000)
	end
end