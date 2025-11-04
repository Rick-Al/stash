-- simple recursive crafting program (network version)
local relay = peripheral.find("redstone_relay")
local crafter = peripheral.find("minecraft:crafter")

if not (relay and crafter) then
    error("Missing peripherals! Ensure a relay and crafter are connected.")
end

local crafterName = peripheral.getName(crafter)

-- Find all connected inventories (chests, barrels, etc.)
local inventories = {}
for _, name in ipairs(peripheral.getNames()) do
    local methods = peripheral.getMethods(name)
    if methods and table.concat(methods, " "):find("list") and name ~= crafterName then
        table.insert(inventories, name)
    end
end

if #inventories == 0 then
    error("No storage inventories found on the network.")
else
    print("Connected inventories:")
    for _, inv in ipairs(inventories) do print(" - " .. inv) end
end

-- Parse arguments
local args = {...}
if #args < 2 then
    print("Usage: craft <recipe> <count>")
    return
end

local recipeNameArg = args[1]
local count = tonumber(args[2])

if not count or count <= 0 then
    print("Please enter a valid number")
    return
end

-- Load recipes
local recipeFile = "recipes.tbl"
local recipes = {}

if not fs.exists(recipeFile) then
    print("recipes.tbl not found. Downloading default recipe file...")
    local url = "https://raw.githubusercontent.com/Rick-Al/stash/refs/heads/main/recipes.tbl"
    shell.run("wget", url, recipeFile)
end

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

-- Normalize recipe input and fuzzy match
local recipeName = recipeNameArg
if not recipeName:find(":") then
    recipeName = "minecraft:" .. recipeName
end

if not recipes[recipeName] then
    local matches = {}
    local lowerArg = recipeNameArg:lower()
    for name, _ in pairs(recipes) do
        if name:lower():find(lowerArg) then
            table.insert(matches, name)
        end
    end

    if #matches == 1 then
        print("Assuming you meant: " .. matches[1])
        recipeName = matches[1]
    elseif #matches > 1 then
        print("Multiple possible matches found for '" .. recipeNameArg .. "':")
        for _, name in ipairs(matches) do print(" - " .. name) end
        return
    else
        print("Unknown recipe: " .. recipeNameArg)
        print("Available recipes:")
        for name, _ in pairs(recipes) do print(" - " .. name) end
        return
    end
end

local recipe = recipes[recipeName]
if not recipe then
    error("Recipe missing or failed to load: " .. recipeName)
end

-- Helper functions
local function getAllItems()
    local total = {}
    for _, inv in ipairs(inventories) do
        for slot, stack in pairs(peripheral.call(inv, "list")) do
            total[stack.name] = (total[stack.name] or 0) + stack.count
        end
    end
    return total
end

local function pullItemFromNetwork(itemName, count, destSlot)
    for _, inv in ipairs(inventories) do
        for slot, stack in pairs(peripheral.call(inv, "list")) do
            if stack.name == itemName and count > 0 then
                local moved = crafter.pullItems(inv, slot, count, destSlot)
                count = count - moved
                if count <= 0 then return true end
            end
        end
    end
    return count <= 0
end

local function getAvailableCrafts(recipe)
    local allItems = getAllItems()
    local maxCrafts = math.huge
    local missing = {}
    for itemName, needed in pairs(recipe.inputs) do
        local total = allItems[itemName] or 0
        local crafts = math.floor(total / needed)
        if crafts < maxCrafts then maxCrafts = crafts end
        if total < needed then
            missing[itemName] = { have = total, need = needed }
        end
    end
    return maxCrafts, missing, allItems
end

-- Recursive auto-crafter
local function autoCraftItem(itemName, neededCount, depth)
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

    local allItems = getAllItems()
    for subItem, perCraftNeed in pairs(subRecipe.inputs) do
        local totalNeed = perCraftNeed * craftsNeeded
        local have = allItems[subItem] or 0
        if have < totalNeed then
            local missing = totalNeed - have
            print(("Need %d more %s for %s, attempting to craft..."):format(
                missing, subItem, itemName))
            if recipes[subItem] then
                local ok = autoCraftItem(subItem, missing, depth + 1)
                if not ok then return false end
            else
                print(("Missing %d of %s and no recipe exists."):format(missing, subItem))
                return false
            end
        end
    end

    for i = 1, craftsNeeded do
        for slot = 1, 9 do
            local mat = subRecipe.layout[slot]
            if mat then
                pullItemFromNetwork(mat, 1, slot)
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

-- === Main crafting logic ===
local availableCrafts, missing, have = getAvailableCrafts(recipe)
local craftsNeeded = math.ceil(count / recipe.output)

-- Ensure dependencies
for itemName, perCraftNeed in pairs(recipe.inputs) do
    local totalNeeded = perCraftNeed * craftsNeeded
    local have = (have[itemName] or 0)
    if have < totalNeeded then
        local missingCount = totalNeeded - have
        print(("Missing %d of %s for %s"):format(missingCount, itemName, recipeName))
        if recipes[itemName] then
            autoCraftItem(itemName, missingCount)
        else
            print("No recipe found for " .. itemName)
        end
    end
end

-- Recheck
availableCrafts, missing = getAvailableCrafts(recipe)
if availableCrafts == 0 then
    print("Still missing ingredients after dependency crafting. Aborting.")
    for k, v in pairs(missing) do
        print(("- %s: have %d / need %d"):format(k, v.have, v.need))
    end
    return
end

print(("Crafting %d %s(s)..."):format(count, recipeName))
for i = 1, craftsNeeded do
    for slot = 1, 9 do
        local mat = recipe.layout[slot]
        if mat then pullItemFromNetwork(mat, 1, slot) end
    end
    relay.setOutput("front", true)
    sleep(0.1)
    relay.setOutput("front", false)
    sleep(0.2)
end

print(("Crafted %d %s(s)!"):format(count, recipeName))
