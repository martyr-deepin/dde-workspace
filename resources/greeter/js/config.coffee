VERSION = " "  #RC Beta
CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
LOGIN_FAILED_TIP_TEXT = "Oops~无法识别您的面部信息，请点击头像重试或点击用户ID切换到密码输入"

ESC_KEY = 27
ENTER_KEY = 13

APP_NAME = ''
is_greeter = null
is_hide_users = null

try
    DCore.Greeter.get_date()
    is_greeter = true
    APP_NAME = "Greeter"
catch error
    is_greeter = false
    APP_NAME = "Lock"

if is_greeter
    is_hide_users = DCore.Greeter.is_hide_users()
else
    is_hide_users = false






