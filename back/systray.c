#include <xcb/xcb.h>

void
xembed_message_send(xcb_connection_t *connection, xcb_window_t towin,
                    long message, long d1, long d2, long d3)
{
    xcb_client_message_event_t ev;

    p_clear(&ev, 1);
    ev.response_type = XCB_CLIENT_MESSAGE;
    ev.window = towin;
    ev.format = 32;
    ev.data.data32[0] = XCB_CURRENT_TIME;
    ev.data.data32[1] = message;
    ev.data.data32[2] = d1;
    ev.data.data32[3] = d2;
    ev.data.data32[4] = d3;
    ev.type = _XEMBED;
    xcb_send_event(connection, false, towin, XCB_EVENT_MASK_NO_EVENT, (char *) &ev);
}
xcb_get_property_cookie_t
xembed_info_get_unchecked(xcb_connection_t *connection, xcb_window_t win)
{
    return xcb_get_property_unchecked(connection, false, win, 
            _XEMBED_INFO, XCB_GET_PROPERTY_TYPE_ANY, 0L, 2);
}

static bool
xembed_info_from_reply(xembed_info_t *info, xcb_get_property_reply_t *prop_r)
{
    uint32_t *data;
    if (!prop_r || !prop_r->value_len)
        return false;
    if (!(data = (uint32_t*)xcb_get_property_value(prop_r)))
        return false;
    info->version = data[0];
    info->flags = data[1]  & XEMBED_INFO_FLAGS_ALL;
}

bool
xembed_info_get_reply(xcb_connection_t *connection,
        xcb_get_property_cookie_t cookie,
        xembed_info_t *info)
{
    xcb_get_property_reply_t *prop_r = xcb_get_property_reply(connection,
            cookie, NULL);
    bool ret = xembed_info_from_reply(info, prop_r);
    free(prop_r);
    return ret;
}

xembed_window_t *
xembed_getbywin(xembed_window_array_t *list, xcb_window_t win)
{
    for(int i=0; i<list->len; i++)
        if(list->tab[i].win == win)
            return &list->tab[i];
    return NULL;
}

void
xembed_property_update(xcb_connection_t *connection, xembed_window_t *emwin,
        xcb_get_property_reply_t *reply)
{
    int flags_changed;
    xembed_info_t info = {0, 0};
    xembed_info_from_reply(&info, reply);

    if (!(flags_changed = info.flags ^ emwin->info.flags))
        return;
    emwin->info.flags = info.flags;
    if (flags_changed & XEMBED_MAPPED) {
        if (info.flags & XEMBED_MAPPED) {
            xcb_map_window(connection, emwin->win);
            xembed_window_activate(connection, emwin->win);
        } else {
            xcb_unmap_window(connection, emwin->win);
            xembed_window_deactivate(connection, emwin->win);
            xembed_focus_out(connection, emwin->win);
        }
    }
}

#define XEMBED_VERSION 0
#define XEMBED_MAPPED (1<<0)
#define XEMBED_INFO_FLAGS_ALL 1

#define XEMBED_EMBEDDED_NOTIFY  0
#define XEMBED_WINDOW_ACTIVATE  1
#define XEMBED_WINDOW_DEFACTIVATE 2
#define XEMBED_REQUEST_FOCUS 3
#define XEMBED_FOCUS_IN 4
#define XEMBED_FOCUS_OUT 5
#define XEMBED_FOCUS_NEXT 6
#define XEMBED_FOCUS_PREV 7

#define XEMBED_MODALITY_ON 10
#define XEMBED_MODALITY_OFF 11
#define XEMBED_REGISTER_ACCELERATOR 12
#define XEMBED_UNREGISTER_ACCELERATOR 13
#define XEMBED_ACTIVATE_ACCELERATOR 14

#define XEMBED_FOCUS_CURRENT 0
#define XEMBED_FOCUS_FIRST 1
#define XEMBED_FOCUS_LAST 2

#define XEMBED_MODIFIER_SHIFT (1 << 0)
#define XEMBED_MODIFIER_CONTROL (1 << 1)
#define XEMBED_MODIFIER_ALT (1 << 2)
#define XEMBED_MODIFIER_SUPER (1 << 3)
#define XEMBED_MODIFIER_HYPER (1 << 4)

#define XEMBED_ACCELERATOR_OVERLOADED (1 << 0)

void xembed_message_send(xcb_connection_t*, xcb_window_t, long, long, long, long);
xembed_window_t* xembed_getbywin(xembed_window_array_t*, xcb_window_t);
void xembed_property_update(xcb_connection_t*, xembed_window_t*, 
        xcb_get_property_reply *);
xcb_get_property_cookie_t xembed_info_get_unchecked(xcb_connection_t*,
        xcb_window_t);
bool xembed_info_get_reply(xcb_connection_t *connection,
        xcb_get_property_cookie_t cookie,
        xembed_info_t *info);
static inline void
xembed_focus_in(xcb_connection_t *c, xcb_window_t client, long focus_type)
{
    xembed_message_send(c, client, XEMBED_FOCUS_IN, focus_type, 0, 0);
}

static inline void
xembed_window_activate(xcb_connection_t *c, xcb_window_t client)
{
    xembed_message_send(c, client, XEMBED_WINDOW_ACTIVATE, 0, 0, 0);
}

static inline
void xembed_window_deactivate(xcb_connection_t *c, xcb_window_t client)
{
    xembed_message_send(c, client, XEMBED_WINDOW_DEACTIVATE, 0, 0, 0);
}

static inline 
void xembed_embedded_notify(xcb_connection_t *c,
        xcb_window_t client, xcb_window_t embedder,
        long version)
{
    xembed_message_send(c, client, XEMBED_EMBEDDED_NOTIFY, 0, embedder, version);
}

static inline void
xembed_window_unembed(xcb_connection_t *connection, xcb_window_t child,
        xcb_window_t root)
{
    xcb_reparent_window(connection, child, root, 0, 0);
}

static inline void
xembed_focus_out(xcb_connection_t *c, xcb_window_t client)
{
    xembed_message_send(c, client, XEMBED_FOCUS_OUT, 0, 0, 0);
}






















xcb_window_t tray_window;
xcb_screen_t *screen;
xcb_connection_t *c;

typedef struct {
    unsigned long version;
    unsigned long flags;
} xembed_info_t;

typedef struct xembed_window xembed_window_t;
struct xembed_window {
    xcb_window_t win;
    int pyhs_screen;
    xembed_info_t info;
};
 
int registed = false;

void tray_init()
{
    c = xcb_connect(NULL, NULL);
    tray_window = xcb_generate_id(c);
    screen = xcb_setup_roots_iterator(xcb_get_setup(c)).data;

    xcb_create_window(c,
            XCB_COPY_FROM_PARENT,
            tray_window,
            screen->root,
            0, 0,
            150, 150,
            10,
            XCB_WINDOW_CLASS_INPUT_OUTPUT,
            screen->root_visual,
            0, NULL);
    xcb_map_window(c, tray_window);
    xcb_flush(c);


}
void tray_register(int screen_number)
{
    xcb_client_message_event t ev;
    char *atom_name = "_NET_SYSTEM_TRAY_S0";
    xcb_intern_atom_cookie_t atom_systray_q;
    xcb_intern_atom_reply_t *atom_systray_r;
    xcb_atom_t atom_systray;
    if (registed == true)
        return;
    registed = true;
    atom_systray_q = xcb_intern_atom_unchecked(c, false, strlen(atom_name), atom_name);
    memset(ev, 0, sizeof(ev));
    ev.response_type = XCB_CLIENT_MESSAGE;
    ev.window = screen->root;
    ev.format = 32;
    ev.type = MANAGER;
    ev.data.data32[0] = XCB_CURRENT_TIME;
    ev.data.data32[2] = tray_window;
    ev.data.data32[3] = ev.data.data32[4] = 0;

    atom_systray_r = xcb_intern_atom_reply(c, atom_systray_q, NULL);
    if (!atom_systray_r) {
        printf("erro getting systray atom");
        return;
    }
    ev.data.data32[1] = atom_systray = atom_systray_r->atom;
    free(atom_systray_r);
    xcb_set_selection_onwer(c,
            tray_window, atom_systray, XCB_CURRENT_TIME);
    xcb_send_event(c, false, screen->root, 0xFFFFFF, (char*)&ev);


}

int tray_request_handle(xcb_window_t embed_win, int phys_screen, 
        xembed_info_t *info)
{
    xembed_window_t em;
    xcb_get_property_cookie_t em_cookie;
    const uint32_t select_input_val[] = {
        XCB_EVENT_MASK_STRUCTURE_NOTIFY
            | XCB_EVENT_MASK_PROPERTY_CHANGE
            | XCB_EVENT_MASK_ENTER_WINDOW
    };
    if (xembed_getbywin(&globalconf.embedded, embed_win))
        return -1;
    memset(&em_cookie, 0, sizeof(em_cookie));

    if (!info) 
        em_cookie = xembed_info_get_unchecked(c, embed_win);
    xcb_change_window_attributes(c, embed_win, XCB_CW_EVENT_MASK, select_input_val);

    window_state_set(embed_win, XCB_ICCM_WM_STATE_WITHDRAWN);
    xcb_change_save_set(c, XCB_SET_MODE_INSERT, embed_win);
    xcb_reparent_window(c, embed_win, tray_window, 0, 0);
    em.win = embed_win;
    em.phys_screen = phys_screen;

    if (info)
        em.info = *info;
    else
        xembed_info_get_reply(c, em_cookie, &em.info);

    xembed_embedded_notify(c, em.win, tray_window,
            MIN(XEMBED_VERSION, em.info.version));

    xembed_window_array_append(embeded, em);
    //widget_invalidate_bytype(widget_systray);
    return 0;
}

int tray_process_client_message(xcb_client_message_event_t *ev)
{
    int screen_nbr = 0, ret = 0;
    xcb_get_geometry_cookie_t geom_c;
    xcb_get_geometry_reply_t *geom_r;

    switch (ev->data.data32[1]) {
        case SYSTEM_TRAY_REQUEST_DOCK:
            geom_c = xcb_get_geometry_unchecked(c, ev->window);
            geom_r = xcb_get_geometry_reply(c, geom_c);
            if (!geom_r)
                return -1;
            free((void*)geom_r);

            ret = tray_request_handle(ev->data32[2], 0, NULL);
            break;
    }
    return ret;
}
int xembed_process_client_message(xcb_client_message_event_t *ev)
{
    switch(ev->data.data32[1]) {
        case XEMBED_REQUEST_FOCUS:
            xembed_focus_in(c, ev->window XEMBED_FOCUS_CURRENT);
            break;
    }
    return 0;
}

int main()
{
    tray_init();
}
