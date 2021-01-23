local lib = LibChatMessage
local internal = lib.internal
local callback = lib.callback

local DEFAULT_IDENTIFIER = lib.id

local SelectableFunction = ZO_Object:Subclass()
internal.class.SelectableFunction = SelectableFunction

function SelectableFunction:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function SelectableFunction:Initialize(pathId, defaultFunc)
    self.pathId = pathId
    self.functions = { [DEFAULT_IDENTIFIER] = defaultFunc }
    self.identifiers = { DEFAULT_IDENTIFIER }
    self:SelectFunction(DEFAULT_IDENTIFIER)
    self.hasChoice = false

    internal.selectableFunctionRegistry:Register(pathId, self)
end

function SelectableFunction:SetSavedVariable(savedVariable)
    self.savedVariable = savedVariable
end

function SelectableFunction:HasChoice()
    return self.hasChoice
end

function SelectableFunction:RegisterFunction(identifier, func)
    assert(identifier ~= DEFAULT_IDENTIFIER, "Cannot replace default function")
    if not self.functions[identifier] then
        self.identifiers[#self.identifiers + 1] = identifier
    end
    self.functions[identifier] = func
    self.hasChoice = true

    -- we automatically select the registered function. it will be overwritten by a stored user choice later
    self.selected = func
    self.selectedIdentifier = identifier
end

function SelectableFunction:GetIdentifiers()
    return self.identifiers
end

function SelectableFunction:GetSelectedIdentifier()
    return self.selectedIdentifier
end

function SelectableFunction:SelectFunction(identifier)
    assert(self.functions[identifier], "Identifier not registered")
    self.selected = self.functions[identifier]
    self.selectedIdentifier = identifier
    if(self.savedVariable) then
        self.savedVariable[self.pathId] = identifier
    end
end

function SelectableFunction:HasIdentifier(identifier)
    return self.functions[identifier] ~= nil
end

function SelectableFunction:Run(...)
    return self.selected(...)
end
