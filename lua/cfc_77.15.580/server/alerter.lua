require("webhooker_interface")
util.AddNetworkString("AlertNetAbuse")
local SysTime = SysTime
local Webhooker = WebhookerInterface and WebhookerInterface() or {
  send = function()
    return "noop"
  end
}
local RED = Color(255, 0, 0)
local YELLOW = Color(255, 255, 0)
local Alerter
do
  local _class_0
  local _base_0 = {
    alertDiscord = function(self, steamId, name, ip, timeframe, identifier, count)
      if not (self.shouldWebhook) then
        return 
      end
      local data = {
        steamId = steamId,
        name = name,
        ip = ip,
        timeframe = timeframe,
        identifier = identifier,
        count = count
      }
      return Webhooker:send("net-spam", data)
    end,
    alertStaff = function(self, steamId, name, identifier, certainty)
      if identifier == nil then
        identifier = "<Varied>"
      end
      local rightNow = SysTime()
      local lastAlerts = rawget(self, "lastStaffAlerts")
      local lastAlert = rawget(lastAlerts, steamId)
      if lastAlert then
        local staffAlertDelay = rawget(self, "staffAlertDelay")
        if rightNow < (lastAlert + staffAlertDelay) then
          return 
        end
      end
      local surrounder = "\n============================================\n"
      local message = {
        RED,
        surrounder,
        "Detected " .. tostring(certainty) .. " net message spam from '" .. tostring(name) .. "'\n",
        "(message: '" .. tostring(identifier) .. "')\n",
        YELLOW,
        steamId and "Steam ID: " .. tostring(steamId) .. "\n" or nil,
        "This player may be using an exploit to lag or crash the server",
        RED,
        surrounder
      }
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #message do
          local line = message[_index_0]
          if line ~= nil then
            _accum_0[_len_0] = line
            _len_0 = _len_0 + 1
          end
        end
        message = _accum_0
      end
      PrintTable(message)
      local staff
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = player.GetAll()
        for _index_0 = 1, #_list_0 do
          local ply = _list_0[_index_0]
          if IsValid(ply) and self.shouldAlert[ply:GetUserGroup()] then
            _accum_0[_len_0] = ply
            _len_0 = _len_0 + 1
          end
        end
        staff = _accum_0
      end
      if #staff > 0 then
        net.Start("AlertNetAbuse")
        net.WriteTable(message)
        net.Send(staff)
      end
      self.lastStaffAlerts[steamId] = rightNow
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.shouldWebhook = false
      self.shouldAlert = {
        ["moderator"] = true,
        ["developer"] = true,
        ["admin"] = true,
        ["superadmin"] = true,
        ["owner"] = true
      }
      self.staffAlertDelay = 5
      self.lastStaffAlerts = { }
    end,
    __base = _base_0,
    __name = "Alerter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Alerter = _class_0
end
return Alerter()
