#ifndef _TRAY_H__
#define _TRAY_H__
void tray_init(GtkWidget* container);
gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr, gpointer data);
#endif
