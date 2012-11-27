SET(NAME "dock")

add_subdirectory(notification_area)

execute_process(
    COMMAND ${BIN_JSC_GEN} "jsc"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )

AUX_SOURCE_DIRECTORY(jsc JSC)
AUX_SOURCE_DIRECTORY(jsc/gen/ JSC_GEN)


include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST dock.c dock_config.c tray.c tasklist.c draw.c ${JSC} ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

target_link_libraries(${NAME} dcom dbus tray ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-dock.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )
