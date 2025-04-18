-- Wrap the reactor peripheral
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")

-- Helper to format percentage
local function toPercent(value)
    return string.format("%.1f%%", value * 100)
end

-- Function to display the menu
local function showMenu()
    print("=== Reactor Control Panel ===")
    print("1. Activate Reactor")
    print("2. Scram (Shutdown)")
    print("3. Get Status")
    print("4. Exit")
    io.write("> ")
end

-- Function to get and display detailed status
local function getStatus()
    local status = reactor.getStatus()
    local fuel = toPercent(reactor.getFuelFilledPercentage())
    local coolant = toPercent(reactor.getCoolantFilledPercentage())
    local heatedCoolant = toPercent(reactor.getHeatedCoolantFilledPercentage())
    local waste = toPercent(reactor.getWasteFilledPercentage())

    print("=== Reactor Status ===")
    print("Status: " .. (status and "RUNNING" or "SHUT DOWN"))
    print("Fuel Level: " .. fuel)
    print("Coolant Level: " .. coolant)
    print("Heated Coolant Level: " .. heatedCoolant)
    print("Waste Level: " .. waste)
end

-- Main program loop
while true do
    showMenu()
    local input = read()
    
    if input == "1" then
        reactor.activate()
        print("Reactor activated.")
    elseif input == "2" then
        reactor.scram()
        print("SCRAM initiated. Reactor shutting down.")
    elseif input == "3" then
        getStatus()
    elseif input == "4" then
        print("Exiting control panel.")
        break
    else
        print("Invalid option. Please select 1-4.")
    end

    print()
    sleep(1)
end
