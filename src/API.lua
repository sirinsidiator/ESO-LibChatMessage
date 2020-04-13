local lib = LibChatMessage
local internal = lib.internal
local ChatProxy = internal.class.ChatProxy

--- Returns the current LibChatMessage API version. It will be incremented in case there are any breaking changes.
--- You can check this before accessing any functions to gracefully handle future incompatibilities.
lib.GetAPIVersion = function() return 2 end

--- Creates a proxy or returns a previous instance if it already exists.
--- The tags have to be non-empty strings and are not allowed to be the same as the label for CHAT_CATEGORY_SYSTEM
--- To print system messages use CHAT_ROUTER:AddSystemMessage instead.
--- @param longTag - a string identifier that is used to identify messages printed via this object. e.g. MyCoolAddon
--- @param shortTag - a string identifier that is used to identify messages printed via this object. e.g. MCA
--- @param identifier - an optional string identifier that is used to register the proxy with the library. If not specified the longTag is used
--- @return a new chat proxy instance with the passed tags. See ChatProxy.lua for details.
function lib.Create(longTag, shortTag, identifier)
    identifier = identifier or longTag
    if(not internal.proxyCache[identifier]) then
        internal.proxyCache[identifier] = ChatProxy:New(longTag, shortTag, identifier)
    end
    return internal.proxyCache[identifier]
end
setmetatable(lib, { __call = function(_, ...) return lib.Create(...) end })

--- @param identifier - the string identifier which was used to register the proxy with the library.
--- @return the proxy instance for the passed identifier.
function lib:GetProxy(identifier)
    return internal.proxyCache[identifier]
end

--- @param eventType - the event type of the formatter. Either an event id or a string identifier
--- @return the formatter instance for the passed event type.
function lib:GetFormatter(eventType)
    return internal.formatter[eventType]
end

--- Clears all chat windows
function lib:ClearChat()
    local activeWindows = CHAT_SYSTEM.windowPool:GetActiveObjects()
    for _, window in pairs(activeWindows) do
        window.buffer:Clear()
    end
end

--- Clears the stored chat history for the current session
function lib:ClearHistory()
    internal.chatHistory = {}
    if(internal.saveDataKey) then
        LibChatMessageHistory[internal.saveDataKey] = internal.chatHistory
    end
end

--- @return the stored chat history for the current session
function lib:GetHistory()
    return internal.chatHistory
end

--- @param enabled - controls the time prefix for chat messages
function lib:SetTimePrefixEnabled(enabled)
    internal.settings.timePrefixEnabled = enabled
end

--- @return true, if the time prefix is enabled
function lib:IsTimePrefixEnabled()
    return internal.settings.timePrefixEnabled
end

--- @param enabled - controls the time prefix for regular chat messages sent by players
function lib:SetRegularChatMessageTimePrefixEnabled(enabled)
    internal.settings.timePrefixOnRegularChat = enabled
end

--- @return true, if the time prefix is enabled for regular chat messages sent by players
function lib:IsRegularChatMessageTimePrefixEnabled()
    return internal.settings.timePrefixOnRegularChat
end

local TIME_FORMAT_AUTO = "%X"
local TIME_FORMAT_12 = "%I:%M:%S %p"
local TIME_FORMAT_24 = "%T"
local TIME_FORMATS = { TIME_FORMAT_AUTO, TIME_FORMAT_12, TIME_FORMAT_24 }
lib.TIME_FORMATS = TIME_FORMATS

--- @param format - sets the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:SetTimePrefixFormat(format)
    internal.settings.timePrefixFormat = format
end

--- @return the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:GetTimePrefixFormat()
    return internal.settings.timePrefixFormat
end

local TAG_PREFIX_OFF = 1
local TAG_PREFIX_LONG = 2
local TAG_PREFIX_SHORT = 3
lib.TAG_PREFIX_OFF = TAG_PREFIX_OFF
lib.TAG_PREFIX_LONG = TAG_PREFIX_LONG
lib.TAG_PREFIX_SHORT = TAG_PREFIX_SHORT

--- @param mode - controls how add-ons should print the tag prefix for their messages.
--- Turning it off will still save the long tag in case the history is enabled
function lib:SetTagPrefixMode(mode)
    internal.settings.tagPrefixMode = mode
end

--- @return The mode how add-ons should print the tag prefix for their messages.
function lib:GetTagPrefixMode()
    return internal.settings.tagPrefixMode
end

--- @param enabled - controls if add-ons should print a long or short tag prefix for their messages.
--- @deprecated - use SetTagPrefixMode instead
function lib:SetShortTagPrefixEnabled(enabled)
    self:SetTagPrefixMode(enabled and TAG_PREFIX_SHORT or TAG_PREFIX_LONG)
end

--- @return true, if add-ons should print a short tag prefix for their messages.
--- @deprecated - use GetTagPrefixMode instead
function lib:IsShortTagPrefixEnabled()
    return self:GetTagPrefixMode() == TAG_PREFIX_SHORT
end

--- @param enabled - controls if the chat history should be enabled on the next UI load.
function lib:SetChatHistoryEnabled(enabled)
    internal.settings.historyEnabled = enabled
end

--- @return true, if the chat history will be enabled on the next UI load.
function lib:IsChatHistoryEnabled()
    return internal.settings.historyEnabled
end

--- @return true, if the chat history is currently running.
function lib:IsChatHistoryActive()
    return internal.chatHistoryActive
end

--- @param maxAge - number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:SetChatHistoryMaxAge(maxAge)
    internal.settings.historyMaxAge = maxAge
end

--- @return number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:GetChatHistoryMaxAge()
    return internal.settings.historyMaxAge
end

--- @return a unique id for the current chat formatting event
--- @return the timestamp for the current chat formatting event
function lib:GetCurrentFormattingEventMetaData()
    return internal.currentEventId, internal.currentEventTime
end

--- Register to a callback fired by the library. Usage is the same as with CALLBACK_MANAGER:RegisterCallback.
--- The available callback names are located in Callbacks.lua
function lib:RegisterCallback(...)
    return internal.callbackObject:RegisterCallback(...)
end
