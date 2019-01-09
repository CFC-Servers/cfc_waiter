Waiter = {}
WaiterQueue = WaiterQueue or {}

-- Last execution time of attendPatrons()
Waiter.lastLoopDuration = 0

local patronQueue = {}
local patronCount = 0

local maxAttempts = 10

-- Minimum delay between executions of attendPatrons()
local minBreakAfterAttending = 1

local function generatePatron( waitingFor, onSuccess, onTimeout )
    print( "[CFC Waiter] Generating new Patron!" )
    local patron = {}
    patron["onSuccess"] = onSuccess
    patron["onTimeout"] = onTimeout
    patron["waitingFor"] = waitingFor
    patron["attempts"] = 0

    patronQueue[patronCount] = patron

    patronCount = patronCount + 1
    print( "[CFC Waiter] New Patron Count: " .. tostring(patronCount) )
end

local function removePatron( patronID )
    patronQueue[patronID] = nil
end

function Waiter.waitFor( waitingFor, onSuccess, onTimeout )
    print( "[CFC Waiter] Registering new Patron!" )
    generatePatron( waitingFor, onSuccess, onTimeout )
end

local function attendPatron( patronID, patron )
    print( "[CFC Waiter] Attending to patron ID: " .. tostring( patronID ) )
    if patron.attempts >= maxAttempts then
        print( "[CFC Waiter] Patron ID " .. tostring( patronID ) .. " has reached max attempts! Running onTimeout and removing.." )
        patron.onTimeout()
        return removePatron( patronID )
    end

    if patron.waitingFor() == true then
        print( "[CFC Waiter] Patron ID " .. tostring( patronID ) .. " was successful! Running onSuccess and removing.. " )
        patron.onSuccess()
        return removePatron( patronID )
    end

    print( "[CFC Waiter] Patron ID: " .. tostring( patronID ) .. " failed to return true. Incrementing attempts.. " )
    patron.attempts = patron.attempts + 1
end

local function attendPatrons()
    print( "[CFC Waiter] Attending to patrons.. " )
    local startTime = SysTime()

    for patronID, patron in pairs(patronQueue) do
        attendPatron( patronID, patron )
    end

    local endTime = SysTime()
    local elapsedTime = endTime - startTime

    Waiter.lastLoopDuration = elapsedTime

    print( "[CFC Waiter] Finished attending to patrons. Elapsed time: " .. tostring(elapstedTime) )

    local delayTime = math.max( 0, minBreakAfterAttending - elapsedTime )

    print( "[CFC Waiter] Next delay time: " .. tostring(delayTime) )

    timer.Simple( delayTime, attendPatrons )
end

local function getPatronsFromQueue()
    print( "[CFC Waiter] Retrieving patrons from WaiterQueue.." )
    for _, patron in pairs(WaiterQueue) do
        print( "[CFC Waiter] Found patron in WaiterQueue! Importing.." )
        generatePatron( patron["waitingFor"], patron["onSuccess"], patron["onTimeout"] )
    end
end

getPatronsFromQueue()
attendPatrons()
