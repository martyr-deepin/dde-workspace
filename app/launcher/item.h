#ifndef ITEM_H
#define ITEM_H

#include <glib.h>

#include "dentry/entry.h"

#define APPS_INI "launcher/apps.ini"
#define LAUNCHER_CONF "launcher/config.ini"
#define AUTOSTART_DIR "autostart"
#define GNOME_AUTOSTART_KEY "X-GNOME-Autostart-enabled"

void destroy_item_config();
GPtrArray* get_autostart_paths();
JS_EXPORT_API gboolean launcher_is_autostart(Entry* _item);

#endif /* end of include guard: ITEM_H */

