require("logger")
local CurTime = CurTime
local Logger = Logger("CFC Section580")
local prefix = "cfc_section580"
local protected = FCVAR_PROTECTED
local netClearTime = CreateConVar(tostring(prefix) .. "_net_clear_time", 1, protected, "How often to reset net spam budget", 0)
local netSpamThreshold = CreateConVar(tostring(prefix) .. "_net_spam_threshold", 1, protected, "Net spam threshold per clear time for a single message", 1)
local netTotalSpamThreshold = CreateConVar(tostring(prefix) .. "_total_net_spam_threshold", 1, protected, "Net spam threshold per clear time for all messages", 1)
local netExtremeSpamThreshold = CreateConVar(tostring(prefix) .. "_extreme_net_spam_threshold", 1, protected, "Extreme net spam threshold per clear time for a single message (triggers reactions like bans/kicks)", 1)
local netExtremeSpamBanLength = CreateConVar(tostring(prefix) .. "_extreme_net_spam_ban_length", 1, protected, "If enabled, how long to ban clients who trigger the extreme net spam threshold", 1)
local netShouldBan = CreateConVar(tostring(prefix) .. "_net_should_ban", 0, protected, "Whether or not to ban a client for triggering extreme net spam thresholds", 0, 1)
local commandClearTime = CreateConVar(tostring(prefix) .. "_command_clear_time", 1, protected, "How often to reset command spam budget", 0)
local commandSpamThreshold = CreateConVar(tostring(prefix) .. "_command_spam_threshold", 1, protected, "Command spam threshold per clear time for a single message", 1)
local commandTotalSpamThreshold = CreateConVar(tostring(prefix) .. "_total_command_spam_threshold", 1, protected, "Command spam threshold per clear time for all messages", 1)
local commandExtremeSpamThreshold = CreateConVar(tostring(prefix) .. "_extreme_command_spam_threshold", 1, protected, "Extreme command spam threshold per clear time for a single message (triggers reactions like bans/kicks)", 1)
local commandExtremeSpamBanLength = CreateConVar(tostring(prefix) .. "_extreme_command_spam_ban_length", 1, protected, "If enabled, how long to ban clients who trigger the extreme net spam threshold", 1)
local commandShouldBan = CreateConVar(tostring(prefix) .. "_command_should_ban", 0, protected, "Whether or not to ban a client for triggering extreme command spam thresholds", 0, 1)
Section580 = {
  netClearTime = netClearTime:GetFloat(),
  netSpamThreshold = netSpamThreshold:GetInt(),
  netTotalSpamThreshold = netTotalSpamThreshold:GetInt(),
  netExtremeSpamThreshold = netExtremeSpamThreshold:GetInt(),
  netExtremeSpamBanLength = netExtremeSpamBanLength:GetInt(),
  netShouldBan = netShouldBan:GetBool(),
  safeNetMessages = {
    simfphys_mousesteer = true,
    sf_netmessage = true,
    pac_projectile_remove_all = true,
    pac_entity_mutator = true,
    prop2mesh_sync = true
  },
  commandClearTime = commandClearTime:GetFloat(),
  commandSpamThreshold = commandSpamThreshold:GetInt(),
  commandTotalSpamThreshold = commandTotalSpamThreshold:GetInt(),
  commandExtremeSpamThreshold = commandExtremeSpamThreshold:GetInt(),
  commandExtremeSpamBanLength = commandExtremeSpamBanLength:GetInt(),
  commandShouldBan = commandShouldBan:GetBool(),
  safeCommands = { },
  flaggedCommands = { },
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
    self.commandClearTime = commandClearTime:GetFloat()
    self.commandSpamThreshold = commandSpamThreshold:GetInt()
    self.commandTotalSpamThreshold = commandTotalSpamThreshold:GetInt()
    self.commandExtremeSpamThreshold = commandExtremeSpamThreshold:GetInt()
    self.commandExtremeSpamBanLength = commandExtremeSpamBanLength:GetInt()
    self.commandShouldBan = commandShouldBan:GetBool()
    self:updateNetLocals()
    self:updateCommandLocals()
    return self:updateConnectLocals()
  end,
  warnLogDelay = engine.TickInterval() * 3,
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
include("command.lua")
include("connect.lua")
return hook.Add("Think", "Section580_LoadSettings", function()
  hook.Remove("Think", "Section580_LoadSettings")
  Section580:updateLocals()
  return nil
end)
