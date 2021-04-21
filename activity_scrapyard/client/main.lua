activityName = Config.activity_name
tasks = Config.tasks

-- == Player IDs ==
player = PlayerPedId()
playerId = PlayerId()
playerServerId = nil

-- == Job Variables ==
jobActive = false
currentTask = nil

yard = nil
forklift = nil
foreman = nil
nCarsToScrap = Config.default_cars_to_scrap
nCompletedCars = 0
canStartNewCar = true
canScrap = false
forkControlDisabled = false
foreman = nil
forkliftRequested = false

-- == Car Variables == 
currentCar = nil

-- == Blips ==
yardBlip = nil
scrapZoneBlip = nil
scrapZoneRadius = nil
destroyZoneBlip = nil
destroyZoneRadius = nil
forkliftReturnBlip = nil
AddTextEntry("ForkliftBlipName", "Forklift")
AddTextEntry("ForkliftReturnBlipName", "Forklift")
AddTextEntry("JunkCarBlipName", "Junk Car")
AddTextEntry("DestroyZoneBlipName", "Car Drop-off")
AddTextEntry("ScrapZoneBlipName", "Car Scrap Area")

function AwaitYardArrival()
	local destination = yard.pos
	yardBlip = CreateYardBlip(destination.x, destination.y, destination.z)
	local arrived = false
	while jobActive and not arrived do
		Citizen.Wait(2000)
		local playerPos = GetEntityCoords(player)
		local distance = Vdist2(playerPos, yard.pos)

		arrived = distance < yard.activeRange
	end
end

function SpawnForeman()
	local model = yard.foreman.model or Config.dafault_foreman_model
	local pos = vector3(yard.foreman.x, yard.foreman.y, yard.foreman.z)
	local heading = yard.foreman.heading
	Citizen.CreateThread(function()
		local hash = GetHashKey(model)
		RequestModel(hash)
		while not HasModelLoaded(hash) do
		   Wait(500)
		end
		local foreman = CreatePed(0, hash, pos.x, pos.y, pos.z-1, heading, false, true)
		FreezeEntityPosition(foreman, true)
		SetEntityInvincible(foreman, true)
		SetBlockingOfNonTemporaryEvents(foreman, true)
		TaskStartScenarioInPlace(foreman, "WORLD_HUMAN_CLIPBOARD", 0, true)
	end)
end

function GetRandomCarsToScrap()
	local min = Config.min_cars_to_scrap
	local max = Config.max_cars_to_scrap
	return math.random(min, max)
end

function IsItemInTable(_item, _table)
	local isInTable = false
	for i in pairs(_table) do
		if _table[i] == _item then isInTable = true end
	end
	return isInTable
end

function CreateYardBlip(_x, _y, _z)
	local blip = AddBlipForCoord(_x, _y, _z)
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 15)
	SetBlipRoute(blip, true)
	return blip
end

function CreateScrapZoneBlip(_zone)
	local radius = AddBlipForRadius(_zone.x, _zone.y, _zone.z, _zone.radius/8)
	SetBlipAlpha(radius, 64)
	SetBlipDisplay(radius, 2)

	local blip = AddBlipForCoord(_zone.x, _zone.y, _zone.z)
	SetBlipSprite(blip, 402)
	BeginTextCommandSetBlipName("ScrapZoneBlipName")
	EndTextCommandSetBlipName(blip)

	return blip,radius
end

function CreateDestroyZoneBlip(_zone)
	local radius = AddBlipForRadius(_zone.x, _zone.y, _zone.z, _zone.radius/8)
	SetBlipAlpha(radius, 64)
	SetBlipDisplay(radius, 2)

	local blip = AddBlipForCoord(_zone.x, _zone.y, _zone.z)
	SetBlipSprite(blip, 380)
	BeginTextCommandSetBlipName("DestroyZoneBlipName")
	EndTextCommandSetBlipName(blip)

	return blip,radius
end

-- == NoPixel Exports ==
function StartTask(_task, _modifier)
	_modifier = _modifier or ""
	if exports["np-activities"]:canDoTask(activityName, playerServerId, _task.name) then
		exports["np-activities"]:taskInProgress(activityName, playerServerId, _task.name, _task.description.._modifier)
		currentTask = _task.name
	end
end

function CompleteTask(_task)
	exports["np-activities"]:taskCompleted(activityName, playerServerId, _task.name, true, "")
end

function ActivityFailed(_reason)
	jobActive = false
	exports["np-activities"]:activityCompleted(activityName, playerServerId, false, _reason)
end

function NotifyPlayer(_message)
	exports["np-activities"]:notifyPlayer(playerServerId, _message)
end

function IsPlayerInScrapZone()
	local scrapZone = yard.scrapZone
	local crd = GetEntityCoords(player)
	local dist = Vdist2(scrapZone.x, scrapZone.y, scrapZone.z, crd.x, crd.y, crd.z)
	return dist <= scrapZone.radius
end

function IsPlayerNearForeman()
	local pCrd = GetEntityCoords(player)
	local fCrd = vector3(yard.foreman.x, yard.foreman.y, yard.foreman.z)
	local dist = Vdist2(pCrd.x, pCrd.y, pCrd.z, fCrd.x, fCrd.y, fCrd.z)
	return dist <= 20.0
end

-- == Main Job Thread ==
function StartScrapJob(_yard)
	Citizen.CreateThread(function() 
		yard = _yard
		jobActive = true
		EnsureVariableReset()

		-- == Task 1 - Go to scrapyard ==
		StartTask(tasks[1])
		
		AwaitYardArrival()
		
		SpawnForeman()
		
		CompleteTask(tasks[1])
		RemoveBlip(yardBlip)

		-- == Task 2 - Ask foreman for forklift ==
		StartTask(tasks[2])
		
		AwaitForkliftRequested() -- Halt thread until forklift requested
		
		CompleteTask(tasks[2])

		-- == Task 3 - Get in forklift ==
		forklift = SpawnForklift()
		forkliftBlip = CreateForkliftBlip(forklift)

		StartTask(tasks[3])
		
		AwaitSeatForklift() -- Halt thread until player seated
		
		RemoveBlip(forkliftBlip)
		CompleteTask(tasks[3])

		nCarsToScrap = GetRandomCarsToScrap()
		SpawnJunkCar(GetRandomCarModel()) -- Spawn the first junk car

		-- == Task 4-7: Scrap all cars ==
		local jobCompleted = false
		while not jobCompleted do
			jobCompleted = nCarsToScrap <= 0
			Citizen.Wait(2000)
		end

		-- == Task 5: Return forklift ==
		forkliftReturnBlip = CreateForkliftReturnBlip(yard.forkliftReturnZone)
		StartTask(tasks[8])

		AwaitForkliftReturned() -- Halt thread until forklift returned and player unseated
		
		CompleteTask(tasks[8])

		-- == Job is completed ==
		CompleteScrapJob()
	end)
end

function CompleteScrapJob()
	jobActive = false
	exports["np-activities"]:activityCompleted(activityName, playerServerId, true, "")
end

function AbandonJob()
	jobActive = false
	exports["np-activities"]:activityCompleted(activityName, playerServerId, false, Config.activity_abandonded_message)
end

function ResetVariables()
	yard = nil

	currentTask = nil

	forklift = nil
	forkControlDisabled = false
	SetEntityAsNoLongerNeeded(foreman)
	foreman = nil
	forkliftRequested = false

	nCarsToScrap = Config.default_cars_to_scrap
	nCompletedCars = 0
	canStartNewCar = true
	canScrap = false
	attemptingScrap = false
	currentCar = nil
end

function EnsureVariableReset()
	Citizen.CreateThread(function()
		while jobActive do Wait(3000) end
		ResetVariables()
	end)
end

-- == Debug ==
function CheckScrapInput() -- Using while debugging
	Citizen.CreateThread(function()
		while true do
			if IsControlJustPressed(0, 46) then
				if currentTask == tasks[2].name and IsPlayerNearForeman() then
					forkliftRequested = true
				elseif currentCar and canScrap then
					if not attemptingScrap then
						ScrapNearestVehiclePart(currentCar)
					else
						NotifyPlayer("Please wait before attempting to scrap again.")
					end
				end
			end
			Citizen.Wait(0)
		end
	end)
end

Citizen.CreateThread(function()
	CheckScrapInput()
end)


-- == Events ==
RegisterNetEvent(("%s:assignYard"):format(activityName))
AddEventHandler(("%s:assignYard"):format(activityName), function(_playerServerId, _yard)
	playerServerId = _playerServerId
	StartScrapJob(_yard)
end)

RegisterNetEvent(("%s:requestForklift"):format(activityName))
AddEventHandler(("%s:requestForklift"):format(activityName), function() -- Can be called after third eye select on foreman
	forkliftRequested = true
end)

RegisterNetEvent(("%s:abandonJob"):format(activityName))
AddEventHandler(("%s:abandonJob"):format(activityName), function()
	AbandonJob()
end)