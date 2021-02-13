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
       Logger,
       Webhooker
       from Section580

sendWebhook = (plySteamID, plyNick, plyIP, identifier, count) ->
    Webhooker\send "net-spam",
        steamId: plySteamID
        name: plyNick
        ip: plyIP
        timeframe: netClearTime
        :identifier
        :count

net.Incoming = ( len, client ) ->
    len -= 16
    strName = NetworkIDToString ReadHeader!

    return unless strName

    plySteamID = "<Unknown Steam ID>"
    plyNick = "<Unknown Player Name>"
    plyIP = "<Unknown Player IP>"
    plyIsValid = IsValid client

    if plyIsValid
        plySteamID = ply\SteamID!
        plyNick = ply\Nick!
        plyIP = ply\IPAddress!

    plyNetSpam = rawget netSpam, plySteamID
    plyNetSpam or= {}
    plyNetSpam[strName] or= 0
    plyNetSpam[strName] += 1

    spamCount = rawget plyNetSpam, strName

    if spamCount > netExtremeSpamThreshold
        alertMessage = "Player spamming many network messages! #{plyNick} (#{plySteamID}) is spamming: '#{strName}' (Count: #{spamCount} per #{netSpamThreshold} seconds)"
        Logger\warn alertMessage
        -- alert staff
        -- webhooker

        kickReason = "Suspected malicious action"

        if netShouldBan and plyIsValid
            if ULib
                ULib.ban client, 1, kickReason
            else
                client\Kick kickReason

        return

    if spamCount > netSpamThreshold
        alertMessage = "Player likely spamming network messages! #{plyNick} (#{plySteamID}) is spamming: '#{strName}' (Count: #{spamCount} per #{netSpamThreshold} seconds)"
        Logger\warn alertMessage
        -- alert staff
        -- webhooker alert

    lowerStr = lower strName
    func = rawget Receivers, lowerStr

    if not func
        if not ignoredBadMessages, lowerStr
            Logger\warn "Nonexistent network message sent by #{plyNick} (#{plySteamID})!: '#{strName}'"

        return

    if rawget flaggedMessages, str
        Logger\warn "Flagged network message sent by #{plyNick} (#{plySteamID})!: '#{strName}'"
        -- alert staff
        -- webhooker
        return

    status, err = pcall () -> func( len, client )
    return unless err

    Logger\error "Error in network message handler! '#{strName}' errored: '#{err}'"
    return
