#include "config.h"
#include <gio/gio.h>
#include <gtk/gtk.h>
#include "dentry/fileops_trash.h"

extern GtkWidget* container;

DBUS_EXPORT_API
gboolean desktop_confirm_trash(gchar* primaryText G_GNUC_UNUSED,
                               gchar* secondaryText G_GNUC_UNUSED,
                               gchar* detailText G_GNUC_UNUSED)
{
    g_warning("%s", __func__);
    return fileops_confirm_trash(GTK_WINDOW(container)) == GTK_RESPONSE_OK;
}
