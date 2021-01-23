local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local SocialErrorFormatter = TaggedMessageFormatter:Subclass()
internal.class.SocialErrorFormatter = SocialErrorFormatter

function SocialErrorFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function SocialErrorFormatter:CanFormat(eventId, eventTime, error)
    return not IsSocialErrorIgnoreResponse(error) and not ShouldShowSocialErrorInAlert(error)
end

function SocialErrorFormatter:SetInput(eventId, eventTime, error)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    self.input.error = error
end

function SocialErrorFormatter:GenerateMessage()
    return zo_strformat(GetString("SI_SOCIALACTIONRESULT", self.input.error))
end
