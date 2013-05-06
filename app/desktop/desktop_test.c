#ifdef __DUI_DEBUG

#include "test.h"
int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY = 100000;

#include "inotify_item.h"
void test_inotify()
{
    Test({
        g_assert(FALSE == desktop_file_filter("snyh.txt"));
        g_assert(TRUE == desktop_file_filter(".snyh.txt"));
        g_assert(TRUE == desktop_file_filter("~snyh.txt"));
    }, "desktop_file_filter");
    Test({
        trash_changed();
    }, "trash_changed");
}

void test_dbus()
{
    Test({
        call_dbus("com.deepin.dde.desktop", "FocusChanged", FALSE);
    }, "desktop_dbus");
}

void test_background()
{
}

void test_other()
{
}

void desktop_test()
{
    test_inotify();
    test_dbus();
    test_background();
    test_other();
}

#endif
