--pastebin jZ4mEmny

local monitor = peripheral.find("monitor")
 
monitor.clear()
monitor.setCursorPos(3,1)
monitor.write("World Trade Center Station")
monitor.setCursorPos(1,2)
monitor.write("--------------------------------")
monitor.setCursorPos(3,3)
monitor.write("Red Line to South Shore ->")
monitor.setCursorPos(3,4)
monitor.write("<- Blue Line to Airport")
monitor.setCursorPos(12,5)
while true do
    monitor.write(textutils.formatTime(os.time(), false))
    sleep(1)
    monitor.clearLine()
    monitor.setCursorPos(12,5)
end
