import ReadHeader from net
import NetworkIDToString from util
import lower from string

rawget = rawget
pcall = pcall

import flaggedMessages,
       \warnLog,
       Webhooker
       from Section580

bootPlayer = ( ply ) ->
    kickReason = "Suspected malicious action"

    if Section580.netShouldBan and plyIsValid
        if ULib
            ULib.ban ply, 1, kickReason
        else
            ply\Kick kickReason

sendAlert = (steamId, nick, ip, threshold, strName, spamCount, severity) ->
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, Section580.netSpamThreshold, strName, spamCount

-- Returns whether to ignore the message
tallyUsage = ( message, ply, plySteamId, plyNick, plyIP ) ->
    return if Section580.safeNetMessages[message]

    Section580.netSpam[plySteamId] or= {
        total: 0
        messages: {}
    }

    Section580.netSpam[plySteamId].messages[message] or= 0
    Section580.netSpam[plySteamId].messages[message] += 1
    Section580.netSpam[plySteamId].total += 1

    totalCount = Section580.netSpam[plySteamId].total
    messages = Section580.netSpam[plySteamId].messages
    spamCount = messages[message]

    -- Extreme spam for specific message
    if spamCount > Section580.netExtremeSpamThreshold
        alertMessage = "Player spamming many network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{Section580.netClearTime} seconds)"
        warnLog alertMessage

        sendAlert plySteamId, plyNick, plyIP, Section580.netSpamThreshold, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Extreme spam for all messages
    if totalCount > Section580.netTotalSpamThreshold
        alertMessage = "Player spamming many network messages! #{plyNick} (#{plySteamId}) is spamming: #{totalCount} messages per #{Section580.netClearTime} seconds"
        warnLog alertMessage
        PrintTable messages

        sendAlert plySteamId, plyNick, plyIP, Section580.netSpamThreshold, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Likely spam for specific message
    if spamCount > Section580.netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{Section580.netClearTime} seconds)"
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

    func = rawget net.Receivers, lowerStr

    if not func
        warnLog "Nonexistent network message sent by #{plyNick} (#{plySteamId})!: '#{strName}'"
        return

    len -= 16
    status, err = pcall -> func len, client
    return unless err

    Section580.Logger\error "Error in network message handler! '#{strName}' errored: '#{err}' (Sent by '#{plyNick}'-'#{plySteamId}')"
    return
