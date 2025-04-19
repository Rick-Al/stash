local reactor = peripheral.find("fissionReactorLogicAdapter")
local basalt = require("basalt")
local term = require("term")

-- Helper function to format percentages
local function toPercent(value)
  return string.format("%.1f%%", value * 100)
end

-- Function to update the reactor data and display it
local function showReactorStats()
  local status = reactor.getStatus()
  local fuel = toPercent(reactor.getFuelFilledPercentage())
  local coolant = toPercent(reactor.getCoolantFilledPercentage())
  local heated = toPercent(reactor.getHeatedCoolantFilledPercentage())
  local waste = toPercent(reactor.getWasteFilledPercentage())
  local damage = string.format("%.1f%%", reactor.getDamagePercent())
  local temp = string.format("%.2f K", reactor.getTemperature())

  -- Display reactor stats in a box
  local box = basalt.addContainer()
  box:setSize(30, 12)  -- Adjust size as needed
  box:setPosition(2, 4) -- Adjust position as needed
  box:setBackgroundColor(colors.black)
  box:setBorderColor(colors.white)
  box:setBorder(1)

  -- Display data
  box:addLabel(2, 2, "Fuel: " .. fuel)
  box:addLabel(2, 3, "Coolant: " .. coolant)
  box:addLabel(2, 4, "Heated Coolant: " .. heated)
  box:addLabel(2, 5, "Waste: " .. waste)
  box:addLabel(2, 6, "Damage: " .. damage)
  box:addLabel(2, 7, "Temperature: " .. temp)
end

-- Function to update reactor status
local function showReactorStatus()
  local statusText = reactor.getStatus() == "ACTIVE" and "Nominal" or "SCRAMMED"
  local statusBox = basalt.addContainer()
  statusBox:setSize(30, 5)
  statusBox:setPosition(2, 2)
  statusBox:setBackgroundColor(colors.blue)
  statusBox:setBorderColor(colors.white)
  statusBox:setBorder(1)

  statusBox:addLabel(2, 2, "Status: " .. statusText)
end

-- Function to handle reactor activation or scram
local function controlReactor(action)
  if action == "activate" then
    reactor.activate()
  elseif action == "scram" then
    reactor.scram()
  end
end

-- UI layout for main screen
local function createMainScreen()
  -- Program Title
  local title = basalt.addLabel(1, 1, "Remote Reactor Controller")
  title:setFontSize(2)
  title:setColor(colors.white)

  -- Reactor Status and Data
  showReactorStatus()
  showReactorStats()

  -- Control buttons (Activate / Scram)
  local activateButton = basalt.addButton(2, 10, "Activate")
  activateButton:setSize(15, 3)
  activateButton:setBackgroundColor(colors.green)
  activateButton:setTextColor(colors.white)
  activateButton:setOnClick(function()
    controlReactor("activate")
  end)

  local scramButton = basalt.addButton(18, 10, "SCRAM")
  scramButton:setSize(15, 3)
  scramButton:setBackgroundColor(colors.red)
  scramButton:setTextColor(colors.white)
  scramButton:setOnClick(function()
    controlReactor("scram")
  end)
end

-- Update turbine stats periodically in a separate thread
basalt.addThread(function()
  while true do
    -- You can update turbine stats or reactor stats here
    showReactorStats()
    os.sleep(1)  -- Adjust the update interval as needed
  end
end)

-- Start the main screen
basalt.start()
createMainScreen()
