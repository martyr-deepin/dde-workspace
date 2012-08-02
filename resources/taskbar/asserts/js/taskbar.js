DDesktop = new Object();

DDesktop.init_region = function() {
    Desktop.Core.modify_region(1, 0, 0, 0, window.screen.availWidth, $("#toolbar").height());
    Desktop.Core.modify_region(0, 0, 0, 0, 0, 0);
    //Desktop.Core.modify_region(DCore.GLOBAL_REGION, DCore.REGION_OP_NEW, 0, 0, 1024, 30);
}
DDesktop.apply_region = function(x, y, w, h) {
    Desktop.Core.modify_region(0, 1, x, y, w, h);
}
DDesktop.clear_region = function() {
    Desktop.Core.modify_region(0, 0, 0, 0, 0, 0);
}

DDesktop.init_region();


toggle = false;
$('#tb').click(function() {
    var h = $("#hwindow")
    b = $(this);
    p = b.position();
    if (toggle) {
        h.hide();
        DDesktop.clear_region();
    } else {
        top = p.top + b.outerHeight()+ 10;
        left = p.left + b.outerWidth() / 2;
        h[0].style.top = top
        h[0].style.left = left;

        pos = h.position();

        DDesktop.apply_region(left, top, h.outerWidth() + 23, h.outerHeight() + 23);
        h.show();
    }
    toggle = !toggle;
});
$('#tb1').click(function() {
    var h = $("#hwindow")
    b = $(this);
    p = b.position();
    if (toggle) {
        h.hide();
        DDesktop.clear_region();
    } else {
        top = p.top + b.outerHeight()+ 10;
        left = p.left + b.outerWidth() / 2;
        h[0].style.top = top
        h[0].style.left = left;

        pos = h.position();

        DDesktop.apply_region(
            left, top,
            h.outerWidth() + 23, h.outerHeight() + 23
        );
        h.show();
    }
    toggle = !toggle;
});
