local activityName = Config.activity_name
local activityAvailable = true

function AssignYard(_playerServerId)
	local activeYards = {}
	local numYards = 0
	for k,yard in pairs(scrapYards) do
		if yard.active then
			table.insert(activeYards, yard)
			numYards = numYards + 1
		end
	end
	while numYards > 0 do
		local index = math.random(1, numYards)
		local yard = activeYards[index]
		local id = yard.id
		local nWorkers = 0
		for k in pairs(yard.workers) do
			nWorkers = nWorkers + 1
		end
		if nWorkers < yard.maxWorkers then
			TriggerClientEvent(("%s:assignYard"):format(activityName), _playerServerId, _playerServerId, yard)
			AddWorker(id, _playerServerId)
			print("added")
			return
		else
			table.remove(activeYards, index)
			numYards = numYards - 1
		end
	end
	-- No available yards
	local failMessage = Config.yard_assign_fail_message
	exports["np-activities"]:activityCompleted(activityName, _playerServerId, false, failMessage)
end

function AddWorker(_yardId, _playerServerId)
	for k,yard in pairs(scrapYards) do
		if yard.id == _yardId then
			table.insert(scrapYards[k].workers, _playerServerId)
		end
	end
end

-- Calling this will assign desired player to a scrapyard and start the job
exports('startActivity', function(_playerServerId)
	if not activityAvailable or not exports["np-activities"]:canDoActivity(activityName, _playerServerId) then return end

	exports["np-activities"]:activityInProgress(activityName, _playerServerId)

	AssignYard(_playerServerId)
end)

-- Calling this with enabled set to true will allow players to be assigned yards
-- Calling with enabled set to false will disable new players from being assigned yards. Current players can still finish their job.
exports('setActivityStatus', function(_enabled)
	activityAvailable = _enabled
end)

-- Calling this will set the yard with id _locationId to active/inactive
exports('setLocationStatus', function(_locationId, _enabled)
	for k,yard in pairs(scrapYards) do
		if yard.id == _locationId then
			scrapYards[k].active = _enabled
		end
	end
end)

RegisterNetEvent(("%s:jobEnded"):format(activityName))
AddEventHandler(("%s:jobEnded"):format(activityName), function(_playerServerId)
	for k,yard in pairs(scrapYards) do
		for j,player in pairs(yard.workers) do
			if player == _playerServerId then
				table.remove(scrapYards[k].workers, j)
				return
			end
		end
	end
end)

-- == Debug ==
if Config.debug_mode then -- Starts job automatically
	Citizen.CreateThread(function()
		Citizen.Wait(50)
		exports["np-activities"]:activityInProgress(activityName, -1)

		AssignYard(-1)
	end)
end