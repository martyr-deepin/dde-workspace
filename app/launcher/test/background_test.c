#ifdef __DUI_DEBUG

#include <gtk/gtk.h>
#include <gio/gio.h>

#include "launcher_test.h"
#include "dwebview.h"
#include "../background.h"


char* bg_blur_pict_get_dest_path (const char* src_uri);
gboolean _set_background_aux(GdkWindow* win, const char* bg_path,
                                      double width, double height);
void set_background(GdkWindow* win, GSettings* dde_bg_g_settings,
                             double width, double height);
void background_changed(GSettings* settings, char* key, gpointer user_data);


GSettings* settings = NULL;
GtkWidget* w = NULL;


void test_bg_blur_pict_get_dest_path()
{
    Test({
         char* bg_path = g_settings_get_string(settings, CURRENT_PCITURE);
         char* blur_path = bg_blur_pict_get_dest_path(bg_path);
         g_free(bg_path);
         g_free(blur_path);
         }, "bg_blur_pict_get_dest_path");
}


void test__set_background_aux()
{
    Test({
         char* bg_path = g_settings_get_string(settings, CURRENT_PCITURE);
         _set_background_aux(gtk_widget_get_window(w), bg_path,
                             gdk_screen_width(), gdk_screen_height());
         g_free(bg_path);
         }, "_set_background_aux");
}


void test_set_background()
{
    Test({
         set_background(gtk_widget_get_window(w), settings,
                        gdk_screen_width(), gdk_screen_height());
         }, "set_background");
}


void test_background_changed()
{
    Test({
         background_changed(settings, CURRENT_PCITURE, NULL);
         }, "background_changed");
}


void background_test()
{
    settings = g_settings_new(SCHEMA_ID);
    GtkWidget* c = create_web_container(FALSE, TRUE);
    w = d_webview_new_with_uri("file:///home/liliqiang/dde/app/launcher/test/bg_test.html");
    gtk_container_add(GTK_CONTAINER(c), GTK_WIDGET(w));
    gtk_widget_show_all(c);

    /* test_bg_blur_pict_get_dest_path(); */
    test__set_background_aux();
    test_set_background();
    /* test_background_changed(); */

    g_object_unref(settings);
    g_object_unref(w);
    g_object_unref(c);
}

#endif

