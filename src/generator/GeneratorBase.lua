local lib = LibChatMessage
local internal = lib.internal

local GeneratorBase = ZO_Object:Subclass()
internal.class.GeneratorBase = GeneratorBase

function GeneratorBase:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

-- make sure to call GeneratorBase.Initialize(self) when overwriting this function
function GeneratorBase:Initialize(...)
    self.decorators = {}
end

function GeneratorBase:Reset()
    -- overwrite in case some state has to be reset
end

function GeneratorBase:Build(...)
    local value = self:Generate(...)
    local formatted = self:Format(value)
    self.output = self:Decorate(formatted)
    return self.output
end

function GeneratorBase:Generate(...)
    assert(false, "Function not implemented")
end

function GeneratorBase:Format(value)
    return value
end

function GeneratorBase:Decorate(value)
    local decorators = self.decorators
    for i = 1, #decorators do
        local decorated = decorators[i](self, value)
        if type(decorated) == "string" then value = decorated end
    end
    return value
end

function GeneratorBase:RegisterDecorator(decorator)
    local decorators = self.decorators
    decorators[#decorators + 1] = decorator
end
