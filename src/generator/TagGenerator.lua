local lib = LibChatMessage
local internal = lib.internal
local GeneratorBase = internal.class.GeneratorBase

local COLOR_FORMAT = "|c%s%s|r"
local BRACKET_FORMAT = "[%s]"

local TagGenerator = GeneratorBase:Subclass()
internal.class.TagGenerator = TagGenerator

function TagGenerator:New(...)
    return GeneratorBase.New(self, ...)
end

function TagGenerator:Initialize(pathId, formatter, longTag, shortTag)
    GeneratorBase.Initialize(self, pathId, formatter)
    self:SetTags(longTag, shortTag)
    self:SetBracketFormat(BRACKET_FORMAT)
    self:SetColorFormat(COLOR_FORMAT)
end

function TagGenerator:SetTags(longTag, shortTag)
    self.longTag = longTag
    self.shortTag = shortTag or longTag
end

function TagGenerator:SetTagColor(color)
    self.color = color
end

function TagGenerator:SetBracketFormat(format)
    self.bracketFormat = format
end

function TagGenerator:SetColorFormat(format)
    self.colorFormat = format
end

function TagGenerator:Generate()
    return self:FormatTag(self:GetActiveTag())
end

function TagGenerator:GetActiveTag()
    if(lib:GetTagPrefixMode() == lib.TAG_PREFIX_SHORT) then
        return self.shortTag
    end
    return self.longTag
end

function TagGenerator:FormatTag(tag)
    tag = self.bracketFormat:format(tag)
    if self.color then
        tag = self.colorFormat:format(self.color, tag)
    end
    return tag
end
