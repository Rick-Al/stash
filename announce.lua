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
    "The Green and Blue lines are closed for construction. Sun stone transit authority apologizes for any inconvience. Thank you for your understanding.",
    "The Sun stone transity authority would like to remind riders that fare evasion is a crime. see something, say something.",
    "Information on routes and stations is available from the information kiosk.",
    "Please help keep our metro clean, pick up your trash.",
    "Thank you for choosing the metro."
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

local function announceTime()
    local time = textutils.formatTime(os.time(), false)
    announce("The current is now " .. time .. ".")
end


-- Main loop
print("Announcement system started.")
while true do
    local message = announcements[math.random(1, #announcements)]
    playChime()
    announceTime()
    sleep(0.5)
    announce(message)
    sleep(60)
end
