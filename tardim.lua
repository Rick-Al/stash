local tardim = peripheral.find("digital_tardim_interface")

if not tardim then
    error("No TARDIM interface found.")
end

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

local function pause()
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

local function showStatus()
    clear()

    local fuel = tardim.getFuel()
    local fuelNeeded = tardim.calculateFuelForJourney()
    local locked = tardim.isLocked()
    local inFlight = tardim.isInFlight()
    local owner = tardim.getOwnerName()

    print("=== TARDIM STATUS ===\n")
    print("Owner: " .. owner)
    print("Fuel Level: " .. string.format("%.2f", fuel) .. "%")
    print("Fuel Required For Journey: " .. string.format("%.2f", fuelNeeded) .. "%")

    if fuel >= fuelNeeded then
        print("Fuel Status: Enough for journey")
    else
        print("Fuel Status: NOT enough fuel")
    end

    print("Doors Locked: " .. tostring(locked))
    print("In Flight: " .. tostring(inFlight))

    if inFlight then
        print("Flight Started: " .. tardim.getTimeEnteredFlight())
    end
end

local function setCoordinates()
    clear()
    print("Enter X:")
    local x = tonumber(read())

    print("Enter Y:")
    local y = tonumber(read())

    print("Enter Z:")
    local z = tonumber(read())

    tardim.setTravelLocation(x,y,z)

    print("Destination Updated.")
    pause()
end

local function travelToPlayer()
    clear()
    local players = tardim.getOnlinePlayers()

    print("Online Players:\n")
    for i, name in ipairs(players) do
        print(i .. ". " .. name)
    end

    print("\nSelect player number:")
    local choice = tonumber(read())

    if players[choice] then
        tardim.locatePlayer(players[choice])
        print("Destination set to player.")
    else
        print("Invalid selection.")
    end

    pause()
end

local function locateBiome()
    clear()

    print("Enter biome name:")
    print("(Use getBiomes option if unsure)")
    local biome = read()

    local ok, err = pcall(function()
        tardim.locateBiome(biome)
    end)

    if ok then
        print("Destination set to biome.")
    else
        print("Error: " .. err)
    end

    pause()
end

local function setDimension()
    clear()
    local dims = tardim.getDimensions()

    for i, dim in ipairs(dims) do
        print(i .. ". " .. dim)
    end

    print("\nSelect dimension number:")
    local choice = tonumber(read())

    if dims[choice] then
        tardim.setDimension(dims[choice])
        print("Dimension set.")
    else
        print("Invalid selection.")
    end

    pause()
end

local function setExterior()
    clear()
    local skins = tardim.getSkins()

    for i, skin in ipairs(skins) do
        print(i .. ". " .. skin)
    end

    print("\nSelect exterior number:")
    local choice = tonumber(read())

    if skins[choice] then
        tardim.setSkin(skins[choice])
        print("Exterior updated.")
    else
        print("Invalid selection.")
    end

    pause()
end

local function toggleLock()
    local locked = tardim.isLocked()
    tardim.setLocked(not locked)

    print("Doors are now: " .. tostring(not locked))
    pause()
end

local function takeOff()
    local ok, err = pcall(function()
        tardim.demat()
    end)

    if ok then
        print("Dematerialising...")
    else
        print("Error: " .. err)
    end

    pause()
end

local function land()
    local ok, err = pcall(function()
        tardim.remat()
    end)

    if ok then
        print("Rematerialising...")
    else
        print("Error: " .. err)
    end

    pause()
end

while true do
    clear()

    print("=== TARDIM CONTROL PANEL ===\n")
    print("1. Show Status")
    print("2. Set Coordinates")
    print("3. Travel To Player")
    print("4. Locate Biome")
    print("5. Set Dimension")
    print("6. Set Exterior")
    print("7. Toggle Door Lock")
    print("8. Take Off")
    print("9. Land")
    print("0. Exit")

    print("\nSelect Option:")
    local choice = read()

    if choice == "1" then showStatus(); pause()
    elseif choice == "2" then setCoordinates()
    elseif choice == "3" then travelToPlayer()
    elseif choice == "4" then locateBiome()
    elseif choice == "5" then setDimension()
    elseif choice == "6" then setExterior()
    elseif choice == "7" then toggleLock()
    elseif choice == "8" then takeOff()
    elseif choice == "9" then land()
    elseif choice == "0" then break
    end
end
