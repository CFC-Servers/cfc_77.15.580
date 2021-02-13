require "webhooker_interface"
require "cfclogger"

export Section580 =
    netClearTime = 1 -- In seconds
    netSpamThreshold = 25 -- Per netClearTime
    netExtremeSpamThreshold = 75 -- Per netClearTime
    netExtremeSpamBanLength = 1 -- In Minutes
    netShouldBan = true

    cmdClearTime = 1 -- In seconds
    cmdSpamThreshold = 25 -- Per cmdClearTime
    cmdExtremeSpamThreshold = 75 -- Per cmdClearTime
    cmdExtremeSpamBanLength = 1 -- In Minutes
    cmdShouldBan = true

    netSpam = {}
    cmdSpam = {}

    alertStaff = (message, level="warning") ->
        -- idk do some stuff here

    Webhooker = WebhookerInterface and WebhookerInterface! or { send: () -> "noop" }
    Logger = CFCLogger "CFC_Section580"

timer.Create "CFC_Section580_ClearNetCounts", Section580.netClearTime, 0, -> Section580.netSpam = {}
timer.Create "CFC_Section580_ClearCmdCounts", Section580.cmdClearTime, 0, -> Section580.cmdSpam = {}

include "sv_net.lua"
include "sv_cmd.lua"
