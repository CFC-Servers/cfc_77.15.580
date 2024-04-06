local ReadTable
ReadTable = net.ReadTable
return net.Receive("AlertNetAbuse", function()
  local lines = ReadTable()
  return chat.AddText(unpack(lines))
end)
