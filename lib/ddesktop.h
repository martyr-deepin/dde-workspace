#ifndef __DCORE_H___
#define __DCORE_H___
#include <JavaScriptCore/JSContextRef.h>

struct DDesktopData {
    void* webview;
    void* global_region;
    void* tmp_region;
};

void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data);

#endif


