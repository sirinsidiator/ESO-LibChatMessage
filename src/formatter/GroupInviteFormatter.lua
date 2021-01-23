local lib = LibChatMessage
local internal = lib.internal
local TaggedMessageFormatter = internal.class.TaggedMessageFormatter

local PATH_ID_TEMPLATE = "%s.%s"

local GroupInviteFormatter = TaggedMessageFormatter:Subclass()
internal.class.GroupInviteFormatter = GroupInviteFormatter

function GroupInviteFormatter:New(...)
    return TaggedMessageFormatter.New(self, ...)
end

function GroupInviteFormatter:Initialize(pathId, ...)
    TaggedMessageFormatter.Initialize(self, pathId, ...)

    local nameGenerator = internal.class.SimpleGenerator:New(PATH_ID_TEMPLATE:format(pathId, "name"), function(generator, characterName, displayName)
        if characterName ~= "" then
            return characterName
        else
            return ZO_FormatUserFacingDisplayName(displayName)
        end
    end)
    self.generators.name = nameGenerator
end

function GroupInviteFormatter:CanFormat(eventId, eventTime, characterName, response, displayName)
    return not IsGroupErrorIgnoreResponse(response) and not ShouldShowGroupErrorInAlert(response)
end

function GroupInviteFormatter:SetInput(eventId, eventTime, characterName, response, displayName)
    TaggedMessageFormatter.SetInput(self, eventId, eventTime)
    local input = self.input
    input.characterName = characterName
    input.response = response
    input.displayName = displayName
end

function GroupInviteFormatter:GenerateOutput()
    local hasOutput = TaggedMessageFormatter.GenerateOutput(self)
    if hasOutput then
        self:SetSubject(self.input.displayName)
    end
    return hasOutput
end

function GroupInviteFormatter:GenerateMessage()
    local input = self.input

    local nameToDisplay = self.generators.name:Build(input.characterName, input.displayName)
    if nameToDisplay ~= "" then
        return zo_strformat(GetString("SI_GROUPINVITERESPONSE", input.response), nameToDisplay)
    end

    return GetString(SI_PLAYER_BUSY)
end
