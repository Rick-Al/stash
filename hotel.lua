local h = peripheral.wrap("redstone_relay_3")
local o = peripheral.wrap("redstone_relay_6")
local t = peripheral.wrap("redstone_relay_5")
local e = peripheral.wrap("redstone_relay_4")
local l = peripheral.wrap("redstone_relay_2")

local letters = { h, o, t, e, l }

-- Helper: turn all letters off
local function allOff()
    for _, relay in ipairs(letters) do
        relay.setOutput("top", false)
    end
end

-- Helper: turn all letters on
local function allOn()
    for _, relay in ipairs(letters) do
        relay.setOutput("top", true)
    end
end

-- Animation loop
while true do
    -- Sequentially light each letter
    for _, relay in ipairs(letters) do
        relay.setOutput("top", true)
        sleep(2)  -- delay between letters
    end

    sleep(1)

    -- Flash whole sign twice
    for i = 1, 2 do
        allOff()
        sleep(0.5)
        allOn()
        sleep(0.5)
    end

    -- Turn off before looping
    allOff()
    sleep(1)
end
