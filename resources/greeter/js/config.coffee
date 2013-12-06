VERSION = " "  #RC Beta

CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
ANIMATION_TIME = 2
# SCANNING_TIP = _("Scanning in 3 seconds")
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
    #is_hide_users = DCore.Greeter.is_hide_users()
    is_hide_users = false
else
    is_hide_users = false

de_menu = null


audioplay = new AudioPlay()
audio_play_status = audioplay.get_launched_status()
if audioplay.getTitle() is undefined then audio_play_status = false
is_volume_control = false
echo "audio_play_status:#{audio_play_status}"

enable_detection = (enabled)->
    DCore[APP_NAME].enable_detection(enabled)

