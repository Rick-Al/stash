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

local isMainScreen = true  -- Set to true initially, indicating we're on the main screen

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

-- Last known turbine values
local lastTurbine = {
    flowRate = nil,
    maxFlowRate = nil,
    productionRate = nil,
    steamFilled = nil,
    energyFilled = nil,
    energy = nil,
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
local function refreshUI(force)
    if not isMainScreen then return end -- Don't run if not on the main screen

    local status = reactor.getStatus()
    local fuel = toPercent(reactor.getFuelFilledPercentage())
    local coolant = toPercent(reactor.getCoolantFilledPercentage())
    local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
    local waste = toPercent(reactor.getWasteFilledPercentage())
    local damage = string.format("%.1f%%", reactor.getDamagePercent())
    local temp = string.format("%.2f K", reactor.getTemperature())

    local uptimeDisplay = formatTime(reactorUptime)

    -- Redraw if forced or if values have changed
    if force or status ~= last.status then
        updateLine(3, "Status: ", status and "RUNNING" or "SHUT DOWN")
        last.status = status
    end
    if force or not status and autoScramTriggered then
        updateLine(4, "Auto Scram Reason: ", autoScramReason)
    elseif force or uptimeDisplay ~= last.uptime then
        updateLine(4, "Uptime: ", uptimeDisplay)
        last.uptime = uptimeDisplay
    end
    if force or fuel ~= last.fuel then
        updateLine(5, "Fuel Level: ", fuel)
        last.fuel = fuel
    end
    if force or coolant ~= last.coolant then
        updateLine(6, "Coolant Level: ", coolant)
        last.coolant = coolant
    end
    if force or heated ~= last.heated then
        updateLine(7, "Heated Coolant: ", heated)
        last.heated = heated
    end
    if force or waste ~= last.waste then
        updateLine(8, "Waste Level: ", waste)
        last.waste = waste
    end
    if force or damage ~= last.damage then
        updateLine(9, "Damage: ", damage)
        last.damage = damage
    end
    if force or temp ~= last.temp then
        updateLine(10, "Temperature: ", temp)
        last.temp = temp
    end
    if force or actionMessage ~= last.message then
        term.setCursorPos(1, 17)
        term.clearLine()
        print(actionMessage)
        last.message = actionMessage
    end
end


-- Function to update individual turbine stats line
local function updateTurbineLine(line, label, value)
    term.setCursorPos(1, line)
    write(label .. value)
end

-- Function to refresh the turbine stats and update the display
local function refreshTurbineStats()
    -- Exit if we're on the main screen or no turbine found
    if isMainScreen or not turbine then return end

    -- Get turbine data with protection
    local flowRate, maxFlowRate, productionRate, steamPercentage, energyPercentage, energyStored
    if turbine then
        flowRate = string.format("%.1f mB/t", turbine.getFlowRate())
        maxFlowRate = string.format("%.1f mB/t", turbine.getMaxFlowRate())
        productionRate = string.format("%.1f RF/t", turbine.getProductionRate())
        steamPercentage = string.format("%.1f%%", turbine.getSteamFilledPercentage())
        energyPercentage = string.format("%.1f%%", turbine.getEnergyFilledPercentage())
        energyStored = string.format("%.1f RF", turbine.getEnergy())
    else
        -- Fallback if turbine is nil (no turbine detected)
        flowRate = "N/A"
        maxFlowRate = "N/A"
        productionRate = "N/A"
        steamPercentage = "N/A"
        energyPercentage = "N/A"
        energyStored = "N/A"
    end

    -- Update turbine stats lines
    updateTurbineLine(3, "Flow Rate: ", flowRate)
    updateTurbineLine(4, "Max Flow: ", maxFlowRate)
    updateTurbineLine(5, "Production Rate: ", productionRate)
    updateTurbineLine(6, "Steam Percentage: ", steamPercentage)
    updateTurbineLine(7, "Energy Percentage: ", energyPercentage)
    updateTurbineLine(8, "Energy Stored: ", energyStored)
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

-- Function to show the turbine stats screen
local function showTurbineStats()
    -- Reserve lines for the turbine stats screen
    for i = 2, 9 do
        term.setCursorPos(1, i)
        print("") -- Reserve lines
    end

    -- Print header for turbine stats
    term.setCursorPos(1, 2)
    print("Turbine Stats")

    -- Immediately draw the initial turbine stats
    refreshTurbineStats()

    -- Start the timer for refreshing turbine stats every 1 second
    local timerId = os.startTimer(1)
    while true do
        local event, param = os.pullEvent()
        
        if event == "key" then
            -- Handle key press to go back to main screen
            isMainScreen = true
            drawStaticUI()
            refreshUI(true)
            return
        elseif event == "timer" and param == timerId then
            -- Refresh turbine stats every 1 second
            refreshTurbineStats()
            -- Restart the timer
            timerId = os.startTimer(1)
        end
    end
end


-- Safety logic + uptime tracking with reactor formation and turbine checks
local function statusLoop()
    while true do
        local status, damage, waste, coolant, heated, fuel, temp = nil, nil, nil, nil, nil, nil, nil
        local turbineSteam, turbineEnergy = nil, nil

        local reactorFormed = reactor.isFormed()
        local turbineFormed = turbine and turbine.isFormed()

        -- Reactor is not formed, trigger alarm
        if not reactorFormed then
            actionMessage = "REACTOR LOST"
            parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
        else
            status = reactor.getStatus()
            damage = reactor.getDamagePercent()
            waste = reactor.getWasteFilledPercentage()
            coolant = reactor.getCoolantFilledPercentage()
            heated = reactor.getHeatedCoolantFilledPercentage()
            fuel = reactor.getFuelFilledPercentage()
            temp = reactor.getTemperature()

            -- Uptime tracking
            if status then
                if not reactorRunningSince then
                    reactorRunningSince = os.clock()
                end
                reactorUptime = math.floor(os.clock() - reactorRunningSince)
            else
                reactorRunningSince = nil
                reactorUptime = 0
            end
        end

        -- Turbine is not formed, trigger alarm
        if turbine and not turbineFormed then
            actionMessage = "TURBINE LOST"
            parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
        elseif turbineFormed then
            turbineSteam = turbine.getSteamFilledPercentage()
            turbineEnergy = turbine.getEnergyFilledPercentage()
        end

        -- Only perform safety checks if everything is formed and the reactor is on
        if reactorFormed and status and not autoScramTriggered then
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
            elseif turbineFormed and turbineSteam and turbineSteam >= 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "TURBINE STEAM FULL"
                actionMessage = "TURBINE STEAM FULL! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            elseif turbineFormed and turbineEnergy and turbineEnergy >= 0.95 then
                reactor.scram()
                autoScramTriggered = true
                autoScramReason = "TURBINE ENERGY FULL"
                actionMessage = "TURBINE ENERGY FULL! AUTO-SCRAM."
                parallel.waitForAny(playAlarm, blinkWarning, waitForAcknowledge)
            end
        end

        refreshUI(false)
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
                refreshUI(false)         -- Refresh values after returning
            end
        end  -- This end is for the if statement checking the keys
    end
end

-- Start
term.clear()
term.setCursorPos(1, 1)
drawStaticUI()
parallel.waitForAny(statusLoop, inputLoop)
