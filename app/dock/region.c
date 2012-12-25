#include "region.h"

cairo_region_t* _region = NULL;
GdkWindow* _win = NULL;
int _base_x = 0;
int _base_y = 0;


void init_region(GdkWindow* win, double x, double y, double width, double height)
{
    if (_win == NULL) {
        _win = win;
        _region = cairo_region_create();
        _base_x = x;
        _base_y = y;
        dock_require_region(0, 0, width, height);
    } else {
        _win = NULL;
        cairo_region_destroy(_region);
        init_region(win, x, y, width, height);
        /*g_assert_not_reached();*/
    }
}

void dock_require_region(double x, double y, double width, double height)
{  
    cairo_rectangle_int_t tmp = {(int)x + _base_x, (int)y + _base_y, (int)width, (int)height};
    cairo_region_union_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_release_region(double x, double y, double width, double height)
{
    printf("base(%d,%d): release(%f,%f,%f,%f)\n", _base_x, _base_y, x, y, width, height);
    cairo_rectangle_int_t tmp = {(int)x + _base_x, (int)y + _base_y, (int)width, (int)height};
    cairo_region_subtract_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_set_region_origin(double x, double y)
{
    _base_x = x;
    _base_y = y;
}
