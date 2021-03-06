require "webhooker_interface"
util.AddNetworkString "AlertNetAbuse"

SysTime = SysTime
Webhooker = WebhookerInterface and WebhookerInterface! or { send: () -> "noop" }

RED = Color 255, 0, 0
YELLOW = Color 255, 255, 0

class Alerter
    new: =>
        @shouldWebhook = false
        @shouldAlert =
            "moderator": true
            "developer": true
            "admin": true
            "superadmin": true
            "owner": true

        @staffAlertDelay = 5 -- How many seconds between staff alerts
        @lastStaffAlerts = {} -- Per steamid

    alertDiscord: (steamId, name, ip, timeframe, identifier, count) =>
        return unless @shouldWebhook
        data = :steamId, :name, :ip, :timeframe, :identifier, :count
        Webhooker\send "net-spam", data

    alertStaff: (steamId, name, identifier="<Varied>", certainty) =>
        rightNow = SysTime!
        lastAlerts = rawget self, "lastStaffAlerts"
        lastAlert = rawget lastAlerts, steamId

        if lastAlert
            staffAlertDelay = rawget self, "staffAlertDelay"
            return if rightNow < (lastAlert + staffAlertDelay)

        surrounder = "\n============================================\n"

        message = {
            RED,
            surrounder,
            "Detected #{certainty} net message spam from '#{name}'\n",
            "(message: '#{identifier}')\n",
            YELLOW,
            steamId and "Steam ID: #{steamId}\n" or nil,
            "This player may be using an exploit to lag or crash the server",
            RED,
            surrounder
        }

        message = [line for line in *message when line ~= nil]
        PrintTable message

        staff = [ply for ply in *player.GetAll! when IsValid(ply) and @shouldAlert[ply\GetUserGroup!]]

        if #staff > 0
            net.Start "AlertNetAbuse"
            net.WriteTable message
            net.Send staff

        @lastStaffAlerts[steamId] = rightNow

Alerter!
