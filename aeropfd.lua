local sensor = peripheral.find("gimbal_sensor")
local monitor = peripheral.find("monitor")

if not sensor then error("No gimbal sensor found") end
if not monitor then error("No monitor found") end

monitor.setTextScale(0.5)

local w, h = monitor.getSize()

-- tuning
local PITCH_SCALE = 1.2   -- pixels per degree
local ROLL_SCALE  = 0.08  -- horizon tilt per x-offset

-- colors
local SKY    = colors.lightBlue
local GROUND = colors.brown
local HORIZON = colors.white

local function drawPixel(x, y, color)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(color)
    monitor.write(" ")
end

local function drawHorizon(pitch, roll)
    monitor.clear()

    local centerY = math.floor(h / 2)

    -- horizon line base (shifted by pitch)
    local horizonBase = centerY + math.floor(pitch * PITCH_SCALE)

    -- DRAW SKY / GROUND WITH ROLL EFFECT
    for y = 1, h do
        for x = 1, w do

            -- roll tilts horizon
            local rollOffset = math.floor((x - w/2) * roll * ROLL_SCALE)
            local horizonY = horizonBase + rollOffset

            if y < horizonY then
                drawPixel(x, y, SKY)
            else
                drawPixel(x, y, GROUND)
            end
        end
    end

    -- DRAW HORIZON LINE
    for x = 1, w do
        local rollOffset = math.floor((x - w/2) * roll * ROLL_SCALE)
        local y = horizonBase + rollOffset

        if y >= 1 and y <= h then
            drawPixel(x, y, HORIZON)
        end
    end

    -- DRAW PITCH LADDER
    drawPitchLadder(pitch, roll, horizonBase)
end

function drawPitchLadder(pitch, roll, horizonBase)
    local spacing = 10 -- degrees per ladder step

    for angle = -30, 30, spacing do
        local yOffset = math.floor((pitch - angle) * PITCH_SCALE)

        local y = math.floor(h / 2) + yOffset

        if y > 1 and y < h then

            local lineLength = 6
            local centerX = math.floor(w / 2)

            -- small horizontal line (left/right ticks)
            for dx = -lineLength, lineLength do
                local x = centerX + dx

                if x >= 1 and x <= w then
                    drawPixel(x, y, HORIZON)
                end
            end

            -- label (e.g. 10, 20, 30)
            monitor.setCursorPos(centerX + lineLength + 2, y)
            monitor.setBackgroundColor(colors.black)
            monitor.setTextColor(colors.white)

            if angle ~= 0 then
                monitor.write(tostring(math.abs(angle)))
            end
        end
    end
end

while true do
    local angles = sensor.getAngles()

    local pitch = angles[1]
    local roll  = angles[2]

    drawHorizon(pitch, roll)

    sleep(0.05)
end
