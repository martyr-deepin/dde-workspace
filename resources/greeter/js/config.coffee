VERSION = " "  #RC Beta

CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
ANIMATION_TIME = 2
# SCANNING_TIP = _("Scanning in 3 seconds")

ESC_KEY = 27
ENTER_KEY = 13
LEFT_ARROW = 37
RIGHT_ARROW = 39

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


is_auto_login = (username) ->
    #delete this function 
    return false
    if is_greeter then return DCore.Greeter.user_need_password(username)
    else return DCore.Lock.need_password(username)

is_disable_user = (username)->
    disable = false
    Dbus_Account = DCore.DBus.sys("org.freedesktop.Accounts")
    users_path = Dbus_Account.ListCachedUsers_sync()
    for u in users_path
        user_dbus = DCore.DBus.sys_object("org.freedesktop.Accounts",u,"org.freedesktop.Accounts.User")
        if username is user_dbus.UserName
            if user_dbus.Locked is null then disable = false
            else if user_dbus.Locked is true then disable = true
            return disable
