local sensor = peripheral.find("gimbal_sensor")
local monitor = peripheral.find("monitor")

if not sensor then error("No gimbal sensor found") end
if not monitor then error("No monitor found") end

monitor.setTextScale(0.5)

local width, height = monitor.getSize()

-- tuning constants
local PITCH_SCALE = 2     -- how sensitive pitch is
local ROLL_SCALE  = 1     -- how sensitive roll is

local function drawHorizon(pitch, roll)
    monitor.clear()

    -- convert sensor values
    local pitchOffset = math.floor(pitch * PITCH_SCALE)
    local rollOffset = math.floor(roll * ROLL_SCALE)

    local centerY = math.floor(height / 2) + pitchOffset

    for y = 1, height do
        for x = 1, width do

            -- simple roll effect: shift horizon diagonally
            local horizonY = centerY + math.floor((x - width/2) * roll * 0.1)

            if y < horizonY then
                monitor.setCursorPos(x, y)
                monitor.write(" ") -- sky (could color blue if using colors)
            else
                monitor.setCursorPos(x, y)
                monitor.write(" ") -- ground
            end
        end
    end

    -- center indicator
    monitor.setCursorPos(math.floor(width/2), math.floor(height/2))
    monitor.write("+")
end

while true do
    local angles = sensor.getAngles()

    local pitch = angles[1]
    local roll  = angles[2]

    drawHorizon(pitch, roll)

    sleep(0.05)
end
