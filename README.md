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

## WaiterQueue
"But guys!" you exclaim, "What happens if my addon loads before AddonWaiter? Won't I just have to duplicate some of your code to even use it in the first place?"

Ah, never fear! We've included an easy way to handle this situation.

`WaiterQueue` is just a global table that anyone can append their patrons (jobs) to.
When Waiter loads, it loads and begins processing all valid jobs in the `WaiterQueue`.

Here's an example:

```lua
--lua/autorun/server/m9k_stubber.lua
local waiterLoaded = Waiter

if waiterLoaded then
    print("[M9k Stubber] Waiter is loaded, registering with it!")
    Waiter.waitFor( m9kIsLoaded, runStubs, handleWaiterTimeout )
else
    print("[M9k Stubber] Waiter is not loaded! Inserting our struct into the queue!")
    WaiterQueue = WaiterQueue or {}

    local struct = {}
    struct["waitingFor"] = m9kIsLoaded
    struct["onSuccess"] = runStubs
    struct["onTimeout"] = handleWaiterTimeout

    table.insert( WaiterQueue, struct )
end
```
As you can see, you first check if the `Waiter` table exists. If it does, you can just use Waiter normally. If it doesn't, you're able to generate a simple structure and push it to the `WaiterQueue` table.

**Note:** `WaiterQueue = WaiterQueue or {}` is an important line. This says "Use the existing `WaiterQueue` table, but if it doesn't exist just create a new empty table. This is the polite way of using the `WaiterQueue` to ensure you're not overwriting/deleting other addons' entries in the queue.

# Technical Details

Waiter keeps a queue of all registered patrons and loops through them sequentially. Because we can't predict how long this will take, Waiter can't guarantee that your `waitFor` function will be run at any specific interval.

There is a minimum of a 1 second delay between loops over the queue, but the delay is actually calculated as `( minDelayTime - loopTime )` where `minDelayTime` is 1 and `loopTime` is how long (in seconds) it took for the loop to run ( with a minimum delay of 0s ).

Put simply, if the processing loop took 0.25 seconds to run, Waiter would only wait 0.75 seconds until it loops through the queue again.

You can keep an eye on how long it's taking Waiter to get through the queue by looking at the `Waiter.lastLoopDuration` variable, which will return how long the last processing loop took, in seconds.
This can help give you an idea of how frequently your `waitFor` function will be run.

Each patron is given 10 attempts before its `onTimeout` function is called, and it is purged from the queue.
