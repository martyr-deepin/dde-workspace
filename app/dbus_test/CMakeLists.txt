set(NAME "dbus_test")
add_executable(${NAME} web.c)

include_directories(${DWEBVIEW_INCLUDE_DIRS})
target_link_libraries(${NAME} dwebkit ${DWEBVIEW_LIBRARIES})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
