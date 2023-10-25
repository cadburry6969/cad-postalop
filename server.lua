local QBCore = exports['qb-core']:GetCoreObject()

-- FUNCTIONS

function Notify(src, msg)
	TriggerClientEvent("QBCore:Notify", src, msg)
end

-- JOB CASH

RegisterNetEvent('cad-delivery:cash', function(currentJobPay, value)
	local _source = source
	local Player = QBCore.Functions.GetPlayer(_source)
	if not Player then return end
	if value == "job" then
		Player.Functions.AddMoney("bank", currentJobPay, "postal-job")
		Notify(_source, "You recieved payslip of $" .. currentJobPay)
	elseif value == "add" then
		Player.Functions.AddMoney("cash", currentJobPay, "postal-deposit-return")
		Notify(_source, "Your $" .. currentJobPay .. " deposit was returned.")
	elseif value == "remove" and Player.PlayerData.money.cash >= currentJobPay then
		Player.Functions.RemoveMoney("cash", currentJobPay, "postal-deposit-pay")
		Notify(_source, "Your $" .. currentJobPay .. " was taken as deposit.")
	end
end)
