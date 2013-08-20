#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <gio/gio.h>

#include "camera.h"
#include "jsextension.h"

#define GREETER_SCHEAM_ID "com.deepin.dde.greeter"

gboolean _get_face_recognition_login_setting()
{
    GSettings* settings = g_settings_new(GREETER_SCHEAM_ID);
    gboolean uses_camera = g_settings_get_boolean(settings,
                                                  "face-recognition-login");
    g_object_unref(settings);
    return uses_camera;
}


JS_EXPORT_API
gboolean lock_use_face_recognition_login()
{
    /* return _has_camera() && _get_face_recognition_login_setting(); */
    return TRUE;
}


JS_EXPORT_API
gboolean greeter_use_face_recognition_login()
{
    /* return _has_camera() && _get_face_recognition_login_setting(); */
    return TRUE;
}
