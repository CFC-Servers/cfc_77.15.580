import ReadHeader from net
import NetworkIDToString from util
import lower from string

rawget = rawget
pcall = pcall

import flaggedMessages,
       \warnLog,
       Webhooker
       from Section580

tallyUsage = ( message, ply, plySteamId, plyNick, plyIP ) ->
    return if Section580.safeNetMessages[message]

    Section580.netSpam[plySteamId] or= {}
    Section580.netSpam[plySteamId][message] or= 0
    Section580.netSpam[plySteamId][message] += 1

    spamCount = Section580.netSpam[plySteamId][message]

    if spamCount > Section580.netExtremeSpamThreshold
        alertMessage = "Player spamming many network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{Section580.netClearTime} seconds)"
        warnLog alertMessage

        Section580.Alerter\alertStaff plySteamId, plyNick, strName, "extreme"
        Section580.Alerter\alertDiscord plySteamId, plyNick, plyIP, Section580.netSpamThreshold, strName, spamCount

        kickReason = "Suspected malicious action"

        if Section580.netShouldBan and plyIsValid
            if ULib
                ULib.ban ply, 1, kickReason
            else
                ply\Kick kickReason

        return

    if spamCount > Section580.netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{Section580.netClearTime} seconds)"
        warnLog alertMessage
        Section580.Alerter\alertStaff plySteamId, plyNick, strName, "likely"


net.Incoming = ( len, client ) ->
    len -= 16
    strName = NetworkIDToString ReadHeader!

    return unless strName

    lowerStr = lower strName
    plySteamId = "<Unknown Steam ID>"
    plyNick = "<Unknown Player Name>"
    plyIP = "<Unknown Player IP>"
    plyIsValid = IsValid client

    if plyIsValid
        plySteamId = client\SteamID!
        plyNick = client\Nick!
        plyIP = client\IPAddress!

    tallyUsage lowerStr, client, plySteamId, plyNick, plyIP

    func = rawget net.Receivers, lowerStr

    if not func
        warnLog "Nonexistent network message sent by #{plyNick} (#{plySteamId})!: '#{strName}'"
        return

    status, err = pcall -> func len, client
    return unless err

    Section580.Logger\error "Error in network message handler! '#{strName}' errored: '#{err}'"
    return
