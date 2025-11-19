-- currency
local function convertBronze(totalBronze)
    local gold = math.floor(totalBronze / 10000)
    totalBronze = totalBronze % 10000

    local silver = math.floor(totalBronze / 100)
    local bronze = totalBronze % 100

    return gold, silver, bronze
end

-- wrap
local function wrapLine(line, maxWidth)
    local out = {}
    while #line > maxWidth do
        table.insert(out, line:sub(1, maxWidth))
        line = line:sub(maxWidth + 1)
    end
    table.insert(out, line)
    return out
end

-- printing
local function try_print_to_printer(text, address)
    local pr = peripheral.find("printer")
    if not pr then
        return false, "No printer found."
    end

    if not pr.newPage() then
        return false, "Unable to start a page (paper or ink missing)."
    end

    pr.setPageTitle(address or "Land Deed")

    local maxWidth = 26
    local cursorX = 1
    local cursorY = 1

    local function printLine(str)
        pr.setCursorPos(cursorX, cursorY)
        pr.write(str)
        cursorY = cursorY + 1

        if cursorY > 21 then
            pr.endPage()
            pr.newPage()
            pr.setPageTitle(address or "Land Deed")
            cursorY = 1
        end
    end

    for line in text:gmatch("[^\n]+") do
        local wrapped = wrapLine(line, maxWidth)
        for _, segment in ipairs(wrapped) do
            printLine(segment)
        end
    end

    pr.endPage()
    return true, "Printed successfully."
end

-- main
term.clear()
term.setCursorPos(1,1)
print("City of Sun Stone Shores Auto Deed Kiosk")
print()

write("Owner name: ")
local owner = read()

write("Address or Lot name: ")
local address = read()

print("")
print("Enter coordinates (X and Z only): ")
write("X1: ") local x1 = tonumber(read())
write("Z1: ") local z1 = tonumber(read())
write("X2: ") local x2 = tonumber(read())
write("Z2: ") local z2 = tonumber(read())

-- dimensions
local width = math.abs(x2 - x1) + 1
local height = math.abs(z2 - z1) + 1
local area = width * height

-- zoning
print("")
print("Zoning Types:")
print("1) Commercial (1 silver/block)")
print("2) Residential (75 bronze/block)")
print("3) Industrial (1s 25b/block)")
print("4) Public")

write("Select zoning type (1-4): ")
local zoneChoice = tonumber(read())

local zoneName = ""
local priceBronze = 0

if zoneChoice == 1 then
    zoneName = "Commercial"
    priceBronze = 100 -- 1 silver
elseif zoneChoice == 2 then
    zoneName = "Residential"
    priceBronze = 75
elseif zoneChoice == 3 then
    zoneName = "Industrial"
    priceBronze = 125 -- 1 silver (100) + 25 bronze
elseif zoneChoice == 4 then
    zoneName = "Public"
    priceBronze = 0
else
    print("Invalid zoning choice.")
    return
end

-- price calculation
local totalBronze = area * priceBronze
local gold, silver, bronze = convertBronze(totalBronze)

-- date
local dateStr = os.date("%B %e %Y")

-- build deed text
local deedText =
    " OFFICIAL DEED FOR LAND \n" ..
    "" ..
    "Owner: " .. owner .. "\n" ..
    "" ..
    "Address: " .. address .. "\n" ..
    "" ..
    string.format("Coords: (%d,%d) to (%d,%d)\n", x1, z1, x2, z2) ..
    "" ..
    string.format("Size: %d x %d\n", width, height) ..
    "" ..
    "Area: " .. area .. " sqB\n" ..
    "" ..
    "Zoning: " .. zoneName .. "\n" ..
    "" ..
    "Price per block: " .. priceBronze .. " b\n" ..
    "" ..
    "Total cost:\n" ..
    string.format("  %d g, %d s, %d b\n", gold, silver, bronze) ..
    "" ..
    "Date issued: " .. dateStr .. "\n"

-- print deed
print("\nPrinting deed...")

local ok, msg = try_print_to_printer(deedText, address)
if ok then
    print("Success: " .. msg)
else
    print("ERROR: " .. msg)
end

print("\nDone.")
sleep(3)
os.reboot()
