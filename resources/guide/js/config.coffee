DEBUG = false
primary_info =
    x:0
    y:0
    width:1366
    height:768

#launcher
COLLECT_LEFT = 130
EACH_APP_HEIGHT = 120
EACH_APP_WIDTH = 120
EACH_APP_MARGIN_LEFT = 40
EACH_APP_MARGIN_TOP = 60

COLLECT_APP_NUMBERS = 10
COLLECT_TOP = 84

CATE_TOP_DELTA = 5
CATE_LEFT = 27
CATE_NUMBERS = 7
CATE_EACH_HEIGHT = 62
CATE_EACH_WIDTH = 62
CATE_WIDTH = CATE_EACH_WIDTH
CATE_HEIGHT = CATE_EACH_HEIGHT * CATE_NUMBERS

COLLECT_WIDTH = primary_info.width - COLLECT_LEFT * 2
COLLECT_APP_ROWS = Math.floor((COLLECT_APP_NUMBERS * EACH_APP_WIDTH + (COLLECT_APP_NUMBERS - 1) * EACH_APP_MARGIN_LEFT) / COLLECT_WIDTH)
COLLECT_HEIGHT = COLLECT_APP_ROWS * EACH_APP_HEIGHT + (COLLECT_APP_ROWS - 1) * EACH_APP_MARGIN_TOP
APP_NUM_MAX_IN_ONE_ROW = Math.floor((COLLECT_WIDTH + EACH_APP_MARGIN_LEFT) / (EACH_APP_WIDTH + EACH_APP_MARGIN_LEFT))

#dock

DisplayMode =
    Fashion: 0
    Efficient: 1
    Classic: 2

POINTER_AREA_SIZE = {}
POINTER_AREA_SIZE[DisplayMode.Fashion] = 64
POINTER_AREA_SIZE[DisplayMode.Efficient] = 38
POINTER_AREA_SIZE[DisplayMode.Classic] = 30


ICON_SIZE = {}
ICON_SIZE[DisplayMode.Fashion] = {w:48,h:48}
ICON_SIZE[DisplayMode.Efficient] = {w:32,h:32}
ICON_SIZE[DisplayMode.Classic] = {w:24,h:24}

DOCK_PADDING = {}
DOCK_PADDING[DisplayMode.Fashion] = [5,30,10,30]#top right bottom left
DOCK_PADDING[DisplayMode.Efficient] = [1,0,0,0]
DOCK_PADDING[DisplayMode.Classic] = [3,24,10,24]

ICON_MARGIN = {}
ICON_MARGIN[DisplayMode.Fashion] = 7
ICON_MARGIN[DisplayMode.Efficient] = 3
ICON_MARGIN[DisplayMode.Classic] = 7

ITEM_SIZE = {}

DOCK_LAUNCHER_ICON_INDEX = {}
DOCK_LAUNCHER_ICON_INDEX[DisplayMode.Fashion] = 1
DOCK_LAUNCHER_ICON_INDEX[DisplayMode.Efficient] = 1
DOCK_LAUNCHER_ICON_INDEX[DisplayMode.Classic] = 1

DOCK_DSS_ICON_INDEX = {}
DOCK_DSS_ICON_INDEX[DisplayMode.Fashion] = 8
DOCK_DSS_ICON_INDEX[DisplayMode.Efficient] = 8
DOCK_DSS_ICON_INDEX[DisplayMode.Classic] = 8

_dm = DCore.Guide.get_dock_displaymode()
ITEM_SIZE[_dm] =
    w:ICON_MARGIN[_dm] + ICON_SIZE[_dm].w + ICON_MARGIN[_dm]
    h:DOCK_PADDING[_dm][0] + ICON_SIZE[_dm].w + DOCK_PADDING[_dm][0]
#others
ESC_KEYSYM_TO_CODE = 0xff08

CLICK_TYPE =
    leftclick:1
    copy:2
    rightclick:3
    scrollup:4
    scrolldown:5

pages_id = [
    "Welcome",
    "Start",
    "LauncherLaunch",
    "LauncherCollect",
    "LauncherAllApps",
    "LauncherScroll"
]

t_switch_page = 4000
t_mid_switch_page = 2000
t_min_switch_page = 500
t_check_if_done = 10000

POS_TYPE =
    leftup:"leftup"
    leftdown:"leftdown"
    rightup:"rightup"
    rightdown:"rightdown"
    down:"down"
    up:"up"

each_item_update_times = 3
desktop_file_numbers = 2
