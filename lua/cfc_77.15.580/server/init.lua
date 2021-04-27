require("cfclogger")
local CurTime = CurTime
local Logger = CFCLogger("CFC Section580")
local prefix = "cfc_section580"
local protected = FCVAR_PROTECTED
local netClearTime = CreateConVar(tostring(prefix) .. "_net_clear_time", 1, protected, "How often to reset net spam budget", 0)
local netSpamThreshold = CreateConVar(tostring(prefix) .. "_net_spam_threshold", 1, protected, "Net spam threshold per clear time for a single message", 1)
local netTotalSpamThreshold = CreateConVar(tostring(prefix) .. "_total_net_spam_threshold", 1, protected, "Net spam threshold per clear time for all messages", 1)
local netExtremeSpamThreshold = CreateConVar(tostring(prefix) .. "_extreme_net_spam_threshold", 1, protected, "Extreme net spam threshold per clear time for a single message (triggers reactions like bans/kicks)", 1)
local netExtremeSpamBanLength = CreateConVar(tostring(prefix) .. "_extreme_net_spam_ban_length", 1, protected, "If enabled, how long to ban clients who trigger the extreme net spam threshold", 1)
local netShouldBan = CreateConVar(tostring(prefix) .. "_should_ban", 1, protected, "Whether or not to ban a client for triggering extreme spam thresholds", 0, 1)
Section580 = {
  netClearTime = netClearTime:GetFloat(),
  netSpamThreshold = netSpamThreshold:GetInt(),
  netTotalSpamThreshold = netTotalSpamThreshold:GetInt(),
  netExtremeSpamThreshold = netExtremeSpamThreshold:GetInt(),
  netExtremeSpamBanLength = netExtremeSpamBanLength:GetInt(),
  netShouldBan = netShouldBan:GetBool(),
  safeNetMessages = {
    simfphys_mousesteer = true,
    sf_netmessage = true
  },
  connectClearTime = 3,
  connectSpamThreshold = 3,
  connectSpamBanLength = 5,
  connectShouldBan = true,
  updateLocals = function(self)
    self.netClearTime = netClearTime:GetFloat()
    self.netSpamThreshold = netSpamThreshold:GetInt()
    self.netTotalSpamThreshold = netTotalSpamThreshold:GetInt()
    self.netExtremeSpamThreshold = netExtremeSpamThreshold:GetInt()
    self.netExtremeSpamBanLength = netExtremeSpamBanLength:GetInt()
    self.netShouldBan = netShouldBan:GetBool()
    self:updateConnectLocals()
    return self:updateNetLocals()
  end,
  warnLogDelay = 0.25,
  lastWarnLog = 0,
  Logger = Logger,
  warnLog = function(self, message, forced)
    if forced == nil then
      forced = false
    end
    local rightNow = CurTime()
    if not forced then
      if rightNow < (self.lastWarnLog + self.warnLogDelay) then
        return 
      end
    end
    self.Logger:warn(message)
    self.lastWarnLog = rightNow
  end,
  Alerter = include("alerter.lua")
}
include("net.lua")
include("connect.lua")
return hook.Add("Think", "Section580_LoadSettings", function()
  hook.Remove("Think", "Section580_LoadSettings")
  Section580:updateLocals()
  return nil
end)
