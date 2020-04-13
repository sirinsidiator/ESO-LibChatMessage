local lib = LibChatMessage
local internal = lib.internal

local ChatBuffer = ZO_Object:Subclass()
internal.class.ChatBuffer = ChatBuffer

function ChatBuffer:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ChatBuffer:Initialize(copyHandler, chatWindow)
    local textBuffer = chatWindow.buffer
    self.chatWindow = chatWindow
    self.entries = {}
    self.maxSize = textBuffer:GetMaxHistoryLines()
    self.count = 0
    self.nextIndex = 1

    ZO_PreHook(textBuffer, "AddMessage", function()
        self:Add(copyHandler:GetCurrentData())
    end)

    ZO_PreHook(textBuffer, "Clear", function()
        self:Clear()
    end)

    ZO_PreHook(textBuffer, "SetMaxHistoryLines", function(_, maxSize)
        self.maxSize = maxSize
    end)
end

function ChatBuffer:Add(element)
    self.entries[self.nextIndex] = element
    self.nextIndex = (self.nextIndex % self.maxSize) + 1
    if(self.count < self.maxSize) then
        self.count = self.count + 1
    end
end

function ChatBuffer:Clear()
    ZO_ClearTable(self.entries)
    self.count = 0
    self.nextIndex = 1
end

-- TODO id iterators