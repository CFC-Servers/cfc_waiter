# cfc_waiter
Tell me when!

Have you ever written an addon/tool that needed to wait until another addon was loaded before running?

It's a little inconvenient.

CFC Waiter aims to make it as easy as possible to write code that relies on other code out of your control.


# Usage
Very simple to use. It might be easier to show you:


Here's the simplest possible example of how to use Waiter
```lua
/* Wait for LocalPlayer() to be valid */
Waiter.waitFor(
    function() return IsValid(LocalPlayer()) end,
    function() print("Local Player is valid!") end,
    function() print("Timed out while trying to find LocalPlayer!") end
)
```

A more realistic implementation might look like this:
```lua
globalTestVariable = "this"

-- Alert function
local function alertAll( alertMsg )
    for k, v in pairs(player.GetAll()) do
        v:ChatPrint( alertMsg )
    end
end

-- Condition
local function waitingFor()
    local check = globalTestVariable == "that"
    print( "Running the waitingFor function: " .. check )

    return check
end

-- Success
local function alertOnSuccess()
    alertAll( "Waiter called onSuccess -- whatever you were waiting for completed!" )
end

-- Timeout
local function alertOnTimeout()
    alertAll( "Waiter called onTimeout -- whatever you were waiting for didn't complete in time!" )
end

timer.Simple( 2, function()
    globalTestVariable = "that"
end )

local maxAttempts = 15

-- When waitingFor returns true, run alertOnSuccess. Or run alertOnTimeout if waitingFor doesn't return true.
Waiter.waitFor( waitingFor, alertOnSuccess, alertOnTimeout, maxAttempts )
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

`WaiterQueue` is a global table that anyone can append their patrons (jobs) to.
When Waiter loads, it ingests and processes all valid jobs in the `WaiterQueue`.

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
As you can see, you first check if the `Waiter` table exists. If it does, you can use Waiter normally. If it doesn't, you're able to generate a simple structure and push it to the `WaiterQueue` table.

**Note:** `WaiterQueue = WaiterQueue or {}` is an important line. This says "Use the existing `WaiterQueue` table, but if it doesn't exist, create a new empty table." This is the polite way of using the `WaiterQueue` to ensure you're not overwriting/deleting other addons' entries in the queue.

# Technical Details

Waiter keeps a queue of all registered patrons and loops through them sequentially. Because we can't predict how long this will take, Waiter can't guarantee that your `waitFor` function will be run at any specific interval.

There is a minimum of a 0.5 second delay between loops over the queue, but the delay is actually calculated as `( minDelayTime - loopTime )` where `minDelayTime` is 0.5 and `loopTime` is how long (in seconds) it took for the loop to run ( with a minimum delay of 0s ).

Put simply, if the minimum time was 1 second and the processing loop took 0.25 seconds to run, Waiter would only wait 0.75 seconds until it loops through the queue again.

You can keep an eye on how long it's taking Waiter to get through the queue by looking at the `Waiter.lastLoopDuration` variable, which will return how long the last processing loop took, in seconds.
This can help give you an idea of how frequently your `waitFor` function will be run.

Each patron is, by default, given 10 attempts before its `onTimeout` function is called, and it is purged from the queue. Though, each patron can defined its own attempt limit.
