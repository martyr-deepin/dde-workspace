LAUNCHER_DAEMON="com.deepin.dde.daemon.Launcher"
daemon = DCore.DBus.session(LAUNCHER_DAEMON)

ITEM_WIDTH = 160
ITEM_HEIGHT = 160

CONTAINER_BOTTOM_MARGIN = 70
SEARCH_BAR_HEIGHT = 120

SCROLL_STEP_LEN = ITEM_HEIGHT

CATEGORY_ID =
    ALL: -1
    OTHER: -2
    FAVOR: -3

NUM_SHOWN_ONCE = 10

ITEM_IMG_SIZE = 48

GRID_MARGIN_BOTTOM = 30

KEYCODE.BACKSPACE = 8
KEYCODE.TAB = 9
KEYCODE.P = 80
KEYCODE.N = 78
KEYCODE.B = 66
KEYCODE.F = 70

HIDDEN_ICONS_MESSAGE =
    true: _("_Hide hidden icons")
    false: _("_Display hidden icons")

ITEM_HIDDEN_ICON_MESSAGE =
    'display': _("_Hide this icon")
    'hidden': _("_Display this icon")

HIDE_ICON_CLASS = 'hide_icon'

AUTOSTART_MESSAGE =
    false: _("_Add to autostart")
    true: _("_Remove from autostart")

AUTOSTART_ICON =
    NAME: "emblem-autostart"
    SIZE: 16

SOFTWARE_STATE =
    IDLE: 0
    UNINSTALLING: 1
    INSTALLING: 2

_b = document.body
