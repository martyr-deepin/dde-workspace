#ifndef __DEEPIN_WEBVIEW__
#define __DEEPIN_WEBVIEW__

#include <glib.h>
#include <glib-object.h>
#include <webkit/webkit.h>

G_BEGIN_DECLS

#define D_WEBVIEW_TYPE      (d_webview_get_type())
#define D_WEBVIEW(obj)      (G_TYPE_CHECK_INSTANCE_CAST((obj),\
            D_WEBVIEW_TYPE, DWebView))
#define D_WEBVIEW_CLASS(klass)  (G_TYPE_CHECK_CLASS_CAST((klass), \
            D_WEBVIEW_TYPE, DWebViewClass))
#define IS_D_WEBVIEW(obj)   (G_TYPE_CHECK_INSTANCE_TYPE((obj), \
            D_WEBVIEW_TYPE))
#define IS_D_WEBVIEW_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE((klass),\
            D_WEBVIEW_TYPE))

typedef struct _DWebView    DWebView;
typedef struct _DWebViewClass   DWebViewClass;

struct _DWebView {
    WebKitWebView parent;
};

struct _DWebViewClass {
    WebKitWebViewClass parent_class;
};


GtkWidget* create_web_container(bool normal, bool above);
GtkWidget* d_webview_new();
GtkWidget* d_webview_new_with_uri();

void js_post_message(const char* name, const char* message_json);

G_END_DECLS


#endif
