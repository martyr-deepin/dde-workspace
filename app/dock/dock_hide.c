#include "dock_hide.h"
#include "region.h"
#include <gtk/gtk.h>

extern int _dock_height;
extern void _change_workarea_height(int height);
extern void update_dock_hide_mode();
extern GdkWindow* DOCK_GDK_WINDOW();

enum Event {
    TriggerShow,
    TriggerHide,
    ShowNow,
    HideNow,
};
static void handle_event(enum Event ev);
static void _cancel_detect_hide_mode();

enum State {
    StateShow,
    StateShowing,
    StateHidden,
    StateHidding,
} CURRENT_STATE = StateShow;

gboolean dock_is_hidden()
{
    if (CURRENT_STATE == StateHidding)
        return TRUE;
    else
        return FALSE;
}

static void set_state(enum State new_state)
{
    /*char* StateStr[] = { "StateShow", "StateShowing", "StateHidden", "StateHidding"};*/
    /*printf("from %s to %s\n", StateStr[CURRENT_STATE], StateStr[new_state]);*/
    CURRENT_STATE = new_state;
}


static void enter_show()
{
    set_state(StateShow);
    _change_workarea_height(_dock_height);
    gdk_window_move(DOCK_GDK_WINDOW(), 0, 0);
    dock_region_restore();
}
static void enter_hide()
{
    dock_region_save();

    set_state(StateHidden);
    _change_workarea_height(0);
    gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height-3);

    extern int _screen_width;
    dock_require_region(0, 0, _screen_width, 3);
}

#define SHOW_HIDE_ANIMATION_STEP 6
#define SHOW_HIDE_ANIMATION_INTERVAL 40
static gboolean do_hide_animation(int data);
static gboolean do_show_animation(int data);
static guint _animation_show_id = 0;
static guint _animation_hide_id = 0;

static void _cancel_animation()
{
    if (_animation_show_id != 0) {
        g_source_remove(_animation_show_id);
        _animation_show_id = 0;
    }
}
static void enter_hidding()
{
    set_state(StateHidding);
    _cancel_animation();
    do_hide_animation(_dock_height);
}
static void enter_showing()
{
    set_state(StateShowing);
    _cancel_animation();
    do_show_animation(0);
}

static void handle_event(enum Event ev)
{
    switch (CURRENT_STATE) {
        case StateShow: {
                            switch (ev) {
                                case TriggerShow:
                                    break;
                                case TriggerHide:
                                    enter_hidding(); break;
                                case ShowNow:
                                    break;
                                case HideNow:
                                    enter_hide(); break;
                                default:
                                    g_assert_not_reached();
                            }
                            break;
                        }
        case StateShowing: {
                               switch (ev) {
                                   case TriggerShow:
                                       break;
                                   case TriggerHide:
                                       enter_hidding(); break;
                                   case ShowNow:
                                       enter_show(); break;
                                   case HideNow:
                                       enter_hide(); break;
                                   default:
                                       g_assert_not_reached();
                               }
                               break;
                           }
        case StateHidden: {
                              switch (ev) {
                                  case TriggerShow:
                                      enter_showing(); break;
                                  case TriggerHide:
                                      break;
                                  case ShowNow:
                                      enter_show(); break;
                                  case HideNow:
                                      break;
                                  default:
                                      g_assert_not_reached();
                              }
                              break;
                          }
        case StateHidding: {
                               switch (ev) {
                                   case TriggerShow:
                                       enter_showing(); break;
                                   case TriggerHide:
                                       break;
                                   case ShowNow:
                                       enter_show(); break;
                                   case HideNow:
                                       enter_hide(); break;
                                   default:
                                       g_assert_not_reached();
                               }
                               break;
                           }
    };
}



static gboolean do_show_animation(int current_height)
{
    if (CURRENT_STATE != StateShowing) return FALSE;

    if (current_height <= _dock_height) {
        gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_show_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_show_animation,
                GINT_TO_POINTER(current_height + SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(ShowNow);
    }
    return FALSE;
}

static gboolean do_hide_animation(int current_height)
{
    if (CURRENT_STATE != StateHidding) return FALSE;

    if (current_height >= 0) {
        gdk_window_move(DOCK_GDK_WINDOW(), 0, _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_hide_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_hide_animation,
                GINT_TO_POINTER(current_height - SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(HideNow);
    }
    return FALSE;
}


static gboolean do_hide_dock()
{
    handle_event(TriggerHide);
    return FALSE;
}
static gboolean do_show_dock()
{
    handle_event(TriggerShow);
    return FALSE;
}

static guint _delay_id = 0;
static void _cancel_delay()
{
    if (_delay_id != 0) {
        g_source_remove(_delay_id);
        _delay_id = 0;
    }
}
void dock_delay_show(int delay)
{
    _cancel_detect_hide_mode();
    if (CURRENT_STATE == StateHidding) {
        do_show_dock();
    } else {
        _cancel_delay();
        _delay_id = g_timeout_add(delay, do_show_dock, NULL);
    }
}
void dock_delay_hide(int delay)
{
    _cancel_detect_hide_mode();
    _cancel_delay();
    _delay_id = g_timeout_add(delay, do_hide_dock, NULL);
}

void dock_show_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerShow);
}
void dock_hide_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerHide);
}

static guint _detect_hide_mode_id = 0;
static void _cancel_detect_hide_mode()
{
    if (_detect_hide_mode_id != 0) {
        g_source_remove(_detect_hide_mode_id);
        _detect_hide_mode_id = 0;
    }
}
void dock_toggle_show()
{
    if (CURRENT_STATE == StateHidden || CURRENT_STATE == StateHidding) {
        handle_event(TriggerShow);
    } else if (CURRENT_STATE == StateShow || CURRENT_STATE == StateShowing) {
        handle_event(TriggerHide);
    }
    _detect_hide_mode_id = g_timeout_add(3000, (GSourceFunc)update_dock_hide_mode, NULL);
}
