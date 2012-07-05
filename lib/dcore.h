#ifndef __DCORE_H___
#define __DCORE_H___
#include <gtk/gtk.h>
#include <JavaScriptCore/JSContextRef.h>

struct DDesktopData {
    GtkWidget* webview;
    cairo_region_t* global_region;
    cairo_region_t* tmp_region;
};

void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data);

#endif


