-- automated annoucements using speaker from cc and speaker block from supp
local chimeSpeaker = peripheral.find("speaker")
local ttsSpeaker = peripheral.find("speaker_block")

if not chimeSpeaker then
    error("No speaker found!")
end
if not ttsSpeaker then
    error("No speaker block found!")
end

local announcements = {
    "Please remember to sign out your devices before leaving.",
    "Lunch break begins in 10 minutes.",
    "Safety is everyone's responsibility. Keep your area clean.",
    "Meeting in the main conference room at 3 PM.",
    "Don’t forget to hydrate!",
    "All systems operating normally."
}

local function playChime()
    chimeSpeaker.playNote("chime", 1, 5)
    sleep(0.5)
    chimeSpeaker.playNote("chime", 1, 1)
    sleep(1)
end

local function announce(message)
    ttsSpeaker.setName(" ")
    ttsSpeaker.setNarrator("narrator")
    ttsSpeaker.setMessage(message)
    ttsSpeaker.activate()
end

-- Main loop
print("Announcement system started.")
while true do
    local message = announcements[math.random(1, #announcements)]
    playChime()
    sleep(0.5)
    announce(message)
    sleep(60)
end
