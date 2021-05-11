import lower from string

pcall = pcall
rawget = rawget
rawset = rawset
pairs = pairs
IsValid = IsValid

export Section580
import safeCommands,
       flaggedCommands,
       commandClearTime,
       commandSpamThreshold,
       commandExtremeSpamThreshold,
       commandTotalSpamThreshold,
       commandShouldBan,
       \warnLog,
       Webhooker
       from Section580

Section580.updateCommandLocals = ->
    import safeCommands,
           flaggedCommands,
           commandClearTime,
           commandSpamThreshold,
           commandExtremeSpamThreshold,
           commandTotalSpamThreshold,
           commandShouldBan,
           \warnLog,
           Webhooker
           from Section580

commandSpam = {}
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

-- Returns whether to ignore the command
tallyUsage = ( command, ply, plySteamId, plyNick, plyIP ) ->
    return if rawget safeCommands, command
    return if IsValid(ply) and ply\IsAdmin!

    plyInfo = rawget commandSpam, plySteamId
    if not plyInfo
        rawset commandSpam, plySteamId, {
            total: 0,
            commands: {}
        }

        plyInfo = rawget commandSpam, plySteamId

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

    -- Extreme spam for specific command
    if spamCount > commandExtremeSpamThreshold
        alertMessage = "Player spamming a command! #{plyNick} (#{plySteamId}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
        warnLog alertMessage, true

        sendAlert plySteamId, plyNick, plyIP, command, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Extreme spam for all commands
    if totalCount > commandTotalSpamThreshold
        alertMessage = "Player spamming large number of commands! #{plyNick} (#{plySteamId}) is spamming: #{totalCount} commands per #{commandClearTime} seconds"
        warnLog alertMessage, true
        PrintTable commands

        sendAlert plySteamId, plyNick, plyIP, nil, spamCount, "extreme"
        bootPlayer ply

        return true

    -- Likely spam for specific command
    if spamCount > commandSpamThreshold
        alertMessage = "Player likely spamming commands! #{plyNick} (#{plySteamId}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
        warnLog alertMessage
        Section580.Alerter\alertStaff plySteamId, plyNick, command, "likely"

        return true

concommand.Run = ( client, command, arguments, args ) ->
    lowerCommand = command and lower command

    return unless lowerCommand

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

    func = rawget CommandList, lowerCommand

    if not func
        warnLog "Command with no receivers sent by #{plyNick} (#{plySteamId})!: '#{lowerCommand}'"
        return

    func client, command, arguments, args
