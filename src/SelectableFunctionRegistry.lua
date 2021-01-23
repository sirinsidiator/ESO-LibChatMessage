local lib = LibChatMessage
local internal = lib.internal
local callback = lib.callback

local DEFAULT_IDENTIFIER = lib.id

local SelectableFunctionRegistry = ZO_Object:Subclass()
internal.class.SelectableFunctionRegistry = SelectableFunctionRegistry

function SelectableFunctionRegistry:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function SelectableFunctionRegistry:Initialize()
    self.selectableFunction = {}
end

function SelectableFunctionRegistry:Register(path, selectableFunction)
    self.selectableFunction[path] = selectableFunction
end

function SelectableFunctionRegistry:Get(path)
    return self.selectableFunction[path]
end

function SelectableFunctionRegistry:RegisterFunction(path, identifier, func)
    local selectableFunction = self.selectableFunction[path]
    if selectableFunction then
        selectableFunction:RegisterFunction(identifier, func)
    else
        internal.logger:Warn("Tried to register function for non-existing path")
    end
end

function SelectableFunctionRegistry:GetPathsWithAChoice()
    local paths = {}
    for path, func in pairs(self.selectableFunction) do
        if(func:HasChoice()) then
            paths[#paths + 1] = path
        end
    end
    table.sort(paths)
    return paths
end

internal.selectableFunctionRegistry = SelectableFunctionRegistry:New()

function internal:InitializeSelectableFunctionRegistry(settings)
    internal.logger:Verbose("Initialize SelectableFunctionRegistry")
    local registry = internal.selectableFunctionRegistry

    internal.logger:Verbose("Before SELECTABLE_FUNCTIONS_SETUP")
    self:FireCallbacks(callback.SELECTABLE_FUNCTIONS_SETUP, registry)
    internal.logger:Verbose("After SELECTABLE_FUNCTIONS_SETUP")

    local selectedFunctions = settings.selectedFunctions
    for path, func in pairs(registry.selectableFunction) do
        local identifier = selectedFunctions[path]
        if(identifier and func:HasIdentifier(identifier)) then
            func:SelectFunction(identifier)
        end
        func:SetSavedVariable(selectedFunctions)
    end

    internal.logger:Verbose("Before SELECTABLE_FUNCTIONS_READY")
    self:FireCallbacks(callback.SELECTABLE_FUNCTIONS_READY, registry)
    internal.logger:Verbose("After SELECTABLE_FUNCTIONS_READY")
end
