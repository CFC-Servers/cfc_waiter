AddonWaiter = {}

-- Last execution time of waitOnPatrions()
AddonWaiter.lastProcessingDuration = 0

local patronQueue = {}
local patronCount = 0

local maxAttempts = 3


-- In seconds, minimum time to rest between grooms
local breakAfterWaiting = 1

function AddonWaiter.waitFor( waitingFor, onSuccess, onTimeout )

    local struct = {}
    struct["onSuccess"] = onSuccess
    struct["onTimeout"] = onTimeout
    struct["waitingFor"] = waitingFor
    struct["attempts"] = 0

    patronQueue[patronCount] = struct

    patronCount = patronCount + 1
end

local function removePatron( patronID )
    local waitingStruct = patronQueue[patronID]

    waitingStruct.onTimeout()

    patronQueue[patronID] = nil
end

local function waitOnPatron( patronID, patron )
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

local function waitOnPatrons()
    local startTime = SysTime()

    for patronID, patron in pairs(patronQueue) do
        waitOnPatron( patronID, patron )
    end

    local endTime = SysTime()
    local elapsedTime = endTime - startTime

    AddonWaiter.lastProcessingDuration = elapsedTime

    local delayTime = math.max( 0, breakAfterWaiting - elapsedTime )

    timer.Simple( delayTime, waitOnPatrons )
end

waitOnPatrons()
