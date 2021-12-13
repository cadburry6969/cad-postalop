local QBCore = exports['qb-core']:GetCoreObject()
--===================================================
--                 JOB CASH
--===================================================
RegisterServerEvent('cad-delivery:cash')
AddEventHandler('cad-delivery:cash', function(currentJobPay, value)
	local _source = source
	local Player = QBCore.Functions.GetPlayer(_source)
	if value == "job" then
		Player.Functions.AddMoney("bank", currentJobPay)		
		TriggerClientEvent("QBCore:Notify", _source, "You recieved payslip of $"..currentJobPay)	
	elseif value == "add" then		
		Player.Functions.AddMoney("cash", currentJobPay)		
		TriggerClientEvent("QBCore:Notify", _source, "Your $"..currentJobPay.." deposit was returned.")	
	elseif value == "remove" and Player.PlayerData.money.cash >= currentJobPay then
		Player.Functions.RemoveMoney("cash", currentJobPay)		
		TriggerClientEvent("QBCore:Notify", _source, "Your $"..currentJobPay.." was taken as deposit.")	
	end
end)	