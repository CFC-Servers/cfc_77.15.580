require "cfclogger"

CurTime = CurTime
Logger = CFCLogger "CFC Section580"

export Section580 = {
    netClearTime: 1 -- In seconds
    netSpamThreshold: 85 -- Per netClearTime
    netExtremeSpamThreshold: 150 -- Per netClearTime
    netExtremeSpamBanLength: 1 -- In Minutes
    netShouldBan: false

    netSpam: {}

    warnLogDelay: 0.25 -- In seconds, mandatory delay between logs
    lastWarnLog: 0
    warnLog: (message, forced = false) =>
        rightNow = CurTime!

        if not forced
            return if rightNow < (@lastWarnLog + @warnLogDelay)

        Logger\warn message
        @lastWarnLog = rightNow

    Alerter: include "alerter.lua"
}

timer.Create "CFC_Section580_ClearNetCounts", Section580.netClearTime, 0, -> Section580.netSpam = {}

include "net.lua"
