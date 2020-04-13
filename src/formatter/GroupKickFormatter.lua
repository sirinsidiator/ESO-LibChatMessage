local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local GroupKickFormatter = TaggedMessageFormatter:Subclass()
internal.class.GroupKickFormatter = GroupKickFormatter

function GroupKickFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function GroupKickFormatter:CanFormat(eventId, eventTime, characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)
    return reason == GROUP_LEAVE_REASON_KICKED and isLocalPlayer and actionRequiredVote
end

function GroupKickFormatter:SetInput(eventId, eventTime, characterName, reason, isLocalPlayer, isLeader, displayName, actionRequiredVote)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    local input = self.input
    input.characterName = characterName
    input.reason = reason
    input.isLocalPlayer = isLocalPlayer
    input.isLeader = isLeader
    input.displayName = displayName
    input.actionRequiredVote = actionRequiredVote
end

function GroupKickFormatter:GenerateMessage()
    return GetString(SI_GROUP_ELECTION_KICK_PLAYER_PASSED)
end
