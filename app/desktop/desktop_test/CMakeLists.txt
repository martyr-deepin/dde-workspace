SET(SRC_LIST desktop_test.c)
ADD_library(desktop_test ${SRC_LIST})

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})
include_directories(..)

target_link_libraries(desktop_test dcom dentry dbus ${DWEBVIEW_LIBRARIES} dtest)
