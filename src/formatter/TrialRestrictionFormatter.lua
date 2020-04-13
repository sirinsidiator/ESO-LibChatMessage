local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local TrialRestrictionFormatter = TaggedMessageFormatter:Subclass()
internal.class.TrialRestrictionFormatter = TrialRestrictionFormatter

function TrialRestrictionFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function TrialRestrictionFormatter:CanFormat(eventId, eventTime, restrictionType)
    return ZO_ChatSystem_GetTrialEventMappings()[restrictionType]
end

function TrialRestrictionFormatter:SetInput(eventId, eventTime, restrictionType)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    self.input.restrictionType = restrictionType
end

function TrialRestrictionFormatter:GenerateMessage()
    return GetString("SI_TRIALACCOUNTRESTRICTIONTYPE", self.input.restrictionType)
end
