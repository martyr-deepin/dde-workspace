#ifndef __HANDLE_ICON_H__
#define __HANDLE_ICON_H__

#define BOARD_WIDTH 48
#define BOARD_HEIGHT 48
#define IMG_WIDTH 36
#define IMG_HEIGHT 36
#define MARGIN_LEFT ((BOARD_WIDTH-IMG_WIDTH)/2)
#define MARGIN_TOP ((BOARD_HEIGHT-IMG_HEIGHT)/2)


char* get_data_uri_by_surface(cairo_surface_t* surface);


#endif
