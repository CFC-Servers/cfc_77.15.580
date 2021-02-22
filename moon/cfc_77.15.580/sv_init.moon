require "cfclogger"

CurTime = CurTime
Logger = CFCLogger "CFC Section580"

export Section580 = {
    netClearTime: 1 -- In seconds
    netSpamThreshold: 35 -- Per netClearTime
    netExtremeSpamThreshold: 100 -- Per netClearTime
    netExtremeSpamBanLength: 1 -- In Minutes
    netShouldBan: false

    cmdClearTime: 1 -- In seconds
    cmdSpamThreshold: 25 -- Per cmdClearTime
    cmdExtremeSpamThreshold: 75 -- Per cmdClearTime
    cmdExtremeSpamBanLength: 1 -- In Minutes
    cmdShouldBan: false

    netSpam: {}
    cmdSpam: {}

    warnLogDelay: 0.25 -- In seconds, mandatory delay between logs
    lastWarnLog: 0
    warnLog: (message, forced = false) =>
        rightNow = CurTime!

        if not forced
            return if rightNow < (@lastWarnLog + @warnLogDelay)

        Logger\warn message
        @lastWarnLog = rightNow

    Alerter: include "sv_alerter.lua"
}

timer.Create "CFC_Section580_ClearNetCounts", Section580.netClearTime, 0, -> Section580.netSpam = {}
timer.Create "CFC_Section580_ClearCmdCounts", Section580.cmdClearTime, 0, -> Section580.cmdSpam = {}

include "sv_net.lua"
