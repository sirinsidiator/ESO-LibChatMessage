local lib = LibChatMessage
local internal = lib.internal

local SYSTEM_TAG = GetString("SI_CHATCHANNELCATEGORIES", CHAT_CATEGORY_SYSTEM)

local ChatProxy = ZO_Object:Subclass()
internal.class.ChatProxy = ChatProxy

function ChatProxy:New(longTag, shortTag, identifier)
    assert(type(longTag) == "string" and longTag ~= "" and longTag ~= SYSTEM_TAG, "Invalid long tag for ChatProxy")
    assert(type(shortTag) == "string" and shortTag ~= "" and shortTag ~= SYSTEM_TAG, "Invalid short tag for ChatProxy")
    local obj = ZO_Object.New(self)
    obj:Initialize(longTag, shortTag, identifier)
    return obj
end

function ChatProxy:Initialize(longTag, shortTag, identifier)
    self.enabled = true
    self.longTag = longTag
    self.shortTag = shortTag
    self.identifier = identifier
end

local function DoPrint(proxy, message)
    CHAT_ROUTER:FormatAndAddChatMessage(lib.id, proxy.longTag, proxy.shortTag, message, proxy.tagColor)
    -- reset the color after each message
    proxy.tagColor = nil
end

-- public API

--- Method to a change the color of the tag for the next printed message.
--- @param color - A ZO_ColorDef or hex color string ("RRGGBB")
--- @return self, so you can chain the call like this: chat:SetTagColor(color):Print(message)
function ChatProxy:SetTagColor(color)
    if(self.enabled) then
        if(type(color) == "table") then
            color = color:ToHex()
        end
        self.tagColor = color
    end
    return self
end

--- @return the active tag color as hex string.
function ChatProxy:GetTagColor()
    return self.tagColor
end

--- @return the long tag and the short tag.
function ChatProxy:GetTags()
    return self.longTag, self.shortTag
end

--- @return the proxy identifier
function ChatProxy:GetIdentifier()
    return self.identifier
end

--- Method to a print regular messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param message - The message to print.
function ChatProxy:Print(message)
    if(not self.enabled) then return end
    DoPrint(self, message)
end

--- Method to a print formatted messages to chat. The message will automatically be prefixed with the time and tag based on user preferences.
--- @param formatString - The formatting string passed to string.format
--- @param ... - values passed to string.format
function ChatProxy:Printf(formatString, ...)
    if(not self.enabled) then return end
    DoPrint(self, formatString:format(...))
end

--- setter to turn this proxy  off, so it no longer print anything to chat when one of its methods is called.
--- @param enabled - boolean which turns the output on or off
function ChatProxy:SetEnabled(enabled)
    self.enabled = enabled
end
