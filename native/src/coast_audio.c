#include "coast_audio.h"

CA_API void coast_audio_get_version(char *pMajor, char *pMinor, char *pPatch)
{
    *pMajor = 1;
    *pMinor = 0;
    *pPatch = 0;
}
