-- Peripheral setup
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")
local speaker = peripheral.find("speaker")  -- Finds a connected speaker
local autoScramTriggered = false
local actionMessage = ""

-- Helper to format decimal values as percentages
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

-- Determines if it's safe to start the reactor
local function isReactorSafeToStart()
    return reactor.getDamagePercent() <= 100
       and reactor.getCoolantFilledPercentage() >= 0.10
       and reactor.getHeatedCoolantFilledPercentage() <= 0.95
       and reactor.getWasteFilledPercentage() <= 0.95
end

-- Alarm system
local function playAlarm()
    if speaker then
        while autoScramTriggered do
            speaker.playNote("harp", 3, 5)
            sleep(5)
        end
    end
end

local function blinkWarning()
    local blink = true
    while autoScramTriggered do
        term.setCursorPos(1, 17)
        if blink then
            term.clearLine()
            io.write("!!! EMERGENCY SCRAM ACTIVE !!!")
        else
            term.clearLine()
        end
        blink = not blink
        sleep(0.5)
    end
end

local function waitForAcknowledge()
    term.setCursorPos(1, 18)
    term.clearLine()
    io.write("Press Enter to acknowledge and stop alarm... > ")
    read()
    autoScramTriggered = false
    term.setCursorPos(1, 17)
    term.clearLine()
    term.setCursorPos(1, 18)
    term.clearLine()
end

-- Status monitoring loop
local function statusLoop()
    while true do
        local status = reactor.getStatus()
        local fuel = reactor.getFuelFilledPercentage()
        local coolant = reactor.getCoolantFilledPercentage()
        local heatedCoolant = reactor.getHeatedCoolantFilledPercentage()
        local waste = reactor.getWasteFilledPercentage()
        local damage = reactor.getDamagePercent()

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
            elseif heatedCoolant > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                actionMessage = "HEATED COOLANT OVERFLOW! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            end
        end

        if fuel < 0.05 then
            actionMessage = "WARNING: Fuel critically low!"
        end

        sleep(1)
    end
end

-- Main menu interface
local function showMenu()
    term.clear()
    while true do
        local status = reactor.getStatus()
        local fuel = toPercent(reactor.getFuelFilledPercentage())
        local coolant = toPercent(reactor.getCoolantFilledPercentage())
        local heatedCoolant = toPercent(reactor.getHeatedCoolantFilledPercentage())
        local waste = toPercent(reactor.getWasteFilledPercentage())
        local damage = string.format("%.1f%%", reactor.getDamagePercent())
        local temperature = string.format("%.2f K", reactor.getTemperature())

        -- Draw UI
        term.setCursorPos(1, 1)
        print("=== Reactor Control Panel ===")
        print("Status: " .. (status and "RUNNING" or "SHUT DOWN"))
        print("Fuel Level: " .. fuel)
        print("Coolant Level: " .. coolant)
        print("Heated Coolant: " .. heatedCoolant)
        print("Waste Level: " .. waste)
        print("Damage: " .. damage)
        print("Temperature: " .. temperature)
        print("-----------------------------")

        -- Menu options
        if not status then
            print("1. Activate Reactor")
        else
            print("1. SCRAM (Shutdown)")
        end
        print("2. Exit")
        print("-----------------------------")
        print(actionMessage)
        term.setCursorPos(1, 15)
        term.clearLine()
        io.write("> ")

        -- Read input
        local input = read()

        if input == "1" then
            if not status then
                if isReactorSafeToStart() then
                    reactor.activate()
                    actionMessage = "Reactor Activated."
                else
                    actionMessage = "Cannot start reactor! Unsafe conditions."
                end
            else
                reactor.scram()
                actionMessage = "Reactor SCRAMMED."
            end
        elseif input == "2" then
            break
        end
    end
end

-- Run everything in parallel
parallel.waitForAny(statusLoop, showMenu)
