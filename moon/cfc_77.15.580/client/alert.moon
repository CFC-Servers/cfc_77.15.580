import ReadTable from net

net.Receive "AlertNetAbuse", ->
    lines = ReadTable!
    chat.AddText unpack lines
