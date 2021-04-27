local ReadHeader
ReadHeader = net.ReadHeader
local NetworkIDToString
NetworkIDToString = util.NetworkIDToString
local lower
lower = string.lower
local rawget = rawget
local pcall = pcall
rawget = rawget
local rawset = rawset
local pairs = pairs
local IsValid = IsValid
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
local bootPlayer
bootPlayer = function(ply)
  local kickReason = "Suspected malicious action"
  if not (netShouldBan) then
    return 
  end
  if not (IsValid(ply)) then
    return 
  end
  if ply:IsAdmin() then
    return 
  end
  if ply.Section580PendingAction then
    return 
  end
  ply.Section580PendingAction = true
  if ULib then
    return ULib.ban(ply, 1, kickReason)
  else
    return ply:Kick(kickReason)
  end
end
local sendAlert
sendAlert = function(steamId, nick, ip, strName, spamCount, severity)
  Section580.Alerter:alertStaff(steamId, nick, strName, severity)
  return Section580.Alerter:alertDiscord(steamId, nick, ip, netSpamThreshold, strName, spamCount)
end
local tallyUsage
tallyUsage = function(message, ply, plySteamId, plyNick, plyIP)
  if rawget(safeNetMessages, message) then
    return 
  end
  if IsValid(ply) and ply:IsAdmin() then
    return 
  end
  local plyInfo = rawget(netSpam, plySteamId)
  if not plyInfo then
    rawset(netSpam, plySteamId, {
      total = 0,
      messages = { }
    })
    plyInfo = rawget(netSpam, plySteamId)
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
    local alertMessage = "Player spamming a network message! " .. tostring(plyNick) .. " (" .. tostring(plySteamId) .. ") is spamming: '" .. tostring(message) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(netClearTime) .. " seconds)"
    warnLog(alertMessage, true)
    sendAlert(plySteamId, plyNick, plyIP, message, spamCount, "extreme")
    bootPlayer(ply)
    return true
  end
  if totalCount > netTotalSpamThreshold then
    local alertMessage = "Player spamming large number of network messages! " .. tostring(plyNick) .. " (" .. tostring(plySteamId) .. ") is spamming: " .. tostring(totalCount) .. " messages per " .. tostring(netClearTime) .. " seconds"
    warnLog(alertMessage, true)
    PrintTable(messages)
    sendAlert(plySteamId, plyNick, plyIP, nil, spamCount, "extreme")
    bootPlayer(ply)
    return true
  end
  if spamCount > netSpamThreshold then
    local alertMessage = "Player likely spamming network messages! " .. tostring(plyNick) .. " (" .. tostring(plySteamId) .. ") is spamming: '" .. tostring(message) .. "' (Count: " .. tostring(spamCount) .. " per " .. tostring(netClearTime) .. " seconds)"
    warnLog(alertMessage)
    Section580.Alerter:alertStaff(plySteamId, plyNick, message, "likely")
    return true
  end
end
net.Incoming = function(len, client)
  local header = ReadHeader()
  local strName = NetworkIDToString(header)
  if not (strName) then
    return 
  end
  if strName == "nil" then
    warnLog("Invalid network message sent by '" .. tostring(client) .. "': Header: '" .. tostring(header) .. "' | strName: '" .. tostring(strName) .. "' | len: '" .. tostring(len) .. "'")
  end
  local lowerStr = lower(strName)
  local plySteamId = "<Unknown Steam ID>"
  local plyNick = "<Unknown Player Name>"
  local plyIP = "<Unknown Player IP>"
  local plyIsValid = IsValid(client)
  if plyIsValid then
    plySteamId = client:SteamID()
    plyNick = client:Nick()
    plyIP = client:IPAddress()
  end
  local shouldIgnore = tallyUsage(lowerStr, client, plySteamId, plyNick, plyIP)
  if shouldIgnore then
    return 
  end
  local func = rawget(rawget(net, "Receivers"), lowerStr)
  if not func then
    warnLog("Network message with no receivers sent by " .. tostring(plyNick) .. " (" .. tostring(plySteamId) .. ")!: '" .. tostring(strName) .. "'")
    return 
  end
  len = len - 16
  return func(len, client)
end
