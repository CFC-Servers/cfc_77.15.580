if SERVER then
  AddCSLuaFile("cfc_77.15.580/client/init.lua")
  AddCSLuaFile("cfc_77.15.580/client/alert.lua")
  return include("cfc_77.15.580/server/init.lua")
else
  return include("cfc_77.15.580/client/init.lua")
end
