local QBCore = exports['qb-core']:GetCoreObject()
--===================================================
--                 LOCALS
--===================================================
local currentJob = {}
local onJob = false 
local onDelivery = false
local goPostalVehicle = nil
local currentJobPay = 0
local totalpayamount = 0
local MaxDelivery = 0
local PackageObject = nil
local missionblip = nil
local blip = nil 
--===================================================
--                 CONFIG
--===================================================
local locations = {
	["LosSantos"] = {
		['Max'] = 20,
		[1] = {441.12, -981.12, 30.68},
		[2] = {306.72, -594.88, 43.28},
		[3] = {-37.2, -1110.36, 26.44},
		[4] = {-267.08, -955.64, 31.24},
		[5] = {-1200.36, -891.12, 14.0},
		[6] = {-705.72, -906.68, 19.2}, 
		[7] = {26.04, -1339.24, 29.48},
		[8] = {-41.52, -1752.52, 29.44},
		[9] = {-534.64, -165.96, 38.32},
		[10] = {-633.08, 233.88, 81.88},
		[11] = {246.92, 222.2, 106.28}, 
		[12] = {375.64, 333.72, 103.56},
		[13] = {314.48, -278.6, 54.16},
		[14] = {149.44, -1040.0, 29.36},
		[15] = {-1081.96, -248.24, 37.76},
		[16] = {-350.76, -48.84, 49.04}, 
		[17] = {-1484.2, -380.24, 40.16},
		[18] = {2550.24, 382.0, 108.64},
		[19] = {-1816.56, -1193.48, 14.32},
		[20] = {-2966.64, 388.0, 15.04},		
	}
}

local restockLocations = {
 [1] = {134.73, 95.14, 82.50},
 [2] = {134.11, 93.91, 82.50},
 [3] = {135.34, 93.52, 82.50},
 [4] = {135.85, 94.76, 82.50},
 [5] = {133.03, 95.79, 82.50},
 [6] = {132.37, 94.46, 82.50},
 [7] = {131.16, 96.46, 82.50},
 [8] = {130.67, 95.30, 82.50}
}

local vehicleSpawnLocations = {
 {x = -446.24,  y = -2789.72,  z = 5.96, h = 46.04},
 {x = -451.24,  y = -2793.8,  z = 5.96, h = 47.51},
 {x = -455.8,  y = -2798.48,  z = 5.96, h = 44.91}
}
--===================================================
--                 FUNCTIONS
--===================================================
function CreateBlip()
	PostalBlip = AddBlipForCoord(-425.44, -2787.76, 6.0)
	SetBlipSprite(PostalBlip, 478)
	SetBlipScale(PostalBlip, 0.6)
	SetBlipDisplay(PostalBlip, 4)
	SetBlipColour(PostalBlip, 10)
	SetBlipAsShortRange(PostalBlip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Postal OP')
	EndTextCommandSetBlipName(PostalBlip)
end

function newShift()	
	if MaxDelivery >= 0 then		
		local jobLocation = locations['LosSantos'][math.random(1, locations['LosSantos']['Max'])] 
		SetJobBlip(jobLocation[1],jobLocation[2],jobLocation[3])
		currentJob = jobLocation
		currentJobPay = CalculateTravelDistanceBetweenPoints(GetEntityCoords(goPostalVehicle), currentJob[1],currentJob[2],currentJob[3])/2/4
		if currentJobPay > 60 then 
			currentJobPay = math.random(180, 210)
		end
	else
		onJob = false				
		RemoveJobBlip()
		SetNewWaypoint(-425.44, -2787.76, 6.0)
		QBCore.Functions.Notify("You finished deliveries, please return to warehouse.")
	end
end

function SpawnGoPostal(x,y,z,h)
	local vehicleHash = GetHashKey('benson')
	RequestModel(vehicleHash)
	while not HasModelLoaded(vehicleHash) do
		Citizen.Wait(0)
	end
	goPostalVehicle = CreateVehicle(vehicleHash, x, y, z, h, true, false)
	local id = NetworkGetNetworkIdFromEntity(goPostalVehicle)
	SetNetworkIdCanMigrate(id, true)
	SetNetworkIdExistsOnAllMachines(id, true)
	SetVehicleDirtLevel(goPostalVehicle, 0) 
	SetVehicleHasBeenOwnedByPlayer(goPostalVehicle, true)
	SetEntityAsMissionEntity(goPostalVehicle, true, true)
	SetVehicleEngineOn(goPostalVehicle, true)
	SetVehicleColours(goPostalVehicle, 131, 74)
	exports['LegacyFuel']:SetFuel(goPostalVehicle, 100.0)
	local plate = GetVehicleNumberPlateText(goPostalVehicle)	
	TriggerEvent("vehiclekeys:client:SetOwner", plate)  	
end

function getParkingPosition(spots)
  for id,v in pairs(spots) do 
    if GetClosestVehicle(v.x, v.y, v.z, 3.0, 0, 70) == 0 then  
      return true, v
    end
  end 
  QBCore.Functions.Notify("Parking Spots Full, Please Wait")		  
end

function SetJobBlip(x,y,z)
  if DoesBlipExist(missionblip) then RemoveBlip(missionblip) end
  missionblip = AddBlipForCoord(x,y,z)
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
    Citizen.Wait(10)
  end
end

function LoadModel(model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    Citizen.Wait(10)
  end
end

function ShowHelp(msg)
    BeginTextCommandDisplayHelp('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandDisplayHelp(0, false, true, -1)
end

--===================================================
--                 JOB WORK
--===================================================
local isSignedIn = false
Citizen.CreateThread(function()
	CreateBlip()
	while true do		
		local inRange = false				
		if isSignedIn then			
			if (GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), -425.44, -2787.76, 6.0, true) < 1.5) then				
				inRange = true
				ShowHelp("Press ~INPUT_PICKUP~ Recieve payslip and finish work")
				if IsControlJustPressed(0, 38) then 
					if DoesEntityExist(goPostalVehicle) then 																												
						DeleteVehicle(goPostalVehicle)
						RemoveJobBlip()							
						if IsVehicleDamaged(goPostalVehicle) then
							TriggerServerEvent('cad-delivery:cash', 200, "add")
						else
							TriggerServerEvent('cad-delivery:cash', 1000, "add")
						end	  							
						isSignedIn = false	
						onJob = false	
						TriggerServerEvent('cad-delivery:cash', totalpayamount, "job")	
						Wait(500)
						totalpayamount = 0
					else
						isSignedIn = false	
						onJob = false	
						QBCore.Functions.Notify("You wont get anything, cause you lost the delivery vehicle.")																					
					end														
				end				
			end

			if (GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), currentJob[1], currentJob[2], currentJob[3], true) < 50) and onJob and onDelivery then				
				inRange = true
				DrawMarker(2, currentJob[1], currentJob[2], currentJob[3], 0, 0, 0, 0, 0, 0, 0.3, 0.2, -0.2, 100, 100, 155, 255, true, true, 0,0)				
				if (GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), currentJob[1], currentJob[2], currentJob[3], true) < 2.0) and onJob and onDelivery then																			
					LoadAnim("creatures@rottweiler@tricks@")
					TaskPlayAnim(PlayerPedId(), "creatures@rottweiler@tricks@", "petting_franklin", 8.0, 8.0, -1, 50, 0, false, false, false)					
					Citizen.Wait(3000)
					DeleteObject(PackageObject)
					ClearPedTasksImmediately(PlayerPedId())
					PackageObject = nil 
					onDelivery = false
					totalpayamount = totalpayamount + currentJobPay							  
					MaxDelivery = MaxDelivery - 1						
					newShift()					
				end
			end
			if not onDelivery and onJob and not IsPedInAnyVehicle(PlayerPedId()) and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), currentJob[1], currentJob[2], currentJob[3], true) < 40 then     
				local backside = GetEntityBoneIndexByName(goPostalVehicle, 'boot')
				local vehiclecoords = GetWorldPositionOfEntityBone(goPostalVehicle, backside)
				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), vehiclecoords.x, vehiclecoords.y, vehiclecoords.z, true) < 2.5 and PackageObject == nil then      
					inRange = true
					ShowHelp("Press ~INPUT_PICKUP~ Take Package")
					if IsControlJustPressed(0, 38) then
						LoadModel("prop_cs_cardbox_01")
						local pos = GetEntityCoords(PlayerPedId(), false)
						PackageObject = CreateObject(GetHashKey("prop_cs_cardbox_01"), pos.x, pos.y, pos.z, true, true, true)
						AttachEntityToEntity(PackageObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), 0.0, -0.03, 0.0, 5.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
						LoadAnim("anim@heists@box_carry@")
						TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
						onDelivery = true
					end
				end 				
			end			
		elseif not isSignedIn then			
			if(GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), -425.44, -2787.76, 6.0, true) < 1.5) and not onJob then
				if not DoesEntityExist(goPostalVehicle) then 
					inRange = true
					ShowHelp("Press ~INPUT_PICKUP~ Start Work")
					if IsControlJustPressed(0, 38) then 
						if QBCore.Functions.GetPlayerData().money.cash >= 1000 then
							local freespot, v = getParkingPosition(vehicleSpawnLocations)
							if freespot then SpawnGoPostal(v.x, v.y, v.z, v.h) end	
							MaxDelivery = math.random(1, 6)
							TriggerServerEvent('cad-delivery:cash', 1000, "remove")	  
							newShift()						
							onJob = true
							isSignedIn = true	
						else
							QBCore.Functions.Notify("No money for deposit")
						end					
					end
				end
			end					
		end		
		if not inRange then
			Citizen.Wait(1000)
		end
		Citizen.Wait(5)
	end
end)

Citizen.CreateThread(function()	
	RequestModel(GetHashKey("s_m_m_postal_01"))
	while not HasModelLoaded(GetHashKey("s_m_m_postal_01")) do
		Wait(1)
	end
	ped =  CreatePed(4, GetHashKey("s_m_m_postal_01"), -425.44, -2787.76, 5.0, 326.65, false, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetPedDiesWhenInjured(ped, false)
	SetEntityHeading(ped, 326.65)
	SetPedCanPlayAmbientAnims(ped, true)
	SetPedCanRagdollFromPlayerImpact(ped, false)
	SetEntityInvincible(ped, true)
	FreezeEntityPosition(ped, true)	
end)

--===================================================
--                 END
--===================================================s
