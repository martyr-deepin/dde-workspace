#include "jsextension.h"
#include <gio/gio.h>
#include <glib.h>
gboolean launch(GAppInfo* info)
{
    return g_app_info_launch(info, NULL, NULL, NULL);
}
