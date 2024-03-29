import ConsoleCommand from game

export Section580
import
    connectClearTime,
    connectSpamThreshold,
    connectShouldBan,
    connectSpamBanLength,
    \warnLog
    from Section580

Section580.updateConnectLocals = ->
    import
        connectClearTime,
        connectSpamThreshold,
        connectShouldBan,
        connectSpamBanLength
        from Section580

connectSpam = {}
timer.Create "CFC_Section580_ClearConnectCounts", connectClearTime, 0, ->
    for k in pairs connectSpam
        rawset connectSpam, k, nil

hook.Add "PlayerConnect", "Section580_ConnectionThrottle", (name, ip) ->
    newAmount = 1
    connectAmount = rawget connectSpam, ip
    if connectAmount
        newAmount = connectAmount + 1

    rawset connectSpam, ip, newAmount

    return unless newAmount > connectSpamThreshold
    return unless shouldBan

    ConsoleCommand "addip #{connectSpamBanLength} #{ip}\n"

    warnLog "Spam connections from IP: #{ip} - Banning: #{connectShouldBan}", true
