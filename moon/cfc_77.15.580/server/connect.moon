import rawget, rawset from _G

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

ipMap = {}
connectSpam = {}
timer.Create "CFC_Section580_ClearConnectCounts", connectClearTime, 0, ->
    for k in pairs connectSpam
        rawset connectSpam, k, nil

tallyForPlayer = (steamID, name, ip) ->
    newAmount = 1
    connectAmount = rawget connectSpam, ip
    if connectAmount
        newAmount = connectAmount + 1

    rawset ipMap, steamID, ip
    rawset connectSpam, ip, newAmount

    return unless newAmount > connectSpamThreshold
    return unless shouldBan

    warnLog "Spam connections from IP: #{ip} - Banning: #{connectShouldBan}", true

    RunConsoleCommand "addip", connectSpamBanLength, ip
    RunConsoleCommand "writeip"
    RunConsoleCommand "ulx", "banid", steamID, connectSpamBanLength, "Suspected malicious action"
    ULib.addBan steamID, connectSpamBanLength, "Suspected malicious action", name, "Section 580"

gameevent.Listen "player_connect"
hook.Add "player_connect", "Section580_ConnectionThrottle", (_, steamID, name, _, _, ip) ->
    tallyForPlayer steamID, name, ip

gameevent.Listen "player_disconnect"
hook.Add "player_disconnect", "Section580_ConnectionThrottle", (_, steamID, name, _, reason) ->
    ip = rawget ipMap, steamID

    if not ip
        print steamID, name, reason
        ErrorNoHaltWithStack "No IP in IP map for: #{steamID}"
    else
        tallyForPlayer steamID, name, rawget ipMap
