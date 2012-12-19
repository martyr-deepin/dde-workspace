#include <glib.h>
#include "jsextension.h"

JS_EXPORT_API
char* dfile_get_basename(GFile* f)
{
    return g_file_get_basename(f);
}
