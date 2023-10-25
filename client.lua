local QBCore = exports['qb-core']:GetCoreObject()

-- LOCALS
local currentJob = {}
local onJob = false
local onDelivery = false
local goPostalVehicle = nil
local currentJobPay = 0
local totalpayamount = 0
local MaxDelivery = 0
local PackageObject = nil
local missionblip = nil
local isDeliverySignedIn = false

-- CONFIG
local locations = Config.deliveryLocations
local vehicleSpawnLocations = Config.vehicleSpawnLocations

function Notify(msg)
	QBCore.Functions.Notify(msg)
end

function Givekeys(plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end

-- FUNCTIONS

function DeliveryBlipToggle()
	if onJob then
		local bCfg = Config.blip
		PostalBlip = AddBlipForCoord(bCfg.coords.x, bCfg.coords.y, bCfg.coords.z)
		SetBlipSprite(PostalBlip, bCfg.sprite)
		SetBlipScale(PostalBlip, bCfg.scale)
		SetBlipDisplay(PostalBlip, 4)
		SetBlipColour(PostalBlip, bCfg.color)
		SetBlipAsShortRange(PostalBlip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(bCfg.label)
		EndTextCommandSetBlipName(PostalBlip)
	else
		if PostalBlip and DoesBlipExist(PostalBlip) then
			RemoveBlip(PostalBlip)
		end
	end
end

function NewDeliveryShift()
	if MaxDelivery >= 0 then
		local vehcoords = GetEntityCoords(goPostalVehicle)
		local jobLocation = locations[math.random(1, #locations)]
		SetDeliveryJobBlip(jobLocation[1], jobLocation[2], jobLocation[3])
		currentJob = jobLocation
		currentJobPay = CalculateTravelDistanceBetweenPoints(vehcoords.x, vehcoords.y, vehcoords.z, currentJob[1], currentJob[2], currentJob[3]) / 2 / 4
		if currentJobPay > 60 then
			currentJobPay = math.random(1200, 1500)
		end
		Notify("Go to next delivery point.")
	else
		onJob = false
		RemoveJobBlip()
		SetNewWaypoint(-425.44, -2787.76)
		Notify("You finished deliveries, please return to warehouse.")
	end
end

function SpawnGoPostal(x, y, z, w)
	local vehicleHash = Config.vehicleModel
	RequestModel(vehicleHash)
	while not HasModelLoaded(vehicleHash) do
		Wait(0)
	end
	goPostalVehicle = CreateVehicle(vehicleHash, x, y, z, w, true, false)
	local id = NetworkGetNetworkIdFromEntity(goPostalVehicle)
	SetNetworkIdCanMigrate(id, true)
	SetNetworkIdExistsOnAllMachines(id, true)
	SetVehicleDirtLevel(goPostalVehicle, 0)
	SetVehicleHasBeenOwnedByPlayer(goPostalVehicle, true)
	SetEntityAsMissionEntity(goPostalVehicle, true, true)
	SetVehicleEngineOn(goPostalVehicle, true, true, true)
	SetVehicleColours(goPostalVehicle, 131, 74)
	exports[Config.fuel]:SetFuel(goPostalVehicle, 100.0)
	local plate = GetVehicleNumberPlateText(goPostalVehicle)
	Givekeys(plate)
end

function GetParkingPosition(spots)
	for id, v in pairs(spots) do
		if GetClosestVehicle(v.x, v.y, v.z, 3.0, 0, 70) == 0 then
			return true, v
		end
	end
	Notify("Parking Spots Full, Please Wait")
end

function SetDeliveryJobBlip(x, y, z)
	if missionblip and DoesBlipExist(missionblip) then RemoveBlip(missionblip) end
	missionblip = AddBlipForCoord(x, y, z)
	SetBlipSprite(missionblip, 164)
	SetBlipColour(missionblip, 53)
	SetNewWaypoint(x, y)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Destination")
	EndTextCommandSetBlipName(missionblip)
end

function RemoveJobBlip()
	if DoesBlipExist(missionblip) then RemoveBlip(missionblip) end
end

function LoadAnim(animDict)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Wait(10)
	end
end

function LoadModel(model)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(10)
	end
end

-- JOB WORK

CreateThread(function()
	local pedModel = GetHashKey(Config.pedModel)
	RequestModel(pedModel)
	while not HasModelLoaded(pedModel) do
		Wait(1)
	end
	local ped = CreatePed(4, pedModel, Config.pedCoords.x, Config.pedCoords.y, Config.pedCoords.z, Config.pedCoords.w, false, false)
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetPedDiesWhenInjured(ped, false)
	SetEntityHeading(ped, Config.pedCoords.w)
	SetPedCanPlayAmbientAnims(ped, true)
	SetPedCanRagdollFromPlayerImpact(ped, false)
	SetEntityInvincible(ped, true)
	FreezeEntityPosition(ped, true)
	if Config.target == 'ox' then
		exports.ox_target:addModel('s_m_m_postal_01', {
			{
				label = "Sign In",
				distance = 1.5,
				event = "cad-postalop:startwork",
				icon = "fas fa-sign-in-alt",
				canInteract = function(entity, data)
					return not isDeliverySignedIn
				end,
			},
			{
				label = "Recieve Payment & End Work",
				distance = 1.5,
				event = "cad-postalop:finishwork",
				icon = "fas fa-money-check-alt",
				canInteract = function(entity, data)
					return isDeliverySignedIn
				end,
			},
		})
		exports.ox_target:addGlobalVehicle({
			{
				label = "Take Package",
				event = "cad-postalop:takepackage",
				icon = "fas fa-box",
				distance = 2.5,
				bones = { 'boot', 'platelight' },
				canInteract = function(entity, data)
					return onJob and (GetEntityModel(entity) == Config.vehicleModel)
				end,
			}
		})
	elseif Config.target == 'qb' then
		exports['qb-target']:AddTargetModel('s_m_m_postal_01', {
			options = {
				{
					type = "client",
					event = "cad-postalop:startwork",
					icon = "fas fa-sign-in-alt",
					label = "Sign In",
					canInteract = function(entity, data)
						return not isDeliverySignedIn
					end,
				},
				{
					type = "client",
					event = "cad-postalop:finishwork",
					icon = "fas fa-money-check-alt",
					label = "Recieve Payment & End Work",
					canInteract = function(entity, data)
						return isDeliverySignedIn
					end,
				},
			},
			distance = 1.5
		})
		exports['qb-target']:AddTargetBone('boot', {
			options = {
				{
					type = "client",
					event = "cad-postalop:takepackage",
					icon = "fas fa-box",
					label = "Take Package",
					canInteract = function(entity, data)
						return onJob and (GetEntityModel(entity) == Config.vehicleModel)
					end,
				}
			},
			distance = 2.5,
		})
	end
end)

function DeliveryCheck()
CreateThread(function()
	while isDeliverySignedIn do
		local inRange = false
		local coords = GetEntityCoords(PlayerPedId())
		local distance = #(vec3(coords.x, coords.y, coords.z)- vec3(currentJob[1], currentJob[2], currentJob[3]) )
		if distance < 50 and onJob and onDelivery then
			inRange = true
			DrawMarker(2, currentJob[1], currentJob[2], currentJob[3], 0, 0, 0, 0, 0, 0, 0.3, 0.2, -0.2, 100, 100, 155, 255, true, true, 0, false, nil, nil, false)
			if distance < 1.5 and onJob and onDelivery then
				LoadAnim("creatures@rottweiler@tricks@")
				TaskPlayAnim(PlayerPedId(), "creatures@rottweiler@tricks@", "petting_franklin", 8.0, 8.0, -1, 50, 0, false, false, false)
				FreezeEntityPosition(PlayerPedId(), true)
				Wait(5000)
				DeleteObject(PackageObject)
				FreezeEntityPosition(PlayerPedId(), false)
				ClearPedTasksImmediately(PlayerPedId())
				PackageObject = nil
				onDelivery = false
				totalpayamount = totalpayamount + currentJobPay
				MaxDelivery = MaxDelivery - 1
				NewDeliveryShift()
			end
		end
		if not inRange then Wait(800) end
		Wait(4)
	end
end)
end

RegisterNetEvent('cad-postalop:startwork', function()
	if not isDeliverySignedIn and not onJob then
		if not DoesEntityExist(goPostalVehicle) then
			if QBCore.Functions.GetPlayerData().money.cash >= 1000 then
				local freespot, v = GetParkingPosition(vehicleSpawnLocations)
				if freespot then SpawnGoPostal(v.x, v.y, v.z, v.w) end
				MaxDelivery = math.random(2, 8)
				TriggerServerEvent('cad-delivery:cash', 1000, "remove")
				NewDeliveryShift()
				onJob = true
				isDeliverySignedIn = true
				DeliveryCheck()
				DeliveryBlipToggle()
			else
				Notify("No money for deposit")
			end
		end
	else
		Notify("Already doing a work, finish that first")
	end
end)

RegisterNetEvent('cad-postalop:takepackage', function()
	if not onDelivery and onJob and not IsPedInAnyVehicle(PlayerPedId()) and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), currentJob[1], currentJob[2], currentJob[3], true) < 40 then
		LoadModel("hei_prop_heist_box")
		local pos = GetEntityCoords(PlayerPedId(), false)
		PackageObject = CreateObject(GetHashKey("hei_prop_heist_box"), pos.x, pos.y, pos.z, true, true, true)
		AttachEntityToEntity(PackageObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, -0.03, 0.0, 5.0, 0.0, 0.0, true, true, false, true, 0, true)
		LoadAnim("anim@heists@box_carry@")
		TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
		onDelivery = true
	end
end)

RegisterNetEvent('cad-postalop:finishwork', function()
	if isDeliverySignedIn then
		if not onJob then
			if goPostalVehicle and DoesEntityExist(goPostalVehicle) then
				DeleteVehicle(goPostalVehicle)
				RemoveJobBlip()
				if IsVehicleDamaged(goPostalVehicle) then
					TriggerServerEvent('cad-delivery:cash', 200, "add")
				else
					TriggerServerEvent('cad-delivery:cash', 1000, "add")
				end
				isDeliverySignedIn = false
				onJob = false
				TriggerServerEvent('cad-delivery:cash', totalpayamount, "job")
				Wait(500)
				totalpayamount = 0
			else
				isDeliverySignedIn = false
				onJob = false
				Notify("You wont get anything, cause you lost the delivery vehicle.")
			end
			DeliveryBlipToggle()
		else
			Notify("You have to complete your work to recieve payment.")
		end
	else
		Notify("Sign in & work first to recieve payment.")
	end
end)