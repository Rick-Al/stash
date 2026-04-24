local sensor = peripheral.find("gimbal_sensor")
local velocitySensor = peripheral.find("velocity_sensor")
local altitudeSensor = peripheral.find("altitude_sensor")
local monitor = peripheral.find("monitor")

if not sensor then error("Missing gimbal_sensor") end
if not velocitySensor then error("Missing velocity_sensor") end
if not altitudeSensor then error("Missing altitude_sensor") end
if not monitor then error("Missing monitor") end

monitor.setTextScale(0.5)

local w, h = monitor.getSize()

-- tuning
local PITCH_SCALE = 1   -- pixels per degree
local ROLL_SCALE  = 0.025  -- horizon tilt per x-offset

-- colors
local SKY    = colors.lightBlue
local GROUND = colors.orange
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

local function getAirspeed()
    return velocitySensor.getVelocity() or 0
end

local function getAltitude()
    return altitudeSensor.getHeight() or 0
end

local function drawHUD()
    local speed = getAirspeed()
    local altitude = getAltitude()

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)

    -- Airspeed (top-left)
    monitor.setCursorPos(2, 2)
    monitor.write(string.format("IAS: %.1f m/s", speed))

    -- Altitude (top-right)
    local altText = string.format("ALT: %.0f m", altitude)
    monitor.setCursorPos(w - #altText - 1, 2)
    monitor.write(altText)
end

while true do
    local angles = sensor.getAngles()

    local roll = angles[1]
    local pitch  = -angles[2]

    drawHorizon(pitch, roll)
    drawHUD()

    sleep(0.05)
end
