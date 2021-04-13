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
    if connectSpam
        newAmount = connectAmount + 1

    rawset connectSpam, ip, newAmount

    if newAmount > connectSpamThreshold
        warnLog "Spam connections from IP: #{ip} - Banning: #{connectShouldBan}", true
        return unless shouldBan

        banLength = connectSpamBanLength
        RunConsoleCommand "addip", banLength, ip
