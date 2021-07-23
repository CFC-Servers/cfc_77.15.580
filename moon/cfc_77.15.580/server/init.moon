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
netShouldBan = CreateConVar "#{prefix}_should_ban", 1, protected, "Whether or not to ban a client for triggering extreme spam thresholds", 0, 1

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

        @updateConnectLocals!
        @updateNetLocals!

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
include "connect.lua"

hook.Add "Think", "Section580_LoadSettings", ->
    hook.Remove "Think", "Section580_LoadSettings"

    Section580\updateLocals!
    nil
