reactor = peripheral.find("fissionReactorLogicAdapter")

local basalt = require("basalt")
local main = basalt.createFrame()

-- Top title
main:addLabel()
    :setText("Remote Reactor Controller")
    :setPosition(2, 1)
    :setForeground(colors.yellow)

-- Status Box
local statusFrame = main:addFrame()
    :setPosition(2, 3)
    :setSize("parent.w-4", 3)
    :setBackground(colors.gray)
    :setForeground(colors.white)
    :setBorder(true)

local statusLabel = statusFrame:addLabel()
    :setPosition(2, 2)
    :setText("Status: Loading...")

-- Data Box
local dataFrame = main:addFrame()
    :setPosition(2, 7)
    :setSize("parent.w-4", 8)
    :setBackground(colors.gray)
    :setForeground(colors.white)
    :setBorder(true)

local labels = {
    fuel = dataFrame:addLabel():setPosition(2, 1),
    waste = dataFrame:addLabel():setPosition(2, 2),
    coolant = dataFrame:addLabel():setPosition(2, 3),
    heated = dataFrame:addLabel():setPosition(2, 4),
    damage = dataFrame:addLabel():setPosition(2, 5),
    temp = dataFrame:addLabel():setPosition(2, 6),
}

-- Control Buttons
local btnScram = main:addButton()
    :setText("SCRAM")
    :setPosition(2, "parent.h-2")
    :setSize(12, 3)
    :onClick(function()
        reactor.scram()
    end)

local btnActivate = main:addButton()
    :setText("Activate")
    :setPosition(16, "parent.h-2")
    :setSize(12, 3)
    :onClick(function()
        reactor.activate()
    end)

-- Utility functions
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

-- Refresh loop
basalt.schedule(function()
    while true do
        local status = reactor.getStatus()
        local fuel = toPercent(reactor.getFuelFilledPercentage())
        local coolant = toPercent(reactor.getCoolantFilledPercentage())
        local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
        local waste = toPercent(reactor.getWasteFilledPercentage())
        local damage = string.format("%.1f%%", reactor.getDamagePercent())
        local temp = string.format("%.2f K", reactor.getTemperature())

        local readableStatus = "Nominal"
        if not status then
            readableStatus = "SCRAMMED: Manual"
        elseif reactor.getDamagePercent() > 0.5 then
            readableStatus = "Auto-SCRAMMED: High Damage"
        end

        statusLabel:setText("Status: " .. readableStatus)
        labels.fuel:setText("Fuel: " .. fuel)
        labels.waste:setText("Waste: " .. waste)
        labels.coolant:setText("Coolant: " .. coolant)
        labels.heated:setText("Heated Coolant: " .. heated)
        labels.damage:setText("Damage: " .. damage)
        labels.temp:setText("Temperature: " .. temp)

        os.sleep(1)
    end
end)

basalt.autoUpdate()

