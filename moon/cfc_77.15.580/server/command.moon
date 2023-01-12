import lower from string
import Left, find from string

pcall = pcall
rawget = rawget
rawset = rawset
pairs = pairs
IsValid = IsValid
timerSimple = timer.Simple
concmdRun = concommand.Run

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

pendingAction = {}
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

kickReason = "Suspected malicious action"
boot = ( steamId, ip, nick ) ->
    return unless commandShouldBan
    return if rawget pendingAction, ip

    -- Removes port number
    cleanIP = Left ip, find(ip, ":", 7, true) - 1

    RunConsoleCommand "addip", 10, cleanIP
    RunConsoleCommand "writeip"
    timerSimple 1, -> ULib.addBan steamId, 10, kickReason, nick

    rawset pendingAction, ip, true
    timerSimple 5, -> pendingAction[ip] = nil

sendAlert = (steamId, nick, ip, strName, spamCount, severity) ->
    Section580.Alerter\alertStaff steamId, nick, strName, severity
    Section580.Alerter\alertDiscord steamId, nick, ip, commandSpamThreshold, strName, spamCount

extremeSpamResponse = (ply, nick, steamID, ip, command, spamCount) ->
    boot steamID, ip, nick

    alertMessage = "Player spamming a command! #{nick} (#{steamID}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
    warnLog alertMessage, true

    sendAlert steamID, nick, ip, command, spamCount, "extreme"

totalSpamResponse = (ply, nick, steamID, ip, totalCount) ->
    boot ply, steamID, ip, nick

    alertMessage = "Player spamming large number of commands! #{nick} (#{steamID}) is spamming: #{totalCount} commands per #{commandClearTime} seconds"
    warnLog alertMessage, true

    sendAlert steamID, nick, ip, nil, spamCount, "extreme"

likelySpamResponse = (ply, nick, steamID, ip, command, spamCount) ->
    alertMessage = "Player likely spamming commands! #{nick} (#{steamID}) is spamming: '#{command}' (Count: #{spamCount} per #{commandClearTime} seconds)"
    warnLog alertMessage
    Section580.Alerter\alertStaff steamID, nick, command, "likely"


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
    return unless IsValid ply

    ip = ply\IPAddress!
    return true if rawget pendingAction, ip

    command = lower command
    return if rawget safeCommands, command
    return if ply\IsAdmin!

    steamID = ply\SteamID!
    nick = ply\Nick!

    spamCount, totalCount = calculateCounts steamID, command

    -- Extreme spam for specific command
    if spamCount > commandExtremeSpamThreshold
        extremeSpamResponse ply, nick, steamID, ip, command, spamCount
        return true

    -- Extreme spam for all commands
    if totalCount > commandTotalSpamThreshold
        totalSpamResponse ply, nick, steamID, ip, totalCount
        return true

    -- Likely spam for specific command
    if spamCount > commandSpamThreshold
        likelySpamResponse ply, nick, steamID, ip, command, spamCount
        return true

    return false

concommand.Run = ( ... ) ->
    return if shouldIgnore ...

    concmdRun ...
