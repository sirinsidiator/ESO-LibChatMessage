local lib = LibChatMessage
local internal = lib.internal
local FormatterBase = internal.class.FormatterBase

local TaggedMessageFormatter = FormatterBase:Subclass()
internal.class.TaggedMessageFormatter = TaggedMessageFormatter

function TaggedMessageFormatter:New(...)
    return FormatterBase.New(self, ...)
end

function TaggedMessageFormatter:Initialize(longTag, shortTag)
    FormatterBase.Initialize(self)

    local generators = self.generators
    generators.time  = internal.class.TimeGenerator:New()
    generators.tag = internal.class.TagGenerator:New(longTag, shortTag)
    generators.message  = internal.class.SimpleGenerator:New()
    generators.output = internal.class.ConcatGenerator:New()

    -- most subclasses will want to generate a different message,
    -- so we replace the function to avoid having to create new generator classes for everything
    self.generators.message.Generate = function() return self:GenerateMessage() end
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
