local tardim = peripheral.find("digital_tardim_interface")

if not tardim then
    error("No TARDIM interface found.")
end


-- CONFIG


local SAVE_FILE = "saved_destinations"
local FLIGHT_DURATION = 30


-- UTILITY


local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

local function pause()
    print("\nPress any key to continue...")
    os.pullEvent("key")
end

local function ringBell()
    pcall(function()
        tardim.cloisterBell()
    end)
end


-- SAVE SYSTEM


local function loadDestinations()
    if not fs.exists(SAVE_FILE) then
        return {}
    end

    local file = fs.open(SAVE_FILE, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()

    return data or {}
end

local function saveDestinations(data)
    local file = fs.open(SAVE_FILE, "w")
    file.write(textutils.serialize(data))
    file.close()
end

local savedDestinations = loadDestinations()


-- STATUS


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
    print("Fuel Required: " .. string.format("%.2f", fuelNeeded) .. "%")

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


-- DESTINATION CONTROL


local function setCoordinates()
    clear()
    print("Enter X:")
    local x = tonumber(read())

    print("Enter Y:")
    local y = tonumber(read())

    print("Enter Z:")
    local z = tonumber(read())

    tardim.setTravelLocation(x,y,z)
    ringBell()

    print("Destination Updated.")
    pause()
end

local function saveCurrentDestination()
    clear()

    local loc = tardim.getTravelLocation()
    local rotation = tardim.getDoorRotation()

    print("Enter name for this destination:")
    local name = read()

    print("Use current door rotation (" .. rotation .. ")? (y/n)")
    local useCurrent = read()

    if useCurrent:lower() ~= "y" then
        print("Enter preferred rotation (north/east/south/west):")
        rotation = read()
    end

    savedDestinations[name] = {
        dimension = loc.dimension,
        pos = {
            x = loc.pos.x,
            y = loc.pos.y,
            z = loc.pos.z
        },
        doorRotation = rotation
    }

    saveDestinations(savedDestinations)
    ringBell()

    print("Destination saved.")
    pause()
end


-- PROGRESS BAR


local function drawProgressBar(progress)
    local width = 30
    local filled = math.floor(progress * width)

    term.write("[")
    term.write(string.rep("#", filled))
    term.write(string.rep("-", width - filled))
    term.write("]")
end


-- AUTO TRAVEL


local function autoTravel(name)
    local data = savedDestinations[name]
    if not data then return end

    if tardim.isInFlight() then
        print("Already in flight!")
        pause()
        return
    end

    clear()
    print("Preparing Auto-Travel to " .. name .. "...\n")

    tardim.setDimension(data.dimension)
    tardim.setTravelLocation(
        data.pos.x,
        data.pos.y,
        data.pos.z
    )

    local fuel = tardim.getFuel()
    local fuelNeeded = tardim.calculateFuelForJourney()

    print("Fuel Available: " .. string.format("%.2f", fuel))
    print("Fuel Required: " .. string.format("%.2f", fuelNeeded))

    if fuel < fuelNeeded then
        print("\nNot enough fuel!")
        pause()
        return
    end

    print("\nDematerialising...")
    ringBell()

    local ok = pcall(function() tardim.demat() end)
    if not ok then
        print("Takeoff failed.")
        pause()
        return
    end

    -- Wait until flight registers
    local startTime
    repeat
        sleep(0.1)
        startTime = tardim.getTimeEnteredFlight()
    until startTime ~= -1

    -- Flight loop
    while true do
        clear()
        print("=== IN FLIGHT ===\n")

        local currentTime = os.epoch("utc") / 1000
        local elapsed = currentTime - startTime
        local progress = math.min(elapsed / FLIGHT_DURATION, 1)

        drawProgressBar(progress)
        print("\n")
        print("Elapsed: " .. math.floor(elapsed) .. "s")
        print("Remaining: " .. math.max(0, FLIGHT_DURATION - math.floor(elapsed)) .. "s")

        if elapsed >= FLIGHT_DURATION then break end
        sleep(0.2)
    end

    clear()
    print("Rematerialising...")

    local ok2 = pcall(function() tardim.remat() end)
    if not ok2 then
        print("Landing failed.")
        pause()
        return
    end

    if data.doorRotation then
        pcall(function()
            tardim.setDoorRotation(data.doorRotation)
        end)
    end

    ringBell()
    print("\nAuto-Travel Complete.")
    pause()
end

local function recallDestination()
    clear()

    local keys = {}
    for name, _ in pairs(savedDestinations) do
        table.insert(keys, name)
    end

    if #keys == 0 then
        print("No saved destinations.")
        pause()
        return
    end

    table.sort(keys)

    for i, name in ipairs(keys) do
        print(i .. ". " .. name)
    end

    print("\nSelect destination:")
    local choice = tonumber(read())
    local selected = keys[choice]

    if not selected then return end

    clear()
    print("1. Set Only")
    print("2. Auto Travel")
    print("0. Cancel")

    local mode = read()

    if mode == "1" then
        local data = savedDestinations[selected]
        tardim.setDimension(data.dimension)
        tardim.setTravelLocation(
            data.pos.x,
            data.pos.y,
            data.pos.z
        )
        ringBell()
        print("Destination Set.")
        pause()

    elseif mode == "2" then
        autoTravel(selected)
    end
end


-- DOOR CONTROL


local function manageDoorRotation()
    clear()

    local current = tardim.getDoorRotation()
    print("Current Rotation: " .. current .. "\n")

    print("1. Set Rotation")
    print("2. Toggle")
    print("0. Back")

    local choice = read()

    if choice == "1" then
        print("Enter rotation (north/east/south/west):")
        local dir = read()
        pcall(function() tardim.setDoorRotation(dir) end)
        ringBell()
        print("Rotation Updated.")
        pause()

    elseif choice == "2" then
        tardim.toggleDoorRotation()
        ringBell()
        print("Rotation Toggled.")
        pause()
    end
end


-- HOME


local function goHome()
    clear()
    tardim.home()
    ringBell()
    print("Destination set to Home.")
    pause()
end


-- LOCK CONTROL


local function toggleLock()
    local locked = tardim.isLocked()
    tardim.setLocked(not locked)
    ringBell()
    print("Doors now: " .. tostring(not locked))
    pause()
end


-- MAIN MENU


while true do
    clear()

    print("=== TARDIM CONTROL PANEL ===\n")
    print("1. Show Status")
    print("2. Set Coordinates")
    print("3. Save Current Destination")
    print("4. Recall Saved Destination")
    print("5. Set Destination To Home")
    print("6. Door Rotation Control")
    print("7. Toggle Door Lock")
    print("0. Exit")

    print("\nSelect Option:")
    local choice = read()

    if choice == "1" then showStatus(); pause()
    elseif choice == "2" then setCoordinates()
    elseif choice == "3" then saveCurrentDestination()
    elseif choice == "4" then recallDestination()
    elseif choice == "5" then goHome()
    elseif choice == "6" then manageDoorRotation()
    elseif choice == "7" then toggleLock()
    elseif choice == "0" then break
    end
end
