-- == Main Junk Car Thread ==
function StartCarThread(_vehicle) -- Creates instance of a junk car
	Citizen.CreateThread(function()
		local blip = CreateCarBlip(_vehicle)
		local attached = false
		local carScrapped = false
		local tiresLeft,doorsLeft,engineScrapped = GetScrappableCarParts(_vehicle)
		local readyToDestroy = false
		
		-- == Task 1 - Pick up car with forklift ==
		StartTask(tasks[4], string.format(" (%s/%s)", nCompletedCars, nCompletedCars+nCarsToScrap))
		while not attached do -- Halts thread until forklift is nearby and attaches car to forklift
			while jobActive  and canStartNewCar do
				Citizen.Wait(0)
				local pickupSide = AwaitForkliftNearby(_vehicle, forklift)

				attached = AttachVehicleToFork(_vehicle, forklift, pickupSide)
				canStartNewCar = false
			end
			Citizen.Wait(2000)
		end
		currentCar = _vehicle
		RemoveBlip(blip)
		CompleteTask(tasks[4])

		-- == Task 2 - Take car to scrap zone and scrap parts ==
		scrapZoneBlip,scrapZoneRadius = CreateScrapZoneBlip(yard.scrapZone)
		StartTask(tasks[5], string.format(" (%s/%s)", nCompletedCars, nCompletedCars+nCarsToScrap))
		local scrapZoneEntered = false
		while jobActive and not IsCarScrapped(tiresLeft,doorsLeft,engineScrapped) do
			if IsVehicleInScrapZone(_vehicle) and IsPlayerInScrapZone() then -- This allows players to leave the scrap zone if they choose to
				tiresLeft,doorsLeft,engineScrapped = GetScrappableCarParts(_vehicle)
				
				canScrap = true

				if not scrapZoneEntered then
					scrapZoneEntered = true
					CompleteTask(tasks[5])
					StartTask(tasks[6], string.format(" (%s/%s)", nCompletedCars, nCompletedCars+nCarsToScrap))
				end
			else
				if canScrap then
					NotifyPlayer("The car still has parts to scrap.")
					canScrap = false
				end
			end
			Citizen.Wait(1000)
		end
		canScrap = false
		RemoveBlip(scrapZoneBlip)
		RemoveBlip(scrapZoneRadius)
		CompleteTask(tasks[6])
		
		-- == Task 3 - Take car to drop-off zone for destruction ==
		destroyZoneBlip,destroyZoneRadius = CreateDestroyZoneBlip(yard.destroyZone)
		StartTask(tasks[7], string.format(" (%s/%s)", nCompletedCars, nCompletedCars+nCarsToScrap))

		while jobActive and not readyToDestroy do
			if IsVehicleInDestroyZone(_vehicle) then
				BringVehicleToHalt(forklift, 1.0, 1.0, false) -- Stop forklift so it does not drive through car when car is dropped
				Citizen.Wait(1000)

				DetachEntity(_vehicle) -- Remove car from forklift and lower fork
				forkControlDisabled = false
				SetForkliftForkHeight(forklift, 0.08)
				SetVehicleOnGroundProperly(_vehicle)
				readyToDestroy = true

				StopBringVehicleToHalt(forklift)
			end
			Citizen.Wait(1000)
		end
		-- Car is destroyed
		RemoveBlip(destroyZoneBlip)
		RemoveBlip(destroyZoneRadius)
		DeleteJunkCar(_vehicle)
		currentCar = nil
		CompleteTask(tasks[7])
		
		-- Subtract number of cars left to scrap, create new instance if job not finished
		nCarsToScrap = nCarsToScrap - 1
		nCompletedCars = nCompletedCars + 1
		if nCarsToScrap > 0 then
			SpawnJunkCar(GetRandomCarModel())
			canStartNewCar = true
		end
	end)
end

-- == Utility ==
function GetVehicleDimensions(_vehicle)
	local min,max = GetModelDimensions(GetEntityModel(_vehicle))
	local dimensions = vector3(max.x-min.x, max.y-min.y, max.z-min.z)
	return dimensions
end

function GetModelDimensionsWithPadding(_model, _padding --[[ % as decimal (0.1 = 10% padding) ]]) -- Gets dimensions and returns them with padding
	_padding = _padding or 0
	_padding = 1 + _padding
	local min,max = GetModelDimensions(_model)
	local dimensions = vector3((max.x-min.x)*_padding, (max.y-min.y)*_padding, (max.z-min.z)*_padding)
	return dimensions
end

function GetRandomCarModel() -- Chooses a model from config/cars.lua based on spawn rate
	local models = carModels
	local pool = {}
	local poolSize = 0
	for k,car in pairs(carModels) do
		for i = 1, car.spawnRate, 1 do
			table.insert(pool, car.hash)
			poolSize = poolSize + 1
		end
	end
	local carToSpawn = pool[math.random(poolSize)]
	return carToSpawn
end

function RoomForSpawn(_model, _x, _y, _z, _heading, _padding) -- Uses a single raycast to see if there is room to spawn a car without colliding with entities
	RequestModel(_model)
	while not HasModelLoaded(_model) do -- Set timeout
		Citizen.Wait(50)
	end
	local vehicle = CreateVehicle(_model, _x, _y, _z, _heading, false, false)
	local vehicleSize = GetModelDimensionsWithPadding(_model, _padding)
	SetModelAsNoLongerNeeded(_model)
	SetEntityVisible(vehicle, false, 0)
	SetEntityCollision(vehicle, false, true)
	FreezeEntityPosition(vehicle, true)

	local startLoc = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, vehicleSize.y/2, 0.0)
	local endLoc = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -vehicleSize.y/2, 0.0)

	DrawDebugLine(startLoc.x, startLoc.y, startLoc.z, endLoc.x, endLoc.y, endLoc.z)
	local raycast = StartShapeTestCapsule(startLoc.x, startLoc.y, startLoc.z, endLoc.x, endLoc.y, endLoc.z, vehicleSize.x/2, 10, nil, 7)
	local _,hit,_,_,ent = GetShapeTestResult(raycast)

	DeleteEntity(vehicle)
	if hit == 0 then return true
	else return false end
end

function CreateCarBlip(_vehicle) -- Creates and returns a blip for a new junk car
	local blip = AddBlipForEntity(_vehicle)
	SetBlipSprite(blip, 225)
	SetBlipColour(blip, 10)
	SetBlipDisplay(blip, 2)
	BeginTextCommandSetBlipName("JunkCarBlipName")
	EndTextCommandSetBlipName(blip)
	return blip
end

function BeginScrapCooldown()
	Citizen.CreateThread(function()
		Citizen.Wait(Config.scrap_attempt_cooldown)
		attemptingScrap = false
	end)
end

-- == Forklift Interaction ==
function AwaitForkliftNearby(_vehicle, _forklift) -- Waits until forklift is within range of car and returns which side the forklift is near
	local inRange = false
	while jobActive and canStartNewCar do
		local pickupRange = 8.0 -- If needed, could use car width with padding
		local vehCrd = GetEntityCoords(_vehicle)
		local forkCrd = GetEntityCoords(_forklift)
		local dFromForklift = Vdist2(vehCrd.x, vehCrd.y, vehCrd.z, forkCrd.x, forkCrd.y, forkCrd.z)
		if dFromForklift < pickupRange then
			local leftSide = GetOffsetFromEntityInWorldCoords(_vehicle, -0.5, 0.0, 0.0)
			local rightSide = GetOffsetFromEntityInWorldCoords(_vehicle, 0.5, 0.0, 0.0)
			local leftDist = Vdist2(forkCrd.x, forkCrd.y, forkCrd.z, leftSide.x, leftSide.y, leftSide.z)
			local rightDist = Vdist2(forkCrd.x, forkCrd.y, forkCrd.z, rightSide.x, rightSide.y, rightSide.z)

			if leftDist < rightDist then
				return 1
			else
				return -1
			end
		end
		Citizen.Wait(2000)
	end
end

function AttachVehicleToFork(_vehicle, _forklift, _side) -- Attaches vehicle to forklift
	_side = _side or 1
	SetForkliftForkHeight(_forklift, 0.75)

	local vehicleSize = GetVehicleDimensions(_vehicle)
	local wheelSize = GetVehicleWheelTireColliderSize(_vehicle, 0)

	local offset = vector3(0.0, 1.35 + vehicleSize.x/2, 1.15 - wheelSize/2) -- Uses vehicle and wheel dimensions to ensure vehicle is properly alligned on fork

	SetEntityNoCollisionEntity(_forklift, _vehicle, false)

	AttachEntityToEntity(_vehicle, _forklift, nil, offset.x, offset.y, offset.z, nil, nil, 90.0 * _side, true, true, true, false, nil, true)
	DisableForkControl(_forklift) -- Keep fork at this height while car is stuck in position
	return true
end


-- == Zone Detection ==
function IsVehicleInScrapZone(_vehicle)
	local scrapZone = yard.scrapZone
	local crd = GetEntityCoords(_vehicle)
	local dist = Vdist2(scrapZone.x, scrapZone.y, scrapZone.z, crd.x, crd.y, crd.z)
	return dist <= scrapZone.radius
end

function IsVehicleInDestroyZone(_vehicle)
	local destroyZone = yard.destroyZone
	local crd = GetEntityCoords(_vehicle)
	local dist = Vdist2(destroyZone.x, destroyZone.y, destroyZone.z, crd.x, crd.y, crd.z)
	return dist <= destroyZone.radius
end

-- == Part Scrapping ==
function PerformScrap() -- Called when scrapping a car part. Returns bool which determines scrap success/fail
	TaskStartScenarioInPlace(player, "WORLD_HUMAN_WELDING", 0, true)
	Citizen.Wait(2000)
	ClearPedTasksImmediately(player)

	-- Start Quick Time Event, return true/false if success/fail
	return true
end


function ScrapDoor(_vehicle, _door)
	if not IsVehicleDoorDamaged(_vehicle, _door) then
		Citizen.CreateThread(function()
			if PerformScrap() then
				SetVehicleDoorBroken(_vehicle, _door, true)
			end
		end)
	end
end
function ScrapWindow(_vehicle, _window)
	if IsVehicleWindowIntact(_vehicle, _window) then
		Citizen.CreateThread(function()
			if PerformScrap() then
				RemoveVehicleWindow(_vehicle, _window)
			end
		end)
	end
end
function ScrapTire(_vehicle, _wheel)
	if _wheel == 2 then _wheel = 1 end -- Index mismatch from bone detection
	
	if not IsVehicleTyreBurst(_vehicle, _wheel, true) then
		Citizen.CreateThread(function()
			if PerformScrap() then
				SetVehicleTyreBurst(_vehicle, _wheel, true, 1)
			end
		end)
	end
end
function ScrapEngine(_vehicle)
	local engineHealth = GetVehicleEngineHealth(_vehicle)

	local relativeEngineHealth = (engineHealth - minEngineHealth) / (maxEngineHealth - minEngineHealth)
	-- relativeEngineHealth is how much health the engine has between its min and max values.
	-- This can be used to determine the material yield when scrapping an engine
	
	Citizen.CreateThread(function()
		if PerformScrap() then
			SetVehicleEngineHealth(_vehicle, minEngineHealth)
		end
	end)
end

function IsCarScrapped(tiresLeft,doorsLeft,engineScrapped) -- Pass result of GetScrappableCarParts
	local nTires = 0
	local nDoors = 0
	for i in pairs(tiresLeft) do nTires = nTires + 1 end
	for i in pairs(doorsLeft) do nDoors = nDoors + 1 end
	return not(nTires > 0 or nDoors > 0 or not engineScrapped)
end

function GetScrappableCarParts(_vehicle) -- Determines and returns number of tires/windows/doors left and whether engine is scrapped
	local tiresLeft = {}
	local doorsLeft = {}
	local engineScrapped = true

	-- Since indices of car windows/tires/doors are different for 2/4 door cars and cars with more than 4 wheels
	-- and bone indices mismatch from indices used to check window/door existence, only 4 door, 4 wheel cars work for now
	for _,tire in pairs({0, 1, 4, 5}) do 
		if not IsVehicleTyreBurst(_vehicle, tire, true) then
			if tire == 1 then table.insert(tiresLeft, 2) else -- This index differs from the index gotten from bones for some reason
				table.insert(tiresLeft, tire)
			end
		end
	end

	for _,door in pairs({0, 1, 2, 3, 5}) do
		if not IsVehicleDoorDamaged(_vehicle, door) then
			table.insert(doorsLeft, door)
		end
	end

	if GetVehicleEngineHealth(_vehicle) > minEngineHealth then -- engine is scrapped if it is at its lowest allowable health
		engineScrapped = false
	end

	return tiresLeft,doorsLeft,engineScrapped
end


-- == Car Wreckage ==
function ApplyVehicleDamage(_vehicle, _wreckType, _dmg, _radius, _multiplier) -- Applies deformation to cars. Works best with shorter 4 door cars.
	for i = 1, _multiplier, 1 do
		SetVehicleDamage(_vehicle, _wreckType, _dmg, _radius, true)
	end
end

function JunkifyCar(_vehicle) -- Uses randomness and values from config/cars.lua to make car looked wrecked/totalled
	local function GetRandomHealth(_min, _max) -- Used to determine engine health within allowable range
		return _min + math.random() * (_max - _min)
	end

	SetVehicleUndriveable(_vehicle, true)

	-- = Deformation =
	if math.random() < frontWreckPercent then
		ApplyVehicleDamage(_vehicle, impacts.primary.front, 200.0, 300.0, frontBackDamageMultiplier)
	else 
		ApplyVehicleDamage(_vehicle, impacts.primary.back, 200.0, 300.0, frontBackDamageMultiplier)
	end

	for k,wreckType in pairs(impacts.secondary) do
		if math.random() < secondaryWreckPercent then
			ApplyVehicleDamage(_vehicle, wreckType, 300.0, 200.0, secondaryWreckMultiplier)
			break
		end
	end

	-- = Tires =
	for tire = 0, 7, 1 do
		if Citizen.InvokeNative(0x534E36D4DB9ECC5D, _vehicle, tire) then -- DoesVehicleTyreExist
			if math.random() < tireMissingPercent then
				SetVehicleTyreBurst(_vehicle, tire, true, 1000)
			end
		end
	end

	-- = Doors =
	for door = 0, GetNumberOfVehicleDoors(_vehicle) - 1, 1 do
		if door ~= 4 then
			if math.random() < doorBrokenPercent then
				SetVehicleDoorBroken(_vehicle, door, true)
			end
		end
	end

	-- = Engine =
	SetDisableVehicleEngineFires(_vehicle, true)
	local engineHealth = GetRandomHealth(minEngineHealth+5.0, maxEngineHealth) -- Engine always has more health than min so it is always scrappable
	SetVehicleEngineHealth(_vehicle, engineHealth)
	
	-- = Tank =
	SetVehicleFuelLevel(_vehicle, 0.0) -- Remove fuel first so fuel doesn't leak and car doesn't explode
	local tankHealth = GetRandomHealth(minTankHealth, maxTankHealth)
	
	-- = Body =
	SetVehiclePetrolTankHealth(_vehicle, tankHealth)
	local bodyHealth = GetRandomHealth(minBodyHealth, maxBodyHealth)
	SetVehicleBodyHealth(_vehicle, bodyHealth)

	-- = Convertible =
	if IsVehicleAConvertible(_vehicle, false) then
		if math.random() < convertibleRoofLoweredPercent then
			LowerConvertibleRoof(_vehicle, true)
		end
	end

	-- Dirt
	SetVehicleDirtLevel(_vehicle, math.random(15)+math.random())

	-- Plate
	if math.random() < plateMissingPercent then
		SetVehicleNumberPlateText(_vehicle, "")
	end
end

function ScrapNearestVehiclePart(_vehicle) -- Determines if player is close to a scrappable car part and calls appropriate method
	attemptingScrap = true
	BeginScrapCooldown()
	local tiresLeft,doorsLeft,engineScrapped = GetScrappableCarParts(_vehicle)
	local offset = GetOffsetFromEntityInWorldCoords(player, playerScrapPointOffset)
	
	local partToScrap

	function SetScrapPartIfNearest(_part) -- Used to determine nearest part out of multiple nearby parts
		if not partToScrap or _part.distance < partToScrap.distance then
			partToScrap = _part
		end
	end

	local leftSide = GetOffsetFromEntityInWorldCoords(_vehicle, -0.5, 0.0, 0.0)
	local rightSide = GetOffsetFromEntityInWorldCoords(_vehicle, 0.5, 0.0, 0.0)
	local leftDist = Vdist2(offset.x, offset.y, offset.z, leftSide.x, leftSide.y, leftSide.z)
	local rightDist = Vdist2(offset.x, offset.y, offset.z, rightSide.x, rightSide.y, rightSide.z)

	local side
	if leftDist < rightDist then side = "left" else side = "right" end

	for _,door in pairs(vehiclePartData.doors[side]) do
		if IsItemInTable(door.index, doorsLeft) then
			local index = GetEntityBoneIndexByName(_vehicle, door.bone)
			local pos = GetWorldPositionOfEntityBone(_vehicle, index)
			local dist = Vdist2(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)
			DrawDebugLine(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)

			if dist < doorScrapRange then
				if IsVehicleWindowIntact(_vehicle, door.index) then
					SetScrapPartIfNearest({type = "window", index = door.index, distance = dist}) -- Remove window first
				else
					SetScrapPartIfNearest({type = "door", index = door.index, distance = dist})
				end
			end
		end
	end

	if IsItemInTable(vehiclePartData.doors.boot.index, doorsLeft) then -- Boot
		local door = vehiclePartData.doors.boot
		local index = GetEntityBoneIndexByName(_vehicle, door.bone)
		local pos = GetWorldPositionOfEntityBone(_vehicle, index)
		local dist = Vdist2(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)
		DrawDebugLine(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)

		if dist < bootScrapRange then
			SetScrapPartIfNearest({type = "door", index = door.index, distance = dist})
		end
	end

	for _,wheel in pairs(vehiclePartData.wheels[side]) do
		if IsItemInTable(wheel.index, tiresLeft) then
			local index = GetEntityBoneIndexByName(_vehicle, wheel.bone)
			local pos = GetWorldPositionOfEntityBone(_vehicle, index)
			local dist = Vdist2(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)
			DrawDebugLine(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)

			if dist < wheelScrapRange then
				SetScrapPartIfNearest({type = "wheel", index = wheel.index, distance = dist})
			end	
		end
	end

	if not engineScrapped or IsItemInTable(4, doorsLeft) then
		(function() -- Checks if engine can be scrapped
			local index = GetEntityBoneIndexByName(_vehicle, "engine")
			local pos = GetWorldPositionOfEntityBone(_vehicle, index)
			local dist = Vdist2(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)
			DrawDebugLine(offset.x, offset.y, pos.z, pos.x, pos.y, pos.z)

			if dist < engineScrapRange and (GetVehicleEngineHealth(_vehicle) > minEngineHealth or IsItemInTable(4, doorsLeft)) then -- Engine can only be scrapped if above min allowed health
				if IsVehicleDoorDamaged(_vehicle, 4) then
					SetScrapPartIfNearest({type = "engine", distance = dist})
				else -- Take off hood first
					SetScrapPartIfNearest({type = "door", index = 4, distance = dist})
				end
			end
		end)()
	end

	if partToScrap then
		if partToScrap.type == "window" then -- Windows must be removed before doors to ensure player gets glass
			ScrapWindow(_vehicle, partToScrap.index)
		elseif partToScrap.type == "door" then
			ScrapDoor(_vehicle, partToScrap.index)
		elseif partToScrap.type == "wheel" then
			ScrapTire(_vehicle, partToScrap.index)
		elseif partToScrap.type == "engine" then
			ScrapEngine(_vehicle)
		end
	else
		NotifyPlayer("You are not close enough to any parts.")
	end
end

-- == Vehicle Spawning/Deletion ==
function SpawnVehicle(_model, _x, _y, _z, _heading, _network, _mission, _onlyPlayerAccess) -- Used to spawn cars/forklifts. Returns vehicle index
	_onlyPlayerAccess = _onlyPlayerAccess or false

	RequestModel(_model)
	while not HasModelLoaded(_model) do -- Set timeout
		Citizen.Wait(500)
	end
	local vehicle = CreateVehicle(_model, _x, _y, _z, _heading, _network, _mission)
	SetEntityVisible(vehicle, false, 0)
	SetModelAsNoLongerNeeded(_model)
	SetVehicleDoorsLockedForAllPlayers(vehicle, _onlyPlayerAccess)
	SetVehicleDoorsLockedForPlayer(vehicle, playerId, false)
	SetEntityInvincible(vehicle, true)
	Citizen.Wait(500)
	NetworkFadeInEntity(vehicle, 5)
	return vehicle
end

function SpawnJunkCar(_model) -- Used to spawn a car at one of the yard's spawn points and apply cosmetic damage / remove parts
	local spawned = false
	local spawns = {}
	local nSpawns = 0
	for k in pairs(yard.carSpawns) do
		table.insert(spawns, yard.carSpawns[k])
		nSpawns = nSpawns + 1
	end
	while not spawned and nSpawns > 0 do
		local index = math.random(1, nSpawns)
		local spawn = spawns[index]
		if RoomForSpawn(_model, spawn.x, spawn.y, spawn.z, spawn.heading, .2) then -- change
			local vehicle = SpawnVehicle(_model, spawn.x, spawn.y, spawn.z, spawn.heading, true, false, false)
			JunkifyCar(vehicle)
			StartCarThread(vehicle)
			spawned = true
		end
		table.remove(spawns, index)
		Citizen.Wait(0)
	end
	if not spawned then
		-- No room around scrapyard
		local failMessage = Config.car_spawn_fail_message
		ActivityFailed(failMessage)
	end
end

function DeleteJunkCar(_vehicle) -- Fades car into deletion
	Citizen.CreateThread(function()
		NetworkFadeOutEntity(_vehicle, false, true)
		Citizen.Wait(3000)
		DeleteEntity(_vehicle)
	end)
end

-- == Debug ==
function DrawDebugLine(x1, y1, z1, x2, y2, z2) -- Draws a line between two points for 5 seconds
	if Config.debug_mode then
		local over = false
		Citizen.CreateThread(function()
			while not over do
				DrawLine(x1, y1, z1, x2, y2, z2, 255, 0, 0, 255)
				Citizen.Wait(0)
			end
		end)
		Citizen.CreateThread(function()
			for i = 1, 4, 1 do
				Citizen.Wait(1000)
			end
			over = true
		end)
	end
end