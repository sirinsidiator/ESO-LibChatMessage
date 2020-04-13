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
    local name, linkTarget, linkType
    local isDecorated = IsDecoratedDisplayName(fromName)
    if not isDecorated and fromDisplayName ~= "" then
        --We have a character name and a display name, so follow the setting
        if ZO_ShouldPreferUserId() then
            name = fromDisplayName
            linkTarget = fromDisplayName
            linkType = DISPLAY_NAME_LINK_TYPE
        else
            name = fromName
            linkTarget = fromName
            linkType = CHARACTER_LINK_TYPE
        end
    else
        --We either have two display names, or we weren't given a guaranteed display name, so just use the default fromName
        name = fromName
        linkTarget = fromName
        linkType = isDecorated and DISPLAY_NAME_LINK_TYPE or CHARACTER_LINK_TYPE
    end

    if showCSIcon then
        name = CUSTOMER_SERVICE_ICON_TEMPLATE:format("%s", name)
    end

    self.linkTarget = linkTarget
    self.linkType = linkType
    return name
end

function ChatNameGenerator:Format(name)
    return zo_strformat(SI_CHAT_MESSAGE_PLAYER_FORMATTER, name)
end
