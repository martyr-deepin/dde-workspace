SET(NAME "lock")

GEN_JSC_SOURCE("jsc" JSC_GEN)

SET(SRC_LIST lock.c ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})
add_executable(unlockcheck unlockcheck.c)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} )
target_link_libraries(unlockcheck crypt)

include_directories(${DWEBVIEW_INCLUDE_DIRS})

#execute_process(
    #COMMAND make
    #WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    #)
install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
