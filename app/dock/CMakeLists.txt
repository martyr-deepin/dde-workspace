SET(NAME "dock")

# add_subdirectory(notification_area)
add_subdirectory(test)

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "dock")

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DTEST_INCLUDE_DIRS})

SET(SRC_LIST
	embed_window.c
	dock.c
	dock_hide.c
	dock_config.c
	handle_icon.c
	migration.c
	dominant_color.c
	draw.c
	region.c
	monitor.c
	switcher.c
	date_time.c
	${JSC_GEN} ${DBUS_GEN})

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME}_js)
SET_TARGET_PROPERTIES(${NAME}
	PROPERTIES OUTPUT_NAME dde-${NAME}
	)


target_link_libraries(${NAME} dcom dentry dbus
    ddock_test
    ${DWEBVIEW_LIBRARIES} dtest)

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

GEN_JS_FILE(${NAME})

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/deepin-dock.desktop
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications
    )
