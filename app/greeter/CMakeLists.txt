SET(NAME "greeter")

GEN_JSC_SOURCE2(JSC_GEN "jsc" "greeter" "greeter.cfg" "dbus.cfg")
GEN_JSC_SOURCE2(JSC_LOCK_GEN "jsc" "lock" "lock.cfg" "dbus.cfg")

pkg_check_modules(LIGHTDM REQUIRED liblightdm-gobject-1)

add_executable(${NAME} greeter.c ${JSC_GEN})
add_executable(switchtogreeter switchtogreeter.c)
add_executable(dlock dlock.c ${JSC_LOCK_GEN})
add_executable(unlockcheck unlockcheck.c)

target_link_libraries(${NAME} dcom dbus ${DWEBVIEW_LIBRARIES} ${LIGHTDM_LIBRARIES})
target_link_libraries(switchtogreeter ${DWEBVIEW_LIBRARIES})
target_link_libraries(dlock dcom dbus ${DWEBVIEW_LIBRARIES})
target_link_libraries(unlockcheck crypt)

include_directories(${DWEBVIEW_INCLUDE_DIRS} ${LIGHTDM_INCLUDE_DIRS})

execute_process(
    COMMAND make
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}/js
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/switchtogreeter
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/dlock
    DESTINATION bin
    )

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/unlockcheck
    DESTINATION bin
    )

install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
