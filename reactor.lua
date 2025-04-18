-- Peripheral setup
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")
local speaker = peripheral.find("speaker")
local autoScramTriggered = false
local actionMessage = ""
local menuSelection = 0

-- Helper functions
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

local function isReactorSafeToStart()
    return reactor.getDamagePercent() <= 100
       and reactor.getCoolantFilledPercentage() >= 0.10
       and reactor.getHeatedCoolantFilledPercentage() <= 0.95
       and reactor.getWasteFilledPercentage() <= 0.95
end

-- Draw UI without clearing everything
local function drawUI()
    term.setCursorPos(1, 1)
    term.clear()
    print("=== Reactor Control Panel ===")

    local status = reactor.getStatus()
    local fuel = toPercent(reactor.getFuelFilledPercentage())
    local coolant = toPercent(reactor.getCoolantFilledPercentage())
    local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
    local waste = toPercent(reactor.getWasteFilledPercentage())
    local damage = string.format("%.1f%%", reactor.getDamagePercent())
    local temp = string.format("%.2f K", reactor.getTemperature())

    print("Status: " .. (status and "RUNNING" or "SHUT DOWN"))
    print("Fuel Level: " .. fuel)
    print("Coolant Level: " .. coolant)
    print("Heated Coolant: " .. heated)
    print("Waste Level: " .. waste)
    print("Damage: " .. damage)
    print("Temperature: " .. temp)
    print("-----------------------------")
    print("1. " .. (status and "SCRAM (Shutdown)" or "Activate Reactor"))
    print("2. Exit")
    print("-----------------------------")
    print(actionMessage or "")
end

-- Alarm loop: two-tone alternating
local function playAlarm()
    local toggle = true
    while autoScramTriggered do
        if speaker then
            if toggle then
                speaker.playNote("harp", 3, 10) -- High tone
            else
                speaker.playNote("bass", 1, 3) -- Low tone
            end
        end
        toggle = not toggle
        sleep(2)
    end
end

-- Blinking warning display
local function blinkWarning()
    local blink = true
    while autoScramTriggered do
        term.setCursorPos(1, 17)
        term.clearLine()
        if blink then
            io.write("!!! EMERGENCY SCRAM ACTIVE !!!")
        end
        blink = not blink
        sleep(0.5)
    end
end

-- Wait for key press to acknowledge
local function waitForAcknowledge()
    term.setCursorPos(1, 18)
    term.clearLine()
    io.write("Press any key to acknowledge...")
    os.pullEvent("key")
    autoScramTriggered = false
    term.setCursorPos(1, 17)
    term.clearLine()
    term.setCursorPos(1, 18)
    term.clearLine()
end

-- Monitor reactor for safety
local function statusLoop()
    while true do
        local status = reactor.getStatus()
        local damage = reactor.getDamagePercent()
        local waste = reactor.getWasteFilledPercentage()
        local coolant = reactor.getCoolantFilledPercentage()
        local heated = reactor.getHeatedCoolantFilledPercentage()
        local fuel = reactor.getFuelFilledPercentage()

        if status and not autoScramTriggered then
            if damage > 100 then
                reactor.scram()
                autoScramTriggered = true
                actionMessage = "CRITICAL DAMAGE! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif waste > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                actionMessage = "WASTE OVERFLOW! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif coolant < 0.10 then
                reactor.scram()
                autoScramTriggered = true
                actionMessage = "LOW COOLANT! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif heated > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                actionMessage = "HEATED COOLANT OVERFLOW! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            end
        end

        if fuel < 0.05 and not autoScramTriggered then
            actionMessage = "WARNING: Fuel critically low!"
        end

        drawUI()
        sleep(1)
    end
end

-- Input handler (key-based)
local function inputLoop()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.one then
            local status = reactor.getStatus()
            if status then
                reactor.scram()
                actionMessage = "Reactor SCRAMMED."
            else
                if autoScramTriggered then
                    actionMessage = "Unsafe! Reset conditions first."
                elseif isReactorSafeToStart() then
                    reactor.activate()
                    actionMessage = "Reactor Activated."
                else
                    actionMessage = "Unsafe! Cannot activate."
                end
            end
        elseif key == keys.two then
            term.setCursorPos(1, 20)
            print("Exiting...")
            sleep(1)
            os.shutdown()
        end
    end
end

-- Run both loops in parallel
term.clear()
term.setCursorPos(1, 1)
parallel.waitForAny(statusLoop, inputLoop)
