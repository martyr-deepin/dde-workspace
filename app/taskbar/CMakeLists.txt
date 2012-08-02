set(NAME "taskbar")
AUX_SOURCE_DIRECTORY(. SRC_LIST)

add_executable(${NAME} ${SRC_LIST})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

target_link_libraries(${NAME} dwebkit ${DWEBVIEW_LIBRARIES} X11)
