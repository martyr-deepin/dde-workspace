/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/
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
gboolean erase_background(GtkWidget* widget, cairo_t *cr, gpointer data);

void js_post_message(const char* name, const char* format, ...);

G_END_DECLS


#endif
