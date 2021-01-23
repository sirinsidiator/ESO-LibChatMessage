local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local SimpleGenerator = GeneratorBase:Subclass()
internal.class.SimpleGenerator = SimpleGenerator

function SimpleGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function SimpleGenerator:Initialize(pathId, formatter, generate)
    -- optionally take a generate function to avoid having to create new classes for every little thing
    -- we have to set it before we call the parent Initialize, otherwise we pass the wrong one to SelectableFunction
    if generate then self.Generate = generate end

    GeneratorBase.Initialize(self, pathId, formatter)
end

function SimpleGenerator:Generate(value)
    return value
end
