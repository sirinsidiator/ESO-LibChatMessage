local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local SimpleGenerator = GeneratorBase:Subclass()
internal.class.SimpleGenerator = SimpleGenerator

function SimpleGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function SimpleGenerator:Generate(value)
    return value
end
