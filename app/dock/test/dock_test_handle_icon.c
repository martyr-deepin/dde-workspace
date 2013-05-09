#include "dock_test.h"

void dock_test_handle_icon()
{
    Test({
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/apps/48/ccsm.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/action/document-open-recent.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/categories/48/applications-accessories.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/cursors/bd_double_arrow") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/devices/scalable/computer.svg") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/emblems/16/emblem-art.icon") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/mime/application-x-ms-dos-executable.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/misc/48/invalid-dock_app.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/places/48/deepin-user-home.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Deepin/status/48/dialog-question.png") == TRUE);
         g_assert(is_deepin_icon("/usr/share/icons/Adwaita/cursors/bd_double_arrow") == FALSE);
         g_assert(is_deepin_icon("/usr/share/icons/hicolor/48x48/apps/applications-internet.png") == FALSE);
         g_assert(is_deepin_icon("/usr/share/pixmaps/nautilus.xpm") == FALSE);
         }, "is_deepin_icon");

    Test({
         char* icon = NULL;
         int operator = -1;
         try_get_deepin_icon("devhelp", &icon, &operator);
         g_free(icon);
         icon = NULL;
         try_get_deepin_icon("deepin-music-player", &icon, &operator);
         g_free(icon);
         icon = NULL;
         try_get_deepin_icon("vim", &icon, &operator);
         g_free(icon);
         icon = NULL;
         try_get_deepin_icon("emacs", &icon, &operator);
         g_free(icon);
         icon = NULL;
         try_get_deepin_icon("chromium", &icon, &operator);
         g_free(icon);
         icon = NULL;
         }, "try_get_deepin_icon");

    GdkPixbuf* pixbuf1 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-media-player.png", NULL);
    GdkPixbuf* pixbuf2 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-music-player.png", NULL);
    GdkPixbuf* pixbuf3 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-screenshot.png", NULL);
    Test({
         g_free(handle_icon(pixbuf1));
         g_free(handle_icon(pixbuf2));
         g_free(handle_icon(pixbuf3));
         }, "handle_icon");
    g_object_unref(pixbuf1);
    g_object_unref(pixbuf2);
    g_object_unref(pixbuf3);
}
