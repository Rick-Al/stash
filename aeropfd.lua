local sensor = peripheral.find("gimbal_sensor")

if not sensor then
    error("No gimbal sensor found")
end

local w, h = term.getSize()

local centerX = math.floor(w / 2)
local centerY = math.floor(h / 2)

-- tuning values (you WILL tweak these)
local pitchScale = 0.2   -- how sensitive vertical movement is
local rollScale = 0.05   -- how steep the tilt is

local function clear()
    term.setBackgroundColor(colors.black)
    term.clear()
end

local function drawHorizon(pitch, roll)
    clear()

    -- base vertical offset from pitch
    local baseY = centerY + pitch * pitchScale

    for x = 1, w do
        -- apply roll tilt across screen
        local offset = (x - centerX) * roll * rollScale
        local y = math.floor(baseY + offset)

        if y >= 1 and y <= h then
            term.setCursorPos(x, y)

            -- draw horizon line
            term.setBackgroundColor(colors.white)
            term.write(" ")
        end

        -- fill sky above
        for yy = 1, y - 1 do
            term.setCursorPos(x, yy)
            term.setBackgroundColor(colors.blue)
            term.write(" ")
        end

        -- fill ground below
        for yy = y + 1, h do
            term.setCursorPos(x, yy)
            term.setBackgroundColor(colors.brown)
            term.write(" ")
        end
    end
end

while true do
    local xRot, zRot = sensor.getAngles()

    local pitch = xRot
    local roll = zRot

    drawHorizon(pitch, roll)

    sleep(0.05)
end
