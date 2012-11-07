set(NAME "dbus_test")

execute_process(
    COMMAND ${BIN_JSC_GEN} "jsc"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

AUX_SOURCE_DIRECTORY(jsc JSC)
AUX_SOURCE_DIRECTORY(jsc/gen/ JSC_GEN)

SET(SRC_LIST web.c ${JSC} ${JSC_GEN})

add_executable(${NAME} ${SRC_LIST})

pkg_check_modules(DBUS REQUIRED dbus-glib-1)

include(CheckCSourceRuns)
set(CMAKE_REQUIRED_INCLUDES  ${DBUS_INCLUDE_DIRS})
CHECK_C_SOURCE_RUNS(
    "#include <dbus/dbus.h>
    int main() { DBusBasicValue a;}
    "  HasDbusBasicValue)

if (HasDbusBasicValue) 
    add_definitions("-D__DBUSBASIC_VALUE__=1")
endif()

include_directories(${DWEBVIEW_INCLUDE_DIRS})
include_directories(${DBUS_INCLUDE_DIRS})
target_link_libraries(${NAME} dcom ${DBUS_LIBRARIES} ${DWEBVIEW_LIBRARIES})

install(
    PROGRAMS ${PROJECT_BINARY_DIR}/${NAME}
    DESTINATION bin
    )
install(
    DIRECTORY ${PROJECT_SOURCE_DIR}/resources/${NAME}
    DESTINATION ${RESOURCE_DIR}
    )
