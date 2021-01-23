local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local CUSTOMER_SERVICE_ICON_TEMPLATE = "|t16:16:EsoUI/Art/ChatWindow/csIcon.dds|t%s"

local ChatNameGenerator = GeneratorBase:Subclass()
internal.class.ChatNameGenerator = ChatNameGenerator

function ChatNameGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function ChatNameGenerator:Build(...)
    GeneratorBase.Build(self, ...)
    return self.output, self.linkTarget, self.linkType
end

function ChatNameGenerator:Generate(fromName, fromDisplayName, showCSIcon)
    local name, linkType = self:GetPreferredName(fromName, fromDisplayName)

    -- store the link data so we can return it from Build()
    self.linkTarget = name
    self.linkType = linkType

    name = zo_strformat(SI_CHAT_MESSAGE_PLAYER_FORMATTER, name)

    if showCSIcon then
        name = self:ApplyCustomerServiceIcon(name)
    end

    return name
end

function ChatNameGenerator:GetPreferredName(fromName, fromDisplayName)
    local isDecorated = IsDecoratedDisplayName(fromName)
    if not isDecorated and fromDisplayName ~= "" then
        --We have a character name and a display name, so follow the setting
        if ZO_ShouldPreferUserId() then
            return fromDisplayName, DISPLAY_NAME_LINK_TYPE
        else
            fromName = zo_strformat(SI_CHAT_MESSAGE_PLAYER_FORMATTER, fromName)
            return fromName, CHARACTER_LINK_TYPE
        end
    else
        --We either have two display names, or we weren't given a guaranteed display name, so just use the default fromName
        if not isDecorated then
            fromName = zo_strformat(SI_CHAT_MESSAGE_PLAYER_FORMATTER, fromName)
            return fromName, CHARACTER_LINK_TYPE
        else
            return fromName, DISPLAY_NAME_LINK_TYPE
        end
    end
end

function ChatNameGenerator:ApplyCustomerServiceIcon(name)
    return CUSTOMER_SERVICE_ICON_TEMPLATE:format(name)
end
