SET(NAME "dde-lowpower")
SET(NAME_SRC "lowpower")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "lowpower" "lowpower.cfg" "dbus.cfg")

include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST  ${JSC_GEN} )

add_executable(${NAME} ${SRC_LIST} lowpower.c)
add_dependencies(${NAME} ${NAME_SRC}_js)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES})


execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME_SRC}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION lib/deepin-daemon
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME_SRC}
    DESTINATION ${RESOURCE_DIR}
    )

GEN_JS_FILE(${NAME_SRC})
