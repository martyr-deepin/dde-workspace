#include "config.h"
#include <glib.h>
#include "dwebview.h"
#include "jsextension.h"

void init_js_extension(JSGlobalContextRef c, void* t)
{
}

int main(int argc, char *argv[])
{
    gtk_init(NULL, NULL);
    GtkWidget* container = create_web_container(FALSE, TRUE);
    GtkWidget* webview = d_webview_new_with_uri("file:///home/liliqiang/dde/app/launcher/test/bg.html");

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));
    gtk_widget_show_all(container);

    gtk_main();
    return 0;
}

