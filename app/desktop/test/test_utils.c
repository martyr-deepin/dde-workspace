#include "desktop_test.h"

void test_utils()
{
	setup_fixture();


	Test({


	},"test_");

    typedef void Entry;

    void desktop_run_terminal();
    Test({
        desktop_run_terminal();
    }, "desktop_run_terminal");

    void desktop_run_deepin_settings(const char* mod);
    Test({
        desktop_run_deepin_settings("display");
    }, "desktop_run_deepin_settings");

    void desktop_run_deepin_software_center();
    Test({
        desktop_run_deepin_software_center();
    }, "desktop_run_deepin_software_center");

    void desktop_open_trash_can();
    Test({
        desktop_open_trash_can();
    }, "desktop_open_trash_can");

    Entry* desktop_get_home_entry();
    Test({
        Entry *entry = desktop_get_home_entry();
        if (NULL != entry)
            g_object_unref(entry);
    }, "desktop_get_home_entry");

    Entry* desktop_get_computer_entry();
    Test({
        Entry *entry = desktop_get_computer_entry();
        if (NULL != entry)
            g_object_unref(entry);
    }, "desktop_get_computer_entry");

    char* desktop_get_transient_icon (Entry* p1);
    Test({
        GFile *f = g_file_new_for_path(file1);
        gchar *str = (gchar *)desktop_get_transient_icon((Entry *)f);
        g_free(str);
        g_object_unref(f);
    }, "desktop_get_transient_icon");


    
	tear_down_fixture();

}