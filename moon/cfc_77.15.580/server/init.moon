require "cfclogger"

CurTime = CurTime
Logger = CFCLogger "CFC Section580"

export Section580 = {
    -- Net spam
    netClearTime: 1 -- In seconds
    netSpamThreshold: 150 -- Per netClearTime
    netTotalSpamThreshold: 500 -- Per netClearTime
    netExtremeSpamThreshold: 300 -- Per netClearTime
    netExtremeSpamBanLength: 1 -- In Minutes
    netShouldBan: true
    netSpam: {}
    safeNetMessages:
        simfphys_mousesteer: true -- Called on "StartCommand", sets mousesteer value serverside

    -- Connect spam
    connectClearTime: 3 -- In seconds
    connectSpamThreshold: 3 -- Per connectClearTime
    connectSpamBanLength: 5 -- In Minutes
    connectShouldBan: true
    connectSpam: {}

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

timer.Create "CFC_Section580_ClearNetCounts", Section580.netClearTime, 0, -> Section580.netSpam = {}
timer.Create "CFC_Section580_ClearConnectCounts", Section580.connectClearTime, 0, -> Section580.connectSpam = {}

include "net.lua"
include "connect.lua"
