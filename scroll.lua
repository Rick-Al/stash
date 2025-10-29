-- pastebin 51u17dkr

local mon = peripheral.find("monitor")
local monWidth, monHeight = mon.getSize()
local pos = monWidth

local text = "Welcome to World Trade Center Station"

mon.clear()
mon.setTextScale(3)
 
while true do
    mon.clear()
    mon.setCursorPos(pos, 1)
    mon.write(text)
    pos = pos - 1
    
    if pos + #text < 0 then
        pos = monWidth
    end
    
    sleep(0.2)
end
