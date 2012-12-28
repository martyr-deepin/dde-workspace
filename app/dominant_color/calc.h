#ifndef __CALC_H__
#define __CALC_H__
typedef void (*ClampFunc)(double* s, double* v);
void calc_dominant_color_by_path(const char* path, double *r, double *g, double *b, ClampFunc func);
void draw_board(cairo_t* cr, cairo_surface_t* img, cairo_surface_t* mask, double r, double g, double b);
#endif
