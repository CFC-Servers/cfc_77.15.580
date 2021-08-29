-- All convars prefixed with "cfc_section580_"
prefix = "cfc_section580"
protected = FCVAR_PROTECTED

INT = "int" -- Default
BOOL = "bool"
FLOAT = "float"

convars = {
    net_clear_time:
        type: FLOAT
        help: "How often to reset net spam budget"

    net_spam_threshold:
        help: "Net spam threshold per clear time for a single message"

    net_total_spam_threshold:
        help: "Net spam threshold per clear time for all messages"

    net_extreme_spam_threshold:
        help: "Extreme net spam threshold per clear time for a single message (triggers reactions like bans/kicks)"

    net_extreme_spam_ban_length:
        help: "If enabled, how long to ban clients who trigger the extreme net spam threshold (in minutes)"

    net_should_ban:
        type: BOOL
        help: "Whether or not to ban a client for triggering extreme net spam thresholds"

    command_clear_time:
        type: FLOAT
        help: "How often to reset command spam budget"

    command_spam_threshold:
        help: "Command spam threshold per clear time for a single commands"

    command_total_spam_threshold:
        help: "Command spam threshold per clear time for all commands"

    command_extreme_spam_threshold:
        help: "Extreme command spam threshold per clear time for a single command (triggers reactions like bans/kicks)"

    command_extreme_spam_ban_length:
        help: "If enabled, how long to ban clients who trigger the extreme command spam threshold (in minutes)"

    command_should_ban:
        type: BOOL
        help: "Whether or not to ban a client for triggering extreme command spam thresholds"

}

lookupMap =
    [INT]: "GetInt"
    [BOOL]: "GetBool"
    [FLOAT]: "GetFloat"

convarLookup = {}
defaultDefault = 1

for name, data in pairs convars
    local type

    :type, :help, :min, :max = data
    type or= INT
    fullName = "#{prefix}_#{name}"

    convar = CreateConVar fullName, defaultDefault, protected, help, min, max
    lookup = -> convar[lookupMap[type]] convar
    convarLookup[name] = lookup

    AddChangeCallback fullName, Section580\updateLocals

return convarLookup

