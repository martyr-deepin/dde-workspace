#ifndef __REGION_H__
#define __REGION_H__

#include <gtk/gtk.h>

void init_region(GdkWindow* win, double x, double y, double width, double height);
void dock_set_region_origin(double x, double y);
void dock_require_region(double x, double y, double width, double height);
void dock_release_region(double x, double y, double width, double height);

void dock_region_restore();
void dock_region_save();

#endif
