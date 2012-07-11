#ifndef __D_FORWROD_WINDOW__
#define __D_FORWROD_WINDOW__
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define D_TYPE_FORWARD_WINDOW           (d_forward_window_get_type())
#define D_FORWARD_WINDOW(obj)           (G_TYPE_CHECK_INSTANCE_CAST ((obj), D_TYPE_FORWARD_WINDOW, DForwardWindow))
#define D_FORWARD_WINDOW_CLASS(klass)   (G_TYPE_CHECK_CLASS_CAST ((klass), D_TYPE_FORWARD_WINDOW, DForwardWindowClass))
#define D_IS_FORWARD_WINDOW(obj)        (G_TYPE_CHECK_INSTANCE_TYPE ((obj), D_TYPE_FORWARD_WINDOW))
#define D_IS_FORWARD_WINDOW_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), D_TYPE_FORWARD_WINDOW))
#define D_FORWARD_WINDOW_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), D_TYPE_FORWARD_WINDOW, DForwardWindowClass))


typedef struct _DForwardWindow       DForwardWindow;
typedef struct _DForwardWindowClass  DForwardWindowClass;

struct _DForwardWindow
{
  GtkInvisible parent;
};

struct _DForwardWindowClass
{
  GtkInvisibleClass parent_class;
};


GType      d_forward_window_get_type(void);
GtkWidget* d_forward_window_new(GdkWindow* origin_window);
void d_forward_window_update_img(GtkWidget* widget, cairo_surface_t *img);
void d_forward_window_set_show_region(GtkWidget* widget, int x, int y, int width, int height);

void d_forward_window_test(GtkWidget* widget);


G_END_DECLS

#endif 
