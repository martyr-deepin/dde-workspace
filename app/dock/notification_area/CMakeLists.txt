pkg_check_modules(GTK REQUIRED gtk+-3.0)

include_directories(${GTK_INCLUDE_DIRS})

add_library(tray na-marshal.c na-tray-manager.c)

target_link_libraries(tray ${GTK_LIBRARIES})
