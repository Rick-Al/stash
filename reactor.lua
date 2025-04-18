-- Set up the peripherals
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0") -- Change to your reactor's peripheral name
local speaker = peripheral.find("speaker") -- Auto-find attached speaker
local autoScramTriggered = false  -- Flag to track if SCRAM has been triggered
local actionMessage = ""  -- Holds the action message to display

-- Function to format percentage
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

-- Function to play alarm
local function playAlarm()
    if speaker then
        speaker.playNote("harp", 3, 5)  -- A continuous alarm beep
    end
end

-- Function to blink warning and stop when acknowledged
local function blinkWarning()
    local blink = true
    while autoScramTriggered do
        term.setCursorPos(1, 16)
        if blink then
            term.clearLine()
            io.write("⚠️ EMERGENCY SCRAM ⚠️")
        else
            term.clearLine()
        end
        blink = not blink  -- Toggle visibility of the warning
        sleep(0.5)  -- Blink every half second
    end
end

-- Add an acknowledge function
local function waitForAcknowledge()
    term.setCursorPos(1, 16) -- Move to the bottom
    while true do
        io.write("Press any key to acknowledge and stop alarm... > ")
        local input = read()
        if input then
            -- Acknowledge and stop alarm
            autoScramTriggered = false
            return
        end
    end
end

-- Function to display the menu and take user input
local function showMenu()
    while true do
        term.setCursorPos(1, 1)
        term.clear()
        print("=== Reactor Control Panel ===")

        local status = reactor.getStatus()
        local fuelRaw = reactor.getFuelFilledPercentage()
        local coolantRaw = reactor.getCoolantFilledPercentage()
        local heatedCoolantRaw = reactor.getHeatedCoolantFilledPercentage()
        local wasteRaw = reactor.getWasteFilledPercentage()
        local damageRaw = reactor.getDamagePercent()
        local temperature = string.format("%.2f K", reactor.getTemperature())

        local fuel = toPercent(fuelRaw)
        local coolant = toPercent(coolantRaw)
        local heatedCoolant = toPercent(heatedCoolantRaw)
        local waste = toPercent(wasteRaw)
        local damage = string.format("%.1f%%", damageRaw)

        -- Print status
        print("Status: " .. (status and "RUNNING" or "SHUT DOWN"))
        print("Fuel Level: " .. fuel)
        print("Coolant Level: " .. coolant)
        print("Heated Coolant: " .. heatedCoolant)
        print("Waste Level: " .. waste)
        print("Damage: " .. damage)
        print("Temperature: " .. temperature)
        print("-----------------------------")
        print("1. Activate Reactor")
        print("2. Scram (Shutdown)")
        print("3. Exit")
        print("-----------------------------")
        print(actionMessage)
        io.write("> ")

        -- User input handling (check for input every loop)
        local input = read(nil, false)

        if input == "1" then
            reactor.activate()
            actionMessage = "Reactor Activated."
        elseif input == "2" then
            reactor.scram()
            actionMessage = "Reactor SCRAMMED."
        elseif input == "3" then
            break  -- Exit the loop
        end

        sleep(0.1)  -- Small delay before next loop iteration
    end
end

-- Main status loop
local function statusLoop()
    while true do
        local status = reactor.getStatus()
        local fuelRaw = reactor.getFuelFilledPercentage()
        local coolantRaw = reactor.getCoolantFilledPercentage()
        local heatedCoolantRaw = reactor.getHeatedCoolantFilledPercentage()
        local wasteRaw = reactor.getWasteFilledPercentage()
        local damageRaw = reactor.getDamagePercent()

        -- Safety checks (only if running and not already triggered)
        if status and not autoScramTriggered then
            if damageRaw > 100 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠️ CRITICAL DAMAGE (" .. damageRaw .. "%)! AUTO-SCRAM."
            elseif wasteRaw > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠️ WASTE OVERFLOW (" .. wasteRaw .. ")! AUTO-SCRAM."
            elseif coolantRaw < 0.10 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠️ LOW COOLANT (" .. coolantRaw .. ")! AUTO-SCRAM."
            elseif heatedCoolantRaw > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠️ HEATED COOLANT OVERFLOW (" .. heatedCoolantRaw .. ")! AUTO-SCRAM."
            end
        end

        -- Fuel warning (but doesn't trigger SCRAM)
        if fuelRaw < 0.05 then
            actionMessage = "⚠️ WARNING: Fuel critically low (" .. fuelRaw * 100 .. "%)!"
        end

        sleep(1)  -- Check status every second
    end
end

-- Run both the status check and menu in parallel
parallel.waitForAny(statusLoop, showMenu)
