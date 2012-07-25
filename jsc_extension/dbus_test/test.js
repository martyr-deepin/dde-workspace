
var s = Desktop.DBus.session_bus()
window.test = Desktop.DBus.get_object(s, "orz.test", "/orz/test", "orz.test")

var ret = test.fas(1);
if (ret != 1) {
    console.log("fas ERROR")
}


