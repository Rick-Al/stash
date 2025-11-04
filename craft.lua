-- simple crafting program
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

-- Load recipes from recipes.tbl file
local recipeFile = "recipes.tbl"
local recipes = {}

-- If the recipe file is missing, download it from GitHub
if not fs.exists(recipeFile) then
    print("recipes.tbl not found. Downloading default recipe file...")
    local url = "https://raw.githubusercontent.com/Rick-Al/stash/refs/heads/main/recipes.tbl"
    shell.run("wget", url, recipeFile)
end

-- Load file
if fs.exists(recipeFile) then
    local f = fs.open(recipeFile, "r")
    local data = f.readAll()
    f.close()

    local ok, tbl = pcall(textutils.unserialize, data)
    if ok and type(tbl) == "table" then
        recipes = tbl
    else
        error("Failed to load recipes.tbl")
    end
else
    error("Could not load or download recipes.tbl")
end

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
    local inventoryCount = {}

    -- Build a quick lookup table of items in the barrel
    for _, stack in pairs(items) do
        inventoryCount[stack.name] = (inventoryCount[stack.name] or 0) + stack.count
    end

    local missing = {}

    for itemName, needed in pairs(recipe.inputs) do
        local total = inventoryCount[itemName] or 0
        local crafts = math.floor(total / needed)
        if crafts < maxCrafts then
            maxCrafts = crafts
        end

        if total < needed then
            missing[itemName] = { have = total, need = needed }
        end
    end

    return maxCrafts, missing, inventoryCount
end

-- Recursive auto-crafting function
local function autoCraftItem(itemName, neededCount, recipes, depth)
    depth = depth or 0
    if depth > 5 then
        print("Too many recursive crafting levels for " .. itemName)
        return false
    end

    local subRecipe = recipes[itemName]
    if not subRecipe then
        print("No recipe found for missing item: " .. itemName)
        return false
    end

    -- How many crafts are needed to produce enough of the missing item
    local craftsNeeded = math.ceil(neededCount / subRecipe.output)
    print(("Auto-crafting %d of %s (%.0f crafts of %s)"):format(
        neededCount, itemName, craftsNeeded, itemName))

    -- Recursively ensure we have sub-items for this subrecipe
    local availableCrafts, missing, have = getAvailableCrafts(subRecipe)
    if availableCrafts < craftsNeeded then
        for subItem, info in pairs(subRecipe.inputs) do
            local total = have[subItem] or 0
            local required = info * craftsNeeded
            if total < required then
                local toMake = required - total
                autoCraftItem(subItem, toMake, recipes, depth + 1)
            end
        end
    end

    -- Actually craft it
    for i = 1, craftsNeeded do
        for slot = 1, 9 do
            local item = subRecipe.layout[slot]
            if item then
                for barrelSlot, stack in pairs(src.list()) do
                    if stack.name == item and stack.count > 0 then
                        crafter.pullItems(srcName, barrelSlot, 1, slot)
                        break
                    end
                end
            end
        end

        relay.setOutput("front", true)
        sleep(0.1)
        relay.setOutput("front", false)
        sleep(0.2)
    end

    print(("Crafted %d of %s"):format(subRecipe.output * craftsNeeded, itemName))
    return true
end

local availableCrafts, missing, have = getAvailableCrafts(recipe)
local craftsNeeded = math.ceil(count / recipe.output)

if availableCrafts == 0 then
    print("Not enough materials to craft any " .. recipeName .. "(s).")
    print("\nMissing ingredients:")
    for itemName, info in pairs(recipe.inputs) do
        local total = have[itemName] or 0
        local need = info
        if total < need then
            local missingCount = need - total
            print((" - %s: need %d, have %d (missing %d)"):format(itemName, need, total, missingCount))

            -- Try to craft the missing items if recipe exists
            if recipes[itemName] then
                autoCraftItem(itemName, missingCount, recipes)
            else
                print("No recipe found for " .. itemName)
            end
        end
    end

    -- After attempting auto-crafting, recheck inventory
    availableCrafts, missing, have = getAvailableCrafts(recipe)
    if availableCrafts == 0 then
        print("\nStill not enough materials for " .. recipeName .. ".")
        return
    else
        print("\nDependencies crafted! Proceeding with " .. recipeName .. "...")
    end
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
