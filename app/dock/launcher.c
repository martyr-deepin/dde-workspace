#include "xdg_misc.h"
#include "jsextension.h"
#include "launcher.h"
#include "dock_config.h"

void update_dock_apps()
{
    char** tmp = GD.config.apps;
    if (tmp == NULL)
        return;

    const char* path = NULL;
    for (; NULL != (path = *tmp); tmp++) {
        char* json = get_entry_info(path);
        if (json != NULL) {
            js_post_message("launcher_added", json);
            g_free(json);
        }
    }
}


void request_dock(const char* path)
{
    printf("request dock %s\n", path);
}
