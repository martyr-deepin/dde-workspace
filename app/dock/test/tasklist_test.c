#include "dock_test.h"

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};
typedef struct {
    char* title; /* _NET_WM_NAME */
    char* instance_name;  /*WMClass first field */
    char* clss; /* WMClass second field*/
    char* app_id; /*current is executabe file's name*/
    char* exec; /* /proc/pid/cmdline or /proc/pid/exe */
    int state;
    gboolean is_overlay_dock;
    gboolean is_hidden;
    gboolean is_maximize;
    gboolean use_board;
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
    Window xid = 0x260003b;  // ATTENTION!! change it yourself when you need to test.
    Display *_dsp G_GNUC_UNUSED = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    GdkWindow* root G_GNUC_UNUSED = gdk_get_default_root_window();

    /* Test({ */
    /*         _update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "_update_task_list"); */

    /* Test({ */
    /*      extern void active_window_changed(Display* dsp, Window w); */
    /*      active_window_changed(_dsp, (Window)dock_get_active_window()); */
    /* }, "active_window_changed"); */

    /* Test({ */
    /*      g_assert(is_skip_taskbar(xid) == FALSE); */
    /*      g_assert(is_skip_taskbar(GDK_WINDOW_XID(root)) == FALSE); */
    /* }, "is_skip_taskbar"); */

    /* Test({ */
    /*         is_normal_window(xid); */
    /* }, "is_normal_window"); */

    Client* c = g_slice_new0(Client);
    c->window = xid;
    /* Test({ */
    /*      c->title = NULL; */
    /*      g_assert(c->window != 0); */
    /*      _update_window_title(c); */
    /*      g_assert(c->title != NULL); */
    /*      g_free(c->title); */
    /*      } , "_update_window_title"); */

    /* Test({ */
    /*      c->clss = NULL; */
    /*      c->instance_name = NULL; */
    /*      _update_window_class(c); */
    /*      g_free(c->clss); */
    /*      g_free(c->instance_name); */
    /*      }, "_update_window_class"); */

    /* Test({ */
    /*      c->title = NULL; */
    /*      c->clss = NULL; */
    /*      c->instance_name = NULL; */
    /*      c->app_id = NULL; */
    /*      _update_window_title(c); */
    /*      _update_window_class(c); */
    /*      _update_window_appid(c); */
    /*      g_free(c->title); */
    /*      g_free(c->clss); */
    /*      g_free(c->instance_name); */
    /*      g_free(c->app_id); */
    /*      g_free(c->exec); */
    /*      }, "_update_window_appid"); */

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
    /*      g_free(c->exec); */
    /*      g_free(c->icon); */
    /*     } */
    /* , "try_get_deepin_icon"); */

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
    /*      g_free(c->exec); */
    /*      g_free(c->icon); */
    /*      }, "_get_launcher_icon"); */

    /* Test({ */
    /*      c->icon = NULL; */
    /*      _update_window_icon(c); */
    /*      g_free(c->icon); */
    /*      } , "update_window_icon"); */

    /* Test({ */
    /*      extern void _update_is_overlay_client(Client* c); */
    /*      _update_is_overlay_client(c); */
    /*      }, "_update_is_overlay_client"); */

    /* Test({ */
    /*      extern gboolean _is_hidden(Window); */
    /*      g_assert(_is_hidden(xid) == FALSE); */
    /*      }, "_is_hidden"); */

    // TODO: dock_update_hide_mode lead to ending in 54m
    /* extern void _update_window_net_state(Client* c); */
    /* Test({ */
    /*      // !is_skip_taskbar branch */
    /*      c->gdkwindow = root; */
    /*      c->window = GDK_WINDOW_XID(root); */
    /*      _update_window_net_state(c); */

    /*      // is_skip_taskbar branch */
    /*      Window launcher_xid = 0x3200004; */
    /*      c->gdkwindow = gdk_x11_window_lookup_for_display(gdk_display_get_default(), launcher_xid); */
    /*      c->window = launcher_xid; */
    /*      _update_window_net_state(c); */
    /*      }, "_update_window_net_state"); */

    g_slice_free(Client, c);

    /* Test({ */
    /*      g_assert(0 != dock_get_active_window()); */
    /*      }, "dock_get_active_window"); */

    /* extern gboolean _is_maximized_window(Window win); */
    /* Test({ */
    /*      g_assert(_is_maximized_window(xid) == FALSE); */
    /*      g_assert(_is_maximized_window(0x160725f) == FALSE); */
    /*     };, "_is_maximized_window"); */

    /* extern gboolean dock_has_maximize_client(); */
    /* Test({ */
    /*      g_assert(dock_has_maximize_client() == TRUE); */
    /*      }, "dock_has_maximize_client"); */

    // TODO: TBT
    /* extern void dock_active_window(double id); */
    /* Test({ */
    /*      dock_active_window(xid); */
    /*      dock_active_window(0x2e00038); */
    /*      }, "dock_active_window"); */


    /* extern gboolean dock_get_desktop_status(); */
    /* Test({ */
    /*      dock_get_desktop_status(); */
    /*      }, "dock_get_desktop_status"); */


    /* extern gboolean dock_is_client_minimized(double id); */
    /* Test({ */
    /*      g_assert(FALSE == dock_is_client_minimized(xid)); */
    /*      }, "dock_is_client_minimized"); */

    /* extern gboolean dock_window_need_to_be_minimized(double id); */
    /* Test({ */
    /*      g_assert(dock_window_need_to_be_minimized(xid) == TRUE); */
    /*      g_assert(dock_window_need_to_be_minimized(0x3800006) == TRUE); */
    /*      }, "dock_window_need_to_be_minimized"); */

    /* extern gboolean is_has_client(const char* app_id); */
    /* Test({ */
    /*      g_assert(is_has_client("firefox") == FALSE); */
    /*      g_assert(is_has_client("skype") == TRUE); */
    /*      }, "is_has_client"); */

    /* extern gchar* dock_bus_list_apps(); */
    /* Test({ */
    /*      g_free(dock_bus_list_apps()); */
    /*      }, "dock_bus_list_apps"); */

    /* extern guint32 dock_bus_app_id_2_xid(char* app_id); */
    /* Test({ */
    /*      dock_bus_app_id_2_xid("google-chrome"); */
    /*      dock_bus_app_id_2_xid("devhelp"); */
    /*      g_assert(dock_bus_app_id_2_xid("") == 0); */
    /*      }, "dock_bus_app_id_2_xid"); */

    /* extern char* dock_bus_current_focus_app(); */
    /* Test({ */
    /*      g_free(dock_bus_current_focus_app()); */
    /*      }, "dock_bus_current_focus_app"); */

    // TODO:
    // TBT, because client_free cannot free Client.gdkwindow
    /* Test({ */
    /*      update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "update_task_list"); */

    // TODO: TBT
    /* extern void dock_draw_window_preview(JSValueRef canvas, double xid, double */
    /*                                      dest_width, double dest_height, */
    /*                                      JSData* data); */
    /* Test({ */
    /*      }, "dock_draw_window_preview"); */

    /* extern void _update_window_viewport(Client* c); */
    /* Test({ */
    /*      _update_window_viewport(c); */
    /*      }, "_update_window_viewport"); */

    // TODO:
    // TBT, client_free cannot free Client.gdkwindow
    /* Test({ */
    /*      Client* c = create_client_from_window(xid); */
    /*      g_assert(c != NULL); */
    /*      client_free(c); */
    /*      }, "client create and free"); */
}

