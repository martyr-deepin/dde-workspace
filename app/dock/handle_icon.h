#ifndef __HANDLE_ICON_H__
#define __HANDLE_ICON_H__

#include <glib.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#define BOARD_WIDTH 48
#define BOARD_HEIGHT 48
#define BOARD_OFFSET BOARD_HEIGHT - 50
#define BOARD_OFFSET BOARD_HEIGHT - 50
#define IMG_WIDTH 36
#define IMG_HEIGHT 36
#define MARGIN_LEFT ((BOARD_WIDTH-IMG_WIDTH)/2)
#define MARGIN_TOP ((BOARD_HEIGHT-IMG_HEIGHT)/2)


char* get_data_uri_by_surface(cairo_surface_t* surface);
gboolean is_deepin_icon(const char* path);
char* handle_icon(GdkPixbuf* icon, gboolean);
void try_get_deepin_icon(const char* app_id, char** icon, int* operator_code);


#endif
