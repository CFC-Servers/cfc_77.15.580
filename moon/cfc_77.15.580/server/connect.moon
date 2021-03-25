gameevent.Listen "player_connect"

hook.Add "player_connect", "Section580_ConnectionThrottle", (data) ->
    { :networkid, :userid, :name } = data

    connections = Section580.connectSpam[networkid]

    if not connections
        Section580.connectSpam[networkid] = 1
        return

    Section580.connectSpam[networkid] += 1

    if Section580.connectSpam[networkid] > Section580.connectSpamThreshold
        reason = "Too many connnections"

        game.KickID userid, reason

        return unless Section580.connectShouldBan

        -- FIXME: Expect ULib at this point

        banLength = Section580.connectSpamBanLength
        ULib.addBan networkid, banLength, reason, name, "Fishing Regulation"
