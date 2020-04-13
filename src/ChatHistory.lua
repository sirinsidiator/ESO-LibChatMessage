local lib = LibChatMessage
local internal = lib.internal
local callback = lib.callback

local MAX_HISTORY_LENGTH = 10000
local TRIMMED_HISTORY_LENGTH = 9000
local TIMESTAMP_INDEX = 1

local nextId = 1

local function SetCurrentEventTime(time)
    internal.currentEventTime = time or GetTimeStamp()
    return internal.currentEventTime
end

local function SetCurrentEventId()
    internal.currentEventId = nextId
    nextId = nextId + 1
end

local function StoreChatEvent(timeStamp, type, ...)
    if(internal.isReady and not internal.chatHistoryActive) then return end
    local chatHistory = internal.chatHistory
    chatHistory[#chatHistory + 1] = {timeStamp, type, ...}
    if(#chatHistory > MAX_HISTORY_LENGTH) then
        local newHistory = {}
        for i = #chatHistory - TRIMMED_HISTORY_LENGTH, #chatHistory do
            newHistory[#newHistory + 1] = chatHistory[i]
        end
        internal:SetChatHistory(newHistory)
    end
end

ZO_PreHook(CHAT_ROUTER, "FormatAndAddChatMessage", function(self, eventType, ...)
    local skipOutput = false

    if(not internal.isRestoring) then
        local eventTime = SetCurrentEventTime()
        StoreChatEvent(eventTime, eventType, ...)
        -- we will replay all events once the library is ready, so we skip printing them during startup
        skipOutput = internal.isReady
    end

    if skipOutput then
        return true
    else
        SetCurrentEventId()
    end
end)

local function RestoreChatEvent(history, entry)
    history[#history + 1] = entry
    SetCurrentEventTime(entry[TIMESTAMP_INDEX])
    CHAT_ROUTER:FormatAndAddChatMessage(select(TIMESTAMP_INDEX + 1, unpack(entry)))
end

function internal:InitializeHistory(settings)
    LibChatMessageHistory = LibChatMessageHistory or {}

    internal.chatHistoryActive = settings.historyEnabled

    EVENT_MANAGER:RegisterForEvent(lib.id, EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent(lib.id, EVENT_PLAYER_ACTIVATED)
        -- make sure we restore it after other addons had a chance to set up their formatters
        zo_callLater(function()
            self.isRestoring = true
            lib:ClearChat()
            local oldHistory = LibChatMessageHistory[self.saveDataKey]
            local newHistory = {}
            local tempHistory = self.chatHistory

            if(self.chatHistoryActive and oldHistory and not self:FireCallbacks(callback.BEFORE_HISTORY_RESTORE, oldHistory)) then
                local hasRestored = false
                local ageThreshold = GetTimeStamp() - settings.historyMaxAge
                for i = 1, #oldHistory do
                    local entry = oldHistory[i]
                    if(entry[TIMESTAMP_INDEX] > ageThreshold and not self:FireCallbacks(callback.HISTORY_RESTORE, newHistory, entry, oldHistory, i)) then
                        RestoreChatEvent(newHistory, entry)
                        hasRestored = true
                    end
                end

                self:FireCallbacks(callback.AFTER_HISTORY_RESTORE, newHistory)
                if hasRestored then
                    SetCurrentEventTime() -- need to set the time manually here
                    self.chat:Print("End of restored chat history")
                end
            end

            for i = 1, #tempHistory do
                RestoreChatEvent(newHistory, tempHistory[i])
            end

            LibChatMessageHistory[self.saveDataKey] = newHistory
            self.chatHistory = newHistory
            self.isRestoring = false
            self.isReady = true
        end, 0)
    end)

    if(not self.chatHistoryActive) then
        lib:ClearHistory()
    end
end
