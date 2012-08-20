set(NAME "taskbar")
AUX_SOURCE_DIRECTORY(. SRC_LIST)

add_executable(${NAME} ${SRC_LIST})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

target_link_libraries(${NAME} dwebkit ${DWEBVIEW_LIBRARIES} X11)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
