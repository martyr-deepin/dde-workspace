
window.test = Desktop.DBus.session_object("orz.test", "/orz/test", "orz.test")

var ret = test.fas(1);
if (ret != 1) {
    console.log("fas ERROR")
}


