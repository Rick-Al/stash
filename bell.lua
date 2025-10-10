local speaker = peripheral.find("speaker")
local relay = peripheral.find("redstone_relay")
local inputSide = "top"

while true do
  speaker.playNote("bell", 1, 1)
  relay.setOutput("front", true)
  sleep(0.1)
  speaker.playNote("bell", 1, 12)
  relay.setOutput("front", false)
  sleep(0.1)
end
