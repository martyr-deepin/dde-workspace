#ifndef __REGION_H__
#define __REGION_H__

#include <gtk/gtk.h>

void init_region(GdkWindow* win, double x, double y, double width, double height);
void set_region_origin(double x, double y);
void require_region(double x, double y, double width, double height);
void release_region(double x, double y, double width, double height);


#endif
