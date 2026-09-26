local QBCore=exports['qb-core']:GetCoreObject()
local open=false
local function show(data,admin)
  open=true; SetNuiFocus(true,true); SendNUIMessage({action=admin and 'admin' or 'open',data=data})
end
local function refresh()
  QBCore.Functions.TriggerCallback('agc-credit:getData',function(data) if data then show(data,false) end end)
end
RegisterCommand(Config.Command,function() refresh() end)
RegisterNetEvent('agc-credit:refresh',refresh)
RegisterNetEvent('agc-credit:adminView',function(data) show(data,true) end)
RegisterNUICallback('close',function(_,cb) open=false; SetNuiFocus(false,false); cb('ok') end)
RegisterNUICallback('apply',function(data,cb) TriggerServerEvent('agc-credit:apply',data.cardType); cb('ok') end)
RegisterNUICallback('pay',function(data,cb) TriggerServerEvent('agc-credit:pay',tonumber(data.accountId),tonumber(data.amount)); cb('ok') end)
