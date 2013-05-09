file(GLOB TEST_SRC *.c)

add_library(ddock_test ${TEST_SRC})

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})
include_directories(..)

target_link_libraries(ddock_test dcom dentry dbus dtest tray ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES})
