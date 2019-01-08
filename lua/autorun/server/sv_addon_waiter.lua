AddonWaiter = {}

-- Last execution time of waitOnPatrions()
AddonWaiter.lastLoopDuration = 0

local patronQueue = {}
local patronCount = 0

local maxAttempts = 3

local minBreakAfterAttending = 1

function AddonWaiter.waitFor( waitingFor, onSuccess, onTimeout )

    local patron = {}
    patron["onSuccess"] = onSuccess
    patron["onTimeout"] = onTimeout
    patron["waitingFor"] = waitingFor
    patron["attempts"] = 0

    patronQueue[patronCount] = patron

    patronCount = patronCount + 1
end

local function removePatron( patronID )
    local waitingStruct = patronQueue[patronID]

    waitingStruct.onTimeout()

    patronQueue[patronID] = nil
end

local function attendPatron( patronID, patron )
    if patron.attempts >= maxAttempts then
        patron.onTimeout()
        return removePatron( patronID )
    end

    if patron.waitingFor() == true then
        patron.onSuccess()
        return removePatron( patronID )
    end

    patron.attempts = patron.attempts + 1
end

local function attendPatrons()
    local startTime = SysTime()

    for patronID, patron in pairs(patronQueue) do
        attendPatron( patronID, patron )
    end

    local endTime = SysTime()
    local elapsedTime = endTime - startTime

    AddonWaiter.lastLoopDuration = elapsedTime

    local delayTime = math.max( 0, minBreakAfterAttending - elapsedTime )

    timer.Simple( delayTime, attendPatrons )
end

attendPatrons()
