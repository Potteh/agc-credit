# fivem_admin integration hook

`/creditadmin` has been removed. `agc-credit` now exposes this **server-side** export for the existing Manage Player page:

```lua
local credit = exports['agc-credit']:GetAdminCreditData(targetSource)
```

Call it only from the existing fivem_admin server handler after the menu's ACE + Admin Duty validation.

Recommended Manage Player panel fields:
- Credit score
- Card label/type
- Masked card number
- Credit limit
- Balance
- Minimum due
- Due date
- Missed payments
- Status (active / suspended / closed)
- Close reason

The current fivem_admin resource itself is required to wire the NUI button/page into its exact current version.
