local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local PlayerStatusFormatter = TaggedMessageFormatter:Subclass()
internal.class.PlayerStatusFormatter = PlayerStatusFormatter

function PlayerStatusFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function PlayerStatusFormatter:Initialize(systemTag)
    TaggedMessageFormatter.Initialize(self, systemTag)

    local generators = self.generators
    generators.displayNameLink = internal.class.PlayerLinkGenerator:New()
    generators.characterNameLink = internal.class.PlayerLinkGenerator:New()
end

function PlayerStatusFormatter:CanFormat(eventId, eventTime, displayName, characterName, oldStatus, newStatus)
    return oldStatus ~= newStatus
end

function PlayerStatusFormatter:SetInput(eventId, eventTime, displayName, characterName, oldStatus, newStatus)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    local input = self.input
    input.displayName = displayName
    input.characterName = characterName
    input.oldStatus = oldStatus
    input.newStatus = newStatus
end

function PlayerStatusFormatter:GenerateMessage()
    local input = self.input
    local generators = self.generators

    local displayNameLink = generators.displayNameLink:BuildFromDisplayName(input.displayName)
    local characterNameLink = generators.characterNameLink:BuildFromCharacterName(input.characterName)

    if input.newStatus == PLAYER_STATUS_OFFLINE then
        if characterNameLink then
            return zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayNameLink, characterNameLink)
        else
            return zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_OFF, displayNameLink)
        end
    else
        if characterNameLink then
            return zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_ON, displayNameLink, characterNameLink)
        else
            return zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_ON, displayNameLink)
        end
    end
end
