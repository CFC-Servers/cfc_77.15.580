import ReadHeader from net
import NetworkIDToString from util
import lower from string
import pcall, rawget, rawset, pairs, IsValid from _G

netClearTime = 1
netSpamThreshold = 250
netTotalSpamThreshold = 500

safeNetMessages = {}
netSpam =
    messages: {}
    total: 0

timer.Create "CFC_Section580_ClearNetCounts", netClearTime, 0, ->
    messages = rawget netSpam, "messages"

    for message in pairs messages
        rawset messages, message, 0

    rawset netSpam, "total", 0

warnLog = print

-- Returns whether to ignore the message
tallyUsage = (message) ->
    return if rawget safeNetMessages, message

    messages = rawget netSpam, "messages"
    spamCount = rawget messages, message
    totalCount = rawget netSpam, "total"

    newCount = (spamCount or 0) + 1

    spamCount = newCount
    rawset messages, message, newCount

    totalCount = totalCount + 1
    rawset netSpam, "total", totalCount

    -- Spam for specific message
    if spamCount > netSpamThreshold
        alertMessage = "Server is spamming a network message! '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage

        return true

    -- Spam for all messages
    if totalCount > netTotalSpamThreshold
        alertMessage = "Server is spamming large number of network messages! #{totalCount} messages per #{netClearTime} seconds"
        warnLog alertMessage
        PrintTable messages

        return true

receivers = net.Receivers

net.Incoming = (len) ->
    header = ReadHeader!
    strName = NetworkIDToString header

    return unless strName
    lowerStr = lower strName

    shouldIgnore = tallyUsage lowerStr
    return if shouldIgnore

    func = rawget receivers, lowerStr
    if not func
        warnLog "Network message with no receivers sent by the server! ('#{strName}')"
        return

    len -= 16
    func len
