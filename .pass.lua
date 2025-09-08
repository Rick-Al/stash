local speaker = peripheral.find("speaker")

speaker.playNote("bit", 1, 24)

term.setCursorPos(1,1)
term.clear()
textutils.slowPrint("Federal Bureau of Control")
textutils.slowPrint("Facility Access Terminal")
print("")
write("Access Code: ")

input = read("*")

    if input == "1234" then
        term.clear()
        term.setCursorPos(1,1)
        print("Access Granted")
        speaker.playNote("bit", 3, 12)
        redstone.setOutput("left", true)
        sleep(3)
        redstone.setOutput("left", false)
        speaker.playNote("bit", 3, 1)
        os.reboot()
    else
        term.clear()
        term.setCursorPos(1,1)
        print("Access Denied")
        speaker.playNote("bit", 3, 1)
        sleep(0.3)
        speaker.playNote("bit", 3, 1)
        sleep(1)
        os.reboot()
    end
