-- Peripheral setup
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")
local speaker = peripheral.find("speaker")
local autoScramTriggered = false
local autoScramReason = ""  -- Store the reason for auto-scram
local actionMessage = ""

-- Last known values
local last = {
    status = nil,
    fuel = nil,
    coolant = nil,
    heated = nil,
    waste = nil,
    damage = nil,
    temp = nil,
    message = ""
}

-- Percent formatter
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

local function isReactorSafeToStart()
    return reactor.getDamagePercent() <= 100
       and reactor.getCoolantFilledPercentage() >= 0.10
       and reactor.getHeatedCoolantFilledPercentage() <= 0.95
       and reactor.getWasteFilledPercentage() <= 0.95
end

-- Initial layout print
local function drawStaticUI()
    term.setCursorPos(1, 1)
    term.clear()
    print("=== Reactor Control Panel ===")
    for _ = 1, 9 do print("") end  -- reserve 7 lines for live values
    print("-----------------------------")
    print("1. Activate Reactor")
    print("2. SCRAM Reactor")
    print("3. Exit")
    print("-----------------------------")
    print("") -- actionMessage
end

-- Update status line and display scram reason if applicable
local function updateLine(line, label, value)
    term.setCursorPos(1, line)
    term.clearLine()
    io.write(label .. value)
end

-- Redraw only if value changed
local function refreshUI()
    local status = reactor.getStatus()
    local fuel = toPercent(reactor.getFuelFilledPercentage())
    local coolant = toPercent(reactor.getCoolantFilledPercentage())
    local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
    local waste = toPercent(reactor.getWasteFilledPercentage())
    local damage = string.format("%.1f%%", reactor.getDamagePercent())
    local temp = string.format("%.2f K", reactor.getTemperature())

    if status ~= last.status then
        updateLine(2, "Status: ", status and "RUNNING" or "SHUT DOWN")
        if not status and autoScramTriggered then
            updateLine(3, "Auto Scram Reason: ", autoScramReason)
        end
        last.status = status
    end
    if fuel ~= last.fuel then
        updateLine(4, "Fuel Level: ", fuel)
        last.fuel = fuel
    end
    if coolant ~= last.coolant then
        updateLine(5, "Coolant Level: ", coolant)
        last.coolant = coolant
    end
    if heated ~= last.heated then
        updateLine(6, "Heated Coolant: ", heated)
        last.heated = heated
    end
    if waste ~= last.waste then
        updateLine(7, "Waste Level: ", waste)
        last.waste = waste
    end
    if damage ~= last.damage then
        updateLine(8, "Damage: ", damage)
        last.damage = damage
    end
    if temp ~= last.temp then
        updateLine(9, "Temperature: ", temp)
        last.temp = temp
    end
    if actionMessage ~= last.message then
        term.setCursorPos(1, 17)
        term.clearLine()
        print(actionMessage)
        last.message = actionMessage
    end
end

-- Alarm loop
local function playAlarm()
    local toggle = true
    while autoScramTriggered do
        if speaker then
            if toggle then
                speaker.playNote("bit", 3, 10)
            else
                speaker.playNote("bit", 1, 3)
            end
        end
        toggle = not toggle
        sleep(0.5)
    end
end

-- Warning blink
local function blinkWarning()
    local blink = true
    while autoScramTriggered do
        term.setCursorPos(1, 18)
        term.clearLine()
        if blink then
            io.write("!!! EMERGENCY SCRAM ACTIVE !!!")
        end
        blink = not blink
        sleep(0.5)
    end
end

-- Acknowledge key
local function waitForAcknowledge()
    term.setCursorPos(1, 19)
    term.clearLine()
    io.write("Press any key to acknowledge...")
    os.pullEvent("key")
    autoScramTriggered = false
    term.setCursorPos(1, 18)
    term.clearLine()
    term.setCursorPos(1, 19)
    term.clearLine()
end

-- Safety logic
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
                autoScramReason = "CRITICAL DAMAGE"
                actionMessage = "CRITICAL DAMAGE! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif waste > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "WASTE OVERFLOW"
                actionMessage = "WASTE OVERFLOW! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif coolant < 0.10 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "LOW COOLANT"
                actionMessage = "LOW COOLANT! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif heated > 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "HEATED COOLANT OVERFLOW"
                actionMessage = "HEATED COOLANT OVERFLOW! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            end
        end

        if fuel < 0.05 and not autoScramTriggered then
            actionMessage = "WARNING: Fuel critically low!"
        end

        refreshUI()
        sleep(1)
    end
end

-- Input (no Enter)
local function inputLoop()
    while true do
        local event, key = os.pullEvent("key")
        local status = reactor.getStatus()
        if key == keys.one then
            if status then
                actionMessage = "Error: Reactor already running!"
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
            if not status then
                actionMessage = "Error: Reactor is already off!"
            else
                reactor.scram()
                autoScramReason = "MANUAL SCRAM"
                actionMessage = "Reactor SCRAMMED."
            end
        elseif key == keys.three then
            -- Scram the reactor if it's running before exiting
            if status then
                reactor.scram()
                actionMessage = "Reactor SCRAMMED before exit."
            end
            term.setCursorPos(1, 19)
            print("Exiting...")
            sleep(1)
            os.shutdown()
        end
    end
end

-- Start
term.clear()
term.setCursorPos(1, 1)
drawStaticUI()
parallel.waitForAny(statusLoop, inputLoop)
