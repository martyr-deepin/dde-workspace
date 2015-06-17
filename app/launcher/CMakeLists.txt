SET(NAME "launcher")


if (TEST)
  add_subdirectory(test)
endif()

GEN_JSC_SOURCE(JSC_GEN "jsc")
GEN_DBUS_SOURCE(DBUS_GEN "jsc/dbus.go" "launcher")

file(GLOB CFILES *.c)

SET(SRC_LIST ${CFILES} ${JSC_GEN} ${DBUS_GEN})

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${DBUS_INCLUDE_DIRS})

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME}_js)
set_target_properties(${NAME}
	PROPERTIES OUTPUT_NAME dde-${NAME}
	)

if (TEST)
  target_link_libraries(${NAME} dcom dentry dbus ${DWEBVIEW_LIBRARIES}
    dlauncher_test)
else()
  target_link_libraries(${NAME} dcom dentry dbus ${DWEBVIEW_LIBRARIES})
endif()

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
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.deepin.dde.launcher.service
    DESTINATION /usr/share/dbus-1/services/
    )
