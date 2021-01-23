local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local DEFAULT_SEPARATOR = " "

local ConcatGenerator = GeneratorBase:Subclass()
internal.class.ConcatGenerator = ConcatGenerator

function ConcatGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function ConcatGenerator:Initialize(pathId, formatter, separator)
    GeneratorBase.Initialize(self, pathId, formatter)
    self.temp = {}
    self:SetSeparator(separator or DEFAULT_SEPARATOR)
end

function ConcatGenerator:SetSeparator(separator)
    self.separator = separator
end

function ConcatGenerator:Generate(...)
    local temp = self.temp
    local count = select("#", ...)
    for i = 1, count do
        temp[i] = select(i, ...)
    end
    return table.concat(temp, self.separator, 1, count)
end
