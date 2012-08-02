SET(NAME "desktop")
SET(SRC_LIST desktop.c)


add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dwebkit ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS})
