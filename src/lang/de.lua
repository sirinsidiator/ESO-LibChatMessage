local strings = {
    ["LIB_CHATMESSAGE_UNKNOWN_DESCRIPTION"] = 'Der Chat-Link "<<1>>" wird zurzeit nicht unterstützt.\n\nStell sicher, dass das Addon installiert und aktiviert ist.\nEventuell den Absender fragen, welches Addon verwendet wird.'
}
for id, text in pairs(strings) do
    SafeAddString(_G[id], text)
end
