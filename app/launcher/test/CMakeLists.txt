pkg_check_modules(glib REQUIRED glib-2.0)
pkg_check_modules(gio REQUIRED gio-2.0)
pkg_check_modules(gtk REQUIRED gtk+-3.0)
pkg_check_modules(webkit REQUIRED webkitgtk-3.0)

include_directories(
    ${gtk_INCLUDE_DIRS}
    ${webkit_INCLUDE_DIRS}
    ${glib_INCLUDE_DIRS}
    ${gio_INCLUDE_DIRS}
    ${DWEBVIEW_INCLUDE_DIRS}
    )

set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/_launcher_test)
set(test_bg launcher_test_bg_switch)
add_executable(${test_bg} switch_background.c)
target_link_libraries(${test_bg} ${glib_LIBRARIES} ${gio_LIBRARIES})

set(test_deepin_webkit_change_bg launcher_test_deepin_webkit_bg_switch)
add_executable(${test_deepin_webkit_change_bg} deepin_webkit_change_bg.c)
target_link_libraries(${test_deepin_webkit_change_bg} dcom ${DWEBVIEW_LIBRARIES})

set(test_gtk_webkit_change_bg launcher_test_gtk_webkit_bg_switch)
add_executable(${test_gtk_webkit_change_bg} gtk_webkit_change_bg.c)
target_link_libraries(${test_gtk_webkit_change_bg} ${gtk_LIBRARIES}
    ${webkit_LIBRARIES})

set(test_get_pkg_name launcher_test_get_pkg_name)
add_executable(${test_get_pkg_name} test_get_pkg_name.c)
target_link_libraries(${test_get_pkg_name} ${gio_LIBRARIES} ${glib_LIBRARIES}
    ${DWEBVIEW_LIBRARIES} dtest dcom)


file(GLOB TEST_SRC *_test.c)
add_library(dlauncher_test ${TEST_SRC})
target_link_libraries(dlauncher_test dcom dentry dbus dtest ${DWEBVIEW_LIBRARIES})
include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})
include_directories(..)
