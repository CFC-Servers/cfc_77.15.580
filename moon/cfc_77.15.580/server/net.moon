import Receivers, ReadHeader from net
import NetworkIDToString from util
import lower from string

rawget = rawget
pcall = pcall

import flaggedMessages,
       netClearTime,
       netShouldBan,
       netSpamThreshold,
       netExtremeSpamThreshold,
       netSpam,
       \warnLog,
       Alerter,
       Logger,
       Webhooker
       from Section580

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

    if not Section580.netSpam[plySteamId]
        Section580.netSpam[plySteamId] = {}

    Section580.netSpam[lowerStr] or= 0
    Section580.netSpam[lowerStr] += 1

    spamCount = Section580.netSpam[lowerStr][lowerStr]

    if spamCount > netExtremeSpamThreshold
        alertMessage = "Player spamming many network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage

        Alerter\alertStaff plySteamId, plyNick, strName, "extreme"
        Alerter\alertDiscord plySteamId, plyNick, client\IPAddress!, netSpamThreshold, strName, spamCount

        kickReason = "Suspected malicious action"

        if netShouldBan and plyIsValid
            if ULib
                ULib.ban client, 1, kickReason
            else
                client\Kick kickReason

        return

    if spamCount > netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamId}) is spamming: '#{strName}' (Count: #{spamCount} per #{netClearTime} seconds)"
        warnLog alertMessage
        Alerter\alertStaff plySteamId, plyNick, strName, "likely"

    func = rawget Receivers, lowerStr

    if not func
        warnLog "Nonexistent network message sent by #{plyNick} (#{plySteamId})!: '#{strName}'"
        return

    status, err = pcall -> func len, client
    return unless err

    Logger\error "Error in network message handler! '#{strName}' errored: '#{err}'"
    return
