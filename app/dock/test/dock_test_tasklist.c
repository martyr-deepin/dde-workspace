#include "dock_test.h"

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

extern Client* create_client_from_window(Window w);
extern void _update_window_icon(Client *c);
extern void _update_window_title(Client *c);
extern void _update_window_class(Client *c);
extern void _update_window_appid(Client *c);
extern gboolean is_skip_taskbar(Window w);
extern gboolean is_normal_window(Window w);
extern void client_free(Client* c);
extern void update_task_list();
extern void _update_task_list(Window root);

extern GHashTable* _clients_table;

void dock_test_tasklist()
{
    int xid = 0x2800006;
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    GdkWindow* root = gdk_get_default_root_window();

    /* Test({ */
    /*         _update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "update task list"); */

    /* Test({ */
    /*         Client* c = create_client_from_window(xid); */
    /*         g_assert(c != NULL); */
    /*         client_free(c); */
    /* }, "create client and free"); */

    Test({
            g_hash_table_remove_all(_clients_table);
            _update_task_list(GDK_WINDOW_XID(root));
    }, "update_task_list");


    Test({
            is_skip_taskbar(xid);
    }, "is_skip_taskbar");

    Test({
            is_normal_window(xid);
    }, "is_normal_window");

    /* Client* c = create_client_from_window(xid); */
    /* Test({ */
    /*         _update_window_title(c); */
    /*      } */
    /* , "update_window_title"); */

    /* Test({ */
    /*         _update_window_class(c); */
    /*      } */
    /* , "update_window_class"); */

    /* Test({ */
    /*         _update_window_appid(c); */
    /*      } */
    /* , "update_window_appid"); */
    /* Test({ */
    /*         _update_window_icon(c); */
    /*      } */
    /* , "update_window_icon"); */

    /* Test({ */
    /*         char* icon = try_get_deepin_icon(c->app_id); */
    /*         g_free(icon); */
    /*     } */
    /* , "try_get_deepin_icon"); */
    /* client_free(c); */

}
