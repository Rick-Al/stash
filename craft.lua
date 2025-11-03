-- a simple crafting program
local relay = peripheral.find("redstone_relay")
local crafter = peripheral.find("minecraft:crafter")
local src = peripheral.find("minecraft:barrel")

local args = {...}

if not (relay and crafter and src) then
    error("Missing peripherals! Ensure a relay, crafter, and barrel are connected.")
end

local crafterName = peripheral.getName(crafter)
local srcName = peripheral.getName(src)

if #args < 2 then
    print("Usage: craft <recipe> <count>")
    return
end

local recipeName = args[1]
local count = tonumber(args[2])

if not count or count <= 0 then
    print("Please enter a valid number")
    return
end

-- Define recipes with output quantity
local recipes = {
    planks = {
        output = 4,
        inputs = {["minecraft:oak_log"] = 1},
        layout = { [5] = "minecraft:oak_log" }
    },
    bow = {
        output = 1,
        inputs = {
            ["minecraft:stick"] = 3,
            ["minecraft:string"] = 3
        },
        layout = {
            [2] = "minecraft:stick",
            [3] = "minecraft:string",
            [4] = "minecraft:stick",
            [6] = "minecraft:string",
            [8] = "minecraft:stick",
            [9] = "minecraft:string"
        }
    }
}

-- Check if recipe exists
local recipe = recipes[recipeName]
if not recipe then
    print("Unknown recipe: " .. recipeName)
    print("Available recipes:")
    for name, _ in pairs(recipes) do
        print(" - " .. name)
    end
    return
end

-- Count how many crafts possible based on inventory
local function getAvailableCrafts(recipe)
    local items = src.list()
    local maxCrafts = math.huge

    for itemName, needed in pairs(recipe.inputs) do
        local total = 0
        for _, stack in pairs(items) do
            if stack.name == itemName then
                total = total + stack.count
            end
        end
        local crafts = math.floor(total / needed)
        if crafts < maxCrafts then
            maxCrafts = crafts
        end
    end

    return maxCrafts
end

local availableCrafts = getAvailableCrafts(recipe)
local craftsNeeded = math.ceil(count / recipe.output)

if availableCrafts == 0 then
    print("Not enough materials to craft any " .. recipeName .. "(s).")
    return
elseif availableCrafts < craftsNeeded then
    print(("Not enough materials to craft %d %s(s). Crafting %d instead."):
        format(count, recipeName, availableCrafts * recipe.output))
    craftsNeeded = availableCrafts
    count = availableCrafts * recipe.output
end

print("Crafting " .. count .. " " .. recipeName .. "(s)...")

for i = 1, craftsNeeded do
    -- Pull items for this craft
    for slot = 1, 9 do
        local item = recipe.layout[slot]
        if item then
            -- Find the item in the barrel
            for barrelSlot, stack in pairs(src.list()) do
                if stack.name == item and stack.count > 0 then
                    crafter.pullItems(srcName, barrelSlot, 1, slot)
                    break
                end
            end
        end
    end

    -- Trigger craft
    relay.setOutput("front", true)
    sleep(0.1)
    relay.setOutput("front", false)

    sleep(0.2)
end

print("Crafted " .. count .. " " .. recipeName .. "(s)!")

