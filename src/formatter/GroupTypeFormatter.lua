local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local GroupTypeFormatter = TaggedMessageFormatter:Subclass()
internal.class.GroupTypeFormatter = GroupTypeFormatter

function GroupTypeFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function GroupTypeFormatter:CanFormat(eventId, eventTime, largeGroup)
    return true
end

function GroupTypeFormatter:SetInput(eventId, eventTime, largeGroup)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    self.input.largeGroup = largeGroup
end

function GroupTypeFormatter:GenerateMessage()
    if self.input.largeGroup then
        return GetString(SI_CHAT_ANNOUNCEMENT_IN_LARGE_GROUP)
    else
        return GetString(SI_CHAT_ANNOUNCEMENT_IN_SMALL_GROUP)
    end
end
