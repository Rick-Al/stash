local relay = peripheral.find("redstone_relay")
local crafter = peripheral.find("minecraft:crafter")
local src = peripheral.find("minecraft:barrel")
local args = {...}

if #args < 1 then
    print("Usage: planks <number of times to craft>")
    return
end

local count = tonumber(args[1])

if not count then
    print("Please enter a valid number")
    return
end

for i = 1, count do
    print("Crafting item " .. i .. " of " .. count)
    
    crafter.pullItems(peripheral.getName(src), 1, 1)

    relay.setOutput("front", true)
    sleep(0.1)
    relay.setOutput("front", false)
    
    sleep(0.2)
end

print("Done crafting " .. count .. " times!")
--shell.run("scan")
