local lib = LibChatMessage
local callback = lib.callback
local internal = lib.internal

local DEFAULT_ICON_SIZE = 12 -- TODO percentage?
local DEFAULT_ICON_OFFSET = -7 -- TODO percentage?
local COPY_LINK_TYPE_TEMPLATE = "LibChatMessageCopy%s"
local DEFAULT_COPY_ICON = "Chat2Clipboard/images/copy.dds" -- TODO: find a fitting icon ingame or use the existing one?
-- we use a negative image width to go outside the visible area, then place a link with a dot and space as text and then the actual icon
-- the combination of char - space spans the link through the image until the next char appears in the string
local LINK_TEMPLATE = "%s|Hignore:%s:%%d|h. |h%s%%s"

local CopyHandler = ZO_Object:Subclass()
internal.class.CopyHandler = CopyHandler

function CopyHandler:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function CopyHandler:Initialize(chatSystem, linkType, copyCallback)
    self.chatSystem = chatSystem
    self.linkType = linkType

    -- we keep the messages in a weak buffer so they are cleaned up automatically
    self.messages = setmetatable({}, {__mode = "v"})

    -- the CopyBuffers will keep the references in sync with the TextBuffer controls
    self.copyBuffer = {}

    self:SetCopyLinkIcon(DEFAULT_COPY_ICON, DEFAULT_ICON_SIZE, DEFAULT_ICON_OFFSET)

    local originalFactory = chatSystem.windowPool.m_Factory
    chatSystem.windowPool.m_Factory = function(...)
        local window = originalFactory(...)
        self.copyBuffer[window] = internal.class.CopyBuffer:New(self, window)
        return window
    end

    local originalOnFormattedChatMessage = chatSystem.OnFormattedChatMessage
    chatSystem.OnFormattedChatMessage = function(chatSystem, message, ...)
        local id = self:StoreMessage(message)
        message = self:AddCopyLink(id, message) -- TODO add link per window so we can iterate over the messages in case some addon wants to do a copy all
        return originalOnFormattedChatMessage(chatSystem, message, ...)
    end

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, function(link, button, control, color, type, messageId)
        if type == linkType then
            -- TODO pass the message and tab somehow + the copy handler + add filter methods to manipulate the message
            messageId = tonumber(messageId)
            if messageId then
                local message = self.messages[messageId]
                if message then
                    internal:FireCallbacks(copyCallback, message, button) -- TODO handle UI in the lib too?
                end
            end
        end
    end)
end

function CopyHandler:SetCopyLinkIcon(iconPath, size, offset)
    local copyIcon = zo_iconFormat(iconPath, size, size)
    local offsetIcon = zo_iconFormat("blank.dds", offset or (-size / 2), size) -- TODO create a real blank icon?
    self.copyLinkTemplate = LINK_TEMPLATE:format(offsetIcon, self.linkType, copyIcon)
end

function CopyHandler:StoreMessage(message)
    local currentId = self.nextId
    self.nextId = currentId + 1
    self.messages[currentId] = {id = currentId, message = message}
    -- TODO get formatter data
    return currentId
end

function CopyHandler:AddCopyLink(id, message)
    return self.copyLinkTemplate:format(id, message)
end

local function Init() -- TODO
    CopyHandler:New(KEYBOARD_CHAT_SYSTEM, COPY_LINK_TYPE_TEMPLATE:format("Keyboard"), callback.COPY_MESSAGE_KEYBOARD)
    CopyHandler:New(GAMEPAD_CHAT_SYSTEM, COPY_LINK_TYPE_TEMPLATE:format("Gamepad"), callback.COPY_MESSAGE_GAMEPAD) -- TODO can we even do that in the gamepad ui?
end
