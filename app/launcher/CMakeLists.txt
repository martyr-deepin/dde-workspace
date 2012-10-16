SET(NAME "launcher")
SET(SRC_LIST menu_test.c)

add_subdirectory(libmenu)


add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} menu ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} /usr/include/X11/)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
