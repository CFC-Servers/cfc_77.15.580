local lower
lower = string.lower
local ConsoleCommand
ConsoleCommand = game.ConsoleCommand
local Left, find
do
  local _obj_0 = string
  Left, find = _obj_0.Left, _obj_0.find
end
local pcall = pcall
local rawget = rawget
local rawset = rawset
local pairs = pairs
local IsValid = IsValid
local timerSimple = timer.Simple
local concmdRun = concommand.Run
local safeCommands, flaggedCommands, commandClearTime, commandSpamThreshold, commandExtremeSpamThreshold, commandTotalSpamThreshold, commandShouldBan, warnLog, Webhooker
safeCommands, flaggedCommands, commandClearTime, commandSpamThreshold, commandExtremeSpamThreshold, commandTotalSpamThreshold, commandShouldBan, warnLog, Webhooker = Section580.safeCommands, Section580.flaggedCommands, Section580.commandClearTime, Section580.commandSpamThreshold, Section580.commandExtremeSpamThreshold, Section580.commandTotalSpamThreshold, Section580.commandShouldBan, (function()
  local _base_0 = Section580
  local _fn_0 = _base_0.warnLog
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)(), Section580.Webhooker
Section580.updateCommandLocals = function()
  safeCommands, flaggedCommands, commandClearTime, commandSpamThreshold, commandExtremeSpamThreshold, commandTotalSpamThreshold, commandShouldBan, warnLog, Webhooker = Section580.safeCommands, Section580.flaggedCommands, Section580.commandClearTime, Section580.commandSpamThreshold, Section580.commandExtremeSpamThreshold, Section580.commandTotalSpamThreshold, Section580.commandShouldBan, (function()
    local _base_0 = Section580
    local _fn_0 = _base_0.warnLog
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)(), Section580.Webhooker
end
local pendingAction = { }
local commandSpam = { }
Section580.getCommandSpam = function()
  return commandSpam
end
timer.Create("CFC_Section580_ClearCommandCounts", commandClearTime, 0, function()
  for steamId, plyInfo in pairs(commandSpam) do
    local commands = rawget(plyInfo, "commands")
    for command in pairs(commands) do
      rawset(commands, command, nil)
    end
    rawset(plyInfo, "total", 0)
  end
end)
local setupPlayer
setupPlayer = function(_, steamId)
  rawset(commandSpam, steamId, {
    total = 0,
    commands = { }
  })
  return nil
end
hook.Add("NetworkIDValidated", "Section580_SetupPlayerCommands", setupPlayer)
local teardownPlayer
teardownPlayer = function(_, steamId)
  if not (steamId) then
    return 
  end
  rawset(commandSpam, steamId, nil)
  return nil
end
gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Section580_TeardownPlayerCommands", teardownPlayer)
local kickReason = "Suspected malicious action"
local boot
boot = function(steamId, ip, nick)
  if not (commandShouldBan) then
    return 
  end
  if rawget(pendingAction, ip) then
    return 
  end
  local cleanIP = Left(ip, find(ip, ":", 7, true) - 1)
  ConsoleCommand("addip 10 " .. tostring(cleanIP) .. ";writeip\n")
  timerSimple(1, function()
    return ULib.addBan(steamId, 10, kickReason, nick)
  end)
  rawset(pendingAction, ip, true)
  return timerSimple(5, function()
    pendingAction[ip] = nil
  end)
end
local sendAlert
sendAlert = function(steamId, nick, ip, strName, spamCount, severity)
  Section580.Alerter:alertStaff(steamId, nick, strName, severity)
  return Section580.Alerter:alertDiscord(steamId, nick, ip, commandSpamThreshold, strName, spamCount)
end
local extremeSpamResponse
extremeSpamResponse = function(ply, nick, steamID, ip, command, spamCount)
  boot(steamID, ip, nick)
  local alertMessage = "Player spamming a command! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: '" .. tostring(command) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(commandClearTime) .. " seconds)"
  warnLog(alertMessage, true)
  return sendAlert(steamID, nick, ip, command, spamCount, "extreme")
end
local totalSpamResponse
totalSpamResponse = function(ply, nick, steamID, ip, totalCount)
  boot(ply, steamID, ip, nick)
  local alertMessage = "Player spamming large number of commands! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: " .. tostring(totalCount) .. " commands per " .. tostring(commandClearTime) .. " seconds"
  warnLog(alertMessage, true)
  return sendAlert(steamID, nick, ip, nil, spamCount, "extreme")
end
local likelySpamResponse
likelySpamResponse = function(nick, steamID, spamCount, command)
  local alertMessage = "Player likely spamming commands! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: '" .. tostring(command) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(commandClearTime) .. " seconds)"
  warnLog(alertMessage)
  return Section580.Alerter:alertStaff(steamID, nick, command, "likely")
end
local calculateCounts
calculateCounts = function(steamId, command)
  local plyInfo = rawget(commandSpam, steamId)
  if not plyInfo then
    rawset(commandSpam, steamId, {
      total = 0,
      commands = { }
    })
    plyInfo = rawget(commandSpam, steamId)
  end
  local commands = rawget(plyInfo, "commands")
  local totalCount = rawget(plyInfo, "total")
  local spamCount = rawget(commands, command)
  local newCount = 1
  if spamCount then
    newCount = spamCount + 1
  end
  spamCount = newCount
  rawset(commands, command, newCount)
  totalCount = totalCount + 1
  rawset(plyInfo, "total", totalCount)
  return spamCount, totalCount
end
local shouldIgnore
shouldIgnore = function(ply, command)
  if not (IsValid(ply)) then
    return 
  end
  local ip = ply:IPAddress()
  if rawget(pendingAction, ip) then
    return true
  end
  command = lower(command)
  if rawget(safeCommands, command) then
    return 
  end
  if ply:IsAdmin() then
    return 
  end
  local steamID = ply:SteamID()
  local nick = ply:Nick()
  local spamCount, totalCount = calculateCounts(steamID, command)
  if spamCount > commandExtremeSpamThreshold then
    extremeSpamResponse(ply, nick, steamID, ip, command, spamCount)
    return true
  end
  if totalCount > commandTotalSpamThreshold then
    totalSpamResponse(ply, nick, steamID, ip, totalCount)
    return true
  end
  if spamCount > commandSpamThreshold then
    likelySpamResponse(nick, steamID, spamCount, command)
    return true
  end
  return false
end
concommand.Run = function(...)
  if shouldIgnore(...) then
    return 
  end
  return concmdRun(...)
end
