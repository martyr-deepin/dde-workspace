add_library(ddock_test dock_test.c dock_test_config.c
    dock_test_dominant_color.c dock_test_draw.c dock_test.h
    dock_test_handle_icon.c dock_test_hide.c dock_test_launcher.c
    dock_test_region.c dock_test_special_window.c dock_test_tasklist.c
    dock_test_tray.c)

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})
include_directories(..)

target_link_libraries(ddock_test dcom dentry dbus dtest tray ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES})
