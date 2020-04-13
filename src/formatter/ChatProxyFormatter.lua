local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local ChatProxyFormatter = TaggedMessageFormatter:Subclass()
internal.class.ChatProxyFormatter = ChatProxyFormatter

function ChatProxyFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function ChatProxyFormatter:CanFormat(eventId, eventTime, longTag, shortTag, message, tagColor)
    return message and message ~= ""
end

function ChatProxyFormatter:SetInput(eventId, eventTime, longTag, shortTag, message, tagColor)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    local input = self.input
    input.longTag = longTag
    input.shortTag = shortTag
    input.message = message
    input.tagColor = tagColor
end

function ChatProxyFormatter:GenerateOutput()
    local input = self.input
    local tagGenerator = self.generators.tag
    tagGenerator:SetTags(input.longTag, input.shortTag)
    tagGenerator:SetTagColor(input.tagColor)

    return TaggedMessageFormatter.GenerateOutput(self)
end
