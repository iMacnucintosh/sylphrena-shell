set(po_files
    trs/es.po
)

set(trs_script "${CMAKE_SOURCE_DIR}/scripts/trs.fish")
# The translations are compiled with msgfmt directly (gettext, part of base-devel): building the package
# must not need fish, which only the maintenance commands of scripts/trs.fish use.
find_program(MSGFMT msgfmt REQUIRED)

# Compile .po -> .mo and alias each one to <lang>.mo in the module's resources
set(mo_files)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/trs")

foreach(po IN LISTS po_files)
    cmake_path(GET po STEM lang)
    set(mo "${CMAKE_CURRENT_BINARY_DIR}/trs/${lang}.mo")

    add_custom_command(
        OUTPUT "${mo}"
        COMMAND "${MSGFMT}" --check-format -o "${mo}" "${CMAKE_CURRENT_SOURCE_DIR}/${po}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${po}"
        COMMENT "Compiling translations for ${lang}"
        VERBATIM
    )

    set_source_files_properties("${mo}" PROPERTIES QT_RESOURCE_ALIAS "${lang}.mo")
    list(APPEND mo_files "${mo}")
endforeach()

if(SYLPHRENA_TEST_TRS)
    set(test_mo "${CMAKE_CURRENT_BINARY_DIR}/trs/test.mo")

    add_custom_command(
        OUTPUT "${test_mo}"
        COMMAND "${trs_script}" test "${test_mo}"
        DEPENDS "${trs_script}"
        COMMENT "Generating test translations"
        VERBATIM
    )

    set_source_files_properties("${test_mo}" PROPERTIES QT_RESOURCE_ALIAS "test.mo")
    list(APPEND mo_files "${test_mo}")
endif()

qml_module(sylphrena-i18n
    URI Sylphrena.I18n
    INCLUDE_PREFIX i18n
    SOURCES
        translator.cpp
        pluralrules.cpp
    QML_SINGLETONS
        Tr.qml
        Units.qml
    RESOURCES
        ${mo_files}
    LIBRARIES
        sylphrena-util
        sylphrena-config
    DEPENDENCIES
        Sylphrena
        Sylphrena.Config
)
