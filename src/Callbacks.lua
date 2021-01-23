local lib = LibChatMessage
local callback = lib.callback

-- TODO  document

callback.FORMATTER_BEGIN = "OnFormatterBegin"
callback.FORMATTER_RESET = "OnFormatterReset"
callback.FORMATTER_INPUT = "OnFormatterInput"
callback.FORMATTER_OUTPUT = "OnFormatterOutput"

callback.BEFORE_HISTORY_RESTORE = "OnBeforeHistoryRestore"
callback.HISTORY_RESTORE = "OnHistoryRestore"
callback.AFTER_HISTORY_RESTORE = "OnAfterHistoryRestore"

callback.SELECTABLE_FUNCTIONS_SETUP = "OnSelectableFunctionsSetup"
callback.SELECTABLE_FUNCTIONS_READY = "OnSelectableFunctionsReady"