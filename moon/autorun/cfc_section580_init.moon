if SERVER
    AddCSLuaFile "cfc_77.15.580/client/init.lua"
    AddCSLuaFile "cfc_77.15.580/client/alert.lua"
    include "cfc_77.15.580/server/init.lua"
    include "cfc_77.15.580/server/connect.lua"
else
    include "cfc_77.15.580/client/init.lua"
