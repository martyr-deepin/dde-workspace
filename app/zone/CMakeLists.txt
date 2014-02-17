SET(NAME "zone")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "zone" "zone.cfg" "dbus.cfg")

include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST  ${JSC_GEN} )

add_executable(dzone ${SRC_LIST} zone.c)

target_link_libraries(dzone dcom dbus ${DWEBVIEW_LIBRARIES})


execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dzone
    DESTINATION lib/deepin-daemon
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

install(
    FILES ${PROJECT_SOURCE_DIR}/app/zone/com.deepin.dde.zone.service
    DESTINATION /usr/share/dbus-1/services/
    )

