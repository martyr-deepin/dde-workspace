#include <gio/gio.h>

#include "jsextension.h"

#define GREETER_SCHEAM_ID "com.deepin.dde.greeter"

gboolean _has_camera()
{
    // HAS_CAMERA is defined in CMakeLists.txt
    char* argv[] = {HAS_CAMERA, NULL};
    int exit_code = 1;
    GError* error = NULL;
    g_spawn_sync(NULL, argv, NULL, 0, NULL, NULL, NULL, NULL, &exit_code, &error);
    if (error != NULL) {
        g_warning("[Error in _has_camera] %s", error->message);
        g_error_free(error);
        return FALSE;
    }
    return exit_code == 0;
}

gboolean _face_recognition_login()
{
    GSettings* settings = g_settings_new(GREETER_SCHEAM_ID);
    gboolean uses_camera = g_settings_get_boolean(settings,
                                                  "face-recognition-login");
    g_object_unref(settings);
    return uses_camera && _has_camera();
}


JS_EXPORT_API
gboolean lock_use_face_recognition_login()
{
    return _face_recognition_login();
}


JS_EXPORT_API
gboolean greeter_use_face_recognition_login()
{
    return _face_recognition_login();
}
