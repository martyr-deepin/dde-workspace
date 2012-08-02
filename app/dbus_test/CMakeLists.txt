add_executable(dbus_test web.c)

include_directories(${DWEBVIEW_INCLUDE_DIRS})
target_link_libraries(dbus_test dwebkit ${DWEBVIEW_LIBRARIES})
