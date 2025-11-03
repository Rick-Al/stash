-- a simple crafting program
local relay = peripheral.find("redstone_relay")
local crafter = peripheral.find("minecraft:crafter")
local src = peripheral.find("minecraft:barrel")

local recipes = {
    bow = {
        {slot = 1, item = "minecraft:string", count = 1},
        {slot = 2, item = "minecraft:stick", count = 1},
        {slot = 4, item = "minecraft:string", count = 1},
        {slot = 6, item = "minecraft:stick", count = 1},
        {slot = 7, item = "minecraft:string", count = 1},
        {slot = 8, item = "minecraft:stick", count = 1},
    },
    planks = {
        {slot = 5, item = "minecraft:oak_log", count = 1}
    }
}

local args = {...}
if #args < 1 then
    print("Usage: craft <recipe> [amount]")
    return
end

local recipeName = args[1]
local times = tonumber(args[2]) or 1
local recipe = recipes[recipeName]

if not recipe then
    print("Unknown recipe: " .. recipeName)
    return
end

local function countItems(inv, name)
    local total = 0
    for _, item in pairs(inv) do
        if item.name == name then
            total = total + item.count
        end
    end
    return total
end

local function hasAllIngredients(recipe, times)
    local inv = src.list()
    for _, ing in ipairs(recipe) do
        local available = countItems(inv, ing.item)
        local required = ing.count * times
        if available < required then
            print(("Not enough %s (need %d, have %d)"):format(ing.item, required, available))
            return false
        end
    end
    return true
end

local function moveItemToSlot(itemName, count, slot)
    for srcSlot, item in pairs(src.list()) do
        if item.name == itemName then
            local moved = crafter.pullItems(peripheral.getName(src), srcSlot, count, slot)
            count = count - moved
            if count <= 0 then return true end
        end
    end
    return false
end

-- Pre-check before crafting
if not hasAllIngredients(recipe, times) then
    print("Crafting aborted due to missing ingredients.")
    return
end

-- Craft loop
for i = 1, times do
    print("Crafting " .. recipeName .. " " .. i .. " of " .. times)

    -- Load crafter
    for _, ing in ipairs(recipe) do
        moveItemToSlot(ing.item, ing.count, ing.slot)
    end

    -- Pulse crafter
    relay.setOutput("front", true)
    sleep(0.1)
    relay.setOutput("front", false)
    sleep(0.5)

    -- Wait for crafter reset
    sleep(0.2)
end

print("Done crafting " .. times .. " " .. recipeName .. "(s)")

