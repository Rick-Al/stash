local function prompt(msg, default)
  if default then
    io.write(msg .. " [" .. tostring(default) .. "]: ")
  else
    io.write(msg .. ": ")
  end
  local line = read()
  if line == "" or line == nil then
    return default
  end
  return line
end

local function tonumber_or_nil(s)
  if s == nil then return nil end
  local n = tonumber(s)
  return n
end

-- currency helpers (work in bronze units)
local function breakdown_bronze(totalBronze)
  totalBronze = math.max(0, math.floor(totalBronze + 0.5))
  local gold = math.floor(totalBronze / 10000)
  local rem = totalBronze % 10000
  local silver = math.floor(rem / 100)
  local bronze = rem % 100
  return gold, silver, bronze
end

local function format_currency(bronzeTotal)
  local g, s, b = breakdown_bronze(bronzeTotal)
  local parts = {}
  if g > 0 then table.insert(parts, tostring(g) .. " gold") end
  if s > 0 then table.insert(parts, tostring(s) .. " silver") end
  if b > 0 then table.insert(parts, tostring(b) .. " bronze") end
  if #parts == 0 then return "0 bronze" end
  return table.concat(parts, ", ")
end

-- Pricing in bronze per block:
local PRICES = {
  commercial = 100,   -- 1 silver = 100 bronze per block
  residential = 75,   -- 75 bronze per block
  industrial = 125,   -- 1 silver + 25 bronze = 125 bronze per block
  public = 0
}

local function choose_zone()
  print("\nChoose zoning type (enter number):")
  print("  1) Commercial (1 silver / block)")
  print("  2) Residential (75 bronze / block)")
  print("  3) Industrial (1 silver 25 bronze / block)")
  print("  4) Public (free)")
  while true do
    io.write("Choice [1-4]: ")
    local c = read()
    if c == "1" then return "commercial" end
    if c == "2" then return "residential" end
    if c == "3" then return "industrial" end
    if c == "4" then return "public" end
    print("Invalid choice. Enter 1,2,3 or 4.")
  end
end

-- Compute inclusive area from coordinates (Minecraft-style)
local function area_from_coords(x1, z1, x2, z2)
  local w = math.abs(x2 - x1) + 1
  local h = math.abs(z2 - z1) + 1
  return w * h, w, h
end

-- Build deed text
local function build_deed(params)
  local lines = {}
  table.insert(lines, "---------------------------- DEED ----------------------------")
  table.insert(lines, string.format("Owner: %s", params.name))
  table.insert(lines, string.format("Address: %s", params.address))
  table.insert(lines, string.format("Coordinates: (%d, %d) to (%d, %d)", params.x1, params.z1, params.x2, params.z2))
  table.insert(lines, string.format("Dimensions: %d x %d blocks", params.width, params.depth))
  table.insert(lines, string.format("Area: %d blocks squared", params.area))
  table.insert(lines, string.format("Zoning: %s", params.zone:gsub("^%l", string.upper))) -- Capitalize first letter
  table.insert(lines, string.format("Price per block: %s", format_currency(params.pricePerBlock)))
  table.insert(lines, string.format("Total price: %s", format_currency(params.totalPriceBronze)))
  table.insert(lines, "")
  table.insert(lines, string.format("Date issued: %s", params.date))
  table.insert(lines, "---------------------------------------------------------------")
  return table.concat(lines, "\n")
end

-- Try to print to a connected printer peripheral.
-- Returns: (true, "message") on success, (false, "error message") on failure.
local function try_print_to_printer(text, address)
  if not peripheral then
    return false, "Peripheral API unavailable."
  end

  local pr = peripheral.find("printer")
  if not pr then
    return false, "No printer found."
  end

  -- Begin printing
  if not pr.newPage() then
    return false, "Printer could not start a new page (no paper or no ink?)."
  end

  -- Dynamic page title based on the address
  pr.setPageTitle(address or "Land Deed")

  -- Write text line-by-line (printers only support ~25 chars per line)
  for line in text:gmatch("[^\n]+") do
    pr.write(line)
    pr.write("\n")
  end

  pr.endPage()  -- finalize the page
  pr.endJob()   -- eject printed page

  return true, "Printed successfully."
end

-- MAIN
print("=== Land Deed Creator ===")

local name = prompt("Enter owner name")
local address = prompt("Enter address")

-- Coordinates input (re-prompt until valid numbers)
local x1,z1,x2,z2
while true do
  io.write("Enter x1 (X coordinate): ")
  x1 = tonumber(read())
  io.write("Enter z1 (Z coordinate): ")
  z1 = tonumber(read())
  io.write("Enter x2 (X coordinate): ")
  x2 = tonumber(read())
  io.write("Enter z2 (Z coordinate): ")
  z2 = tonumber(read())

  if x1 and z1 and x2 and z2 then break end
  print("Invalid coordinate(s). Please enter numeric values (negative allowed).")
end

local zone = choose_zone()

local area, width, depth = area_from_coords(x1, z1, x2, z2)
local pricePerBlockBronze = PRICES[zone] or 0
local totalPriceBronze = pricePerBlockBronze * area

local date = os.date("%Y-%m-%d") -- ISO date

local params = {
  name = name or "",
  address = address or "",
  x1 = x1,
  z1 = z1,
  x2 = x2,
  z2 = z2,
  width = width,
  depth = depth,
  area = area,
  zone = zone,
  pricePerBlock = pricePerBlockBronze,
  totalPriceBronze = totalPriceBronze,
  date = date
}

local deedText = build_deed(params)

-- Show summary on screen
print("\n--- Summary ---")
print("Owner: " .. params.name)
print("Address: " .. params.address)
print(string.format("Area: %d blocks ( %d x %d )", params.area, params.width, params.depth))
print("Zone: " .. zone)
print("Total cost: " .. format_currency(params.totalPriceBronze))
print("----------------\n")

-- Attempt to print to printer (no pcall wrapper here; function handles its own protection)
local success, info = try_print_to_printer(deedText, params.address)
if success then
  print("Deed sent to printer: " .. info)
else
  print("Printer unavailable or failed: " .. info)
  print("\nShowing deed on screen instead:\n")
  print(deedText)
end

print("\nDone. (If attached printer didn't print, check peripheral wiring and printer paper/ink.)")
