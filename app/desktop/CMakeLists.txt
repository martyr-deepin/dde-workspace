SET(NAME "desktop")


execute_process(
    COMMAND ${BIN_JSC_GEN} "jsc"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

AUX_SOURCE_DIRECTORY(jsc JSC)
AUX_SOURCE_DIRECTORY(jsc/gen/ JSC_GEN)


SET(SRC_LIST desktop.c desktop_item_monitor.c file_operation.c
    ${JSC} ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom ${DWEBVIEW_LIBRARIES})

include_directories(${DWEBVIEW_INCLUDE_DIRS})

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )
install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-desktop.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )
