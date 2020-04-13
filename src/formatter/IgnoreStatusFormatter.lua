local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local IgnoreStatusFormatter = TaggedMessageFormatter:Subclass()
internal.class.IgnoreStatusFormatter = IgnoreStatusFormatter

function IgnoreStatusFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function IgnoreStatusFormatter:Initialize(systemTag, stringId)
    TaggedMessageFormatter.Initialize(self, systemTag)
    self.stringId = stringId
    self.generators.displayNameLink = internal.class.PlayerLinkGenerator:New()
end

function IgnoreStatusFormatter:CanFormat(eventId, eventTime, displayName)
    return displayName and displayName ~= ""
end

function IgnoreStatusFormatter:SetInput(eventId, eventTime, displayName)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    self.input.displayName = displayName
end

function IgnoreStatusFormatter:GenerateMessage()
    local displayNameLink = self.generators.displayNameLink:BuildFromDisplayName(self.input.displayName)
    return zo_strformat(self.stringId, displayNameLink)
end

function IgnoreStatusFormatter:GenerateOutput()
    local hasOutput = TaggedMessageFormatter.GenerateOutput(self)
    if hasOutput then
        self:SetSubject(self.input.displayName)
    end
    return hasOutput
end
