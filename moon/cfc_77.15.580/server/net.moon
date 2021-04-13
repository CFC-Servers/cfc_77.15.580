import ReadHeader from net
import NetworkIDToString from util
import lower from string

rawget = rawget
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
    for k in pairs netSpam
        rawset netSpam, k, nil

bootPlayer = ( ply ) ->
    kickReason = "Suspected malicious action"

    if netShouldBan and IsValid ply
        if ULib
            ULib.ban ply, 1, kickReason
        else
            ply\Kick kickReason

sendAlert = (steamId, nick, ip, strName, spamCount, severity) ->
    print "sendAlert", steamId, nick, ip, strName, spamCount, severity
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, netSpamThreshold, strName, spamCount

-- Returns whether to ignore the message
tallyUsage = ( message, ply, plySteamId, plyNick, plyIP ) ->
    return if rawget safeNetMessages, message

    current = rawget netSpam, plySteamId
    if not current
        rawset netSpam, plySteamId, {
            total: 0
            messages: {}
        }

    messageCount = rawget(rawget(rawget(netSpam, plySteamId), "messages"), message)
    newCount = 1
    if messageCount
        newCount = messageCount + 1

    rawset(netSpam[plySteamId].messages, message, newCount)

    totalCount = rawget(rawget(netSpam, plySteamId), "total")
    newTotal = totalCount + 1

    rawset(netSpam[plySteamId], "total", newTotal)
    totalCount = newTotal

    plyInfo = rawget netSpam, plySteamId
    messages = rawget plyInfo, "messages"
    spamCount = rawget messages, message

    -- Extreme spam for specific message
    if spamCount > netExtremeSpamThreshold
        alertMessage = "Player spamming a network message! #{plyNick} (#{plySteamId}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage

        sendAlert plySteamId, plyNick, plyIP, message, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Extreme spam for all messages
    if totalCount > netTotalSpamThreshold
        alertMessage = "Player spamming large number of network messages! #{plyNick} (#{plySteamId}) is spamming: #{totalCount} messages per #{netClearTime} seconds"
        warnLog alertMessage
        PrintTable messages

        sendAlert plySteamId, plyNick, plyIP, nil, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Likely spam for specific message
    if spamCount > netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamId}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage
        Section580.Alerter\alertStaff plySteamId, plyNick, strName, "likely"

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
        warnLog "Nonexistent network message sent by #{plyNick} (#{plySteamId})!: '#{strName}'"
        return

    len -= 16
    func len, client
