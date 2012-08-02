#ifndef __TASKBAR_H__
#define __TASKBAR_H__

#include <glib.h>
#include <glib-object.h>
#include <dwebview.h>

G_BEGIN_DECLS

#define D_TASKBAR_TYPE      (d_taskbar_get_type())
#define D_TASKBAR(obj)      (G_TYPE_CHECK_INSTANCE_CAST((obj),\
            D_TASKBAR_TYPE, DTaskbar))
#define D_TASKBAR_CLASS(klass)  (G_TYPE_CHECK_CLASS_CAST((klass), \
            D_TASKBAR_TYPE, DTaskbarClass))
#define IS_D_TASKBAR(obj)   (G_TYPE_CHECK_INSTANCE_TYPE((obj), \
            D_TASKBAR_TYPE))
#define IS_D_TASKBAR_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE((klass),\
            D_TASKBAR_TYPE))

typedef struct _DTaskbar DTaskbar;
typedef struct _DTaskbarPrivate DTaskbarPrivate;
typedef struct _DTaskbarClass   DTaskbarClass;

struct _DTaskbar {
    GtkContainer parent;
    DTaskbarPrivate *priv;
};

struct _DTaskbarClass {
    GtkContainerClass parent_class;
};


GtkWidget* d_taskbar_new();
GType d_taskbar_get_type();

G_END_DECLS

#endif
