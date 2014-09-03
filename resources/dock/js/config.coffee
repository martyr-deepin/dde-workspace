MAX_SCALE = 1
CLASSIC_MAX_WIDTH = 160
CLASSIC_MIN_WIDTH = 40
HideMode =
    KeepShowing: 0
    KeepHidden: 1
    AutoHide: 2

HideModeNameMap =
    "keep-showing": 0
    "keep-hidden": 1
    "auto-hide": 2

DisplayMode =
    Fashion: 0
    Efficient: 1
    Classic: 2
DisplayName = ["fashion", "efficient", "classic"]
DisplayModeNameMap =
    "fashion": 0
    "efficient": 1
    "classic": 2

ALL_ITEM_HEIGHT = {}
ALL_ITEM_HEIGHT[DisplayMode.Fashion] = 60.0
ALL_ITEM_HEIGHT[DisplayMode.Efficient] = 46.0
ALL_ITEM_HEIGHT[DisplayMode.Classic] = 32.0
ITEM_HEIGHT = 60.0

ALL_ITEM_WIDTH = {}
ALL_ITEM_WIDTH[DisplayMode.Fashion] = 54.0
ALL_ITEM_WIDTH[DisplayMode.Efficient] = 48.0
ALL_ITEM_WIDTH[DisplayMode.Classic] = 160.0 # max
ITEM_WIDTH = 54.0

ALL_ICON_WIDTH = {}
ALL_ICON_WIDTH[DisplayMode.Fashion] = 48.0
ALL_ICON_WIDTH[DisplayMode.Efficient] = 32.0
ALL_ICON_WIDTH[DisplayMode.Classic] = 24.0
ICON_WIDTH = 48.0

ALL_ICON_HEIGHT = {}
ALL_ICON_HEIGHT[DisplayMode.Fashion] = 48.0
ALL_ICON_HEIGHT[DisplayMode.Efficient] = 32.0
ALL_ICON_HEIGHT[DisplayMode.Classic] = 36.0
ICON_HEIGHT = 48.0

ALL_DOCK_HEIGHT = {}
ALL_DOCK_HEIGHT[DisplayMode.Fashion] = 68.0
ALL_DOCK_HEIGHT[DisplayMode.Efficient] = 48.0
ALL_DOCK_HEIGHT[DisplayMode.Classic] = 36.0
DOCK_HEIGHT = 68.0

ALL_PANEL_HEIGHT = {}
ALL_PANEL_HEIGHT[DisplayMode.Fashion] = 60.0
ALL_PANEL_HEIGHT[DisplayMode.Efficient] = 48.0
ALL_PANEL_HEIGHT[DisplayMode.Classic] = 36.0
PANEL_HEIGHT = 60

PANEL_MARGIN = 36

PANEL_LEFT_IMAGE = 'img/fashion/panel/panel_left.svg'
PANEL_MIDDLE_IMAGE = 'img/fashion/panel/panel.svg'
PANEL_RIGHT_IMAGE = 'img/fashion/panel/panel_right.svg'

BOARD_IMG_PATH = "img/board.png"

BOARD_IMG_MARGIN_BOTTOM = 6.0

INDICATER_WIDTH = ITEM_WIDTH

THREE_MARGIN_STEP = 3.0
TWO_MARGIN_STEP = 2.0

ALL_ITEM_MENU_OFFSET = {}
ALL_ITEM_MENU_OFFSET[DisplayMode.Fashion] = 0
ALL_ITEM_MENU_OFFSET[DisplayMode.Efficient] = 2
ALL_ITEM_MENU_OFFSET[DisplayMode.Classic] = 2
ITEM_MENU_OFFSET = 0

PREVIEW_BOTTOM = {}
PREVIEW_BOTTOM[DisplayMode.Fashion] = 64.0
PREVIEW_BOTTOM[DisplayMode.Efficient] = 48.0
PREVIEW_BOTTOM[DisplayMode.Classic] = 36.0
PREVIEW_CORNER_RADIUS = 4
PREVIEW_SHADOW_BLUR = 6
PREVIEW_CONTAINER_HEIGHT = 160
PREVIEW_CONTAINER_BORDER_WIDTH = 2
PREVIEW_BORDER_LENGTH = 5.0
PREVIEW_WINDOW_WIDTH = 230.0
PREVIEW_WINDOW_HEIGHT = 130.0
PREVIEW_WINDOW_MARGIN = 15
PREVIEW_WINDOW_BORDER_WIDTH = 1
PREVIEW_CANVAS_WIDTH = PREVIEW_WINDOW_WIDTH - PREVIEW_WINDOW_BORDER_WIDTH * 2
PREVIEW_CANVAS_HEIGHT = PREVIEW_WINDOW_HEIGHT - PREVIEW_WINDOW_BORDER_WIDTH * 2
PREVIEW_TRIANGLE =
    width: 18
    height: 10
PREVIEW_CLOSE_BUTTON = "img/fashion/close_normal.png"
PREVIEW_CLOSE_HOVER_BUTTON = "img/fashion/close_hover.png"


#below should not modify
INDICATER_IMG_MARGIN_LEFT = "#{(ITEM_WIDTH - INDICATER_WIDTH) / ITEM_WIDTH * 100}%"
BOARD_IMG_MARGIN_LEFT = "#{((ITEM_WIDTH - ICON_WIDTH) / 2) / ITEM_WIDTH  * 100}%"

IN_INIT = true

NOT_FOUND_ICON = DCore.get_theme_icon("application-default-icon", 48)

ICON_SCALE = MAX_SCALE  #this will be modify on runtime

EMPTY_TRASH_ICON = "user-trash"
FULL_TRASH_ICON = "user-trash-full"

SHORT_INDICATOR = "img/fashion/indicator-short.svg"
LONG_INDICATOR = "img/fashion/indicator-long.svg"

EFFICIENT_ACTIVE_IMG = "img/efficient/active.png"
EFFICIENT_ACTIVE_HOVER_IMG = 'img/efficient/active_hover.png'

CLASSIC_ACTIVE_IMG = 'img/classic/active.png'
CLASSIC_ACTIVE_HOVER_IMG = 'img/classic/active_hover.png'

ITEM_TYPE_NULL = ''
ITEM_TYPE_APP = "App"
ITEM_TYPE_APPLET = "Applet"
ITEM_TYPE_RICH_DIR = "RichDir"

WEEKDAY = ["SUN", "MON", "TUE", "WEN", "THU", "FRI", "STA"]

DIGIT_CLOCK =
    'bg':'img/fashion/digit-clock.svg'
    'id':'dde_digit_clock'
    'type': "digit"

ANALOG_CLOCK =
    'bg':'img/fashion/analog-clock.svg'
    'id':'dde_analog_clock'
    'type': "analog"

DEEPIN_APPTRAY = "dapptray"
NOTIFY_FLAG = "img/bage.svg"


OPENING_INDICATOR = "img/fashion/opening-indicator.png"
OPEN_INDICATOR = "img/fashion/open-indicator.png"

ITEM_TYPE =
    app: "App"
    applet: "Applet"

ITEM_STATUS=
    normal: "normal"
    active: "active"
    invalid: "invalid"

ITEM_DATA_FIELD =
    title: "title"
    icon: "icon"
    xids: "app-xids"
    status: "app-status"
    menu: "menu"

SHOW_HIDE_ANIMATION_TIME = 250

TRASH_ID = "filemanager-trash"

INSERT_INDICATOR_WIDTH = 57

TIME_ID = "AppletDateTime"

READY_FOR_TRAY_ICONS = false

TRAY_ICON_WIDTH = 16
TRAY_ICON_HEIGHT = 16
TRAY_ICON_MARGIN = 8
