gameevent.Listen "player_connect"

hook.Add "player_connect", "Section580_ConnectionThrottle", (data) ->
    { :networkid, :userid, :name } = data

    Section580.connectSpam[networkid] or= 0
    Section580.connectSpam[networkid] += 1

    if Section580.connectSpam[networkid] > Section580.connectSpamThreshold
        reason = Section580.connectSpamBanReason

        game.KickID userid, reason

        return unless Section580.connectShouldBan

        error "Can't ban: '#{networkid}' for '#{reason}' because ULib doesn't exist!" unless ULib

        banLength = Section580.connectSpamBanLength
        ULib.addBan networkid, banLength, reason, name, "Fishing Regulation"
