#pragma once
#include "ca_export.h"
#include "dart_types.h"

typedef void (*Dart_PostCObject_Def)(Dart_Port_DL port_id, Dart_CObject *message);

CA_API void ca_dart_configure(Dart_PostCObject_Def pDartPostCObject);

CA_API void ca_dart_post_cobject(Dart_Port_DL port_id, Dart_CObject *message);
