local lib = LibChatMessage
local internal = lib.internal
local FormatterBase = internal.class.FormatterBase

local TaggedMessageFormatter = FormatterBase:Subclass()
internal.class.TaggedMessageFormatter = TaggedMessageFormatter

function TaggedMessageFormatter:New(...)
    return FormatterBase.New(self, ...)
end

function TaggedMessageFormatter:Initialize(id, longTag, shortTag)
    FormatterBase.Initialize(self, id)

    local generators = self.generators
    generators.time  = internal.class.TimeGenerator:New("time", self)
    generators.tag = internal.class.TagGenerator:New("tag", self, longTag, shortTag)
    generators.message  = internal.class.SimpleGenerator:New("message", self, function() return self:GenerateMessage() end)
    generators.output = internal.class.ConcatGenerator:New("output", self)
end

function TaggedMessageFormatter:CanFormat(eventId, eventTime, message)
    return message and message ~= ""
end

function TaggedMessageFormatter:SetInput(eventId, eventTime, message)
    FormatterBase.SetInput(self, eventId, eventTime)
    self.input.message = message
end

function TaggedMessageFormatter:GenerateOutput()
    local generators = self.generators
    local temp = self.temp

    if lib:IsTimePrefixEnabled() then
        temp[#temp + 1] = generators.time:Build(self.input.eventTime)
    end

    local tagMode = lib:GetTagPrefixMode()
    if tagMode ~= lib.TAG_PREFIX_OFF then
        temp[#temp + 1] = generators.tag:Build(tagMode)
    end

    temp[#temp + 1] = generators.message:Build(self.input.message)

    local formattedMessage = generators.output:Build(unpack(temp))
    self:SetMessage(formattedMessage)

    if formattedMessage then return true end
    return false
end

function TaggedMessageFormatter:GenerateMessage()
    return self.input.message
end
