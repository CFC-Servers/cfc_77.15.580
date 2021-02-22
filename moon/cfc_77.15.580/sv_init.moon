require "webhooker_interface"
require "cfclogger"

CurTime = CurTime

export Section580 = {
    netClearTime: 1 -- In seconds
    netSpamThreshold: 25 -- Per netClearTime
    netExtremeSpamThreshold: 75 -- Per netClearTime
    netExtremeSpamBanLength: 1 -- In Minutes
    netShouldBan: true

    cmdClearTime: 1 -- In seconds
    cmdSpamThreshold: 25 -- Per cmdClearTime
    cmdExtremeSpamThreshold: 75 -- Per cmdClearTime
    cmdExtremeSpamBanLength: 1 -- In Minutes
    cmdShouldBan: true

    netSpam: {}
    cmdSpam: {}

    warnLogDelay: 0.25 -- In seconds, mandatory delay between logs
    lastWarnLog: 0
    warnLog: (message, forced = false) =>
        rightNow = CurTime!

        if not forced
            if rightNow < @lastWarnLog + @warnLogDelay
                return

        @Logger\warn message
        @lastWarnLog = rightNow

    Webhooker: WebhookerInterface and WebhookerInterface! or { send: () -> "noop" }
    Logger: CFCLogger "CFC_Section580"
    Alerter: include "sv_alerter.lua"
}

timer.Create "CFC_Section580_ClearNetCounts", Section580.netClearTime, 0, -> Section580.netSpam = {}
timer.Create "CFC_Section580_ClearCmdCounts", Section580.cmdClearTime, 0, -> Section580.cmdSpam = {}

include "sv_net.lua"
