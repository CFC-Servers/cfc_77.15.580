require "logger"

CurTime = CurTime
Log = Logger "CFC Section580"

export Section580 = {
    config: include "convars.lua"

    -- Always processed
    netWhitelist:
        -- Starfall has its own limitations in place, so this should be safe
        sf_netmessage: true

        -- Gets pretty spammy for some PACs, doesn't seem to be an exploit opportunity
        pac_projectile_remove_all: true

    -- Always ignored
    netBlacklist: {}

    -- Method 1:
    -- <message>: <number of ticks between messages per-player>
    --
    -- Method 2:
    -- <message>:
    --     bucket:
    --         max: <how much the bucket can hold>
    --         refill:
    --           interval: <how often to refill the bucket, in ticks>
    --           amount: <how much to refill the bucket with each interval>
    netThrottles:
        -- Called on "StartCommand", sets mousesteer value serverside
        simfphys_mousesteer: 2

    connectClearTime: 3 -- In seconds
    connectSpamThreshold: 3 -- Per connectClearTime
    connectSpamBanLength: 5 -- In Minutes
    connectShouldBan: true

    updateLocals: =>
        @netClearTime = @config.net_clear_time!
        @netSpamThreshold = @config.net_spam_threshold!
        @netTotalSpamThreshold = @config.net_total_spam_threshold!
        @netExtremeSpamThreshold = @config.net_extreme_spam_threshold!
        @netExtremeSpamBanLength = @config.net_extreme_spam_ban_length!
        @netShouldBan = @config.net_should_ban!

        @commandClearTime = @config.command_clear_time!
        @commandSpamThreshold = @cconfig.command_spam_threshold!
        @commandTotalSpamThreshold = @config.command_total_spam_threshold!
        @commandExtremeSpamThreshold = @config.command_extreme_spam_threshold!
        @commandExtremeSpamBanLength = @config.command_extreme_spam_ban_length!
        @commandShouldBan = @config.command_should_ban!

        @updateNetLocals!
        @updateCommandLocals!
        @updateConnectLocals!

    warnLogDelay: 0.25 -- In seconds, mandatory delay between logs
    lastWarnLog: 0
    logger: Log
    warnLog: (message, forced = false) =>
        rightNow = CurTime!

        if not forced
            return if rightNow < (@lastWarnLog + @warnLogDelay)

        @Log\warn message
        @lastWarnLog = rightNow

    Alerter: include "alerter.lua"
}

include "bucket.lua"
include "net.lua"
include "command.lua"
include "connect.lua"

hook.Add "Think", "Section580_LoadSettings", ->
    hook.Remove "Think", "Section580_LoadSettings"

    Section580\updateLocals!
    nil
