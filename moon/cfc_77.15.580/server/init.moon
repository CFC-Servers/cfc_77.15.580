require "cfclogger"

CurTime = CurTime
Logger = CFCLogger "CFC Section580"

prefix = "cfc_section580"
protected = FCVAR_PROTECTED

netClearTime = CreateConVar "#{prefix}_net_clear_time", 1, protected, "How often to reset net spam budget", 0
netSpamThreshold = CreateConVar "#{prefix}_net_spam_threshold", 1, protected, "Net spam threshold per clear time for a single message", 1
netTotalSpamThreshold = CreateConVar "#{prefix}_total_net_spam_threshold", 1, protected, "Net spam threshold per clear time for all messages", 1
netExtremeSpamThreshold = CreateConVar "#{prefix}_extreme_net_spam_threshold", 1, protected, "Extreme net spam threshold per clear time for a single message (triggers reactions like bans/kicks)", 1
netExtremeSpamBanLength = CreateConVar "#{prefix}_extreme_net_spam_ban_length", 1, protected, "If enabled, how long to ban clients who trigger the extreme net spam threshold", 1
netShouldBan = CreateConVar "#{prefix}_net_should_ban", 1, protected, "Whether or not to ban a client for triggering extreme net spam thresholds", 0, 1

commandClearTime = CreateConVar "#{prefix}_command_clear_time", 1, protected, "How often to reset command spam budget", 0
commandSpamThreshold = CreateConVar "#{prefix}_command_spam_threshold", 1, protected, "Command spam threshold per clear time for a single message", 1
commandTotalSpamThreshold = CreateConVar "#{prefix}_total_command_spam_threshold", 1, protected, "Command spam threshold per clear time for all messages", 1
commandExtremeSpamThreshold = CreateConVar "#{prefix}_extreme_command_spam_threshold", 1, protected, "Extreme command spam threshold per clear time for a single message (triggers reactions like bans/kicks)", 1
commandExtremeSpamBanLength = CreateConVar "#{prefix}_extreme_command_spam_ban_length", 1, protected, "If enabled, how long to ban clients who trigger the extreme net spam threshold", 1
commandShouldBan = CreateConVar "#{prefix}_command_should_ban", 1, protected, "Whether or not to ban a client for triggering extreme command spam thresholds", 0, 1

export Section580 = {
    -- Net spam
    netClearTime: netClearTime\GetFloat!
    netSpamThreshold: netSpamThreshold\GetInt!
    netTotalSpamThreshold: netTotalSpamThreshold\GetInt!
    netExtremeSpamThreshold: netExtremeSpamThreshold\GetInt!
    netExtremeSpamBanLength: netExtremeSpamBanLength\GetInt!
    netShouldBan: netShouldBan\GetBool!
    safeNetMessages:
        simfphys_mousesteer: true -- Called on "StartCommand", sets mousesteer value serverside
        sf_netmessage: true -- Starfall has its own limitations in place, so this should be safe
        pac_projectile_remove_all: -- Gets pretty spammy for some PACs, doesn't seem to be an exploit opportunity

    -- Command spam
    commandClearTime: commandClearTime\GetFloat!
    commandSpamThreshold: commandSpamThreshold\GetInt!
    commandTotalSpamThreshold: commandTotalSpamThreshold\GetInt!
    commandExtremeSpamThreshold: commandExtremeSpamThreshold\GetInt!
    commandExtremeSpamBanLength: commandExtremeSpamBanLength\GetInt!
    commandShouldBan: commandShouldBan\GetBool!
    safeCommands: {}
    flaggedCommands: {}

    -- Connect spam
    connectClearTime: 3 -- In seconds
    connectSpamThreshold: 3 -- Per connectClearTime
    connectSpamBanLength: 5 -- In Minutes
    connectShouldBan: true

    updateLocals: =>
        @netClearTime = netClearTime\GetFloat!
        @netSpamThreshold = netSpamThreshold\GetInt!
        @netTotalSpamThreshold = netTotalSpamThreshold\GetInt!
        @netExtremeSpamThreshold = netExtremeSpamThreshold\GetInt!
        @netExtremeSpamBanLength = netExtremeSpamBanLength\GetInt!
        @netShouldBan = netShouldBan\GetBool!

        @commandClearTime = commandClearTime\GetFloat!
        @commandSpamThreshold = commandSpamThreshold\GetInt!
        @commandTotalSpamThreshold = commandTotalSpamThreshold\GetInt!
        @commandExtremeSpamThreshold = commandExtremeSpamThreshold\GetInt!
        @commandExtremeSpamBanLength = commandExtremeSpamBanLength\GetInt!
        @commandShouldBan = commandShouldBan\GetBool!

        @updateNetLocals!
        @updateCommandLocals!
        @updateConnectLocals!

    warnLogDelay: 0.25 -- In seconds, mandatory delay between logs
    lastWarnLog: 0
    Logger: Logger
    warnLog: (message, forced = false) =>
        rightNow = CurTime!

        if not forced
            return if rightNow < (@lastWarnLog + @warnLogDelay)

        @Logger\warn message
        @lastWarnLog = rightNow

    Alerter: include "alerter.lua"
}

include "net.lua"
include "command.lua"
include "connect.lua"

hook.Add "Think", "Section580_LoadSettings", ->
    hook.Remove "Think", "Section580_LoadSettings"

    Section580\updateLocals!
    nil
