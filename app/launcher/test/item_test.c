#ifdef __DUI_DEBUG

#include <gio/gdesktopappinfo.h>
#include "test.h"
#include "../item.h"

gboolean launcher_is_on_desktop(Entry* _item);
gboolean _read_gnome_autostart_enable(const char* path, const char* name, gboolean* is_autostart/* output */);
gboolean _check_exist(const char* path, const char* name);
gboolean launcher_is_autostart(Entry* _item);
gboolean launcher_add_to_autostart(Entry* _item);
gboolean _remove_autostart(const char* file_path);
gboolean launcher_remove_from_autostart(Entry* _item);


void test_launcher_is_on_desktop()
{
    Test({
         // set the assert according to the real situaction.
         GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
         g_assert(launcher_is_on_desktop((Entry*)firefox) == FALSE);
         g_object_unref(firefox);
         GDesktopAppInfo* chrome = g_desktop_app_info_new("google-chrome.desktop");
         g_assert(launcher_is_on_desktop((Entry*)chrome) == TRUE);
         g_object_unref(chrome);
         }, "launcher_has_this_item_on_desktop");
}


void test_get_autostart_paths()
{
    Test({
         g_ptr_array_unref(get_autostart_paths());
         }, "get_autostart_paths");
}


void test__read_gnome_autostart_enable()
{
    gboolean is = FALSE;
    Test({
         _read_gnome_autostart_enable("/etc/xdg/autostart/", "deepin-software-center-autostart.desktop", &is);
         // install by myself
         _read_gnome_autostart_enable("/etc/xdg/autostart/", "psensor.desktop", &is);
         }, "_read_gnome_autostart_enable");
}


void test__check_exist()
{
    Test({
         g_assert(_check_exist("/etc/xdg/autostart", "psenSor.desktop") == TRUE);
         g_assert(_check_exist("/etc/xdg/autostart", "deepin-software-center-autostart.desktop") == TRUE);
         g_assert(_check_exist("/etc/xdg/autostart", "test.desktop") == FALSE);
    }, "_check_exist");
}


void test_launcher_is_autostart()
{
    GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
    GDesktopAppInfo* chrome = g_desktop_app_info_new("google-chrome.desktop");
    Test({
         launcher_is_autostart((Entry*)firefox);
         launcher_is_autostart((Entry*)chrome);
         }, "launcher_is_autostart");
    g_object_unref(firefox);
    g_object_unref(chrome);
}


void test_add_to_autostart()
{
    GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
    GDesktopAppInfo* chrome = g_desktop_app_info_new("google-chrome.desktop");
    Test({
         launcher_add_to_autostart((Entry*)firefox);
         launcher_add_to_autostart((Entry*)chrome);
         }, "launcher_add_to_autostart");
    g_object_unref(firefox);
    g_object_unref(chrome);
}


void test__remove_autostart()
{
    char* dest_path = g_build_filename(g_get_user_config_dir(),
                                       AUTOSTART_DIR, "firefox.desktop", NULL);
    Test({
         _remove_autostart(dest_path);
         }, "_remove_autostart");
    g_free(dest_path);
}


void test_remove_from_autostart()
{
    GDesktopAppInfo* firefox = g_desktop_app_info_new("firefox.desktop");
    GDesktopAppInfo* chrome = g_desktop_app_info_new("google-chrome.desktop");
    Test({
        launcher_remove_from_autostart((Entry*)firefox);
        launcher_remove_from_autostart((Entry*)chrome);
         }, "launcher_remove_from_autostart");
    g_object_unref(firefox);
    g_object_unref(chrome);
}


void item_test()
{
    test_launcher_is_on_desktop();
    test_get_autostart_paths();
    test__read_gnome_autostart_enable();
    test__check_exist();
    test_launcher_is_autostart();
    test_add_to_autostart();
    test__remove_autostart();
    test_remove_from_autostart();
}

#endif

