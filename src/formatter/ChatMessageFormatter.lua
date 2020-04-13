local lib = LibChatMessage
local internal = lib.internal
local FormatterBase = internal.class.FormatterBase

local ChatMessageFormatter = FormatterBase:Subclass()
internal.class.ChatMessageFormatter = ChatMessageFormatter

function ChatMessageFormatter:New(...)
    return FormatterBase.New(self, ...)
end

function ChatMessageFormatter:Initialize()
    FormatterBase.Initialize(self)

    local generators = self.generators
    generators.time  = internal.class.TimeGenerator:New()
    generators.name  = internal.class.ChatNameGenerator:New()
    generators.nameLink  = internal.class.PlayerLinkGenerator:New()
    generators.channelName  = internal.class.SimpleGenerator:New()
    generators.channelLink  = internal.class.SimpleGenerator:New()
    generators.text  = internal.class.SimpleGenerator:New()
    generators.message  = internal.class.SimpleGenerator:New()
    generators.output = internal.class.ConcatGenerator:New()

    -- we replace the functions, otherwise we'd have to create a new class for one method which is only used here
    generators.channelName.Generate = function(generator, channelId)
        return GetChannelName(channelId)
    end

    generators.channelLink.Generate = function(generator, channelName)
        return ZO_LinkHandler_CreateChannelLink(channelName)
    end

    generators.text.Format = function(generator, text)
        if self.channelInfo.formatMessage then
            return zo_strformat(SI_CHAT_MESSAGE_FORMATTER, text)
        end
        return text
    end

    generators.message.Generate = function(generator, template, ...)
        return template:format(...)
    end
end

function ChatMessageFormatter:CanFormat(eventId, eventTime, messageType, fromName, text, isFromCustomerService, fromDisplayName)
    -- we set this early so anyone who is hooking the formatter can use the channel info easily
    self.channelInfo = ZO_ChatSystem_GetChannelInfo()[messageType]
    return self.channelInfo and text and text ~= ""
end

function ChatMessageFormatter:SetInput(eventId, eventTime, messageType, fromName, text, isFromCustomerService, fromDisplayName)
    FormatterBase.SetInput(self, eventId, eventTime)
    local input = self.input
    input.messageType = messageType
    input.fromName = fromName
    input.text = text
    input.isFromCustomerService = isFromCustomerService
    input.fromDisplayName = fromDisplayName
end

function ChatMessageFormatter:GenerateOutput()
    local input = self.input
    local output = self.output
    local temp = self.temp
    local generators = self.generators
    local channelInfo = self.channelInfo

    if channelInfo.playerLinkable then
        temp.subjectName, temp.linkTarget, temp.linkType = generators.name:Build(input.fromName, input.fromDisplayName, input.isFromCustomerService and channelInfo.supportCSIcon)
        temp.subject = generators.nameLink:Build(temp.linkTarget, temp.subjectName, temp.linkType)
    else
        temp.subject = generators.name:Build(input.fromName, input.fromDisplayName, input.isFromCustomerService and channelInfo.supportCSIcon)
    end

    temp.text = generators.text:Build(input.text)

    if channelInfo.channelLinkable then
        temp.channelName = generators.channelName:Build(channelInfo.id)
        temp.prefix = generators.channelLink:Build(temp.channelName)
    elseif channelInfo.supportCSIcon then
        -- we add the CS icon in name generator already, but still need to provide a prefix for the message template
        temp.prefix = ""
    end

    temp.template = GetString(channelInfo.format)
    if(temp.prefix) then
        temp.message = generators.message:Build(temp.template, temp.prefix, temp.subject, temp.text)
    else
        temp.message = generators.message:Build(temp.template, temp.subject, temp.text)
    end

    if lib:IsTimePrefixEnabled() and lib:IsRegularChatMessageTimePrefixEnabled() then
        temp.time = generators.time:Build(input.eventTime)
        temp.output = generators.output:Build(temp.time, temp.message)
    else
        temp.output = generators.output:Build(temp.message)
    end

    self:SetMessage(temp.output)
    self:SetChannel(channelInfo.saveTarget)
    self:SetSubject(input.fromDisplayName)
    self:SetRawMessage(input.text)

    if temp.output then return true end
    return false
end
