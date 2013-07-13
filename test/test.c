#include <stdio.h>

#include <glib.h>
#include "test.h"
#include <sys/resource.h>

gboolean memory_leak(int ms)
{
    struct rusage usg;
    getrusage(RUSAGE_SELF, &usg);
    if (usg.ru_maxrss > ms)
        return TRUE;
    else
        return FALSE;
}

gboolean T_test(TestFunc f, gpointer data, int ms, int count, const char* test_name)
{
    g_message("T_test start");

    for (int i=0; i<count; i++) {
        f(data);
        printf("\r[%3d%%] Testing %s...", (i + 1) * 100 / count, test_name);
        fflush(stdout);
        if (memory_leak(ms)) {
            printf("\n");
            return TRUE;
        }
    }

    printf("\n");
    g_message("T_test end");

    return FALSE;
}
extern int TEST_MAX_MEMORY;
extern int TEST_MAX_COUNT;

gboolean T(TestFunc f, const char* test_name)
{
    g_message("T start");
    if (T_test(f, NULL, TEST_MAX_MEMORY, TEST_MAX_COUNT, test_name) == FALSE) {
        g_message("Test %s Succefull\n", test_name);
    g_message("T end by T_test FALSE");

        return TRUE;
    } else {
        g_error("Test %s Failed\n", test_name);
    g_message("T end by T_test TRUE");

        return FALSE;
    }

}
