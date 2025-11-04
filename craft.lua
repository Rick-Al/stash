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

-- Recursive auto-crafting function (fully scaled and recursive)
local function autoCraftItem(itemName, neededCount, recipes, depth)
    depth = depth or 0
    if depth > 6 then
        print("Too many recursive crafting levels for " .. itemName)
        return false
    end

    local subRecipe = recipes[itemName]
    if not subRecipe then
        print("No recipe found for missing item: " .. itemName)
        return false
    end

    local craftsNeeded = math.ceil(neededCount / subRecipe.output)
    print(("Auto-crafting %d of %s (%.0f crafts of recipe '%s')"):format(
        neededCount, itemName, craftsNeeded, itemName))

    -- Get inventory state
    local items = src.list()
    local inventoryCount = {}
    for _, stack in pairs(items) do
        inventoryCount[stack.name] = (inventoryCount[stack.name] or 0) + stack.count
    end

    -- Recursively ensure sub-items exist
    for subItem, perCraftNeed in pairs(subRecipe.inputs) do
        local totalNeed = perCraftNeed * craftsNeeded
        local have = inventoryCount[subItem] or 0
        if have < totalNeed then
            local missing = totalNeed - have
            print(("Need %d more %s for %s, attempting to craft..."):format(
                missing, subItem, itemName))
            if recipes[subItem] then
                local ok = autoCraftItem(subItem, missing, recipes, depth + 1)
                if not ok then
                    print("Failed to craft required " .. subItem)
                    return false
                end
            else
                print(("Missing %d of %s and no recipe exists."):format(missing, subItem))
                return false
            end
        end
    end

    -- Perform actual crafting
    for i = 1, craftsNeeded do
        for slot = 1, 9 do
            local mat = subRecipe.layout[slot]
            if mat then
                for barrelSlot, stack in pairs(src.list()) do
                    if stack.name == mat and stack.count > 0 then
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

    print(("Crafted %d %s"):format(subRecipe.output * craftsNeeded, itemName))
    return true
end

-- === Crafting logic ===
local availableCrafts, missing, have = getAvailableCrafts(recipe)
local craftsNeeded = math.ceil(count / recipe.output)

-- Check for missing items
local function ensureDependencies(recipe, craftsNeeded)
    local items = src.list()
    local inventoryCount = {}
    for _, stack in pairs(items) do
        inventoryCount[stack.name] = (inventoryCount[stack.name] or 0) + stack.count
    end

    for itemName, perCraftNeed in pairs(recipe.inputs) do
        local totalNeeded = perCraftNeed * craftsNeeded
        local have = inventoryCount[itemName] or 0
        if have < totalNeeded then
            local missingCount = totalNeeded - have
            print(("Missing %d of %s for %s"):format(missingCount, itemName, recipeName))
            if recipes[itemName] then
                autoCraftItem(itemName, missingCount, recipes)
            else
                print("No recipe found for " .. itemName)
            end
        end
    end
end

-- Try to ensure sub-items before main craft
ensureDependencies(recipe, craftsNeeded)

-- Recheck inventory after crafting dependencies
availableCrafts, missing, have = getAvailableCrafts(recipe)
if availableCrafts == 0 then
    print("Still missing ingredients after dependency crafting. Aborting.")
    return
end

print(("Crafting %d %s(s)..."):format(count, recipeName))
for i = 1, craftsNeeded do
    for slot = 1, 9 do
        local mat = recipe.layout[slot]
        if mat then
            for barrelSlot, stack in pairs(src.list()) do
                if stack.name == mat and stack.count > 0 then
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

print(("Crafted %d %s(s)!"):format(count, recipeName))
