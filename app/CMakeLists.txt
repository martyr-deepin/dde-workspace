add_subdirectory(dbus_test)
add_subdirectory(desktop)
#add_subdirectory(taskbar)

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/common
    DESTINATION ${RESOURCE_DIR}
    )
