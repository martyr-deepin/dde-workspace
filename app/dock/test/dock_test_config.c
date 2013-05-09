#include "dock_test.h"

void dock_test_config()
{
    GSettings* s = g_settings_new("com.deepin.dde.dock");
    Test({
         g_signal_emit_by_name(s, "changed", "active-mini-mode", NULL);
         g_signal_emit_by_name(s, "changed", "background-color", NULL);
         g_signal_emit_by_name(s, "changed", "hide-mode", NULL);
         g_signal_emit_by_name(s, "changed", "112098", NULL);
         }, "settings_changed");
     g_object_unref(s);
}

