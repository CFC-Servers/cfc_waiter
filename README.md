# cfc_waiter
Tell me when!


# Usage
Very simple to use. It might be easier to show you:

```lua
globalTestVariable = "this"

local function alertAll( alertMsg )
    for k, v in pairs(player.GetAll()) do
        v:ChatPrint( alertMsg )
    end
end

local function alertOnSuccess()
    alertAll( "Waiter called onSuccess -- whatever you were waiting for completed!" )
end

local function alertOnTimeout()
    alertAll( "Waiter called onTimeout -- whatever you were waiting for didn't complete in time!" )
end

timer.Simple( 2, function()
    globalTestVariable = "that"
end )

local function waitingFor()
    local succeeded = globalTestVariable == "that"
    alertAll( "Running the waitingFor function: " .. succeeded )

    return succeeded
end

Waiter.waitFor( waitingFor, alertOnSuccess, alertOnTimeout )
```
