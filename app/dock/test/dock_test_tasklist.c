#include "dock_test.h"

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};
typedef struct {
    char* title; /* _net_wm_name */
    char* instance_name;  /*wmclass first field */
    char* clss; /* wmclass second field*/
    char* app_id; /*current is executabe file's name*/
    char* exec; /* /proc/pid/cmdline or /proc/pid/exe */
    int state;
    gboolean is_overlay_dock;
    gboolean is_hidden;
    gboolean is_maximize;
    gulong cross_workspace_num;
    Workspace workspace[4];

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
extern void update_task_list(); extern void _update_task_list(Window root);
extern GHashTable* _clients_table;

void dock_test_tasklist()
{
    int xid = 0x802f2a;  // attention!! change it yourself if necessary.
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    GdkWindow* root = gdk_get_default_root_window();

    /* Test({ */
    /*         _update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "_update_task_list"); */

    /* Test({ */
    /*      extern void active_window_changed(Display* dsp, Window w); */
    /*      active_window_changed(_dsp, (Window)dock_get_active_window()); */
    /* }, "active_window_changed"); */

    // TBT
    /* Test({ */
         /* g_hash_table_remove_all(_clients_table); */
         /* g_hash_table_destroy(_clients_table); */
         /* _clients_table = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)client_free); */
         /* _update_task_list(GDK_WINDOW_XID(root)); */
    /*      update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "update_task_list"); */


    /* Test({ */
    /*         is_skip_taskbar(xid); */
    /* }, "is_skip_taskbar"); */

    /* Test({ */
    /*         is_normal_window(xid); */
    /* }, "is_normal_window"); */

    Client* c = g_new0(Client, 1);
    c->window = xid;
    /* Test({ */
    /*      c->title = NULL; */
    /*      _update_window_title(c); */
    /*      g_assert(c->title != NULL); */
    /*      g_free(c->title); */
    /*      } , "_update_window_title"); */

    /* Test({ */
    /*      c->clss = NULL; */
    /*      c->instance_name = NULL; */
    /*      _update_window_class(c); */
    /*      g_assert(c->clss != NULL); */
    /*      g_assert(c->instance_name != NULL); */
    /*      g_free(c->clss); */
    /*      g_free(c->instance_name); */
    /*      }, "_update_window_class"); */

    //TBD, end in 36m
    Test({
         c->title = NULL;
         c->clss = NULL;
         c->instance_name = NULL;
         c->app_id = NULL;
         _update_window_title(c);
         _update_window_class(c);
         _update_window_appid(c);
         g_assert(c->app_id != NULL);
         g_free(c->title);
         g_free(c->clss);
         g_free(c->instance_name);
         g_free(c->app_id);
         }, "_update_window_appid");

    //TBD, end in 54m
    extern void _update_window_viewport(Client* c);
    Test({
         _update_window_viewport(c);
         }, "_update_window_viewport");

    /* Test({ */
    /*      c->title = NULL; */
    /*      c->clss = NULL; */
    /*      c->instance_name = NULL; */
    /*      c->app_id = NULL; */
    /*      _update_window_title(c); */
    /*      _update_window_class(c); */
    /*      _update_window_appid(c); */
    /*      int operator_code; */
    /*      try_get_deepin_icon(c->app_id, &c->icon, &operator_code); */
    /*      g_free(c->title); */
    /*      g_free(c->clss); */
    /*      g_free(c->instance_name); */
    /*      g_free(c->app_id); */
    /*      g_free(c->icon); */
    /*     } */
    /* , "try_get_deepin_icon"); */

    //TBD, end in 36m
    /* extern gboolean _get_launcher_icon(Client* c); */
    /* Test({ */
    /*      c->title = NULL; */
    /*      c->clss = NULL; */
    /*      c->instance_name = NULL; */
    /*      c->app_id = NULL; */
    /*      _update_window_title(c); */
    /*      _update_window_class(c); */
    /*      _update_window_appid(c); */
    /*      _get_launcher_icon(c); */
    /*      g_free(c->title); */
    /*      g_free(c->clss); */
    /*      g_free(c->instance_name); */
    /*      g_free(c->app_id); */
    /*      g_free(c->icon); */
    /*      }, "_get_launcher_icon"); */

    //TBD, end in 54m
    Test({
            _update_window_icon(c);
         } , "update_window_icon");

    /* Test({ */
    /*      extern void _update_is_overlay_client(Client* c); */
    /*      _update_is_overlay_client(c); */
    /*      }, "_update_is_overlay_client"); */

    //TBD, end in 54m
    extern void _update_window_net_state(Client* c);
    Test({
         _update_window_net_state(c);
         }, "_update_window_net_state");

    g_free(c);

    /* Test({ */
    /*      extern gboolean _is_hidden(Window); */
    /*      _is_hidden(xid); */
    /*      }, "_is_hidden"); */

    // TBT
    /* Test({ */
    /*      Client* c = create_client_from_window(xid); */
    /*      g_assert(c != NULL); */
    /*      client_free(c); */
    /*      }, "create client and free"); */

    /* client_free(c); */
}
