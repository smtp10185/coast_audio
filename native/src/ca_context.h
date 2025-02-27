#include "miniaudio.h"
#include "ca_export.h"

typedef struct
{
    void *pRef;
} ca_context;

CA_API ma_result ca_context_init(const ma_backend backends[], ma_uint32 backendCount, const ma_context_config *pConfig, ca_context *pContext);

CA_API ma_context *ca_context_get_ref(ca_context *pContext);

CA_API ma_result ca_context_uninit(ca_context *pContext);
