-- Wrap the reactor peripheral
local reactor = peripheral.wrap("fissionReactorLogicAdapter_0")

-- Function to display the menu
local function showMenu()
    print("=== Reactor Control Panel ===")
    print("1. Activate Reactor")
    print("2. Scram (Shutdown)")
    print("3. Get Status")
    print("4. Exit")
    io.write("> ")
end

-- Function to get status and display it
local function getStatus()
    local status = reactor.getStatus()
    if status then
        print("Reactor is RUNNING.")
    else
        print("Reactor is SHUT DOWN.")
    end
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
