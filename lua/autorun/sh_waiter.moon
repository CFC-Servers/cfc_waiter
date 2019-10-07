require "moonscript"

AddCSLuaFile!

export Waiter
export WaiterQueue

Waiter = {}
WaiterQueue = WaiterQueue or {}

Waiter.lastLoopDuration = 0

patronQueue = {}
patronCount = 0

-- Minimum delay (in seconds) between executions of attendPatrons()
minBreakAfterAttending = 0.5

generatePatron = (waitingFor, onSuccess, onTimeout, maxAttempts=0) ->
    print "[CFC Waiter] Generating new Patron!"
    patron =
        :onSuccess,
        :onTimeout,
        :waitingFor,
        :maxAttempts,
        attempts: 0

    patronQueue[patronCount] = patron

    patronCount += 1

    print "[CFC Waiter] New Patron Count: #{patronCount}"

removePatron = (patronID) ->
    patronQueue[patronID] = nil

Waiter.waitFor = (waitingFor, onSuccess, onTimeout) ->
    print "[CFC Waiter] Registering new Patron!"
    generatePatron waitingFor, onSuccess, onTimeout

attendPatron = (patronID, patron) ->
    print "[CFC Waiter] Attending to patron ID: #{patronID}"

    if patron.attempts >= patron.maxAttempts
        print "[CFC Waiter] Patron ID #{patronID} has reached max attempts! Running onTimeout and removing..."
        patron.onTimeout!
        return removePatron patronID

    if patron.waitingFor!
        print "[CFC Waiter] Patron ID #{patronID} was successful! Running onSuccess and removing..."
        patron.onSuccess!

    print "[CFC Waiter] Patron ID: #{patronID} failed to return true. Incrementing attempts..."
    patron.attempts += 1

attendPatrons = ->
    startTime = SysTime!

    for patronID, patron in pairs patronQueue
        attendPatron patronID, patron

    endTime = SysTime!
    elapsedTime = endTime - startTime

    Waiter.lastLoopDuration = elapsedTime

    delayTime = math.max 0, minBreakAfterAttending - elapsedTime

    timer.Simple delayTime attendPatrons

getPatronsFromQueue = ->
    print "[CFC Waiter] Retrieving patrons from WaiterQueue..."

    for _, patron in pairs WaiterQueue
        print "[CFC Waiter] Found patron in WaiterQueue! Importing..."

        {:waitingFor, :onSuccess, :onTimeout, :maxAttempts} = patron

        generatePatron waitingFor, onSuccess, onTimeout, maxAttempts

getPatronsFromQueue!
attendPatrons!
