local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local BRACKET_FORMAT = "[%s]"

local TimeGenerator = GeneratorBase:Subclass()
internal.class.TimeGenerator = TimeGenerator

function TimeGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function TimeGenerator:Initialize(pathId, formatter)
    GeneratorBase.Initialize(self, pathId, formatter)
    self:SetBracketFormat(BRACKET_FORMAT)
end

function TimeGenerator:SetBracketFormat(format)
    self.bracketFormat = format
end

function TimeGenerator:Generate(timeStamp)
    local time = os.date(lib:GetTimePrefixFormat(), timeStamp)
    return self.bracketFormat:format(time)
end
