local lib = LibChatMessage
local internal = lib.internal
local SelectableFunction = internal.class.SelectableFunction

local PATH_ID_TEMPLATE = "%s.%s"
local GENERATOR_PATH_ID = "generator"
local FORMATTER_PATH_ID = "formatter"
local DEFAULT_IDENTIFIER = lib.id
local COLOR_TEMPLATE = "|c%.2x%.2x%.2x%s|r"
local RETURN_COLOR_TEMPLATE = "|c%.2x%.2x%.2x"
local RETURN_DEFAULT_TEMPLATE = "|r"

local GeneratorBase = ZO_Object:Subclass()
internal.class.GeneratorBase = GeneratorBase

function GeneratorBase:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

-- make sure to call GeneratorBase.Initialize(self, pathId, formatter) when overwriting this function
function GeneratorBase:Initialize(id, formatter)
    self.id = id
    self.formatter = formatter
    self.generator = SelectableFunction:New(id, self.Generate)
    self.decorators = {}
end

function GeneratorBase:Reset()
-- overwrite in case some state has to be reset
end

function GeneratorBase:Build(...)
    local value = self.generator:Run(self, ...)
    local decorated = self:Decorate(value)
    self.output = self:Colorize(decorated)
    return self.output
end

function GeneratorBase:Generate(...)
    assert(false, "Function not implemented")
end

function GeneratorBase:Format(value)
    return value
end

function GeneratorBase:Decorate(value)
    local decorators = self.decorators
    for i = 1, #decorators do
        local decorated = decorators[i](self, value)
        if type(decorated) == "string" then value = decorated end
    end
    return value
end

function GeneratorBase:RegisterDecorator(decorator)
    local decorators = self.decorators
    decorators[#decorators + 1] = decorator
end

--- can be used by addons to apply a color to the generated output. should be called in the FORMATTER_INPUT callback.
function GeneratorBase:SetColor(color)
    self.color = color
end

function GeneratorBase:Colorize(value)
    if self.color then
        local c = self.color
        return COLOR_TEMPLATE:format(math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255), value)
    end
    return value
end

--- can be used by addons to apply the correct color markup in case they changed it during the build phase
function GeneratorBase:GetColorMarkup()
    if self.color then
        local c = self.color
        return RETURN_COLOR_TEMPLATE:format(math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
    end
    return RETURN_DEFAULT_TEMPLATE
end
