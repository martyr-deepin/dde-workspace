SET(NAME "zone")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "zone" "zone.cfg" "dbus.cfg")

include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST  ${JSC_GEN} )

add_executable(${NAME} ${SRC_LIST} zone.c)
add_dependencies(${NAME} ${NAME}_js)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES})

SET_TARGET_PROPERTIES(${NAME}
    PROPERTIES OUTPUT_NAME dde-${NAME}
    )

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-${NAME}
    DESTINATION lib/deepin-daemon
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

GEN_JS_FILE(${NAME})
