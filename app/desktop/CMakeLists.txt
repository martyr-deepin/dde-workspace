SET(NAME "desktop")


AUX_SOURCE_DIRECTORY(jsc JSC)
AUX_SOURCE_DIRECTORY(jsc/gen/ JSC_GEN)

execute_process(
    COMMAND ${BIN_JSC_GEN} "jsc"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

SET(SRC_LIST desktop.c X_misc.c desktop_item_monitor.c
    ${JSC} ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS} /usr/include/X11/)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
