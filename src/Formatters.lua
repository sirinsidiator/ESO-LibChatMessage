local lib = LibChatMessage
local internal = lib.internal
local logger = internal.logger

local SYSTEM_TAG = GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM)

-- we overwrite the ingame formatter as soon as we can. Other addons can modify them via our API, but must not replace them,
-- or the library won't work anymore. In order to ensure this, we make the table read only with the help of meta methods.

local messageFormatters = CHAT_ROUTER:GetRegisteredMessageFormatters()
local function ReplaceBuiltInFormatter(eventType, formatter)
    logger:Verbose("ReplaceBuiltInFormatter")
    formatter:SetEventType(eventType)
    internal.formatter[eventType] = formatter
    messageFormatters[eventType] = function(...) return formatter:Format(...) end
end

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_CHAT_MESSAGE_CHANNEL, CHAT_CHANNEL_SAY, "test", "test", false, "test")
ReplaceBuiltInFormatter(EVENT_CHAT_MESSAGE_CHANNEL, internal.class.ChatMessageFormatter:New("chat"))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_BROADCAST, "test")
ReplaceBuiltInFormatter(EVENT_BROADCAST, internal.class.TaggedMessageFormatter:New("broadcast", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_FRIEND_PLAYER_STATUS_CHANGED, "test", "test", PLAYER_STATUS_OFFLINE, PLAYER_STATUS_ONLINE)
ReplaceBuiltInFormatter(EVENT_FRIEND_PLAYER_STATUS_CHANGED, internal.class.PlayerStatusFormatter:New("friendstatus", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_IGNORE_ADDED, "test")
ReplaceBuiltInFormatter(EVENT_IGNORE_ADDED, internal.class.IgnoreStatusFormatter:New("ignore", SYSTEM_TAG, SI_FRIENDS_LIST_IGNORE_ADDED))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_IGNORE_REMOVED, "test")
ReplaceBuiltInFormatter(EVENT_IGNORE_REMOVED, internal.class.IgnoreStatusFormatter:New("unignore", SYSTEM_TAG, SI_FRIENDS_LIST_IGNORE_REMOVED))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_TYPE_CHANGED, false)
ReplaceBuiltInFormatter(EVENT_GROUP_TYPE_CHANGED, internal.class.GroupTypeFormatter:New("grouptype", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_INVITE_RESPONSE, "test", GROUP_INVITE_RESPONSE_PLAYER_NOT_FOUND, "test")
ReplaceBuiltInFormatter(EVENT_GROUP_INVITE_RESPONSE, internal.class.GroupInviteFormatter:New("groupinvite", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_SOCIAL_ERROR, SOCIAL_RESULT_ACCOUNT_NOT_FOUND)
ReplaceBuiltInFormatter(EVENT_SOCIAL_ERROR, internal.class.SocialErrorFormatter:New("socialerror", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_TRIAL_FEATURE_RESTRICTED, TRIAL_RESTRICTION_CANNOT_WHISPER)
ReplaceBuiltInFormatter(EVENT_TRIAL_FEATURE_RESTRICTED, internal.class.TrialRestrictionFormatter:New("featurerestriction", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_GROUP_MEMBER_LEFT, "character", GROUP_LEAVE_REASON_KICKED, true, false, "account", true)
ReplaceBuiltInFormatter(EVENT_GROUP_MEMBER_LEFT, internal.class.GroupKickFormatter:New("groupkick", SYSTEM_TAG))

-- CHAT_ROUTER:FormatAndAddChatMessage(EVENT_BATTLEGROUND_INACTIVITY_WARNING)
ReplaceBuiltInFormatter(EVENT_BATTLEGROUND_INACTIVITY_WARNING, internal.class.BattlegroundInactivityFormatter:New("battleground", SYSTEM_TAG))

-- CHAT_ROUTER:AddSystemMessage("test")
ReplaceBuiltInFormatter("AddSystemMessage", internal.class.TaggedMessageFormatter:New("system", SYSTEM_TAG))

-- LibChatMessage("long", "short", "test"):Print("test")
do
    local _, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
    SimpleEventToCategoryMappings[lib.id] = CHAT_CATEGORY_SYSTEM
    local formatter = internal.class.ChatProxyFormatter:New("addon")
    CHAT_ROUTER:RegisterMessageFormatter(lib.id, function(...)
        return formatter:Format(...)
    end)
    internal.formatter[lib.id] = formatter
end

do
    -- move the actual formatters into a second table and only access them via meta events in order to prevent others from replacing them and breaking the library
    local privateTable = ZO_ShallowTableCopy(messageFormatters)
    ZO_ClearTable(messageFormatters)
    setmetatable(messageFormatters, {
        ["__index"] = privateTable,
        ["__newindex"] = function(t, key, value)
            if(internal.formatter[key]) then
                logger:Warn("Cannot set formatter when LibChatMessage is active. You need to use its API to modify messages")
            else
                t[key] = value
            end
        end,
    })
end
