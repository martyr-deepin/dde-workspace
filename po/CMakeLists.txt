find_package(Gettext REQUIRED)

file(GLOB PO_FILES *.po)

foreach(f ${PO_FILES})
    GET_FILENAME_COMPONENT(f_we ${f} NAME_WE)
    set(out "${f_we}.gmo")
    set(in "${f_we}.po")

    add_custom_command(
        OUTPUT ${out}
        COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${out} ${in}
        DEPENDS ${in}
        )
    install(
        FILES ${out}
        DESTINATION ${CMAKE_INSTALL_PREFIX}/usr/share/locale/${f_we}/LC_MESSAGES/
        RENAME DDE.mo
        )

    set(_outputs ${_outputs} ${out})
endforeach(f)
