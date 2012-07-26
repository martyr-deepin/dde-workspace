shell = Desktop.DBus.session_object("org.gnome.Shell", "/org/gnome/Shell", "org.gnome.Shell");
test = Desktop.DBus.session_object("org.snyh.test", "/org/snyh/test", "org.snyh.test");

var b1 = document.getElementById("b1");
b1.addEventListener("click", function() {
    var path = "/dev/shm/test_" + Math.random() + ".png";

    shell.Screenshot_sync(true, true, path);

    var img = new Image();
    img.onload = function() {
        var canv = document.getElementById("can");
        var ctx = can.getContext('2d');
        ctx.clearRect(0, 0, 1024, 800);
        ctx.drawImage(img, 0, 0, 1024, 800);
        Desktop.Core.run_command("rm -rf " + path);
    }
    img.src = path;
});



var b2 = document.getElementById("b2");
b2.addEventListener("click", function() {
    shell.OverviewActive = true;
    setTimeout(function(){shell.OverviewActive=false;}, 1000);
});

var b3 = document.getElementById("b3");
b3.addEventListener("click", function() {
    test.es(1,
        function(){
            alert("funciton reply OK");
        },
        function() {
            alert("function reply error");
        }
    );
});


test = Desktop.DBus.session_object("org.snyh.test",
        "/org/snyh/test", "org.snyh.test");
test.connect("t_sig", function(a, b, c) {
    console.log(a, b, c);
});
