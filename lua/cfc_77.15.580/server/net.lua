local ReadHeader
ReadHeader = net.ReadHeader
local NetworkIDToString
NetworkIDToString = util.NetworkIDToString
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
local safeNetMessages, flaggedMessages, netClearTime, netSpamThreshold, netExtremeSpamThreshold, netTotalSpamThreshold, netShouldBan, warnLog, Webhooker
safeNetMessages, flaggedMessages, netClearTime, netSpamThreshold, netExtremeSpamThreshold, netTotalSpamThreshold, netShouldBan, warnLog, Webhooker = Section580.safeNetMessages, Section580.flaggedMessages, Section580.netClearTime, Section580.netSpamThreshold, Section580.netExtremeSpamThreshold, Section580.netTotalSpamThreshold, Section580.netShouldBan, (function()
  local _base_0 = Section580
  local _fn_0 = _base_0.warnLog
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)(), Section580.Webhooker
Section580.updateNetLocals = function()
  safeNetMessages, flaggedMessages, netClearTime, netSpamThreshold, netExtremeSpamThreshold, netTotalSpamThreshold, netShouldBan = Section580.safeNetMessages, Section580.flaggedMessages, Section580.netClearTime, Section580.netSpamThreshold, Section580.netExtremeSpamThreshold, Section580.netTotalSpamThreshold, Section580.netShouldBan
end
local pendingAction = { }
local netSpam = { }
timer.Create("CFC_Section580_ClearNetCounts", netClearTime, 0, function()
  for steamId, plyInfo in pairs(netSpam) do
    local messages = rawget(plyInfo, "messages")
    for message in pairs(messages) do
      rawset(messages, message, nil)
    end
    rawset(plyInfo, "total", 0)
  end
end)
local setupPlayer
setupPlayer = function(_, steamId)
  rawset(netSpam, steamId, {
    total = 0,
    messages = { }
  })
  return nil
end
hook.Add("NetworkIDValidated", "Section580_SetupPlayer", setupPlayer)
local teardownPlayer
teardownPlayer = function(_, steamId)
  if not (steamId) then
    return 
  end
  rawset(netSpam, steamId, nil)
  return nil
end
gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Section580_TeardownPlayer", teardownPlayer)
local kickReason = "Suspected malicious action"
local boot
boot = function(ply, steamId, ip)
  if not (netShouldBan) then
    return 
  end
  if rawget(pendingAction, ip) then
    return 
  end
  local cleanIP = Left(ip, find(ip, ":", 7, true) - 1)
  ConsoleCommand("addip 10 " .. tostring(cleanIP) .. ";writeip\n")
  warnLog("Booted player: SteamID: " .. tostring(steamId) .. " | IP: " .. tostring(ip), true)
  timerSimple(1, function()
    return ULib.addBan(steamId, 10, kickReason)
  end)
  rawset(pendingAction, ip, true)
  return timerSimple(5, function()
    pendingAction[ip] = nil
  end)
end
local sendAlert
sendAlert = function(steamId, nick, ip, strName, spamCount, severity)
  Section580.Alerter:alertStaff(steamId, nick, strName, severity)
  return Section580.Alerter:alertDiscord(steamId, nick, ip, netSpamThreshold, strName, spamCount)
end
local tallyUsage
tallyUsage = function(message, ply, steamID, nick, ip)
  if rawget(pendingAction, ip) then
    return true
  end
  if rawget(safeNetMessages, message) then
    return 
  end
  local plyInfo = rawget(netSpam, steamID)
  if not plyInfo then
    rawset(netSpam, steamID, {
      total = 0,
      messages = { }
    })
    plyInfo = rawget(netSpam, steamID)
  end
  local messages = rawget(plyInfo, "messages")
  local totalCount = rawget(plyInfo, "total")
  local spamCount = rawget(messages, message)
  local newCount = 1
  if spamCount then
    newCount = spamCount + 1
  end
  spamCount = newCount
  rawset(messages, message, newCount)
  totalCount = totalCount + 1
  rawset(plyInfo, "total", totalCount)
  if spamCount > netExtremeSpamThreshold then
    boot(ply, steamID, ip)
    local alertMessage = "Player spamming a network message! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: '" .. tostring(message) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(netClearTime) .. " seconds)"
    warnLog(alertMessage)
    sendAlert(steamID, nick, ip, message, spamCount, "extreme")
    return true
  end
  if totalCount > netTotalSpamThreshold then
    boot(ply, steamID, ip)
    local alertMessage = "Player spamming large number of network messages! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: " .. tostring(totalCount) .. " messages per " .. tostring(netClearTime) .. " seconds"
    warnLog(alertMessage)
    PrintTable(messages)
    sendAlert(steamID, nick, ip, nil, spamCount, "extreme")
    return true
  end
  if spamCount > netSpamThreshold then
    local alertMessage = "Player likely spamming network messages! " .. tostring(nick) .. " (" .. tostring(steamID) .. ") is spamming: '" .. tostring(message) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(netClearTime) .. " seconds)"
    warnLog(alertMessage)
    Section580.Alerter:alertStaff(steamID, nick, message, "likely")
    return true
  end
end
net.Incoming = function(len, client)
  if not IsValid(client) then
    warnLog("Received net message from an invalid player! Discarding. " .. tostring(client), true)
    return 
  end
  local header = ReadHeader()
  local messageName = NetworkIDToString(header)
  if not (messageName) then
    return 
  end
  if messageName == "nil" then
    warnLog("Invalid network message sent by '" .. tostring(client) .. "': Header: '" .. tostring(header) .. "' | messageName: '" .. tostring(messageName) .. "' | len: '" .. tostring(len) .. "'")
  end
  local lowerName = lower(messageName)
  local steamID = client:SteamID()
  local nick = client:Nick()
  local ip = client:IPAddress()
  local shouldIgnore = tallyUsage(lowerName, client, steamID, nick, ip)
  if shouldIgnore then
    return 
  end
  local func = rawget(rawget(net, "Receivers"), lowerName)
  if not func then
    warnLog("Network message with no receivers sent by " .. tostring(nick) .. " (" .. tostring(steamID) .. ")!: '" .. tostring(messageName) .. "'")
    return 
  end
  len = len - 16
  return func(len, client)
end
