#include "dock_test.h"
#include <gio/gdesktopappinfo.h>

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

extern void _update_window_title(Client *c);
extern void _update_window_class(Client *c);
extern void _update_window_appid(Client *c);

void dock_test_launcher()
{
    /* Test({ */
    /*      update_dock_apps(); */
    /*      }, "update_dock_apps"); */

    /* Test({ */
    /*      extern void _save_apps_position(); */
    /*      _save_apps_position(); */
    /*      }, "_save_apps_position"); */

    /* char* app_id = NULL; */
    /* GDesktopAppInfo* info1 = g_desktop_app_info_new_from_filename("/usr/share/applications/devhelp.desktop"); */
    /* GDesktopAppInfo* info2 = g_desktop_app_info_new_from_filename("/usr/share/applications/fcitx.desktop"); */
    /* GDesktopAppInfo* info3 = g_desktop_app_info_new_from_filename("/usr/share/applications/deepin-desktop.desktop"); */
    /* GDesktopAppInfo* info4 = g_desktop_app_info_new_from_filename("/usr/share/applications/deepin-dock.desktop"); */
    /* extern char* get_app_id(GDesktopAppInfo* info); */
    /* Test({ */
    /*      g_assert(info1 != NULL); */
    /*      app_id = get_app_id(info1); */
    /*      g_assert(g_str_equal(app_id, "devhelp")); */
    /*      g_free(app_id); */
    /*      app_id = NULL; */

    /*      g_assert(info2 != NULL); */
    /*      app_id = get_app_id(info2); */
    /*      g_assert(g_str_equal(app_id, "fcitx")); */
    /*      g_free(app_id); */
    /*      app_id = NULL; */

    /*      g_assert(info3 != NULL); */
    /*      app_id = get_app_id(info3); */
    /*      g_assert(g_str_equal(app_id, "desktop")); */
    /*      g_free(app_id); */
    /*      app_id = NULL; */

    /*      g_assert(info4 != NULL); */
    /*      app_id = get_app_id(info4); */
    /*      g_assert(g_str_equal(app_id, "dock")); */
    /*      g_free(app_id); */
    /*      app_id = NULL; */
    /*      }, "get_app_id"); */

    /* Test({ */
    /*      extern int get_need_terminal(GDesktopAppInfo*); */
    /*      g_assert(get_need_terminal(info1) == 0); */
    /*      g_assert(get_need_terminal(info2) == 0); */
    /*      g_assert(get_need_terminal(info3) == 0); */
    /*      g_assert(get_need_terminal(info4) == 0); */
    /*      }, "get_need_terminal"); */

    /* GDesktopAppInfo* info5 = g_desktop_app_info_new_from_filename("/usr/share/applications/firefox.desktop"); */
    // those two seem have some problems
    /* extern void dock_swap_apps_position(const char* id1, const char* id2); */
    /* Test({ */
    /*      dock_swap_apps_position(get_app_id(info1), get_app_id(info2)); */
    /*      dock_swap_apps_position(get_app_id(info2), get_app_id(info1)); */
    /*      dock_swap_apps_position(get_app_id(info2), get_app_id(info3)); */
    /*      dock_swap_apps_position(get_app_id(info1), get_app_id(info5)); */
    /*      }, "dock_swap_apps_position"); */

    /* extern void dock_insert_apps_position(const char* id, const char* anchor_id); */
    /* Test({ */
    /*      dock_insert_apps_position(get_app_id(info1), get_app_id(info2)); */
    /*      dock_insert_apps_position(get_app_id(info2), get_app_id(info1)); */
    /*      dock_insert_apps_position(get_app_id(info2), get_app_id(info3)); */
    /*      dock_insert_apps_position(get_app_id(info1), get_app_id(info5)); */
    /*      }, "dock_insert_apps_position"); */

    /* extern void write_app_info(GDesktopAppInfo* info); */
    /* Test({ */
    /*      write_app_info(info1); */
    /*      write_app_info(info2); */
    /*      write_app_info(info3); */
    /*      write_app_info(info4); */
    /*      write_app_info(info5); */
    /*      }, "write_app_info"); */


    // TODO:
    // TBT
    /* int xid = 0x2a00363;  // attention!! change it yourself when you need to test. */
    /* Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default()); */
    /* GdkWindow* root = gdk_get_default_root_window(); */
    /* Client* c = g_new0(Client, 1); */
    /* c->window = xid; */
    /* _update_window_title(c); */
    /* _update_window_class(c); */
    /* _update_window_appid(c); */
    /* ArrayContainer fs = {NULL, 0}; */

    /* extern gboolean dock_launch_by_app_id(const char* app_id, const char* exec, ArrayContainer fs); */
    /* Test({ */
    /*      dock_launch_by_app_id(c->app_id, c->exec, fs); */
    /*      }, "dock_launch_by_app_id"); */

    /* g_free(c->title); */
    /* g_free(c->clss); */
    /* g_free(c->instance_name); */
    /* g_free(c->app_id); */
    /* g_free(c->exec); */
    /* g_free(c); */

    extern void dock_request_dock(const char* app_id);
    extern void dock_request_undock(const char* app_id);
    Test({
         dock_request_dock("/usr/share/applications/firefox.desktop");
         dock_request_undock("firefox");
         }, "dock_request_dock and dock_request_undock");

    /* g_object_unref(info1); */
    /* g_object_unref(info2); */
    /* g_object_unref(info3); */
    /* g_object_unref(info4); */
    /* g_object_unref(info5); */

}
