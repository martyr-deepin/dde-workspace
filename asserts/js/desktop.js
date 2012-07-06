var icons = DCore.get_desktop_icons()

for (i in icons) {
    $("#iconContainer").append($("#icontemp").render({
        "name" :icons[i].name,
        "icon": icons[i].icon,
        "exec": icons[i].exec
    })
    );
}

$(function() {
    $(".item").draggable();
    $(".item").dblclick(function() {
        var exec = $(this)[0].getAttribute('exec');
        DCore.run_command(exec);
    });
    $(".item").click(function() {
        $(this)[0].tablIndex = 0;
    });
});
