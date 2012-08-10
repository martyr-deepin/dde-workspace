#include "jsextension.h"
#include "desktop_entry.h"
#include "forward_window.h"
#include <assert.h>
#include <webkit/webkitwebview.h>
#include <webkit/WebKitDOMDocument.h>
#include <webkit/WebKitDOMEventTarget.h>
#include <webkit/WebKitDOMNodeList.h>
#include <cairo/cairo.h>
#include <string.h>


enum RegionOP {
    REGION_OP_NEW = 0,
    REGION_OP_UNION,
    REGION_OP_INTERSECT,
    REGION_OP_SUBTRACT,
    REGION_OP_XOR,
};

enum RegionType {
    REGION_TMP = 0,
    REGION_GLOBAL,
};
cairo_region_t* tmp_region = NULL;
cairo_region_t* global_region = NULL;


static void apply_region(JSData* data)
{
    GtkWidget* widget = data->webview;
    GdkWindow *window = gtk_widget_get_window(gtk_widget_get_toplevel(widget));
    cairo_region_t *region = cairo_region_create();
    if (tmp_region != NULL)
        cairo_region_union(region, tmp_region);
    if (global_region != NULL)
        cairo_region_union(region, global_region);
    gdk_window_shape_combine_region(window, region, 0, 0);
    /*gdk_window_input_shape_combine_region(window, region, 0, 0);*/
}


static 
void update_region(int type, const cairo_rectangle_int_t *rect, int op, JSData *data)
{
    if (op == REGION_OP_NEW && type == REGION_TMP) {
        //TODO: gobject auto free?
        /*data->tmp_region = gdk_region_rectangle(rect);*/
        tmp_region = cairo_region_create_rectangle(rect);
        apply_region(data);
        return;
    } else if (op == REGION_OP_NEW && type == REGION_GLOBAL) {
        global_region = cairo_region_create_rectangle(rect);
        apply_region(data);
        return;
    }

    /*GdkRegion *tmp_region = data->tmp_region;
    GdkRegion *global_region = data->global_region;
    GdkRegion *region = NULL;*/

    cairo_region_t *region = NULL;

    if (type == REGION_TMP)
        region = tmp_region;
    else
        region = global_region;

    switch (op) {
        case REGION_OP_UNION:
            /*gdk_region_union_with_rect(region, rect);*/
            cairo_region_union_rectangle(region, rect);
            break;
        case REGION_OP_INTERSECT:
            /*gdk_region_intersect(region, gdk_region_rectangle(rect));*/
            cairo_region_intersect_rectangle(region, rect);
            break;
        case REGION_OP_SUBTRACT:
            /*gdk_region_subtract(region, gdk_region_rectangle(rect));*/
            cairo_region_subtract_rectangle(region, rect);
            break;
        case REGION_OP_XOR:
            /*gdk_region_xor(region, gdk_region_rectangle(rect));*/
            cairo_region_xor_rectangle(region, rect);
            break;
        default:
            assert(!"this operation hasn't support!");
    }
    if (type == REGION_TMP)
        tmp_region = region;
    else
        global_region = region;
    apply_region(data);
}


void modify_region(double type, double op, double x, double y, double width,
        double height, JSData *data)
{
    g_assert(data != NULL);
    cairo_rectangle_int_t rect = {(int)x, (int)y, (int)width, (int)height};
    update_region((int)type, &rect, (int)op, data);
}

char* get_desktop_items()
{
    return get_desktop_entries();
}


char* gen_id(const char* seed)
{
    return g_compute_checksum_for_string(G_CHECKSUM_MD5, seed, strlen(seed));
}

void run_command(const char* cmd)
{
    g_printf("run cmd: %s\n", cmd);
    g_spawn_command_line_async(cmd, NULL);
}


#ifdef __DEEPIN_WEBKIT__

extern int d_dom_element_render(cairo_t* cr, WebKitDOMElement* el);
WebKitDOMElement* el;
bool webview_changed(GtkWidget* widget, WebKitDOMMouseEvent *event, gpointer data)
{

    DForwardWindow* popup = (DForwardWindow*)data;
    int x, y, width, height;
    /*d_dom_element_get_allocation(el, &x, &y, &width, &height);*/


    cairo_t *cr = gdk_cairo_create(gtk_widget_get_window((GtkWidget*)popup));
    /*cairo_translate(cr, 25, 0);*/
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    /*d_dom_element_render(cr, el);*/

    /*if (!d_forward_window_need_change((GtkWidget*)popup, x, y, width, height))*/
        /*return FALSE;*/
    d_forward_window_set_position((GtkWidget*)popup, x, y, width, height);

    GtkAllocation alloc = {x, y+27, width, height};
    static int t = 1;
    if (t == 1) {
        gdk_window_move_resize(gtk_widget_get_window(GTK_WIDGET(popup)),
                x, y+27, width, height);
        t++;
    }
    printf("element:(%d, %d)\n", x, y);
    d_forward_window_move(GTK_WIDGET(popup), x, y+27, -1, -1);

    return FALSE;
}

void make_popup(const char* el_nouse, JSData *data)
{
    g_assert(data != NULL);
    WebKitWebView* webview = (WebKitWebView*)data->webview;
    WebKitDOMDocument *dom = webkit_web_view_get_dom_document(webview);

    el = webkit_dom_node_list_item(
        webkit_dom_document_get_elements_by_class_name(dom, "ui-dialog"), 0);


    GtkWidget* popup = d_forward_window_new(gtk_widget_get_window(data->webview));
    gtk_widget_show(popup);
    gtk_widget_set_app_paintable(popup, TRUE);
    gtk_widget_set_double_buffered(popup, TRUE);
    /*d_forward_window_test(popup);*/
    g_assert(data->webview != NULL);
    g_signal_connect(data->webview, "draw", G_CALLBACK(webview_changed), popup);
}

#else

void make_popup(const char* el_nouse, JSData *data)
{
    g_warning("this feature need deepin webkit support!"); 
}

#endif
