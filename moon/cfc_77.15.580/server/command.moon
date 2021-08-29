import lower from string

pcall = pcall
rawget = rawget
rawset = rawset
pairs = pairs
IsValid = IsValid
concmdRun = concommand.Run

export Section580
import safeCommands,
       flaggedCommands,
       commandClearTime,
       commandSpamThreshold,
       commandExtremeSpamThreshold,
       commandTotalSpamThreshold,
       commandShouldBan,
       \warnLog
       from Section580

Section580.updateCommandLocals = ->
    import safeCommands,
           flaggedCommands,
           commandClearTime,
           commandSpamThreshold,
           commandExtremeSpamThreshold,
           commandTotalSpamThreshold,
           commandShouldBan,
           \warnLog
           from Section580

commandSpam = {}
Section580.getCommandSpam = () -> commandSpam

timer.Create "CFC_Section580_ClearCommandCounts", commandClearTime, 0, ->
    for steamId, plyInfo in pairs commandSpam
        commands = rawget plyInfo, "commands"
        for command in pairs commands
            rawset commands, command, nil

        rawset plyInfo, "total", 0

setupPlayer = (_, steamId) ->
    rawset commandSpam, steamId, {
        total: 0,
        commands: {}
    }
    return nil

hook.Add "NetworkIDValidated", "Section580_SetupPlayerCommands", setupPlayer

teardownPlayer = (_, steamId) ->
    return unless steamId
    rawset commandSpam, steamId, nil
    return nil

gameevent.Listen "player_disconnect"
hook.Add "player_disconnect", "Section580_TeardownPlayerCommands", teardownPlayer

bootPlayer = ( ply ) ->
    kickReason = "Suspected malicious action"
    return unless commandShouldBan
    return unless IsValid ply
    return if ply\IsAdmin!
    return if ply.Section580PendingAction

    ply.Section580PendingAction = true

    if ULib
        ULib.ban ply, 1, kickReason
    else
        ply\Kick kickReason

sendAlert = (steamId, nick, ip, strName, spamCount, severity) ->
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, commandSpamThreshold, strName, spamCount

extremeSpamResponse = (ply, plyNick, plySteamId, plyIP, command, spamCount) ->
    alertMessage = "Player spamming a command! #{plyNick} (#{plySteamId}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
    warnLog alertMessage, true

    sendAlert plySteamId, plyNick, plyIP, command, spamCount, "extreme"
    bootPlayer ply

totalSpamResponse = (ply, plyNick, plySteamId, plyIP, totalCount) ->
    alertMessage = "Player spamming large number of commands! #{plyNick} (#{plySteamId}) is spamming: #{totalCount} commands per #{commandClearTime} seconds"
    warnLog alertMessage, true

    sendAlert plySteamId, plyNick, plyIP, nil, totalCount, "extreme"
    bootPlayer ply

likelySpamResponse = (plyNick, plySteamId, command, spamCount) ->
    alertMessage = "Player likely spamming commands! #{plyNick} (#{plySteamId}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
    warnLog alertMessage
    Section580.Alerter\alertStaff plySteamId, plyNick, command, "likely"


calculateCounts = (steamId, command) ->
    plyInfo = rawget commandSpam, steamId
    if not plyInfo
        rawset commandSpam, steamId, {
            total: 0,
            commands: {}
        }

        plyInfo = rawget commandSpam, steamId

    commands = rawget plyInfo, "commands"
    totalCount = rawget plyInfo, "total"
    spamCount = rawget commands, command

    newCount = 1
    if spamCount
        newCount = spamCount + 1

    spamCount = newCount
    rawset commands, command, newCount

    totalCount = totalCount + 1
    rawset plyInfo, "total", totalCount

    return spamCount, totalCount

-- Returns whether to ignore the command
shouldIgnore = (ply, command) ->
    command = lower command
    return if rawget safeCommands, command
    return unless IsValid ply
    return if ply\IsAdmin!

    plySteamId = ply\SteamID!
    plyNick = ply\Nick!
    plyIP = ply\IPAddress!

    spamCount, totalCount = calculateCounts plySteamId, command

    -- Extreme spam for specific command
    if spamCount > commandExtremeSpamThreshold
        extremeSpamResponse ply, plyNick, plySteamId, plyIP, command, spamCount
        return true

    -- Extreme spam for all commands
    if totalCount > commandTotalSpamThreshold
        totalSpamResponse plyNick, plySteamId, plyIP, totalCount
        return true

    -- Likely spam for specific command
    if spamCount > commandSpamThreshold
        likelySpamResponse plyNick, plySteamId, spamCount
        return true

    false

concommand.Run = ( ... ) ->
    return if shouldIgnore ...

    concmdRun ...
