local speaker = peripheral.find("speaker")
local relay = peripheral.find("redstone_relay")
local inputSide = "top"

local active = true

print("Waiting for ghosts...")

while true do
  os.pullEvent("redstone")

  if redstone.getInput(inputSide) then
    active = not active

    if active then
      print("We got one!")
      parallel.waitForAny(
        function()
          while active do
            speaker.playNote("bell", 1, 1)
            relay.setOutput("front", true)
            sleep(0.1)
            speaker.playNote("bell", 1, 12)
            relay.setOutput("front", false)
            sleep(0.1)
          end
        end,
        function()
          while active do
            os.pullevent("redstone")
            if redstone.getInput(inputSide)
              active = false
              print("Ghosts, busted.")
            end
          end
        end
      )
    else
      print("Ghosts, busted.")
      relay.setOutput("front", false)
    end

    while redstone.getInput(inputSide) do
      os.pullEvent("redstone")
    end
  end
end

  
