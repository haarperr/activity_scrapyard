local activityName = Config.activity_name
local activityAvailable = true

function AssignYard(_playerServerId)
	for k,yard in pairs(scrapYards) do
		local nWorkers = 0
		for k in pairs(yard.workers) do
			nWorkers = nWorkers + 1
		end
		if nWorkers < yard.maxWorkers then
			TriggerClientEvent(("%s:assignYard"):format(activityName), _playerServerId, _playerServerId, yard)
			table.insert(scrapYards[k].workers, _playerServerId)
			return
		end
	end
	-- No available yards
	local failMessage = Config.yard_assign_fail_message
	ActivityFailed(failMessage)
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

-- == Debug ==
Citizen.CreateThread(function()
	Citizen.Wait(50)
	exports["np-activities"]:activityInProgress(activityName, 1)

	AssignYard(1)
end)