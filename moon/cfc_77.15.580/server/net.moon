import ReadHeader from net
import NetworkIDToString from util
import lower from string

pcall = pcall
rawget = rawget
rawset = rawset
pairs = pairs
IsValid = IsValid

export Section580
import safeNetMessages,
       flaggedMessages,
       netClearTime,
       netSpamThreshold,
       netExtremeSpamThreshold,
       netTotalSpamThreshold,
       netShouldBan,
       \warnLog,
       Webhooker
       from Section580

Section580.updateNetLocals = ->
    import safeNetMessages,
           flaggedMessages,
           netClearTime,
           netSpamThreshold,
           netExtremeSpamThreshold,
           netTotalSpamThreshold,
           netShouldBan
           from Section580

netSpam = {}
timer.Create "CFC_Section580_ClearNetCounts", netClearTime, 0, ->
    for steamId, plyInfo in pairs netSpam
        messages = rawget plyInfo, "messages"
        for message in pairs messages
            rawset messages, message, nil

        rawset plyInfo, "total", 0

setupPlayer = (_, steamId) ->
    rawset netSpam, steamId, {
        total: 0,
        messages: {}
    }
    return nil

hook.Add "NetworkIDValidated", "Section580_SetupPlayer", setupPlayer

teardownPlayer = (_, steamId) ->
    return unless steamId
    rawset netSpam, steamId, nil
    return nil

gameevent.Listen "player_disconnect"
hook.Add "player_disconnect", "Section580_TeardownPlayer", teardownPlayer

kickReason = "Suspected malicious action"
bootPlayer = ( ply, steamId, plyIP ) ->
    return unless netShouldBan
    return if ply and ply.Section580PendingAction
    ply.Section580PendingAction = true if ply

    RunConsoleCommand "addip", 10, plyIP
    ULib.addBan steamId, 10, kickReason

sendAlert = (steamId, nick, ip, strName, spamCount, severity) ->
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, netSpamThreshold, strName, spamCount

-- Returns whether to ignore the message
tallyUsage = ( message, ply, plySteamId, plyNick, plyIP ) ->
    return if rawget safeNetMessages, message
    return if IsValid(ply) and ply\IsAdmin!

    plyInfo = rawget netSpam, plySteamId
    if not plyInfo
        rawset netSpam, plySteamId, {
            total: 0,
            messages: {}
        }

        plyInfo = rawget netSpam, plySteamId

    messages = rawget plyInfo, "messages"
    totalCount = rawget plyInfo, "total"
    spamCount = rawget messages, message

    newCount = 1
    if spamCount
        newCount = spamCount + 1

    spamCount = newCount
    rawset messages, message, newCount

    totalCount = totalCount + 1
    rawset plyInfo, "total", totalCount

    -- Extreme spam for specific message
    if spamCount > netExtremeSpamThreshold
        bootPlayer ply, plySteamId, plyIP

        alertMessage = "Player spamming a network message! #{plyNick} (#{plySteamId}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage, true

        sendAlert plySteamId, plyNick, plyIP, message, spamCount, "extreme"

        return true

    -- Extreme spam for all messages
    if totalCount > netTotalSpamThreshold
        bootPlayer ply, plySteamId, plyIP

        alertMessage = "Player spamming large number of network messages! #{plyNick} (#{plySteamId}) is spamming: #{totalCount} messages per #{netClearTime} seconds"
        warnLog alertMessage, true
        PrintTable messages

        sendAlert plySteamId, plyNick, plyIP, nil, spamCount, "extreme"

        return true

    -- Likely spam for specific message
    if spamCount > netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamId}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage
        Section580.Alerter\alertStaff plySteamId, plyNick, message, "likely"

        return true

net.Incoming = ( len, client ) ->
    header = ReadHeader!
    strName = NetworkIDToString header

    return unless strName
    if strName == "nil"
        warnLog "Invalid network message sent by '#{client}': Header: '#{header}' | strName: '#{strName}' | len: '#{len}'"

    lowerStr = lower strName
    plySteamId = "<Unknown Steam ID>"
    plyNick = "<Unknown Player Name>"
    plyIP = "<Unknown Player IP>"
    plyIsValid = IsValid client

    if plyIsValid
        plySteamId = client\SteamID!
        plyNick = client\Nick!
        plyIP = client\IPAddress!

    shouldIgnore = tallyUsage lowerStr, client, plySteamId, plyNick, plyIP
    return if shouldIgnore

    func = rawget(rawget(net, "Receivers"), lowerStr)

    if not func
        warnLog "Network message with no receivers sent by #{plyNick} (#{plySteamId})!: '#{strName}'"
        return

    len -= 16
    func len, client
