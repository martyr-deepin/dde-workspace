#ifndef _LAUNCHER_H__
#define _LAUNCHER_H__

void init_launchers();
gboolean is_has_app_info(const char* app_id);
gboolean request_by_info(const char* name, const char* cmdline, const char* icon);

#endif
