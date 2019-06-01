local LIB_IDENTIFIER = "LibChatMessage"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local lib = {}
_G[LIB_IDENTIFIER] = lib

local TAG_FORMAT = "[%s]"
local COLOR_FORMAT = "|c%s%s|r"
local MESSAGE_TEMPLATE_WITH_TIME = "%s %%s %%s"
local MESSAGE_TEMPLATE = "%s %s"
local SYSTEM_TAG = TAG_FORMAT:format(GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM))

local TIME_FORMAT_AUTO = "[%X]"
local TIME_FORMAT_12 = "[%I:%M:%S %p]"
local TIME_FORMAT_24 = "[%T]"
local TIME_FORMATS = { TIME_FORMAT_AUTO, TIME_FORMAT_12, TIME_FORMAT_24 }
local TIME_FORMAT_MAPPING = {
    ["auto"] = TIME_FORMAT_AUTO,
    ["12h"] = TIME_FORMAT_12,
    ["24h"] = TIME_FORMAT_24,
}
local REVERSE_TIME_FORMAT_MAPPING = {}
for label, format in pairs(TIME_FORMAT_MAPPING) do
    REVERSE_TIME_FORMAT_MAPPING[format] = label
end

local TIMESTAMP_INDEX = 1
local MAX_HISTORY_LENGTH = 10000
local TRIMMED_HISTORY_LENGTH = 9000

local strlower = string.lower
local tconcat = table.concat
local osdate = os.date
local GetTimeStamp = GetTimeStamp
local ZO_ChatEvent = ZO_ChatEvent

lib.defaultSettings = {
    timePrefixEnabled = false,
    timePrefixOnRegularChat = true,
    timePrefixFormat = TIME_FORMAT_AUTO,
    shortTagPrefixEnabled = false,
    historyEnabled = false,
    historyMaxAge = 3600,
}
lib.chatHistory = {}
lib.chatHistoryActive = true

-- internal functions

local function GetFormattedTime(timeStamp)
    return osdate(lib.settings.timePrefixFormat, timeStamp)
end

local function GetFormatString(timeStamp)
    if(lib.settings.timePrefixEnabled) then
        return MESSAGE_TEMPLATE_WITH_TIME:format(GetFormattedTime(timeStamp))
    end
    return MESSAGE_TEMPLATE
end

local function GetTimeStampForEvent()
    if(lib.nextEventTimeStamp) then
        return lib.nextEventTimeStamp, true
    end
    return GetTimeStamp(), false
end

local function StoreChatEvent(timeStamp, type, ...)
    if(not lib.chatHistoryActive) then return end
    local chatHistory = lib.chatHistory
    chatHistory[#chatHistory + 1] = {timeStamp, type, ...}
    if(#chatHistory > MAX_HISTORY_LENGTH) then
        local newHistory = {}
        for i = #chatHistory - TRIMMED_HISTORY_LENGTH, #chatHistory do
            newHistory[#newHistory + 1] = chatHistory[i]
        end
        chatHistory = newHistory
    end
end

local function ApplyTimeAndTagPrefix(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText) then
        local format = GetFormatString(timeStamp)
        formattedEventText = format:format(SYSTEM_TAG, formattedEventText)
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end

-- chat system hooks
local ChatEventFormatters = ZO_ChatSystem_GetEventHandlers()

local function PostHookFormatter(eventType, postHook)
    local originalFormatter = ChatEventFormatters[eventType]
    ChatEventFormatters[eventType] = function(...)
        local timeStamp, isRestoring = GetTimeStampForEvent()
        if(not isRestoring) then
            StoreChatEvent(timeStamp, eventType, ...)
        end
        local formattedEventText, targetChannel, fromDisplayName, rawMessageText = originalFormatter(...)
        return postHook(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    end
end

-- ZO_ChatEvent(EVENT_CHAT_MESSAGE_CHANNEL, CHAT_CHANNEL_SAY, "test", "test", false, "test")
PostHookFormatter(EVENT_CHAT_MESSAGE_CHANNEL, function(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText and lib.settings.timePrefixEnabled and lib.settings.timePrefixOnRegularChat) then
        formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end)

-- ZO_ChatEvent(EVENT_BROADCAST, "test")
PostHookFormatter(EVENT_BROADCAST, function(formattedEventText, targetChannel, fromDisplayName, rawMessageText, timeStamp)
    if(formattedEventText and lib.settings.timePrefixEnabled) then
        formattedEventText = MESSAGE_TEMPLATE:format(GetFormattedTime(timeStamp), formattedEventText)
    end
    return formattedEventText, targetChannel, fromDisplayName, rawMessageText
end)

-- ZO_ChatEvent(EVENT_FRIEND_PLAYER_STATUS_CHANGED, "test", "test", PLAYER_STATUS_OFFLINE, PLAYER_STATUS_ONLINE)
PostHookFormatter(EVENT_FRIEND_PLAYER_STATUS_CHANGED, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_IGNORE_ADDED, "test")
PostHookFormatter(EVENT_IGNORE_ADDED, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_IGNORE_REMOVED, "test")
PostHookFormatter(EVENT_IGNORE_REMOVED, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_GROUP_TYPE_CHANGED, false)
PostHookFormatter(EVENT_GROUP_TYPE_CHANGED, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_GROUP_INVITE_RESPONSE, "test", GROUP_INVITE_RESPONSE_PLAYER_NOT_FOUND, "test")
PostHookFormatter(EVENT_GROUP_INVITE_RESPONSE, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_SOCIAL_ERROR, SOCIAL_RESULT_ACCOUNT_NOT_FOUND)
PostHookFormatter(EVENT_SOCIAL_ERROR, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_TRIAL_FEATURE_RESTRICTED, TRIAL_RESTRICTION_CANNOT_WHISPER)
PostHookFormatter(EVENT_TRIAL_FEATURE_RESTRICTED, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_GROUP_MEMBER_LEFT, "test", GROUP_LEAVE_REASON_KICKED, true, false, "test", true)
PostHookFormatter(EVENT_GROUP_MEMBER_LEFT, ApplyTimeAndTagPrefix)

-- ZO_ChatEvent(EVENT_BATTLEGROUND_INACTIVITY_WARNING)
PostHookFormatter(EVENT_BATTLEGROUND_INACTIVITY_WARNING, ApplyTimeAndTagPrefix)

ChatEventFormatters[LIB_IDENTIFIER] = function(tag, rawMessageText)
    local timeStamp, isRestoring = GetTimeStampForEvent()
    if(not isRestoring) then
        StoreChatEvent(timeStamp, LIB_IDENTIFIER, tag, rawMessageText)
    end
    local formatString = GetFormatString(timeStamp)
    local formattedEventText = formatString:format(tag, rawMessageText)
    return formattedEventText, nil, tag, rawMessageText
end

local _, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
SimpleEventToCategoryMappings[LIB_IDENTIFIER] = CHAT_CATEGORY_SYSTEM

-- chat proxy
local ChatProxy = ZO_Object:Subclass()

function ChatProxy:New(longTag, shortTag)
    local obj = ZO_Object.New(self)
    obj.longTag = longTag
    obj.shortTag = shortTag
    obj.enabled = true
    return obj
end

-- public API

--- Method to a change the color of the tag for the next printed message.
--- @param color - A ZO_ColorDef or hex color string ("RRGGBB")
--- @return self, so you can chain the call like this: chat:SetTagColor:Print(message)
function ChatProxy:SetTagColor(color)
    if(self.enabled) then
        if(type(color) == "table") then
            color = color:ToHex()
        end
        self.tagColor = color
    end
    return self
end

--- Internal method to retrieve the colored tag. Resets the tag color when called.
--- @return string, the colored tag
function ChatProxy:GetTag()
    local tag = lib.settings.shortTagPrefixEnabled and self.shortTag or self.longTag
    tag = TAG_FORMAT:format(tag)
    if(self.tagColor) then
        tag = COLOR_FORMAT:format(self.tagColor, tag)
        self.tagColor = nil
    end
    return tag
end

--- Method to a print regular messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param message - The message to print.
function ChatProxy:Print(message)
    if(not self.enabled) then return end
    local tag = self:GetTag()
    ZO_ChatEvent(LIB_IDENTIFIER, tag, message)
end

--- Method to a print formatted messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param formatString - The formatting string passed to string.format
--- @param ... - values passed to string.format
function ChatProxy:Printf(formatString, ...)
    if(not self.enabled) then return end
    local tag = self:GetTag()
    ZO_ChatEvent(LIB_IDENTIFIER, tag, formatString:format(...))
end

--- setter to turn this proxy  off, so it no longer print anything to chat when one of its methods is called.
--- @param enabled - boolean which turns the output on or off
function ChatProxy:SetEnabled(enabled)
    self.enabled = enabled
end


--- @param longTag - a string identifier that is used to identify messages printed via this object. e.g. MyCoolAddon
--- @param shortTag - a string identifier that is used to identify messages printed via this object. e.g. MCA
--- @return a new print proxy instance with the passed tags
function lib.Create(...)
    return ChatProxy:New(...)
end
setmetatable(lib, { __call = function(_, ...) return lib.Create(...) end })

-- public library functions

--- Clears all chat windows
function lib:ClearChat()
    local activeWindows = CHAT_SYSTEM.windowPool:GetActiveObjects()
    for _, window in pairs(activeWindows) do
        window.buffer:Clear()
    end
end

--- Clears the stored chat history for the current session
function lib:ClearHistory()
    self.chatHistory = {}
    if(self.saveDataKey) then
        LibChatMessageHistory[self.saveDataKey] = self.chatHistory
    end
end

--- @return the stored chat history for the current session
function lib:GetHistory()
    return self.chatHistory
end

--- @param enabled - controls the time prefix for chat messages
function lib:SetTimePrefixEnabled(enabled)
    if(self.settings) then
        self.settings.timePrefixEnabled = enabled
    end
end

--- @return true, if the time prefix is enabled
function lib:IsTimePrefixEnabled()
    if(self.settings) then
        return self.settings.timePrefixEnabled
    end
    return self.defaultSettings.timePrefixEnabled
end

--- @param enabled - controls the time prefix for regular chat messages sent by players
function lib:SetRegularChatMessageTimePrefixEnabled(enabled)
    if(self.settings) then
        self.settings.timePrefixOnRegularChat = enabled
    end
end

--- @return true, if the time prefix is enabled for regular chat messages sent by players
function lib:IsRegularChatMessageTimePrefixEnabled()
    if(self.settings) then
        return self.settings.timePrefixOnRegularChat
    end
    return self.defaultSettings.timePrefixOnRegularChat
end

lib.TIME_FORMATS = TIME_FORMATS

--- @param format - sets the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:SetTimePrefixFormat(format)
    if(self.settings) then
        self.settings.timePrefixFormat = format
    end
end

--- @return the format used for the time prefix. see os.date and TIME_FORMAT constants for details.
function lib:GetTimePrefixFormat()
    if(self.settings) then
        return self.settings.timePrefixFormat
    end
    return self.defaultSettings.timePrefixFormat
end

--- @param enabled - controls if add-ons should print a long or short tag prefix for their messages.
function lib:SetShortTagPrefixEnabled(enabled)
    if(self.settings) then
        self.settings.shortTagPrefixEnabled = enabled
    end
end

--- @return true, if add-ons should print a short tag prefix for their messages.
function lib:IsShortTagPrefixEnabled()
    if(self.settings) then
        return self.settings.shortTagPrefixEnabled
    end
    return self.defaultSettings.shortTagPrefixEnabled
end

--- @param enabled - controls if the chat history should be enabled on the next UI load.
function lib:SetChatHistoryEnabled(enabled)
    if(self.settings) then
        self.settings.historyEnabled = enabled
    end
end

--- @return true, if the chat history will be enabled on the next UI load.
function lib:IsChatHistoryEnabled()
    if(self.settings) then
        return self.settings.historyEnabled
    end
    return self.defaultSettings.historyEnabled
end

--- @return true, if the chat history is currently running.
function lib:IsChatHistoryActive()
    return self.chatHistoryActive
end

--- @param maxAge - number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:SetChatHistoryMaxAge(maxAge)
    if(self.settings) then
        self.settings.historyMaxAge = maxAge
    end
end

--- @return number of seconds a chat message can be stored before it is no longer restored on UI load.
function lib:GetChatHistoryMaxAge()
    if(self.settings) then
        return self.settings.historyMaxAge
    end
    return self.defaultSettings.historyMaxAge
end

EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, function(event, name)
    if(name ~= LIB_IDENTIFIER) then return end

    lib.saveDataKey = GetWorldName() .. GetDisplayName()

    local chat = lib.Create("LibChatMessage", "LCM")
    SLASH_COMMANDS["/chatmessage"] = function(params)
        local handled = false
        local command, arg = zo_strsplit(" ", params)
        command = strlower(command)
        arg = strlower(arg)

        if(command == "time") then
            if(arg == "on") then
                lib:SetTimePrefixEnabled(true)
                chat:Print("Enabled time prefix")
            elseif(arg == "off") then
                lib:SetTimePrefixEnabled(false)
                chat:Print("Disabled time prefix")
            else
                local enabled = lib:IsTimePrefixEnabled()
                chat:Printf("Time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "chat") then
            if(arg == "on") then
                lib:SetRegularChatMessageTimePrefixEnabled(true)
                chat:Print("Enabled player chat message time prefix")
            elseif(arg == "off") then
                lib:SetRegularChatMessageTimePrefixEnabled(false)
                chat:Print("Disabled player chat message time prefix")
            else
                local enabled = lib:IsRegularChatMessageTimePrefixEnabled()
                chat:Printf("Player chat message time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "format") then
            local format = TIME_FORMAT_MAPPING[arg]
            if(format) then
                lib:SetTimePrefixFormat(format)
                chat:Printf("Set time prefix to %s format", arg)
            else
                format = lib:GetTimePrefixFormat()
                if(REVERSE_TIME_FORMAT_MAPPING[format]) then
                    format = REVERSE_TIME_FORMAT_MAPPING[format]
                end
                chat:Printf("Time prefix format is currently set to %s", format)
            end
            handled = true
        elseif(command == "tag") then
            if(arg == "short") then
                lib:SetShortTagPrefixEnabled(true)
                chat:Print("Set tag prefix to short format")
            elseif(arg == "long") then
                lib:SetShortTagPrefixEnabled(false)
                chat:Print("Set tag prefix to long format")
            else
                local enabled = lib:IsShortTagPrefixEnabled()
                chat:Printf("Tag prefix is currently set to %s format", enabled and "short" or "long")
            end
            handled = true
        elseif(command == "history") then
            if(arg == "on") then
                lib:SetChatHistoryEnabled(true)
                chat:Print("Set chat history enabled on the next UI load")
            elseif(arg == "off") then
                lib:SetChatHistoryEnabled(false)
                chat:Print("Set chat history disabled on the next UI load")
            else
                local active = lib:IsChatHistoryActive()
                local enabled = lib:IsChatHistoryEnabled()
                chat:Printf("Chat history is currently %s and will be %s on the next UI load", active and "active" or "inactive", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "age") then
            local maxAge = tonumber(arg)
            if(maxAge and maxAge > 0) then
                lib:SetChatHistoryMaxAge(maxAge)
                chat:Printf("Set maximum history age to %d seconds", maxAge)
            else
                maxAge = lib:GetChatHistoryMaxAge()
                chat:Printf("Maximum history age currently set to %d seconds", maxAge)
            end
            handled = true
        end

        if(not handled) then
            local out = {}
            out[#out + 1] = "/chatmessage <command> [argument]"
            out[#out + 1] = "- <time>      [on/off]"
            out[#out + 1] = "-     Enables or disables the time prefix"
            out[#out + 1] = "- <chat>      [on/off]"
            out[#out + 1] = "-     Controls the time prefix on regular chat"
            out[#out + 1] = "- <format>    [auto/12h/24h]"
            out[#out + 1] = "-     Changes the used time format"
            out[#out + 1] = "- <tag>       [short/long]"
            out[#out + 1] = "-     Changes the length of the used tag"
            out[#out + 1] = "- <history>   [on/off]"
            out[#out + 1] = "-     Restore old chat after login"
            out[#out + 1] = "- <age>       [seconds]"
            out[#out + 1] = "-     The maximum age of restored chat"
            out[#out + 1] = "-"
            out[#out + 1] = "- Example: /chatmessage tag short"
            chat:Print(tconcat(out, "\n"))
        end
    end

    LibChatMessageSettings = LibChatMessageSettings or {}
    LibChatMessageHistory = LibChatMessageHistory or {}

    lib.settings = LibChatMessageSettings[lib.saveDataKey] or ZO_ShallowTableCopy(lib.defaultSettings)
    LibChatMessageSettings[lib.saveDataKey] = lib.settings

    lib.chatHistoryActive = lib.settings.historyEnabled
    if(lib.chatHistoryActive) then
        EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED, function()
            EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED)
            -- make sure we restore it after other addons had a chance to set up their formatters
            zo_callLater(function()
                lib:ClearChat()

                local newHistory = {}
                local oldHistory = LibChatMessageHistory[lib.saveDataKey]
                local tempHistory = lib.chatHistory
                if(oldHistory) then
                    local ageThreshold = GetTimeStamp() - lib.settings.historyMaxAge
                    for i = 1, #oldHistory do
                        local timeStamp = oldHistory[i][TIMESTAMP_INDEX]
                        if(timeStamp > ageThreshold) then
                            newHistory[#newHistory + 1] = oldHistory[i]
                            lib.nextEventTimeStamp = timeStamp
                            ZO_ChatEvent(select(TIMESTAMP_INDEX + 1, unpack(oldHistory[i])))
                        end
                    end
                end

                if(lib.nextEventTimeStamp ~= nil) then
                    -- small hack to avoid storing the message in the history
                    lib.nextEventTimeStamp = GetTimeStamp()
                    chat:Print("End of restored chat history")
                end

                for i = 1, #tempHistory do
                    newHistory[#newHistory + 1] = tempHistory[i]
                    lib.nextEventTimeStamp = tempHistory[i][TIMESTAMP_INDEX]
                    ZO_ChatEvent(select(TIMESTAMP_INDEX + 1, unpack(tempHistory[i])))
                end

                lib.nextEventTimeStamp = nil
                lib.chatHistory = newHistory
                LibChatMessageHistory[lib.saveDataKey] = newHistory
            end, 0)
        end)
    else
        lib:ClearHistory()
    end
end)
