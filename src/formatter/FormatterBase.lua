local lib = LibChatMessage
local internal = lib.internal
local callback = lib.callback

local MESSAGE_INDEX = 1
local CHANNEL_INDEX = 2
local SUBJECT_INDEX = 3
local RAW_INDEX = 4

local FormatterBase = ZO_Object:Subclass()
internal.class.FormatterBase = FormatterBase

function FormatterBase:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

-- make sure to call FormatterBase.Initialize(self) when overwriting this function
function FormatterBase:Initialize()
    self.input = {}
    self.output = {}
    self.temp = {}
    self.generators = {}
end

function FormatterBase:SetEventType(eventType)
    self.eventType = eventType
end

function FormatterBase:GetEventType()
    return self.eventType
end

function FormatterBase:IsForEventType(eventType)
    return self.eventType == eventType
end

function FormatterBase:Format(...)
    local eventId, eventTime = lib:GetCurrentFormattingEventMetaData()
    if not self:CanFormat(eventId, eventTime, ...) or internal:FireCallbacks(callback.FORMATTER_BEGIN, self, eventId, eventTime, ...) then
        return
    end

    self:Reset()
    internal:FireCallbacks(callback.FORMATTER_RESET, self)

    self:SetInput(eventId, eventTime, ...)
    internal:FireCallbacks(callback.FORMATTER_INPUT, self)

    if(self:GenerateOutput()) then
        internal:FireCallbacks(callback.FORMATTER_OUTPUT, self)
        return self:GetOutput()
    end
end

function FormatterBase:CanFormat(eventId, eventTime, ...)
    -- overwrite and return true if the formatter can actually format the inputs
    return false
end

function FormatterBase:Reset()
    ZO_ClearTable(self.input)
    ZO_ClearTable(self.output)
    ZO_ClearTable(self.temp)
    for _, generator in pairs(self.generators) do generator:Reset() end
end

function FormatterBase:SetInput(eventId, eventTime, ...)
    self.input.eventId = eventId
    self.input.eventTime = eventTime
    -- overwrite and assign all arguments to keys in self.input
end

function FormatterBase:GenerateOutput()
    -- overwrite and assign the return arguments to self.output
    -- should return true if output has to be returned
    return false
end

function FormatterBase:SetMessage(message)
    self.output[MESSAGE_INDEX] = message
end

function FormatterBase:SetChannel(channel)
    self.output[CHANNEL_INDEX] = channel
end

function FormatterBase:SetSubject(subject)
    self.output[SUBJECT_INDEX] = subject
end

function FormatterBase:SetRawMessage(message)
    self.output[RAW_INDEX] = message
end

function FormatterBase:GetOutput()
    local output = self.output
    -- unpack wouldn't work here as some of the indices may not have been set
    return output[MESSAGE_INDEX], output[CHANNEL_INDEX], output[SUBJECT_INDEX], output[RAW_INDEX]
end
