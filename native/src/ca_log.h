#include "miniaudio.h"
#include "ca_dart.h"
#include "ca_export.h"

#define CA_LOG_MESSAGE_BUFFER_COUNT 256

typedef struct ca_log_message
{
    ma_log_level level;
    const char *pMessage;
} ca_log_message;

typedef struct ca_log
{
    ma_mutex lock;
    ma_log log;
    Dart_Port_DL portId;
    Dart_CObject notification;
    ma_bool8 hasNotification;
    ma_uint32 messageCount;
    ca_log_message messages[CA_LOG_MESSAGE_BUFFER_COUNT];
} ca_log;

CA_API ma_result ca_log_init(ca_log *pLog);

CA_API ma_log *ca_log_get_ref(ca_log *pLog);

CA_API void ca_log_get_messages(ca_log *pLog, ca_log_message **ppMessages, ma_uint32 *pCount);

CA_API void ca_log_release_messages(ca_log *pLog, ma_uint32 count);

CA_API void ca_log_set_notification(ca_log *pLog, Dart_Port_DL portId);

CA_API void ca_log_uninit(ca_log *pLog);
