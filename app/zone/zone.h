
#ifndef ZONE_H
#define ZONE_H

#define ZONE_SCHEMA_ID "com.deepin.dde.zone"
#define ZONE_ID_NAME "desktop.app.zone"

#define CHOICE_HTML_PATH "file://"RESOURCE_DIR"/zone/zone.html"

#define ZONE_MAJOR_VERSION 2
#define ZONE_MINOR_VERSION 0
#define ZONE_SUBMINOR_VERSION 0
#define ZONE_VERSION G_STRINGIFY(ZONE_MAJOR_VERSION)"."G_STRINGIFY(ZONE_MINOR_VERSION)"."G_STRINGIFY(ZONE_SUBMINOR_VERSION)
#define ZONE_CONF "zone/config.ini"
static GKeyFile* zone_config = NULL;

PRIVATE GtkWidget* container = NULL;
static GSGrab* grab = NULL;

PRIVATE
GSettings* zone_gsettings = NULL;

#define KEY_LEFTUP "left-up"//left-up
#define KEY_RIGHTUP "right-up"//right-up
#define KEY_LEFTDOWN "left-down"//left-down
#define KEY_RIGHTDOWN "right-down"//right-down

#define VAL_LAUNCHER "/usr/bin/launcher"
#define VAL_DSS "/usr/bin/dss"
#define VAL_DESKTOP "/usr/bin/desktop-show"
#define VAL_WORKSPACE "workspace"
#define VAL_NONE "none"

gboolean compiz_set(const char *key, const char *value);

#endif
