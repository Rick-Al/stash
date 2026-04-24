local sensor = peripheral.find("gimbal_sensor")
local velocitySensor = peripheral.find("velocity_sensor")
local altitudeSensor = peripheral.find("altitude_sensor")
local monitor = peripheral.find("monitor")

local lastAlt = nil
local lastTime = os.clock()
local vsi = 0

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

local function updateVSI(altitude)
    local t = os.clock()

    if lastAlt then
        local dt = t - lastTime
        if dt > 0 then
            vsi = (altitude - lastAlt) / dt
        end
    end

    lastAlt = altitude
    lastTime = t

    return vsi
end

local function drawSpeedTape(speed)
    local centerX = 4
    local centerY = math.floor(h / 2)

    local range = 20  -- m/s above/below center
    local step = 5

    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)

    for offset = -range, range, step do
        local value = speed + offset
        local y = centerY - offset

        if y >= 1 and y <= h then
            monitor.setCursorPos(centerX, y)
            monitor.write(string.format("%3d", value))
        end
    end

    -- current speed marker
    monitor.setCursorPos(1, centerY)
    monitor.write(">")
end

local function getAirspeed()
    return velocitySensor.getVelocity() or 0
end

local function getAltitude()
    return altitudeSensor.getHeight() or 0
end

local function drawAltitudeTape(altitude)
    local centerX = w - 8
    local centerY = math.floor(h / 2)

    local range = 50  -- meters above/below center
    local step = 10

    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)

    for offset = -range, range, step do
        local value = altitude + offset
        local y = centerY - math.floor(offset / 2)

        if y >= 1 and y <= h then
            monitor.setCursorPos(centerX, y)
            monitor.write(string.format("%4d", value))
        end
    end

    -- current altitude marker
    monitor.setCursorPos(w - 10, centerY)
    monitor.write("<")
end

local function drawVSI(vsiValue)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(math.floor(w / 2) - 5, 2)
    monitor.write(string.format("VSI: %+0.2f m/s", vsiValue))
end

local function drawHUD()
    local speed = velocitySensor.getVelocity() or 0
    local altitude = altitudeSensor.getHeight() or 0

    local vsiValue = updateVSI(altitude)

    drawSpeedTape(speed)
    drawAltitudeTape(altitude)
    drawVSI(vsiValue)
end

while true do
    local angles = sensor.getAngles()

    local roll = angles[1]
    local pitch  = -angles[2]

    drawHorizon(pitch, roll)
    drawHUD()

    sleep(0.05)
end
