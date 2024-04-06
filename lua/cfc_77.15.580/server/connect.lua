local ConsoleCommand
ConsoleCommand = game.ConsoleCommand
local connectClearTime, connectSpamThreshold, connectShouldBan, connectSpamBanLength, warnLog
connectClearTime, connectSpamThreshold, connectShouldBan, connectSpamBanLength, warnLog = Section580.connectClearTime, Section580.connectSpamThreshold, Section580.connectShouldBan, Section580.connectSpamBanLength, (function()
  local _base_0 = Section580
  local _fn_0 = _base_0.warnLog
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)()
Section580.updateConnectLocals = function()
  connectClearTime, connectSpamThreshold, connectShouldBan, connectSpamBanLength = Section580.connectClearTime, Section580.connectSpamThreshold, Section580.connectShouldBan, Section580.connectSpamBanLength
end
local connectSpam = { }
timer.Create("CFC_Section580_ClearConnectCounts", connectClearTime, 0, function()
  for k in pairs(connectSpam) do
    rawset(connectSpam, k, nil)
  end
end)
return hook.Add("PlayerConnect", "Section580_ConnectionThrottle", function(name, ip)
  local newAmount = 1
  local connectAmount = rawget(connectSpam, ip)
  if connectAmount then
    newAmount = connectAmount + 1
  end
  rawset(connectSpam, ip, newAmount)
  if not (newAmount > connectSpamThreshold) then
    return 
  end
  if not (shouldBan) then
    return 
  end
  ConsoleCommand("addip " .. tostring(connectSpamBanLength) .. " " .. tostring(ip) .. "\n")
  return warnLog("Spam connections from IP: " .. tostring(ip) .. " - Banning: " .. tostring(connectShouldBan), true)
end)
