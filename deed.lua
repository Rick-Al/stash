-- Convert total bronze into bronze/silver/gold tables
local function convertBronze(totalBronze)
    local gold = math.floor(totalBronze / 10000)
    totalBronze = totalBronze % 10000

    local silver = math.floor(totalBronze / 100)
    local bronze = totalBronze % 100

    return gold, silver, bronze
end

-- Word wrap utility
local function wrapLine(line, maxWidth)
    local out = {}
    while #line > maxWidth do
        table.insert(out, line:sub(1, maxWidth))
        line = line:sub(maxWidth + 1)
    end
    table.insert(out, line)
    return out
end

-- Printer output with wrapping
local function try_print_to_printer(text, address)
    local pr = peripheral.find("printer")
    if not pr then
        return false, "No printer found."
    end

    if not pr.newPage() then
        return false, "Unable to start page. (Ink or paper?)"
    end

    pr.setPageTitle(address or "Land Deed")

    for line in text:gmatch("[^\n]+") do
        local wrapped = wrapLine(line, 26)
        for _, segment in ipairs(wrapped) do
            pr.write(segment)
            pr.write("\n")
        end
    end

    pr.endPage()
    return true, "Printed successfully."
end

-- MAIN
term.clear()
term.setCursorPos(1,1)
print("=== LAND DEED CREATOR ===")

-- Collect user info
write("Owner name: ")
local owner = read()

write("Address / Lot name: ")
local address = read()

print("\nEnter coordinates (inclusive area):")
write("X1: ") local x1 = tonumber(read())
write("Z1: ") local z1 = tonumber(read())
write("X2: ") local x2 = tonumber(read())
write("Z2: ") local z2 = tonumber(read())

-- Dimensions
local width = math.abs(x2 - x1) + 1
local height = math.abs(z2 - z1) + 1
local area = width * height

-- Zoning selection
print("\nZoning Types:")
print("1) Commercial (1 silver/block)")
print("2) Residential (75 bronze/block)")
print("3) Industrial (1s 25b/block)")
print("4) Public (FREE)")

write("Select zoning type (1-4): ")
local zoneChoice = tonumber(read())

local zoneName = ""
local priceBronze = 0

if zoneChoice == 1 then
    zoneName = "Commercial"
    priceBronze = 100 -- 1 silver = 100 bronze
elseif zoneChoice == 2 then
    zoneName = "Residential"
    priceBronze = 75
elseif zoneChoice == 3 then
    zoneName = "Industrial"
    priceBronze = 125 -- 1s25b = 100 + 25
elseif zoneChoice == 4 then
    zoneName = "Public"
    priceBronze = 0
else
    print("Invalid choice! Exiting.")
    return
end

local totalBronze = area * priceBronze
local gold, silver, bronze = convertBronze(totalBronze)

-- Date
local dateStr = textutils.formatTime(os.time(), false)

-- Create deed text
local deedText = ""
    .. "----------- DEED -----------\n"
    .. "Owner: " .. owner .. "\n"
    .. "Address: " .. address .. "\n"
    .. string.format("Coords: (%d,%d) to (%d,%d)\n", x1, z1, x2, z2)
    .. string.format("Size: %d x %d blocks\n", width, height)
    .. "Area: " .. area .. " blocks\n"
    .. "Zoning: " .. zoneName .. "\n"
    .. "Price per block: " .. priceBronze .. " bronze\n"
    .. "Total cost:\n"
    .. string.format("  %d gold, %d silver, %d bronze\n", gold, silver, bronze)
    .. "Date issued: " .. dateStr .. "\n"
    .. "----------------------------\n"


-- Print deed
print("\nPrinting deed...")
local ok, msg = try_print_to_printer(deedText, address)

if ok then
    print("Success: " .. msg)
else
    print("Error: " .. msg)
end

print("\nDone.")
