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

-- Used after player input to determine appropriate response
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