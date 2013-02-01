#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <string.h>
#include <glib.h>
#include "test.h"
#include "../app/dock/tasklist.h"
typedef struct {
    char* title; /* _NET_WM_NAME */
    char* clss; /* WMClass */
    char* app_id; /*current is executabe file's name*/
    char* exec;
    int state;
    gboolean is_maximized;

    Window window;
    GdkWindow* gdkwindow;

    char* icon;
    gboolean need_update_icon;
} Client;
Client* create_client_from_window(Window w);
void _update_window_icon(Client *c);
void _update_window_title(Client *c); 
void _update_window_class(Client *c);
void _update_window_appid(Client *c);
gboolean is_skip_taskbar(Window w);
gboolean is_normal_window(Window w);
char* try_get_deepin_icon(const char* app_id);
void client_free(Client* c);
void update_task_list();
void _update_task_list(Window root);
void update_active_window(Display* display, Window root);

int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY= 100000;

extern GHashTable* _clients_table;
void dock_test()
{
    int xid = 0x2800006;
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

    Test({
            Client* c = create_client_from_window(xid);
            g_assert(c != NULL);
            client_free(c);
    }, "create client and free");

    /*Test({*/
            /*g_hash_table_remove_all(_clients_table);*/
            /*GdkWindow* root = gdk_get_default_root_window();*/
            /*_update_task_list(GDK_WINDOW_XID(root));*/
            /*update_active_window(_dsp, GDK_WINDOW_XID(root));*/
    /*}, "update_task_list");*/


    Test({
            is_skip_taskbar(xid);
    }, "is_skip_taskbar");

    Test({
            is_normal_window(xid);
    }, "is_normal_window");

    Client* c = create_client_from_window(xid);
    Test({
            _update_window_title(c);
         }
    , "update_window_title");

    Test({
            _update_window_class(c);
         }
    , "update_window_class");

    Test({
            _update_window_appid(c);
         }
    , "update_window_appid");
    Test({
            _update_window_icon(c);
         }
    , "update_window_icon");

    Test({
            char* icon = try_get_deepin_icon(c->app_id);
            g_free(icon);
        }
    , "try_get_deepin_icon");
    client_free(c);

    g_message("All dock test passed!!!!");
}
