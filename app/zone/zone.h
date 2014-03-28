
#ifndef ZONE_H
#define ZONE_H

#define KEY_LEFTUP "left-up"//left-up
#define KEY_RIGHTUP "right-up"//right-up
#define KEY_LEFTDOWN "left-down"//left-down
#define KEY_RIGHTDOWN "right-down"//right-down

#define VAL_LAUNCHER "/usr/bin/launcher"
#define VAL_DSS "dbus-send --type=method_call --dest=com.deepin.Dss /com/deepin/Dss com.deepin.Dss.Show int32:0"
#define VAL_DESKTOP "/usr/bin/desktop-show"
#define VAL_WORKSPACE "workspace"
#define VAL_NONE "none"

gboolean compiz_set(const char *key, const char *value);

#endif
