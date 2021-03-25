import \warnLog from Section580

hook.Add "PlayerConnect", "Section580_ConnectionThrottle", (name, ip) ->
    Section580.connectSpam[ip] or= 0
    Section580.connectSpam[ip] += 1

    if Section580.connectSpam[ip] > Section580.connectSpamThreshold
        shouldBan = Section580.connectShouldBan

        warnLog "Spam connections from IP: #{ip} - Banning: #{shouldBan}", true
        return unless shouldBan

        banLength = Section580.connectSpamBanLength
        RunConsoleCommand "addip", banLength, ip
