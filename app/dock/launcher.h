#ifndef _LAUNCHER_H__
#define _LAUNCHER_H__

void init_launchers();
gboolean dock_has_launcher(const char* app_id);
gboolean request_by_info(const char* name, const char* cmdline, const char* icon);
void update_dock_apps();

#endif
