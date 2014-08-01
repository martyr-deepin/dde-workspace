MAX_SCALE = 1
ITEM_HEIGHT = 60.0
ITEM_WIDTH = 54.0

ICON_WIDTH = 48.0
ICON_HEIGHT = 48.0

DOCK_HEIGHT = 68.0
PANEL_HEIGHT = 60
PANEL_MARGIN = 36

PANEL_LEFT_IMAGE = 'img/panel/panel_left.svg'
PANEL_MIDDLE_IMAGE = 'img/panel/panel.svg'
PANEL_RIGHT_IMAGE = 'img/panel/panel_right.svg'

BOARD_IMG_PATH = "img/board.png"

BOARD_IMG_MARGIN_BOTTOM = 6.0

INDICATER_WIDTH = ITEM_WIDTH

THREE_MARGIN_STEP = 3.0
TWO_MARGIN_STEP = 2.0


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


#below should not modify
INDICATER_IMG_MARGIN_LEFT = "#{(ITEM_WIDTH - INDICATER_WIDTH) / ITEM_WIDTH * 100}%"
BOARD_IMG_MARGIN_LEFT = "#{((ITEM_WIDTH - ICON_WIDTH) / 2) / ITEM_WIDTH  * 100}%"

IN_INIT = true

NOT_FOUND_ICON = DCore.get_theme_icon("application-default-icon", 48)

ICON_SCALE = MAX_SCALE  #this will be modify on runtime

EMPTY_TRASH_ICON = "user-trash"
FULL_TRASH_ICON = "user-trash-full"

SHORT_INDICATOR = "img/indicator-short.svg"
LONG_INDICATOR = "img/indicator-long.svg"

ITEM_TYPE_NULL = ''
ITEM_TYPE_APP = "App"
ITEM_TYPE_APPLET = "Applet"
ITEM_TYPE_RICH_DIR = "RichDir"

WEEKDAY = ["SUN", "MON", "TUE", "WEN", "THU", "FRI", "STA"]

DIGIT_CLOCK =
    'bg':'img/digit-clock.svg'
    'id':'dde_digit_clock'
    'type': "digit"

ANALOG_CLOCK =
    'bg':'img/analog-clock.svg'
    'id':'dde_analog_clock'
    'type': "analog"

OFFSET_DOWN = 7
DEEPIN_APPTRAY = "dapptray"
NOTIFY_FLAG = "img/bage.svg"


OPENING_INDICATOR = "img/opening-indicator.png"
OPEN_INDICATOR = "img/open-indicator.png"

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

ANIMATION_TIME = 400

TRASH_ID = "filemanager-trash"

INSERT_INDICATOR_WIDTH = 57

TIME_ID = "AppletDateTime"

READY_FOR_TRAY_ICONS = false
