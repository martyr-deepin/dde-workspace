add_subdirectory(dbus_test)
add_subdirectory(desktop)
add_subdirectory(taskbar)
add_subdirectory(launcher)

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/common
    DESTINATION ${RESOURCE_DIR}
    )
