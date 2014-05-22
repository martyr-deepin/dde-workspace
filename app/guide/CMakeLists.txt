SET(NAME "guide")

GEN_JSC_SOURCE(JSC_GEN "jsc")

include_directories(${DWEBVIEW_INCLUDE_DIRS})

SET(SRC_LIST  ${JSC_GEN} guide.c helper.c)

add_executable(${NAME} ${SRC_LIST})
add_dependencies(${NAME} ${NAME}_js)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES})


execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dde-${NAME}
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )

GEN_JS_FILE(${NAME})
