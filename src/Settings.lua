local lib = LibChatMessage
local internal = lib.internal

local TIME_FORMAT_AUTO, TIME_FORMAT_12, TIME_FORMAT_24 = unpack(lib.TIME_FORMATS)
local TIME_FORMAT_MAPPING = {
    ["auto"] = TIME_FORMAT_AUTO,
    ["12h"] = TIME_FORMAT_12,
    ["24h"] = TIME_FORMAT_24,
}
local REVERSE_TIME_FORMAT_MAPPING = {}
for label, format in pairs(TIME_FORMAT_MAPPING) do
    REVERSE_TIME_FORMAT_MAPPING[format] = label
end

internal.defaultSettings = {
    version = 2,
    timePrefixEnabled = false,
    timePrefixOnRegularChat = true,
    timePrefixFormat = TIME_FORMAT_AUTO,
    tagPrefixMode = lib.TAG_PREFIX_LONG,
    historyEnabled = false,
    historyMaxAge = 3600,
    selectedFunctions = {}
}

-- make a temporary copy until the real settings are available to avoid errors when they are accessed
internal.settings = ZO_ShallowTableCopy(internal.defaultSettings)

function internal:InitializeSettings()
    self.saveDataKey = GetWorldName() .. GetDisplayName()

    LibChatMessageSettings = LibChatMessageSettings or {}
    if LibChatMessageSettings[self.saveDataKey] then
        local tempSettings = self.settings
        self.settings = LibChatMessageSettings[self.saveDataKey]

        -- upgrade settings
        for key, value in pairs(tempSettings) do
            if(self.settings[key] == nil) then
                self.settings[key] = value
            end
        end

        for key in pairs(self.settings) do
            if(tempSettings[key] == nil) then
                self.settings[key] = nil
            end
        end

        self.settings.version = tempSettings.version
    else
        LibChatMessageSettings[self.saveDataKey] = self.settings
    end

    local chat = internal.chat

    SLASH_COMMANDS["/chatmessage"] = function(params)
        local handled = false
        local command, arg = zo_strsplit(" ", params)
        command = command and command:lower() or ""
        arg = arg and arg:lower() or "" -- TODO do not lower arg for select command

        if(command == "time") then
            if(arg == "on") then
                lib:SetTimePrefixEnabled(true)
                chat:Print("Enabled time prefix")
            elseif(arg == "off") then
                lib:SetTimePrefixEnabled(false)
                chat:Print("Disabled time prefix")
            else
                local enabled = lib:IsTimePrefixEnabled()
                chat:Printf("Time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "chat") then
            if(arg == "on") then
                lib:SetRegularChatMessageTimePrefixEnabled(true)
                chat:Print("Enabled player chat message time prefix")
            elseif(arg == "off") then
                lib:SetRegularChatMessageTimePrefixEnabled(false)
                chat:Print("Disabled player chat message time prefix")
            else
                local enabled = lib:IsRegularChatMessageTimePrefixEnabled()
                chat:Printf("Player chat message time prefix is currently %s", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "format") then
            local format = TIME_FORMAT_MAPPING[arg]
            if(format) then
                lib:SetTimePrefixFormat(format)
                chat:Printf("Set time prefix to %s format", arg)
            else
                format = lib:GetTimePrefixFormat()
                if(REVERSE_TIME_FORMAT_MAPPING[format]) then
                    format = REVERSE_TIME_FORMAT_MAPPING[format]
                end
                chat:Printf("Time prefix format is currently set to %s", format)
            end
            handled = true
        elseif(command == "tag") then
            if(arg == "short") then
                lib:SetTagPrefixMode(lib.TAG_PREFIX_SHORT)
                chat:Print("Set tag prefix to short format")
            elseif(arg == "long") then
                lib:SetTagPrefixMode(lib.TAG_PREFIX_LONG)
                chat:Print("Set tag prefix to long format")
            elseif(arg == "off") then
                lib:SetTagPrefixMode(lib.TAG_PREFIX_OFF)
                chat:Print("Disabled showing a tag prefix")
            else
                local mode = lib:GetTagPrefixMode()
                if(mode == lib.TAG_PREFIX_OFF) then
                    chat:Print("Tag prefix is currently disabled")
                else
                    local enabled = (mode == lib.TAG_PREFIX_SHORT)
                    chat:Printf("Tag prefix is currently set to %s format", enabled and "short" or "long")
                end
            end
            handled = true
        elseif(command == "history") then
            if(arg == "on") then
                lib:SetChatHistoryEnabled(true)
                chat:Print("Set chat history enabled on the next UI load")
            elseif(arg == "off") then
                lib:SetChatHistoryEnabled(false)
                chat:Print("Set chat history disabled on the next UI load")
            else
                local active = lib:IsChatHistoryActive()
                local enabled = lib:IsChatHistoryEnabled()
                chat:Printf("Chat history is currently %s and will be %s on the next UI load", active and "active" or "inactive", enabled and "enabled" or "disabled")
            end
            handled = true
        elseif(command == "age") then
            local maxAge = tonumber(arg)
            if(maxAge and maxAge > 0) then
                lib:SetChatHistoryMaxAge(maxAge)
                chat:Printf("Set maximum history age to %d seconds", maxAge)
            else
                maxAge = lib:GetChatHistoryMaxAge()
                chat:Printf("Maximum history age currently set to %d seconds", maxAge)
            end
            handled = true
        elseif(command == "select") then
            local path, id = zo_strsplit("=", arg)
            local registry = internal.selectableFunctionRegistry
            local selectableFunction = registry:Get(path)
            if(selectableFunction) then
            internal.logger:Debug("select", path, id, selectableFunction:HasIdentifier(id))
                if(selectableFunction:HasIdentifier(id)) then
                    selectableFunction:SelectFunction(id)
                    chat:Printf("Select %s for %s", id, path)
                else
                    local identifiers = selectableFunction:GetIdentifiers()
                    local out = {}
                    out[#out + 1] = string.format("/chatmessage select %s=%s", path, selectableFunction:GetSelectedIdentifier())
                    out[#out + 1] = "Available addons:"
                    for i = 1, #identifiers do
                        out[#out + 1] = string.format("|u100%%:0:  :|u%s", identifiers[i])
                    end
                    chat:Print(table.concat(out, "\n"))
                end
            else
                local paths = registry:GetPathsWithAChoice()
                local out = {}
                out[#out + 1] = "/chatmessage select <path>=[identifier]"
                out[#out + 1] = "Select which addons are used to generate or format parts of a message"
                out[#out + 1] = "Available generator paths which offer a replacement:"
                for i = 1, #paths do
                    local path = paths[i]
                    local func = registry:Get(path)
                    out[#out + 1] = string.format("|u100%%:0:  :|u%s=%s", path, func:GetSelectedIdentifier())
                end
                out[#out + 1] = "Enter just the path to see which addons are available"
                chat:Print(table.concat(out, "\n"))
            end
            handled = true
        end

        if(not handled) then
            local out = {}
            out[#out + 1] = "/chatmessage <command> [argument]"
            out[#out + 1] = "<time>|u129%:0:  :|u[on/off]|u286%:0:       :|uEnables or disables the time prefix"
            out[#out + 1] = "<chat>|u125%:0:  :|u[on/off]|u288%:0:       :|uShow time prefix on regular chat"
            out[#out + 1] = "<format>|u62%:0: :|u[auto/12h/24h]|u68%:0:  :|uChanges the time format used"
            out[#out + 1] = "<tag>|u165%:0:   :|u[off/short/long]|u50%:0::|uControls how a message is tagged"
            out[#out + 1] = "<history>|u50%:0::|u[on/off]|u286%:0:       :|uRestore old chat after login"
            out[#out + 1] = "<age>|u147%:0:   :|u[seconds]|u200%:0:      :|uThe maximum age of restored chat"
            out[#out + 1] = "<select>|u400%:0:                           :|Choose addons for different tasks"
            out[#out + 1] = "Example: /chatmessage tag short"
            chat:Print(table.concat(out, "\n"))
        end
    end

    return self.settings
end
