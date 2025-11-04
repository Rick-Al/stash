-- user friendly recipe tool
local recipeFile = "recipes.tbl"

local function loadRecipes()
    if not fs.exists(recipeFile) then return {} end
    local f = fs.open(recipeFile, "r")
    local content = f.readAll()
    f.close()
    local ok, tbl = pcall(textutils.unserialize, content)
    if not ok or type(tbl) ~= "table" then
        error("Failed to read " .. recipeFile .. " (corrupt?)")
    end
    return tbl
end

local function saveRecipes(recipes)
    local f = fs.open(recipeFile, "w")
    f.write(textutils.serialize(recipes, true))
    f.close()
end

local function trim(s)
    if not s then return s end
    return s:match("^%s*(.-)%s*$")
end

local function prompt(msg, default)
    if default ~= nil then
        write(msg .. " [" .. tostring(default) .. "]: ")
    else
        write(msg .. ": ")
    end
    local res = read()
    if res == nil then return nil end
    res = trim(res)
    if res == "" and default ~= nil then return tostring(default) end
    return res
end

local function yesno(msg, default)
    local d = default and "y" or "n"
    while true do
        local r = prompt(msg .. " (y/n)", d)
        if not r then return false end
        r = r:lower()
        if r == "y" or r == "yes" then return true end
        if r == "n" or r == "no" then return false end
        print("Please answer y or n.")
    end
end

local function normalizeItemName(name)
    if not name or name == "" then return nil end
    name = trim(name)
    if name == "" then return nil end
    name = name:lower()
    if name == "none" or name == "empty" then return nil end
    -- if looks like minecraft:..., keep; otherwise prefix
    if not name:find(":") then
        return "minecraft:" .. name
    end
    return name
end

-- Main
print("=== Add / Edit Recipe ===")
print("This will add a recipe to " .. recipeFile)
print("Type 'cancel' at any prompt to abort.\n")

local recipes = loadRecipes()

-- show existing recipes
print("Existing recipes:")
if next(recipes) == nil then
    print("  (none)")
else
    for n, _ in pairs(recipes) do print(" - " .. n) end
end
print("")

-- get recipe name
local name = prompt("Recipe name (single word)")
if not name or name:lower() == "cancel" then print("Aborted."); return end
name = name:match("^%S+$") or name -- prevent spaces if desired

local exists = recipes[name] ~= nil
if exists then
    if not yesno(("Recipe '%s' exists — edit/overwrite?"):format(name), false) then
        print("Aborted."); return
    end
end

-- output quantity
local outputQty
while true do
    local s = prompt("Output quantity (how many items one craft produces)", (exists and tostring(recipes[name].output) or "1"))
    if not s or s:lower() == "cancel" then print("Aborted."); return end
    local n = tonumber(s)
    if n and n >= 1 then outputQty = math.floor(n); break end
    print("Please enter a positive integer.")
end

-- optional: output item id (if you want craft to represent item type too)
local outputItem = prompt("Optional: output item id (e.g. minecraft:planks) or leave blank to skip", (exists and recipes[name].output_item) )
if outputItem and outputItem:lower() == "cancel" then print("Aborted."); return end
outputItem = normalizeItemName(outputItem)

print("\nEnter the 3x3 layout slots (1..9).")
print("Slot numbers:\n 1 2 3\n 4 5 6\n 7 8 9")
print("For empty slot press Enter or type 'none'. Use short names like 'stick' or full names like 'minecraft:stick'.\n")

local layout = {}
for slot = 1, 9 do
    local default = nil
    if exists and recipes[name].layout and recipes[name].layout[slot] then
        default = recipes[name].layout[slot]
    end
    local s = prompt(("Slot %d"):format(slot), default)
    if not s then print("Aborted."); return end
    if s:lower() == "cancel" then print("Aborted."); return end
    local item = normalizeItemName(s)
    layout[slot] = item -- nil if empty
end

-- build inputs counts from layout
local inputs = {}
for _, v in pairs(layout) do
    if v then inputs[v] = (inputs[v] or 0) + 1 end
end

-- show summary
print("\n--- Summary ---")
print("Name: " .. name)
print("Output qty per craft: " .. outputQty)
if outputItem then print("Output item id: " .. outputItem) end
print("Layout:")
for slot = 1, 9 do
    print((" %d: %s"):format(slot, tostring(layout[slot] or "(empty)")))
end
print("Inputs (per craft):")
if next(inputs) == nil then print(" (none)") else
    for item, cnt in pairs(inputs) do print((" - %s x%d"):format(item, cnt)) end
end
print("----------------\n")

if not yesno("Save recipe to " .. recipeFile .. " ?", true) then
    print("Not saved. Done."); return
end

-- store and save
recipes[name] = {
    output = outputQty,
    output_item = outputItem,
    inputs = inputs,
    layout = layout
}

local ok, err = pcall(saveRecipes, recipes)
if not ok then
    print("Failed to save recipes: " .. tostring(err))
else
    print("Saved recipe '" .. name .. "' to " .. recipeFile)
end

print("Done.")
