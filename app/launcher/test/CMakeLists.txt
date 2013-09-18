pkg_check_modules(glib REQUIRED glib-2.0)
pkg_check_modules(gio REQUIRED gio-2.0)
pkg_check_modules(gtk REQUIRED gtk+-3.0)
pkg_check_modules(webkit REQUIRED webkitgtk-3.0)


set(test_bg launcher_test_bg_switch)
add_executable(${test_bg} switch_background.c)
include_directories(${test_bg} ${glib_INCLUDE_DIRS} ${gio_INCLUDE_DIRS})
target_link_libraries(${test_bg} ${glib_LIBRARIES} ${gio_LIBRARIES})

set(test_deepin_webkit_change_bg launcher_test_deepin_webkit_bg_switch)
add_executable(${test_deepin_webkit_change_bg} deepin_webkit_change_bg.c)
include_directories(${DWEBVIEW_INCLUDE_DIRS})
target_link_libraries(${test_deepin_webkit_change_bg} dcom ${DWEBVIEW_LIBRARIES})

set(test_gtk_webkit_change_bg launcher_test_gtk_webkit_bg_switch)
add_executable(${test_gtk_webkit_change_bg} gtk_webkit_change_bg.c)
target_link_libraries(${test_gtk_webkit_change_bg} ${gtk_LIBRARIES}
    ${webkit_LIBRARIES})
include_directories(${test_gtk_webkit_change_bg} ${gtk_INCLUDE_DIRS}
    ${webkit_INCLUDE_DIRS})
