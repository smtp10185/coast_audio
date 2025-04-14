#ifdef _WIN32
  #ifdef CA_DLL
    #define CA_API __declspec(dllexport)
  #else
    #define CA_API __declspec(dllimport)
  #endif
#else
  #define CA_API
#endif
