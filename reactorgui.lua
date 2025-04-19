local reactor = peripheral.find("fissionReactorLogicAdapter")

local basalt = require("basalt")

local main = basalt.createFrame()

-- Title
main:addLabel()
    :setText("Remote Reactor Controller")
    :setPosition(2, 1)
    :setForeground(colors.yellow)

-- Simulated box background for reactor stats
local dataBox = main:addFrame()
    :setPosition(2, 3)
    :setSize(46, 9)
    :setBackground(colors.gray)

-- Status label
local statusLabel = dataBox:addLabel()
    :setText("Status: Loading...")
    :setPosition(2, 1)
    :setForeground(colors.white)

-- Stat lines
local fuelLabel     = dataBox:addLabel():setPosition(2, 3):setText("Fuel: Loading...")
local coolantLabel  = dataBox:addLabel():setPosition(2, 4):setText("Coolant: Loading...")
local heatedLabel   = dataBox:addLabel():setPosition(2, 5):setText("Heated Coolant: Loading...")
local wasteLabel    = dataBox:addLabel():setPosition(2, 6):setText("Waste: Loading...")
local tempLabel     = dataBox:addLabel():setPosition(2, 7):setText("Temperature: Loading...")
local damageLabel   = dataBox:addLabel():setPosition(2, 8):setText("Damage: Loading...")

-- Control buttons
local scramBtn = main:addButton()
    :setText("SCRAM")
    :setPosition(2, 13)
    :setSize(10, 3)
    :setBackground(colors.red)

local activateBtn = main:addButton()
    :setText("Activate")
    :setPosition(14, 13)
    :setSize(10, 3)
    :setBackground(colors.green)

-- Helper
local function toPercent(val)
    return string.format("%.1f%%", val * 100)
end

-- Update all UI text
local function refresh()
    if not reactor then return end

    local status = reactor.getStatus()
    local fuel = toPercent(reactor.getFuelFilledPercentage())
    local coolant = toPercent(reactor.getCoolantFilledPercentage())
    local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
    local waste = toPercent(reactor.getWasteFilledPercentage())
    local damage = string.format("%.1f%%", reactor.getDamagePercent())
    local temp = string.format("%.2f K", reactor.getTemperature())

    -- Determine readable status
    local statusText = "Nominal"
    if not status then
        statusText = "SCRAMMED: Manual"
    elseif reactor.getDamagePercent() > 0.5 then
        statusText = "Auto-SCRAMMED: Damage"
        reactor.scram()
    end

    statusLabel:setText("Status: " .. statusText)
    fuelLabel:setText("Fuel: " .. fuel)
    coolantLabel:setText("Coolant: " .. coolant)
    heatedLabel:setText("Heated Coolant: " .. heated)
    wasteLabel:setText("Waste: " .. waste)
    tempLabel:setText("Temperature: " .. temp)
    damageLabel:setText("Damage: " .. damage)
end

-- Button handlers
scramBtn:onClick(function()
    reactor.scram()
    refresh()
end)

activateBtn:onClick(function()
    reactor.activate()
    refresh()
end)

-- Use Basalt's thread system correctly
basalt.addThread(function()
    while true do
        refresh()
        os.sleep(1)
    end
end)

basalt.autoUpdate()
