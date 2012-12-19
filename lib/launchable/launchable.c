#include "jsextension.h"
#include <gio/gio.h>
#include <glib.h>
JS_EXPORT_API
gboolean launchable_launch(GAppInfo* info)
{
    return g_app_info_launch(info, NULL, NULL, NULL);
}
