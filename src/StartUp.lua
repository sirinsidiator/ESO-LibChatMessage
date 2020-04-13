local LIB_IDENTIFIER = "LibChatMessage"

assert(not _G[LIB_IDENTIFIER], LIB_IDENTIFIER .. " is already loaded")

local logger
if(LibDebugLogger) then
    logger = LibDebugLogger(LIB_IDENTIFIER)
else
    local function noop() end
    logger = setmetatable({}, { __index = function() return noop end })
end

local callbackObject = ZO_CallbackObject:New()

local function FireCallbacks(self, ...)
    return callbackObject:FireCallbacks(...)
end

local lib = {
    id = LIB_IDENTIFIER,
    internal = {
        class = {},
        chatHistory = {},
        proxyCache = {},
        formatter = {},
        logger = logger,
        callbackObject = callbackObject,
        FireCallbacks = FireCallbacks
    },
    callback = {},
}
_G[LIB_IDENTIFIER] = lib

EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, function(event, name)
    if(name ~= LIB_IDENTIFIER) then return end

    local internal = lib.internal
    internal.chat = lib.Create("LibChatMessage", "LCM", LIB_IDENTIFIER)
    local settings = internal:InitializeSettings()
    internal:InitializeHistory(settings)
end)
