local mon = peripheral.find("monitor")
if not mon then error("No monitor found!") end

mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.clear()

-- Load the map image (map.nfp)
local map = paintutils.loadImage("map.nfp")
if not map then error("map.nfp not found") end

local function drawMap()
    local old = term.redirect(mon)
    paintutils.drawImage(map, 1, 1)
    term.redirect(old)
end

drawMap()

-- Station list
local stations = {
    { name="Cam Mountain",         x=1,  y=1,  lines={"Green"},               radius=1 },
    { name="Isle Jared",           x=4,  y=1,  lines={"Green"},               radius=1 },
    { name="World Trade Center",   x=6,  y=13, lines={"Green","Red","Blue"},  radius=1 },
    { name="Empire",               x=17, y=3,  lines={"Red"},                 radius=1 },
    { name="Park Street",          x=20, y=13, lines={"Red","Blue"},          radius=1 },
    { name="Moonstone",            x=30, y=13, lines={"Blue"},                radius=1 },
    { name="Aiport",               x=33, y=17, lines={"Blue"},                radius=1 },
    { name="Brick Blvd",           x=12, y=20, lines={"Red"},                 radius=1 },
    { name="Midtown",              x=20, y=20, lines={"Red"},                 radius=1 },
    { name="Dylan Castle",         x=2,  y=35, lines={"Green"},               radius=1 },
    { name="Industry",             x=6,  y=32, lines={"Red"},                 radius=1 },
    { name="South Side",           x=24, y=31, lines={"Blue"},                radius=1 },
    { name="East Chris",           x=23, y=36, lines={"Blue"},                radius=1 },
    { name="West Chris",           x=31, y=36, lines={"Blue"},                radius=1 },
}

-- Color mapping for line names
local LINE_COLORS = {
    Red   = colors.red,
    Blue  = colors.blue,
    Green = colors.green
}

-- Draw station highlight
local function highlight(st)
    local old = term.redirect(mon)
    paintutils.drawPixel(st.x, st.y, colors.yellow)
    term.redirect(old)
end

-- Popup Window
local function drawPopup(st)
    local old = term.redirect(mon)

    -- Popup box size
    local w, h = mon.getSize()
    local boxW = 22
    local boxH = 5
    local boxX = math.floor((w - boxW) / 2)
    local boxY = math.floor((h - boxH) / 2)

    -- Draw popup background
    mon.setBackgroundColor(colors.gray)
    mon.setTextColor(colors.black)
    paintutils.drawFilledBox(boxX, boxY, boxX + boxW, boxY + boxH, colors.gray)

    -- Station name
    mon.setCursorPos(boxX + 1, boxY + 1)
    mon.write(st.name)

    -- Lines served
    mon.setCursorPos(boxX + 1, boxY + 3)
    mon.write("Lines: ")

    local colX = boxX + 9
    for _, line in ipairs(st.lines) do
        mon.setCursorPos(colX, boxY + 3)
        mon.setBackgroundColor(LINE_COLORS[line] or colors.white)
        mon.write("  ")
        colX = colX + 3
    end

    term.redirect(old)
end

-- Main loop
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")

    -- Clear popup and redraw map
    drawMap()

    local tapped = false

    for _, st in ipairs(stations) do
        local dx = x - st.x
        local dy = y - st.y
        if dx * dx + dy * dy <= st.radius * st.radius then
            highlight(st)
            drawPopup(st)
            tapped = true
            break
        end
    end
end
