var DBus = Desktop.DBus;

// First create your DBus Object with bus_name, path, interface
var gshell = DBus.session_object("org.gnome.Shell", "/org/gnome/Shell", "org.gnome.Shell");
//or use the simple function
var gshell_simple  = DBus.session("org.gnome.Shell");

// after this the gshell is a starnd JavaScript Object
// all dbus remote object's method and property export to this JS Object.
// except the "connect" and "emit" function which is used for signals.

// your can call method like below,  method default is call by async.
// and you can get the sync version with call func_name+ " _sync"
gshell.ListExtensions(function(ret) {}, function (error) {});
gshell.ListExtensions(function(ret) {}); // ignore error callback
gshell.Screenshot(true, true, "/dev/shm/screen.png"); //ignore all callback

infos = gshell.ListExtensions_sync()

// the property is simple, but be careful
// not all property are write able.

gshell.OverviewActive = true;  //thsi proeprty is writetable.
ver = gshell.ApiVersion;   //this property is read only.


// signals is also simple.
id = gshell.connect("ExtensionStatusChanged", function(uuid, state, error) {
    alert("extension" + uuid + "now state:" + state);
});


// below API hasn't implementation now.
//
// and can disconnect (hasn't implementation because of lack time)
gshell.disconnect(id);

// and can emit the signal (is this need implementation?)
gshell.emit("ExtensionStatusChanged", uuid, state, "");

