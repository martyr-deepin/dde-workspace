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
    cairo_rectangle_int_t dock_board_rect = _base_rect;
    dock_board_rect.y += 30;
    dock_board_rect.height = 30;
    cairo_region_union_rectangle(_region, &dock_board_rect);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}

void dock_require_region(double x, double y, double width, double height)
{
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_union_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_release_region(double x, double y, double width, double height)
{
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_subtract_rectangle(_region, &tmp);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
}
void dock_set_region_origin(double x, double y)
{
    _base_rect.x = x;
    _base_rect.y = y;
}

void show_region(cairo_region_t* r)
{
    int n = cairo_region_num_rectangles(r);
    for (int i=0; i<n; i++) {
        cairo_rectangle_int_t tmp;
        cairo_region_get_rectangle(r, i, &tmp);
        printf("%d(%d %d %d %d)\n", i, tmp.x, tmp.y, tmp.width, tmp.height);
    }
    printf("\n");
}

gboolean dock_region_overlay(const cairo_region_t* r)
{
    cairo_region_t* region = cairo_region_copy(_region);
    cairo_region_intersect_rectangle(region, &_base_rect);
    int n = cairo_region_num_rectangles(region);
    /*show_region(region);*/

    for (int i=0; i<n; i++) {
        cairo_rectangle_int_t tmp;
        cairo_region_get_rectangle(region, i, &tmp);
        if (cairo_region_contains_rectangle(r, &tmp) != CAIRO_REGION_OVERLAP_OUT) {
            cairo_region_destroy(region);
            return TRUE;
        }
    }
    cairo_region_destroy(region);
    return FALSE;
}
