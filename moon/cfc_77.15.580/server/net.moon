import ReadHeader from net
import NetworkIDToString from util
import lower from string
import ConsoleCommand from game
import Left, find from string

pcall = pcall
rawget = rawget
rawset = rawset
pairs = pairs
IsValid = IsValid
timerSimple = timer.Simple

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

pendingAction = {}
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
boot = ( ply, steamId, ip ) ->
    return unless netShouldBan
    return if rawget pendingAction, ip

    -- Removes port number
    cleanIP = Left ip, find(ip, ":", 7, true) - 1

    cmd = "addip 10 #{cleanIP};writeip\n"
    print cmd
    ConsoleCommand cmd

    warnLog "Booted player: SteamID: #{steamID} | IP: #{ip}", true

    ULib.addBan steamId, 10, kickReason

    rawset pendingAction, ip, true
    timerSimple 5, -> pendingAction[ip] = nil

sendAlert = (steamId, nick, ip, strName, spamCount, severity) ->
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, netSpamThreshold, strName, spamCount

-- Returns whether to ignore the message
tallyUsage = ( message, ply, steamID, nick, ip ) ->
    return true if rawget pendingAction, ip
    return if rawget safeNetMessages, message
    -- return if IsValid(ply) and ply\IsAdmin!

    plyInfo = rawget netSpam, steamID
    if not plyInfo
        rawset netSpam, steamID, {
            total: 0,
            messages: {}
        }

        plyInfo = rawget netSpam, steamID

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
        boot ply, steamID, ip

        alertMessage = "Player spamming a network message! #{nick} (#{steamID}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage

        sendAlert steamID, nick, ip, message, spamCount, "extreme"

        return true

    -- Extreme spam for all messages
    if totalCount > netTotalSpamThreshold
        boot ply, steamID, ip

        alertMessage = "Player spamming large number of network messages! #{nick} (#{steamID}) is spamming: #{totalCount} messages per #{netClearTime} seconds"
        warnLog alertMessage
        PrintTable messages

        sendAlert steamID, nick, ip, nil, spamCount, "extreme"

        return true

    -- Likely spam for specific message
    if spamCount > netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{nick} (#{steamID}) is spamming: '#{message}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage
        Section580.Alerter\alertStaff steamID, nick, message, "likely"

        return true

net.Incoming = ( len, client ) ->
    if not IsValid client
        warnLog "Received net message from an invalid player! Discarding. #{client}", true
        return

    header = ReadHeader!
    messageName = NetworkIDToString header

    return unless messageName
    if messageName == "nil"
        warnLog "Invalid network message sent by '#{client}': Header: '#{header}' | messageName: '#{messageName}' | len: '#{len}'"

    lowerName = lower messageName
    steamID = client\SteamID!
    nick = client\Nick!
    ip = client\IPAddress!

    shouldIgnore = tallyUsage lowerName, client, steamID, nick, ip
    return if shouldIgnore

    func = rawget(rawget(net, "Receivers"), lowerName)

    if not func
        warnLog "Network message with no receivers sent by #{nick} (#{steamID})!: '#{messageName}'"
        return

    len -= 16
    func len, client
