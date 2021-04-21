function GetRandomCarsToScrap() -- Used to determine number of junk cars in activity
	local min = Config.min_cars_to_scrap
	local max = Config.max_cars_to_scrap
    return 1
	-- return math.random(min, max)
end

function IsItemInTable(_item, _table)
	local isInTable = false
	for i in pairs(_table) do
		if _table[i] == _item then isInTable = true end
	end
	return isInTable
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

function EnsureVariableReset() -- Ensures all variables are reset, even if job is abandoned
	Citizen.CreateThread(function()
		while jobActive do Wait(3000) end
		ResetVariables()
	end)
end