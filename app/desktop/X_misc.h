#ifndef __X_MISC_H__
#define __X_MISC_H__

void set_wmspec_desktop_hint (GdkWindow *window);

void get_workarea_size(int screen_n, int desktop_n, 
        int* x, int* y, int* width, int* height);

#endif
