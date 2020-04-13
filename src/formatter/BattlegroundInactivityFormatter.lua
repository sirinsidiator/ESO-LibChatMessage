local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local BattlegroundInactivityFormatter = TaggedMessageFormatter:Subclass()
internal.class.BattlegroundInactivityFormatter = BattlegroundInactivityFormatter

function BattlegroundInactivityFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function BattlegroundInactivityFormatter:CanFormat(eventId, eventTime)
    return true
end

function BattlegroundInactivityFormatter:GenerateMessage()
    return GetString(SI_BATTLEGROUND_INACTIVITY_WARNING)
end
