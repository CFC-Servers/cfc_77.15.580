import concat from table
import flaggedMessages,
       cmdClearTime,
       cmdShouldBan,
       cmdSpamThreshold,
       cmdExtremeSpamThreshold,
       cmdSpam,
       Logger,
       Webhooker
       from Section580

originalRun = concommand.Run

concommand.Run = (ply, cmd, args, argStr) ->
    if not IsValid ply
        return originalRun ply, cmd, args, argStr

    if not cmd
        return originalRun ply, cmd, args, argStr

    plySteamID = "<Unknown Steam ID>"
    plyNick = "<Unknown Player Name>"
    plyIP = "<Unknown Player IP>"
    plyIsValid = IsValid ply

    if plyIsValid
        plySteamID = ply\SteamID!
        plyNick = ply\Nick!
        plyIP = ply\IPAddress!

    plyCmdSpam = rawget cmdSpam, plySteamID
    plyCmdSpam or= {}
    plyCmdSpam[strName] or= 0
    plyCmdSpam[strName] += 1

