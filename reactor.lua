-- Function to blink warning and stop when acknowledged
local function blinkWarning()
    local blink = true
    while autoScramTriggered do
        term.setCursorPos(1, 16)
        if blink then
            term.clearLine()
            io.write("⚠ EMERGENCY SCRAM ⚠")
        else
            term.clearLine()
        end
        blink = not blink  -- Toggle visibility of the warning
        sleep(0.5)  -- Blink every half second
    end
end

-- Add an acknowledge function to stop the alarm and blinking
local function waitForAcknowledge()
    term.setCursorPos(1, 16) -- Move to the bottom
    while true do
        io.write("Press any key to acknowledge and stop alarm... > ")
        local input = read()  -- Wait for user input
        if input then
            -- Acknowledge and stop alarm
            autoScramTriggered = false  -- Stop blinking and alarm
            term.clearLine()  -- Clear the warning
            return  -- Exit the loop
        end
    end
end

-- Function to play alarm
local function playAlarm()
    if speaker then
        speaker.playNote("harp", 3, 5)  -- A continuous alarm beep
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
                actionMessage = "⚠ CRITICAL DAMAGE (" .. damageRaw .. "%)! AUTO-SCRAM."
            elseif wasteRaw > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠ WASTE OVERFLOW (" .. wasteRaw .. ")! AUTO-SCRAM."
            elseif coolantRaw < 0.10 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠ LOW COOLANT (" .. coolantRaw .. ")! AUTO-SCRAM."
            elseif heatedCoolantRaw > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                playAlarm()  -- Start alarm
                blinkWarning()  -- Start blinking warning
                actionMessage = "⚠ HEATED COOLANT OVERFLOW (" .. heatedCoolantRaw .. ")! AUTO-SCRAM."
            end
        end

        -- Fuel warning (but doesn't trigger SCRAM)
        if fuelRaw < 0.05 then
            actionMessage = "⚠ WARNING: Fuel critically low (" .. fuelRaw * 100 .. "%)!"
        end

        sleep(1)  -- Check status every second
    end
end

-- Run both the status check and menu in parallel
parallel.waitForAny(statusLoop, showMenu)
