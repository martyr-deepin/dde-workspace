#include "jsextension.h"
#include "desktop_entry.h"
#include <gio/gio.h>

void install_monitor();

JSObjectRef on_delete = NULL;
JSObjectRef on_update = NULL;
JSObjectRef on_rename = NULL;

GFileMonitor *monitor = NULL;

JSValueRef item_connect(const char* type, JSValueRef value, JSData* js)
{
    JSObjectRef *cb = NULL;
    if (g_ascii_strcasecmp(type, "delete") == 0) {
        cb = &on_delete;
    } else if (g_ascii_strcasecmp(type, "update") == 0) {
        cb = &on_update;
    } else if (g_ascii_strcasecmp(type, "rename") == 0) {
        cb = &on_rename;
    } else {
        FILL_EXCEPTION(js->ctx, js->exception, "Didn't support signal type");
        return NULL;
    }

    if (*cb != NULL)
        JSValueUnprotect(js->ctx, *cb);

    *cb = JSValueToObject(js->ctx, value, js->exception);

    if (*cb != NULL) {
        JSValueProtect(js->ctx, *cb);
        return JSValueMakeUndefined(js->ctx);
    } else {
        return NULL;
    }
}


enum {
    ITEM_UPDATE,
    ITEM_DELETE,
    ITEM_RENAME
};

void item_notify(int action, const char* path, const char* old_path)
{
    switch (action) {
        case ITEM_RENAME:
            {
                if (old_path == NULL)
                    break;

                JSContextRef ctx = get_global_context();
                if (on_rename != NULL && JSObjectIsFunction(ctx, on_rename)) {
                    JSValueRef args[2];
                    args[0] = jsvalue_from_cstr(ctx, old_path);
                    char* info = parse_desktop_item(path);
                    args[1] = json_from_cstr(ctx, info);
                    g_free(info);
                    JSObjectCallAsFunction(ctx, on_rename,
                            NULL, 2, args, NULL);
                }
                break;

            }
        case ITEM_UPDATE:
            {
                JSContextRef ctx = get_global_context();
                if (on_update != NULL && JSObjectIsFunction(ctx, on_update)) {
                    JSValueRef args[1];
                    char* info = parse_desktop_item(path);
                    args[0] = json_from_cstr(ctx, info);
                    g_free(info);
                    JSObjectCallAsFunction(ctx, on_update,
                            NULL, 1, args, NULL);
                }
                break;
            }
        case ITEM_DELETE:
            {
                JSContextRef ctx = get_global_context();
                if (on_delete != NULL && JSObjectIsFunction(ctx, on_delete)) {
                    JSValueRef args[1];
                    args[0] = jsvalue_from_cstr(ctx, path);
                    JSObjectCallAsFunction(ctx, on_delete, 
                            NULL, 1, args, NULL);
                }
                break;
            }
        default:
            g_assert_not_reached();
    }
}

void monitor_desktop_dir_cb(GFileMonitor *m, 
        GFile *file, GFile *other, GFileMonitorEvent t, 
        gpointer user_data)
{
    switch (t) {
        case G_FILE_MONITOR_EVENT_MOVED:
            {
                puts("MOVED\n");
                char* old_path = g_file_get_path(file);
                char* new_path = g_file_get_path(other);
                item_notify(ITEM_RENAME, new_path, old_path);
                g_free(old_path);
                g_free(new_path);
                break;
            }
        case G_FILE_MONITOR_EVENT_DELETED:
            {
                puts("DELETED\n");
                char* path = g_file_get_path(file);
                if (g_strcmp0(path, get_desktop_dir(FALSE)) == 0) {
                    /*g_file_monitor_cancel(m);*/
                    /*install_monitor();*/
                } else {
                    item_notify(ITEM_DELETE, path, NULL);
                }
                g_free(path);
                break;
            }
        case G_FILE_MONITOR_EVENT_CREATED:
        /*case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:*/
            {
                puts("NEW\n");
                char* path = g_file_get_path(file);
                item_notify(ITEM_UPDATE, path, NULL);
                g_free(path);
                break;
            }
    }

}

void install_monitor()
{
    if (monitor == NULL) {
        GFile *dir = g_file_new_for_path(get_desktop_dir(TRUE));
        monitor = g_file_monitor_directory(dir,
                G_FILE_MONITOR_SEND_MOVED, NULL, NULL);
        g_signal_connect(monitor, "changed", 
                G_CALLBACK(monitor_desktop_dir_cb), NULL);
    }
}

