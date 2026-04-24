local sensor = peripheral.find("gimbal_sensor")

if not sensor then
    error("No gimbal sensor found")
end

local w, h = term.getSize()

local centerX = math.floor(w / 2)
local centerY = math.floor(h / 2)

-- tweak these
local pitchScale = 0.15
local rollScale = 0.04

local function normalize(angle)
    if angle > 180 then
        return angle - 360
    end
    return angle
end

local function clear()
    term.setBackgroundColor(colors.black)
    term.clear()
end

local function drawHorizon(pitch, roll)
    -- convert pitch into vertical offset
    local baseY = centerY + pitch * pitchScale

    for x = 1, w do
        local offset = (x - centerX) * roll * rollScale
        local y = math.floor(baseY + offset)

        -- draw sky + ground
        for yy = 1, h do
            term.setCursorPos(x, yy)

            if yy < y then
                term.setBackgroundColor(colors.blue)   -- sky
            else
                term.setBackgroundColor(colors.brown)  -- ground
            end

            term.write(" ")
        end

        -- draw horizon line
        if y >= 1 and y <= h then
            term.setCursorPos(x, y)
            term.setBackgroundColor(colors.white)
            term.write(" ")
        end
    end
end

while true do
    local angles = sensor.getAngles()
    local pitch = normalize(angles[1])
    local roll  = normalize(angles[2])

    clear()
    drawHorizon(pitch, roll)

    sleep(0.05)
end
