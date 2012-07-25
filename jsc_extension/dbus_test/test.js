
var b = document.getElementById("sc");
b.addEventListener("click", function() {
    var rand = Math.random();

    shell = Desktop.DBus.session_object("org.gnome.Shell", "/org/gnome/Shell", "org.gnome.Shell");

    shell.Screenshot(true, true, "/dev/shm/test_png/test_" + rand + ".png");

    var img = new Image();
    img.onload = function() {
        var canv = document.getElementById("can");
        var ctx = can.getContext('2d');
        ctx.clearRect(0, 0, 1024, 800);
        ctx.drawImage(img, 0, 0, 1024, 800);
    }
    img.src = "/dev/shm/test_png/test_" + rand + ".png";
});



