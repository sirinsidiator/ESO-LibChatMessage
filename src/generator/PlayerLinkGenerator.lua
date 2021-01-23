local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local FAKE_CHARACTER_LINK_TEMPLATE = "[%s]"

local PlayerLinkGenerator = GeneratorBase:Subclass()
internal.class.PlayerLinkGenerator = PlayerLinkGenerator

function PlayerLinkGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function PlayerLinkGenerator:BuildFromDisplayName(name, label)
    return self:Build(name, label, DISPLAY_NAME_LINK_TYPE)
end

function PlayerLinkGenerator:BuildFromCharacterName(name, label)
    return self:Build(name, label, CHARACTER_LINK_TYPE)
end

-- cannot use the ZOS link handler functions for char or display name links as they automatically decide on the label
function PlayerLinkGenerator:Generate(target, label, type)
    if not target or target == "" then return end

    if not type then
        type = self:DetectLinkType(target)
    end

    if not label then
        label = self:GenerateLinkLabel(target, type)
    end

    return ZO_LinkHandler_CreateLink(label, nil, type, target)
end

function PlayerLinkGenerator:DetectLinkType(target)
    return IsDecoratedDisplayName(target) and DISPLAY_NAME_LINK_TYPE or CHARACTER_LINK_TYPE
end

function PlayerLinkGenerator:GenerateLinkLabel(target, type)
    if type == DISPLAY_NAME_LINK_TYPE and not IsDecoratedDisplayName(target) then
        return DecorateDisplayName(target)
    else
        return target
    end
end
