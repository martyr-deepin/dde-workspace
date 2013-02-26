#include "region.h"

cairo_region_t* _region = NULL;
GdkWindow* _win = NULL;
cairo_rectangle_int_t _base_rect;

void init_region(GdkWindow* win, double x, double y, double width, double height)
{
    if (_win == NULL) {
        _win = win;
        _region = cairo_region_create();
        _base_rect.x = x;
        _base_rect.y = y;
        _base_rect.width = width;
        _base_rect.height = height;
        dock_require_region(0, 0, width, height);
    } else {
        _win = NULL;
        cairo_region_destroy(_region);
        init_region(win, x, y, width, height);
        /*g_assert_not_reached();*/
    }
}

void dock_force_set_region(double x, double y, double width, double height)
{
    cairo_region_destroy(_region);
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    _region = cairo_region_create_rectangle(&tmp);
    cairo_region_union_rectangle(_region, &_base_rect);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}

void dock_require_region(double x, double y, double width, double height)
{
    printf("dock region require %f %f %f %f\n", x, y, width, height);
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_union_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_release_region(double x, double y, double width, double height)
{
    printf("dock release require %f %f %f %f\n", x, y, width, height);
    g_debug("base(%d,%d): release(%f,%f,%f,%f)\n", _base_rect.x, _base_rect.y, x, y, width, height);
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_subtract_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_set_region_origin(double x, double y)
{
    _base_rect.x = x;
    _base_rect.y = y;
}
