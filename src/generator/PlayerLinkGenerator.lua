local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local FAKE_CHARACTER_LINK_TEMPLATE = "[%s]"

local PlayerLinkGenerator = GeneratorBase:Subclass()
internal.class.PlayerLinkGenerator = PlayerLinkGenerator

function PlayerLinkGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function PlayerLinkGenerator:Initialize()
    GeneratorBase.Initialize(self)
    self:SetBracketsEnabled(true)
end

function PlayerLinkGenerator:BuildFromDisplayName(name, label)
    return self:Build(name, label, DISPLAY_NAME_LINK_TYPE)
end

function PlayerLinkGenerator:BuildFromCharacterName(name, label)
    return self:Build(name, label, CHARACTER_LINK_TYPE)
end

function PlayerLinkGenerator:SetBracketsEnabled(enabled)
    self.bracketsEnabled = enabled
end

-- cannot use the ZOS link handler functions for char or display name links as they automatically decide on the label
function PlayerLinkGenerator:Generate(target, label, type)
    if not target or target == "" then return end

    if not type then
        type = IsDecoratedDisplayName(target) and DISPLAY_NAME_LINK_TYPE or CHARACTER_LINK_TYPE
    end

    if not label then
        if type == DISPLAY_NAME_LINK_TYPE then
            label = self:GetDisplayLinkLabel(target)
        else
            label = self:GetCharacterLinkLabel(target)
        end
    end

    if type == CHARACTER_LINK_TYPE and IsConsoleUI() then
        -- console UI doesn't actually create character links in ZO_LinkHandler_CreateCharacterLink, so we do the same
        if self.bracketsEnabled then
            return FAKE_CHARACTER_LINK_TEMPLATE:format(label)
        end
        return label
    end

    if self.bracketsEnabled then
        return ZO_LinkHandler_CreateLink(label, nil, type, target)
    end
    return ZO_LinkHandler_CreateLinkWithoutBrackets(label, nil, type, target)
end

function PlayerLinkGenerator:GetDisplayLinkLabel(displayName)
    local undecoratedDisplayName
    if(not IsDecoratedDisplayName(displayName)) then
        undecoratedDisplayName = displayName
        displayName = DecorateDisplayName(displayName)
    else
        undecoratedDisplayName = UndecorateDisplayName(displayName)
    end

    return IsConsoleUI() and undecoratedDisplayName or displayName
end

function PlayerLinkGenerator:GetCharacterLinkLabel(characterName)
    return IsConsoleUI() and ZO_FormatUserFacingCharacterName(characterName) or characterName
end
