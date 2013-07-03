file(GLOB TEST_SRC *.c)

add_library(desktop_test ${TEST_SRC})

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})
include_directories(..)

target_link_libraries(desktop_test dcom dentry dbus dtest tray ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES})
