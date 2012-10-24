#ifndef __X_MISC_H__
#define __X_MISC_H__

#include <gtk/gtk.h>
void set_wmspec_desktop_hint(GdkWindow *window);
void set_wmspec_dock_hint(GdkWindow *window);

enum {
    ORIENTATION_LEFT,
    ORIENTATION_RIGHT,
    ORIENTATION_TOP,
    ORIENTATION_BOTTOM,
};
void set_struct_partial(GdkWindow* window, guint32 orientation, guint32 strut, guint32 begin, guint32 end);

void get_workarea_size(int screen_n, int desktop_n, int* x, int* y, int* width, int* height);

void watch_workarea_changes(GtkWidget* widget);

void unwatch_workarea_changes(GtkWidget* widget);

void get_wmclass (GdkWindow* xwindow, char **res_class, char **res_name);

#endif
