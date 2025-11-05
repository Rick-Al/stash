-- program for using supplementaries speaker block in narrator mode
local spkr = peripheral.find("speaker_block")
local args = {...}

if not spkr then
    error("Missing speaker block.")
end

if #args < 1 then
    print("Usage: speak <words>")
    return
end

if #args > 1 then
    print("Use quotes for more than 1 word.")
    return
end

local word = args[1]

spkr.setName(word)
spkr.setNarrator("narrator")
spkr.setMessage("")
spkr.activate()
