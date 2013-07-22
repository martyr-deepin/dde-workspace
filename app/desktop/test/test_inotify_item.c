#include "desktop_test.h"

void test_inotify_item()
{
	setup_fixture();


	Test({


	},"test_");


    void trash_changed();
    Test({
        g_assert(FALSE == desktop_file_filter("snyh.txt"));
        g_assert(TRUE == desktop_file_filter(".snyh.txt"));
        g_assert(TRUE == desktop_file_filter("snyh.txt~"));
    }, "desktop_file_filter");
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

    void handle_rename(GFile *, GFile *);
    Test({
        GFile *old_f = g_file_new_for_path(file1);
        gchar *filename = g_strconcat(file1, "2", NULL);
        GFile *new_f = g_file_new_for_path(filename);
        handle_rename(old_f, new_f);

        g_free(filename);
        g_object_unref(old_f);
        g_object_unref(new_f);
    }, "handle_rename");

    void handle_delete(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_delete(f);
        if (f != NULL)
            g_object_unref(f);
    }, "handle_delete");

    void handle_update(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_update(f);
        g_object_unref(f);
    }, "handle_update");

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