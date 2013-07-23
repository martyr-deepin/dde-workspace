#include "desktop_test.h"

#define TEST_OK FALSE

void test_inotify_item()
{
	setup_fixture();

#if TEST_OK
    gboolean desktop_file_filter(const char *file_name);
    Test({
        g_assert(FALSE == desktop_file_filter("snyh.txt"));
        g_assert(TRUE == desktop_file_filter(".snyh.txt"));
        g_assert(TRUE == desktop_file_filter("snyh.txt~"));
    }, "desktop_file_filter");

    void trash_changed();
    Test({
        trash_changed();
    }, "trash_changed");

    void _add_monitor_directory(GFile *f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        _add_monitor_directory(f);
        g_object_unref(f);
    }, " _add_monitor_directory");

    void install_monitor();
    Test({
        install_monitor();
    }, "install_monitor");
#endif
//end if TEST_OK
//

#if 0
    void handle_rename(GFile *, GFile *);
    Test({
        GFile *old_f = g_file_new_for_path("file:///tmp/test_files/default_background.jpg");
        GFile *new_f = g_file_new_for_path("file:///tmp/test_files/default_background.png");
        handle_rename(old_f, new_f);
        g_object_unref(new_f);
        g_object_unref(old_f);
    }, "handle_rename");
    //gdb test failed  19%

    void handle_delete(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_delete(f);
        if (f != NULL)
            g_object_unref(f);
        else 
            g_message("handle_delete f is null");
    }, "handle_delete");
    //gdb test failed 

    void handle_update(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_update(f);
        g_object_unref(f);
    }, "handle_update");
    //gdb test failed 75%
#endif

    void handle_new(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_new(f);
        g_object_unref(f);
    }, "handle_new");

    void _remove_monitor_directory(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        _remove_monitor_directory(f);
    }, "_remove_monitor_directory");

    void _inotify_poll();
    Test({
        _inotify_poll();
    }, "_inotify_poll");






	tear_down_fixture();

}