# AGC Credit - Payment Integration

The resource now provides a reusable Cash / Debit / Credit selector.

## Recommended integration (server-side)

Call `RequestPayment` when another resource is ready to collect payment:

```lua
exports['agc-credit']:RequestPayment(source, 750, 'Vehicle purchase', function(success, reason, method, accountId)
    if not success then
        TriggerClientEvent('QBCore:Notify', source, reason or 'Payment failed', 'error')
        return
    end

    -- Deliver the item/vehicle ONLY here, after success.
    print(('Paid using %s'):format(method))
end)
```

Payment methods:
- `cash` removes QBCore cash.
- `debit` removes QBCore bank money.
- `credit` posts the purchase to the selected active AGC credit card.

Credit cards that are suspended, closed, or lack enough available credit cannot be used.

## Direct server export

For scripts that already have their own payment UI:

```lua
local ok, reason = exports['agc-credit']:ProcessPayment(source, 'credit', 250, accountId, 'Store purchase')
```

Other exports:

```lua
local cards = exports['agc-credit']:GetPlayerCards(source)
local available = exports['agc-credit']:GetAvailableCredit(source, accountId)
local ok, reason = exports['agc-credit']:ChargeCard(citizenid, accountId, 100, 'Purchase')
```

## Important
Do not deliver the purchased item before the server callback reports success. This prevents client-side payment spoofing.
