#include "dock_test.h"

void dock_test_dominant_color()
{
#define toint(n) (int)(n * 100 + .5)
#define h2int(n) (int)(n * 360)
#define comp(a, b) (a == b || a == b - 1 || a == b + 1)
#define rgb2int(n) (int)(n * 255 + .5)
    double h, s, v;
    double r, g, b;
    extern void rgb2hsv(int r, int g, int b, double *h, double* s, double* v);
    extern void hsv2rgb(double h, double s, double v, double* r, double*g, double *b);
    Test({
         rgb2hsv(179, 102, 102, &h, &s, &v);
         g_assert(comp(h2int(h), 0) && comp(toint(s), 43) && comp(toint(v), 70));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 179) && comp(rgb2int(g), 102) && comp(rgb2int(b), 102));

         rgb2hsv(82, 46, 46, &h, &s, &v);
         g_assert(comp(h2int(h), 0) && comp(toint(s), 44) && comp(toint(v), 32));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 82) && comp(rgb2int(g), 46) && comp(rgb2int(b), 46));

         rgb2hsv(46, 125, 148, &h, &s, &v);
         g_assert(comp(h2int(h), 193) && comp(toint(s), 69) && comp(toint(v), 58));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 46) && comp(rgb2int(g), 125) && comp(rgb2int(b), 148));

         rgb2hsv(82, 85, 119, &h, &s, &v);
         g_assert(comp(h2int(h), 235) && comp(toint(s), 31) && comp(toint(v), 47));
         hsv2rgb(h, s, v, &r, &g, &b);
         g_assert(comp(rgb2int(r), 82) && comp(rgb2int(g), 85) && comp(rgb2int(b), 119));
    }, "rgb2hsv and hsv2rgb");
#undef rgb2int
#undef comp
#undef h2int
#undef toint

    GdkPixbuf* pixbuf1 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-user-manual.png", NULL);
    GdkPixbuf* pixbuf2 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-media-player.png", NULL);
    GdkPixbuf* pixbuf3 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-music-player.png", NULL);
    GdkPixbuf* pixbuf4 = gdk_pixbuf_new_from_file("/usr/share/icons/Deepin/apps/48/deepin-screenshot.png", NULL);
    extern void calc(guchar*, guint, int, double*, double*, double*);
    Test({
         guint size = 0;
         guchar* buf = gdk_pixbuf_get_pixels_with_length(pixbuf1, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf1), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf2, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf2), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf3, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf3), &r, &g, &b);

         buf = gdk_pixbuf_get_pixels_with_length(pixbuf4, &size);
         g_assert(size != 0);
         calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf4), &r, &g, &b);
         }, "calc");

    Test({
         calc_dominant_color_by_pixbuf(pixbuf1, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf2, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf3, &r, &g, &b);
         calc_dominant_color_by_pixbuf(pixbuf4, &r, &g, &b);
         }, "calc_dominant_color_by_pixbuf");
    g_object_unref(pixbuf1);
    g_object_unref(pixbuf2);
    g_object_unref(pixbuf3);
    g_object_unref(pixbuf4);
}
