math.randomseed(os.time() + os.clock() * 1000000 + math.random(1, 1000000))

for _ = 1, 5 do math.random() end

local messages = {
    "Think Different.",
    "One thousand songs in your pocket.",
    "Leave no tune behind.",
    "Touch comes to iPod.",
    "Welcome to the digital music revolution.",
    "Play more than music. Play a part.",
    "Rip. Mix. Burn.",
    "Which iPod are you?"
}

local apple = paintutils.loadImage("apple.nfp")
local applew = paintutils.loadImage("applew.nfp")

local images = {
    apple,
    applew
}

term.clear()
term.setCursorPos(1,1)

textutils.slowPrint(messages[math.random(1, #messages)])

paintutils.drawImage(images[math.random(1, #images)], 1, 1)
