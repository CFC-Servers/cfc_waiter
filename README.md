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

local function waitingFor()
    local succeeded = globalTestVariable == "that"
    alertAll( "Running the waitingFor function: " .. succeeded )

    return succeeded
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

Waiter.waitFor( waitingFor, alertOnSuccess, alertOnTimeout )
```

This code will output:
```
Running the waitingFor function: false
Running the waitingFor function: false
Running the waitingFor function: true
AddonWaiter called onSuccess -- whatever you were waiting for completed!
```

CFC uses this to ensure that addon X is loaded before we begin running addon Y, but you could use this for any number of things.


# Technical Details

Waiter keeps a queue of all registered patrons and loops through them sequentially. Because we can't predict how long this will take, Waiter can't guarantee that your `waitFor` function will be run at any specific interval.

There is a minimum of a 1 second delay between loops over the queue, but the delay is actually calculated as `( minDelayTime - loopTime )` where `minDelayTime` is 1 and `loopTime` is how long (in seconds) it took for the loop to run ( with a minimum delay of 0s ).

Put simply, if the processing loop took 0.25 seconds to run, Waiter would only wait 0.75 seconds until it loops through the queue again.

You can keep an eye on how long it's taking Waiter to get through the queue by looking at the `Waiter.lastLoopDuration` variable, which will return how long the last processing loop took, in seconds.
This can help give you an idea of how frequently your `waitFor` function will be run.

Each patron is given 10 attempts before its `onTimeout` function is called, and it is purged from the queue.
