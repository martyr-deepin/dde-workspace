#ifndef __TRAY_MANAGER_H__
#define __TRAY_MANAGER_H__

#include <gtk/gtk.h>
#include <gdk/gdkx.h>

G_BEGIN_DECLS

#define TYPE_TRAY_MANAGER			(tray_manager_get_type ())
#define TRAY_MANAGER(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_TRAY_MANAGER, TrayManager))
#define TRAY_MANAGER_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_TRAY_MANAGER, TrayManagerClass))
#define IS_TRAY_MANAGER(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_TRAY_MANAGER))
#define IS_TRAY_MANAGER_CLASS(klass)		(G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_TRAY_MANAGER))
#define TRAY_MANAGER_GET_CLASS(obj)		(G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_TRAY_MANAGER, TrayManagerClass))
	
typedef struct _TrayManager	    TrayManager;
typedef struct _TrayManagerClass  TrayManagerClass;
typedef struct _TrayManagerChild  TrayManagerChild;

struct _TrayManager
{
  GObject parent_instance;

  GdkAtom selection_atom;
  Atom    opcode_atom;
  
  GtkWidget *invisible;
  GdkScreen *screen;
  GtkOrientation orientation;

  GList *messages;
  GHashTable *socket_table;
};

struct _TrayManagerClass
{
  GObjectClass parent_class;

  void (* tray_icon_added)   (TrayManager      *manager,
			      TrayManagerChild *child);
  void (* tray_icon_removed) (TrayManager      *manager,
			      TrayManagerChild *child);

  void (* message_sent)      (TrayManager      *manager,
			      TrayManagerChild *child,
			      const gchar        *message,
			      glong               id,
			      glong               timeout);
  
  void (* message_cancelled) (TrayManager      *manager,
			      TrayManagerChild *child,
			      glong               id);

  void (* lost_selection)    (TrayManager      *manager);
};

GType           tray_manager_get_type        (void);

gboolean        tray_manager_check_running   (GdkScreen          *screen);
TrayManager  *tray_manager_new             (void);
gboolean        tray_manager_manage_screen   (TrayManager      *manager,
						 GdkScreen          *screen);
char           *tray_manager_get_child_title (TrayManager      *manager,
						 TrayManagerChild *child);
void            tray_manager_set_orientation (TrayManager      *manager,
						 GtkOrientation      orientation);
GtkOrientation  tray_manager_get_orientation (TrayManager      *manager);

G_END_DECLS

#endif 
