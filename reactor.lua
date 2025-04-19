-- Peripheral setup
local reactor = peripheral.find("fissionReactorLogicAdapter")
local speaker = peripheral.find("speaker")
local turbine = peripheral.find("turbineValve")
local autoScramTriggered = false
local autoScramReason = ""  -- Store the reason for auto-scram
local actionMessage = ""

if not reactor then
    term.setCursorPos(1, 1)
    term.clear()
    print("Error: No fission reactor logic adapter found.")
    sleep(3)
    os.shutdown()
end

if not speaker then
    term.setCursorPos(1, 1)
    term.clear()
    print("Warning: No speaker found. Alarms will be silent.")
    sleep(2)
end

if not turbine then
    term.setCursorPos(1, 1)
    term.clear()
    print("Info: No turbine found. Turbine stats will be unavailable.")
    sleep(2)
end

-- Uptime tracking
local reactorUptime = 0
local reactorRunningSince = nil

-- Last known values
local last = {
    status = nil,
    fuel = nil,
    coolant = nil,
    heated = nil,
    waste = nil,
    damage = nil,
    temp = nil,
    uptime = "",
    message = ""
}

-- Format uptime as HH:MM:SS
local function formatTime(seconds)
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

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
    print("[Remote Reactor Controller v1.1]")
    for _ = 1, 10 do print("") end  -- reserve 10 lines for live values
    print("-----------------------------")
    print("1. Activate Reactor")
    print("2. SCRAM Reactor")
    print("3. Turbine Stats")
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

    local uptimeDisplay = formatTime(reactorUptime)

    if status ~= last.status then
        updateLine(3, "Status: ", status and "RUNNING" or "SHUT DOWN")
        if not status and autoScramTriggered then
            updateLine(4, "Auto Scram Reason: ", autoScramReason)
        end
        last.status = status
    end
    if uptimeDisplay ~= last.uptime then
        updateLine(4, "Uptime: ", uptimeDisplay)  -- Move uptime to line 3
        last.uptime = uptimeDisplay
    end
    if fuel ~= last.fuel then
        updateLine(5, "Fuel Level: ", fuel)
        last.fuel = fuel
    end
    if coolant ~= last.coolant then
        updateLine(6, "Coolant Level: ", coolant)
        last.coolant = coolant
    end
    if heated ~= last.heated then
        updateLine(7, "Heated Coolant: ", heated)
        last.heated = heated
    end
    if waste ~= last.waste then
        updateLine(8, "Waste Level: ", waste)
        last.waste = waste
    end
    if damage ~= last.damage then
        updateLine(9, "Damage: ", damage)
        last.damage = damage
    end
    if temp ~= last.temp then
        updateLine(10, "Temperature: ", temp)
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
    redstone.setOutput("top", true)
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
    redstone.setOutput("top", false)
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
    redstone.setOutput("top", false)
    term.setCursorPos(1, 18)
    term.clearLine()
    term.setCursorPos(1, 19)
    term.clearLine()
end

-- Turbine Stats
local function showTurbineStats()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("[Turbine Status Monitor]")
        print("------------------------")

        if not turbine then
            print("No turbine connected.")
        else
            local flowRate = string.format("%.1f mB/t", turbine.getFlowRate())
            local maxFlowRate = string.format("%.1f mB/t", turbine.getMaxFlowRate())
            local productionRate = string.format("%.1f FE/t", turbine.getProductionRate()) -- Assuming correct method name
            local steam = string.format("%.1f mB", turbine.getSteam())
            local steamFilledPercentage = string.format("%.1f%%", turbine.getSteamFilledPercentage() * 100)
            local energy = string.format("%.1f FE", turbine.getEnergy())
            local energyFilledPercentage = string.format("%.1f%%", turbine.getEnergyFilledPercentage() * 100)

            print("Flow Rate:            " .. flowRate)
            print("Max Flow Rate:        " .. maxFlowRate)
            print("Production Rate:      " .. productionRate)
            print("Steam:                " .. steam)
            print("Steam Filled:         " .. steamFilledPercentage)
            print("Energy:               " .. energy)
            print("Energy Filled:        " .. energyFilledPercentage)
        end

        print("\nPress any key to return...")

        -- Wait up to 1 second for a key or check for alarm
        local timer = os.startTimer(1)
        while true do
            local event, param = os.pullEvent()
            if event == "key" or autoScramTriggered then
                drawStaticUI()
                refreshUI()
                return
            elseif event == "timer" and param == timer then
                break -- refresh turbine screen
            end
        end
    end
end

-- Safety logic + uptime tracking with reactor formation and turbine checks
local function statusLoop()
    while true do
        local status = reactor.getStatus()
        local damage = reactor.getDamagePercent()
        local waste = reactor.getWasteFilledPercentage()
        local coolant = reactor.getCoolantFilledPercentage()
        local heated = reactor.getHeatedCoolantFilledPercentage()
        local fuel = reactor.getFuelFilledPercentage()
        local temp = reactor.getTemperature()

        -- Turbine status checks
        local turbineSteam = turbine.getSteamFilledPercentage()
        local turbineEnergy = turbine.getEnergyFilledPercentage()

        -- Uptime logic
        if status then
            if not reactorRunningSince then
                reactorRunningSince = os.clock()
            end
            reactorUptime = math.floor(os.clock() - reactorRunningSince)
        else
            reactorRunningSince = nil
            reactorUptime = 0  -- Reset uptime on SCRAM
        end

        -- Safety checks with additional scram conditions
        if status and not autoScramTriggered then
            -- Reactor-related safety checks
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
            -- Additional scram triggers (existing)
            elseif temp > 1200 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "OVERHEATED"
                actionMessage = "OVERHEATED! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif fuel < 0.05 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "LOW FUEL"
                actionMessage = "LOW FUEL! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            -- New turbine-related scram checks
            elseif turbineSteam >= 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "TURBINE STEAM FULL"
                actionMessage = "TURBINE STEAM FULL! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif turbineEnergy >= 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "TURBINE ENERGY FULL"
                actionMessage = "TURBINE ENERGY FULL! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif not turbine.isFormed() then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "TURBINE LOST"
                actionMessage = "TURBINE LOST! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            end
        end

        -- Check if reactor is formed (this won't trigger a scram, but will trigger an alarm)
        if not reactor.isFormed() then
            actionMessage = "REACTOR LOST"
            parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)  -- Play alarm, blink warning, and wait for acknowledgment
        end

        -- Refresh UI
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
                    reactorRunningSince = os.clock()
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
            if not turbine then
                actionMessage = "Turbine not connected."
            else
                showTurbineStats()  -- Jump to the turbine stats screen
                drawStaticUI()      -- Redraw the main UI afterward
                refreshUI()         -- Refresh values after returning
            end
        end  -- This end is for the if statement checking the keys
    end
end

-- Start
term.clear()
term.setCursorPos(1, 1)
drawStaticUI()
parallel.waitForAny(statusLoop, inputLoop)
