#ifdef __DUI_DEBUG

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <string.h>
#include <glib.h>
#include "test.h"
#include "tasklist.h"
#include "dock_hide.h"
#include "dbus.h"
#include "dock_config.h"
#include "dominant_color.h"
#include "handle_icon.h"
#include "launcher.h"
#include "region.h"
#include "special_window.h"
#include "tray.h"
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
void client_free(Client* c);
void update_task_list();
void _update_task_list(Window root);
void update_active_window(Display* display, Window root);


void dock_test_draw()
{
}


void dock_test_config()
{
    GSettings* s = g_settings_new("com.deepin.dde.dock");
    Test({
         g_signal_emit_by_name(s, "changed", "active-mini-mode", NULL);
         g_signal_emit_by_name(s, "changed", "background-color", NULL);
         g_signal_emit_by_name(s, "changed", "hide-mode", NULL);
         g_signal_emit_by_name(s, "changed", "112098", NULL);
         }, "settings_changed");
     g_object_unref(s);
}


void dock_test_domain_color()
{
#define toint(n) (int)(n * 100 + .5)
#define h2int(n) (int)(n * 360)
#define comp(a, b) (a == b || a == b - 1 || a == b + 1)
#define rgb2int(n) (int)(n * 255 + .5)
    double h, s, v;
    double r, g, b;
    extern void rgb2hsv(int r, int g, int b, double *h, double* s, double* v);
    extern void hsv2rgb(double h, double s, double v, double* r, double*g, double *b);
    Test({
         rgb2hsv(179, 102, 102, &h, &s, &v);
         g_assert(comp(h2int(h), 0) && comp(toint(s), 43) && comp(toint(v), 70));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 179) && comp(rgb2int(g), 102) && comp(rgb2int(b), 102));

         rgb2hsv(82, 46, 46, &h, &s, &v);
         g_assert(comp(h2int(h), 0) && comp(toint(s), 44) && comp(toint(v), 32));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 82) && comp(rgb2int(g), 46) && comp(rgb2int(b), 46));

         rgb2hsv(46, 125, 148, &h, &s, &v);
         g_assert(comp(h2int(h), 193) && comp(toint(s), 69) && comp(toint(v), 58));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 46) && comp(rgb2int(g), 125) && comp(rgb2int(b), 148));

         rgb2hsv(82, 85, 119, &h, &s, &v);
         g_assert(comp(h2int(h), 235) && comp(toint(s), 31) && comp(toint(v), 47));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 82) && comp(rgb2int(g), 85) && comp(rgb2int(b), 119));
    }, "rgb2hsv and hsv2rgb");
#undef rgb2int
#undef comp
#undef h2int
#undef toint

    GdkPixbuf* pixbuf1 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-user-manual.png", NULL);
    GdkPixbuf* pixbuf2 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-media-player.png", NULL);
    GdkPixbuf* pixbuf3 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-music-player.png", NULL);
    GdkPixbuf* pixbuf4 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-screenshot.png", NULL);
    extern void calc(guchar*, guint, int, double*, double*, double*);
    Test({
         guint size = 0;
         guchar* buf = gdk_pixbuf_get_pixels_with_length(pixbuf1, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf1), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf2, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf2), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf3, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf3), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf4, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf4), &r, &g, &b);
         }, "calc");

    Test({
         calc_dominant_color_by_pixbuf(pixbuf1, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf2, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf3, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf4, &r, &g, &b);
         }, "calc_dominant_color_by_pixbuf");
    g_object_unref(pixbuf1);
    g_object_unref(pixbuf2);
    g_object_unref(pixbuf3);
    g_object_unref(pixbuf4);
}



void dock_test_hide()
{
    Test({
            dock_delay_show(0);
    }, "dock_delay_show");
    Test({
            dock_delay_hide(0);
    }, "dock_delay_hide");

    Test({
            dock_show_now();
    }, "dock_show_now");

    Test({
        dock_hide_now();
    }, "dock_hide_now");

    Test({
        dock_update_hide_mode();
    }, "dock_update_hide_mode");

    extern void _change_workarea_height(int height);

    // failed
    /* Test({ */
    /*      _change_workarea_height(0); */
    /*      _change_workarea_height(60); */
    /*  }, "change_workarea_height"); */

    enum Event {
        TriggerShow,
        TriggerHide,
        ShowNow,
        HideNow,
    };
    enum State {
        StateShow,
        StateShowing,
        StateHidden,
        StateHidding,
    };

    extern void set_state(enum State new_state);
    Test({
         extern void enter_show();
         set_state(StateHidding);
         enter_show();
         }, "enter_show");

    Test({
         extern void enter_showing();
         set_state(StateHidding);
         enter_showing();
         }, "enter_showing");

    Test({
         extern void enter_hide();
         set_state(StateHidding);
         enter_hide();
         }, "enter_hide");

    Test({
         extern void enter_hidding();
         set_state(StateHidden);
         enter_hidding();
         }, "enter_hidding");

    Test({
        dock_hide_real_now();
    }, "dock_hide_real_now");

    Test({
        dock_show_real_now();
    }, "dock_show_real_now");

    Test({
        update_dock_guard_window_position();
    }, "update_dock_guard_window_position");

    // failed
    /* Test({ */
    /*     dock_toggle_show(); */
    /* }, "dock_toggle_show"); */

    // failed
    /* Test({ */
    /*      extern void handle_event(enum Event ev); */
    /*      handle_event(TriggerShow); */
    /*      handle_event(TriggerHide); */
    /*      handle_event(ShowNow); */
    /*      handle_event(HideNow); */
    /*      }, "handle_event"); */
}

int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY= 100000;

extern GHashTable* _clients_table;
void dock_test()
{
    /* int xid = 0x2800006; */
    /* Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default()); */

    /* dock_test_hide(); */
    /* dock_test_config(); */
    /* dock_test_domain_color(); */

    /* Test({ */
    /*         GdkWindow* root = gdk_get_default_root_window(); */
    /*         _update_task_list(GDK_WINDOW_XID(root)); */
    /* }, "update task list"); */

    /* Test({ */
    /*         Client* c = create_client_from_window(xid); */
    /*         g_assert(c != NULL); */
    /*         client_free(c); */
    /* }, "create client and free"); */

    /*Test({*/
            /*g_hash_table_remove_all(_clients_table);*/
            /*GdkWindow* root = gdk_get_default_root_window();*/
            /*_update_task_list(GDK_WINDOW_XID(root));*/
            /*update_active_window(_dsp, GDK_WINDOW_XID(root));*/
    /*}, "update_task_list");*/


    /* Test({ */
    /*         is_skip_taskbar(xid); */
    /* }, "is_skip_taskbar"); */

    /* Test({ */
    /*         is_normal_window(xid); */
    /* }, "is_normal_window"); */

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

    g_message("All dock test passed!!!!");
}

#endif
