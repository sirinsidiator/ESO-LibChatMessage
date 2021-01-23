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

-- RegisterFormatter    path, groups, formatter
-- RegisterGenerator    path, groups

-- /select *=pChat -> try set everything to pChat or ignore otherwise
-- /select private=pChat -> everything in group private
-- /select private.*=pChat -> same
-- /select private.name=pChat -> name in each formatter in the private group
-- /select chat.*= /chat= -> all in the path for chat

-- system.tag -> both game and addons
-- addons.tag -> only addon tags
-- tag -> all generators for "tag"

function SelectProvider(path, provider)
    for component in pairs(GetComponents(path)) do
        component:SelectProvider(provider)
    end
end

function GetComponents(path) -- always return a table
    path = "addon"
    local components = {}
    if registry[path] then
        components[1] = registry[path]
    else
        local groupOrGenerator, component = zo_strsplit(".", path)
        local group = registry[groupOrGenerator]
        if component and group[component] then
            ZO_ShallowTableCopy(group[component], components)
        elseif group then
            ZO_ShallowTableCopy(group, components)
        end
    end

    return components
end

function GetAvailableGroups()
    local groups = {}
    for name in pairs(groupRegistry) do
        groups[#groups + 1] = name
    end
    table.sort(groups)
    return groups
end

function GetAvailablePaths()
    local paths = {}
    for path in pairs(registry) do
        paths[#paths + 1] = path
    end
    table.sort(paths)
    return paths
end

function GetOrCreateGroup(name)
    local registry = groupRegistry
    if not registry[name] then
        registry[name] = {}
    end
    return registry[name]
end

function AddToGroup(name, generator)
    local group = GetOrCreateGroup(name)
    group[#group + 1] = generator
end

function RegisterGenerator(formatterName, generatorName, groups, generator)
    registry[PATH_TEMPLATE:format(formatterName, generatorName)] = generator
    AddToGroup(formatterName, generator)
    AddToGroup(generatorName, generator)
    for i = 1, #groups do
        AddToGroup(groups[i], generator)
    end
end

function RegisterDecorator(path, decorator)
    local generator = registry[path]
    if generator then
        generator:RegisterDecorator(decorator)
    else
        internal.logger:Warn("Generator for path '%s' does not exist", path)
    end
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
