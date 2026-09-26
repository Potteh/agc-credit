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


RegisterNetEvent('agc-credit:openPaymentSelector', function(requestId, amount, description)
  QBCore.Functions.TriggerCallback('agc-credit:getPaymentOptions', function(options)
    if not options then return end
    open=true; SetNuiFocus(true,true)
    SendNUIMessage({action='payment',requestId=requestId,amount=amount,description=description,options=options})
  end, amount)
end)
RegisterNetEvent('agc-credit:paymentResult', function(requestId, success, reason)
  open=false
  SetNuiFocus(false,false)
  SendNUIMessage({action='paymentClosed',requestId=requestId})
  if not success and reason and reason ~= 'Payment cancelled.' then QBCore.Functions.Notify(reason,'error') end
end)
RegisterNUICallback('choosePayment',function(data,cb)
  open=false; SetNuiFocus(false,false)
  TriggerServerEvent('agc-credit:paymentChoice',data.requestId,data.method,tonumber(data.accountId))
  cb('ok')
end)
RegisterNUICallback('cancelPayment',function(data,cb)
  open=false; SetNuiFocus(false,false)
  TriggerServerEvent('agc-credit:paymentChoice',data.requestId,'cancel',nil)
  cb('ok')
end)
