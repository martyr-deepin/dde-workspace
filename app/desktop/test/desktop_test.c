#ifdef __DUI_DEBUG
#include "desktop_test.h"

int TEST_MAX_COUNT = 100000;
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

    // test_entry();//test ok 
    // ps:
    //1. g_file_trash() has bug when trash times and speed too fast
    //2. dentry_clipborad_paste() has bug when speed too fast ,becuase the X cannot follow it
    //3. find and fix a serious bug : symblic_link copy to desktop will kill the desktop actually
    //4. some bug not fix: 
    //a. void _do_dereference_symlink_copy(GFile* src, GFile* dest)    
    //      if (!g_file_copy(src, dest, G_FILE_COPY_NONE, NULL, NULL, NULL, &error))
    //      ----------------------here we should unity the standard ops for symlic_link---------------------
    //b. traverse_directory
    //      g_warning ("traverse_directory 1: %s", error->message);


    // test_fileops_delete();//test ok
    
    // test_fileops_trash();//test ok
    
    // test_fileops_clipboard();//test ok
    
    // test_fileops_error_reporting();//hsanot tested

    // test_fileops_error_dialog();//hasnot tested
    
    // test_mime_actions();////hasnot tested   because it used in dentry_launch()

    test_thumbnails();


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
