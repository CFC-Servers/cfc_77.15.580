import ReadTable from net

net.Receive "AlertNetSpam", ->
    lines = ReadTable!
    chat.AddText unpack lines
