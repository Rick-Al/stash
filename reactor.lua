local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")
local speaker = peripheral.find("speaker")
local monitor = nil -- set to peripheral.wrap("monitor_name") if using external monitor

local running = false
local autoScramReason = nil
local warningMessage = nil
local warningActive = false
local warningBlink = false
local lastData = {}

-- Constants
local damageThreshold = 100
local lowFuelThreshold = 0.1
local lowCoolantThreshold = 0.1
local heatedOverflowThreshold = 0.9
local wasteOverflowThreshold = 0.9

-- Draw static parts
function drawStatic()
    term.setCursorPos(1, 1)
    term.clear()
    print("=== Reactor Control Panel ===")
    print("-----------------------------------")
end

-- Update status and data lines
function drawStatus()
    term.setCursorPos(1, 3)
    term.clearLine()
    if autoScramReason then
        write("Status: SCRAMMED - " .. autoScramReason)
    else
        write("Status: " .. (running and "RUNNING" or "SCRAMMED"))
    end
    term.setCursorPos(1, 4)
    print("-----------------------------------")
end

function percentBar(value)
    return string.format("%5.1f%%", value * 100)
end

function drawData()
    local fuel = reactor.getFuelFilledPercentage()
    local coolant = reactor.getCoolantFilledPercentage()
    local heated = reactor.getHeatedCoolantFilledPercentage()
    local waste = reactor.getWasteFilledPercentage()
    local temp = reactor.getTemperature()
    local damage = reactor.getDamagePercent()

    -- Save for comparison later
    lastData = {fuel = fuel, coolant = coolant, heated = heated, waste = waste, temp = temp, damage = damage}

    term.setCursorPos(1, 5)
    term.clearLine()
    write("Fuel:   " .. percentBar(fuel) .. "    Coolant: " .. percentBar(coolant))

    term.setCursorPos(1, 6)
    term.clearLine()
    write("Heated: " .. percentBar(heated) .. "    Waste:   " .. percentBar(waste))

    term.setCursorPos(1, 7)
    term.clearLine()
    write(string.format("Temp:   %7.2fK", temp) .. " Damage:  " .. string.format("%5.1f%%", damage))

    term.setCursorPos(1, 8)
    print("-----------------------------------")
end

function drawWarning()
    term.setCursorPos(1, 10)
    term.clearLine()
    if warningActive and warningBlink then
        term.setTextColor(colors.red)
        write("[WARNING]: " .. warningMessage)
        term.setTextColor(colors.white)
    end
end

function drawMenu()
    term.setCursorPos(1, 12)
    print("-----------------------------------")
    term.setCursorPos(1, 13)
    term.clearLine()
    print("1. Activate")
    term.setCursorPos(1, 14)
    term.clearLine()
    print("2. SCRAM")
    term.setCursorPos(1, 15)
    term.clearLine()
    print("3. Exit")
end

-- Alarm logic (updated)
local function playAlarm()
    local toggle = true
    while warningActive do
        if speaker then
            if toggle then
                speaker.playNote("bit", 3, 10)  -- High tone
            else
                speaker.playNote("bit", 1, 3)   -- Low tone
            end
        end
        toggle = not toggle
        drawWarning()
        sleep(0.5)  -- Delay between tone switches
    end
end

function checkConditions()
    local fuel = reactor.getFuelFilledPercentage()
    local coolant = reactor.getCoolantFilledPercentage()
    local heated = reactor.getHeatedCoolantFilledPercentage()
    local waste = reactor.getWasteFilledPercentage()
    local damage = reactor.getDamagePercent()

    if running then
        if damage > damageThreshold then
            autoScram("CRITICAL DAMAGE")
        elseif fuel < lowFuelThreshold then
            autoScram("LOW FUEL")
        elseif coolant < lowCoolantThreshold then
            autoScram("LOW COOLANT")
        elseif heated > heatedOverflowThreshold then
            autoScram("HEATED COOLANT OVERFLOW")
        elseif waste > wasteOverflowThreshold then
            autoScram("WASTE OVERFLOW")
        end
    end
end

function autoScram(reason)
    reactor.scram()
    running = false
    autoScramReason = reason
    warningMessage = reason
    warningActive = true
    parallel.waitForAny(playAlarm)  -- Play the alarm concurrently
end

function clearWarning()
    warningActive = false
    warningMessage = nil
    autoScramReason = nil
    warningBlink = false
    drawWarning()
end

function activate()
    if running then
        showAction("Reactor already running.")
    elseif autoScramReason then
        showAction("Cannot activate: " .. autoScramReason)
    else
        reactor.activate()
        running = true
        showAction("Reactor activated.")
    end
end

function scram()
    if not running then
        showAction("Reactor already scrammed.")
    else
        reactor.scram()
        running = false
        showAction("SCRAM engaged.")
    end
end

function showAction(message)
    term.setCursorPos(1, 16)
    term.clearLine()
    write(message)
end

-- Input (non-blocking)
function listenInput()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.one then
            activate()
        elseif key == keys.two then
            scram()
        elseif key == keys.three then
            scram()
            showAction("Shutting down...")
            sleep(1)
            term.clear()
            os.shutdown()
        end
        drawStatus()
        drawData()
        drawWarning()
        drawMenu()
    end
end

-- Refresh loop
function updateLoop()
    while true do
        checkConditions()
        drawStatus()
        drawData()
        drawWarning()
        sleep(1)
    end
end

-- Run
drawStatic()
drawStatus()
drawData()
drawMenu()
parallel.waitForAny(listenInput, updateLoop)
