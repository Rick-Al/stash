-- Interactive recipe creator for recipes.tbl

local recipeFile = "recipes.tbl"

-- Load existing recipes or create a new table
local recipes = {}
if fs.exists(recipeFile) then
    local file = fs.open(recipeFile, "r")
    local content = file.readAll()
    file.close()
    recipes = textutils.unserialize(content) or {}
else
    print("No recipes.tbl found, starting with an empty list.")
end

-- Get new recipe name
print("Enter recipe name (e.g. minecraft:torch):")
local name = read()

if recipes[name] then
    print("A recipe with that name already exists. Overwrite it? (y/n)")
    if read():lower() ~= "y" then
        print("Cancelled.")
        return
    end
end

-- Get output quantity
print("Enter output quantity (number):")
local output = tonumber(read())
if not output or output <= 0 then
    print("Invalid number.")
    return
end

-- Collect layout (1–9)
local layout = {}
print("\nEnter item IDs for each slot (1–9). Leave blank if empty.")
for i = 1, 9 do
    io.write("Slot " .. i .. ": ")
    local item = read()
    if item ~= "" then
        layout[i] = item
    end
end

-- Build inputs automatically (count items in layout)
local inputs = {}
for _, item in pairs(layout) do
    inputs[item] = (inputs[item] or 0) + 1
end

-- Build the final recipe
local newRecipe = {
    output = output,
    inputs = inputs,
    layout = layout
}

-- Save to table
recipes[name] = newRecipe

-- Write to file
local file = fs.open(recipeFile, "w")
file.write(textutils.serialize(recipes))
file.close()

print("\nRecipe '" .. name .. "' added successfully!")
