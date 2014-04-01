VERSION = "2.0"  #RC Beta

PasswordMaxlength = 16 #default 16

CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
ANIMATION_TIME = 2
APP_NAME = ''
is_greeter = null
is_hide_users = null
hide_face_login = null

try
    DCore.Greeter.get_date()
    echo "check is_greeter succeed!"
    is_greeter = true
    APP_NAME = "Greeter"
catch error
    echo "check is_greeter error:#{error}"
    is_greeter = false
    APP_NAME = "Lock"

if is_greeter
    is_hide_users = DCore.Greeter.is_hide_users()
else
    is_hide_users = false
is_hide_users = false

de_menu = null


audioplay = new AudioPlay()
audio_play_status = audioplay.get_launched_status()
if audio_play_status
    if audioplay.getTitle() is undefined then audio_play_status = false
is_volume_control = false
echo "audio_play_status:#{audio_play_status}"

enable_detection = (enabled)->
    try
        DCore[APP_NAME].enable_detection(enabled)
    catch e
        echo "enable_detection #{e}"
    finally
        return null

hideFaceLogin = ->
    try
        face = DCore[APP_NAME].enable_detection()
        return face
    catch e
        echo "face_login #{e}"
        return false
    finally
        return false
hide_face_login = hideFaceLogin()

is_livecd = false
try
    LOCK = "com.deepin.dde.lock"
    dbus = DCore.DBus.sys(LOCK)
    is_livecd = dbus.IsLiveCD_sync(DCore.Lock.get_username())
catch error
    is_livecd = false
     
detect_is_from_lock = ->
    from_lock = false
    if is_greeter
        from_lock = localStorage.getItem("from_lock")
    localStorage.setItem("from_lock",false)
    return from_lock

is_support_guest = false
try
    is_support_guest = DCore.Greeter.is_support_guest() if is_greeter
catch e
    echo "#{e}"
is_support_guest = false


PowerManager = null
ANIMATION = false
