
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

static char* KEY_LEFTUP = "left-up";//left-up
static char* KEY_RIGHUP = "right-up";//right-up
static char* KEY_LEFTDOWN = "left-down";//left-down
static char* KEY_RIGHTDOWN = "right-down";//right-down

static char* VAL_LAUNCHER = "/usr/bin/launcher";
static char* VAL_DSS = "/usr/bin/dss";
static char* VAL_DESKTOP = "/usr/bin/desktop-show";
static char* VAL_WORKSPACE = "workspace";
static char* VAL_NONE = "none";


#endif