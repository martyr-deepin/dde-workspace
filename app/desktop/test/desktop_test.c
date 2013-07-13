#ifdef __DUI_DEBUG
#include "desktop_test.h"

int TEST_MAX_COUNT = 10000;
int TEST_MAX_MEMORY = RES_IN_MB(90);

extern void test_entry();
extern void test_fileops_delete();
extern void test_fileops_trash();
extern void test_fileops_clipboard();
extern void test_fileops_error_reporting();
extern void test_fileops_error_dialog();

extern void test_mime_actions();
extern void test_thumbnails();
extern void test_gnome_desktop_thumbnail();

void desktop_test()
{
    g_message("desktop test start...");

    test_entry();

    /* test inotify successful.*/
    //test_inotify();

    // test_dbus();

    /* test_background(); */

    // test_background_util();

    /* test_desktop(); */

    /* test_utils(); */

    //test_other();
    //
    
    g_message("desktop tests All passed!!!");
}

#endif
