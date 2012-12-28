#add_subdirectory(dbus_test)
add_subdirectory(desktop)
add_subdirectory(launcher)
add_subdirectory(dock)
add_subdirectory(memory_test)
add_subdirectory(dominant_color)

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/common
    DESTINATION ${RESOURCE_DIR}
    )
