local strings = {
    ["LIB_CHATMESSAGE_UNKNOWN_DESCRIPTION"] = 'The chat link "<<1>>" is currently not supported.\n\nMake sure the addon is installed and activated.\nMay ask the sender which addon is used.'
}
for id, text in pairs(strings) do
    ZO_CreateStringId(id, text)
end
