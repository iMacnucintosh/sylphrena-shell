qml_module(sylphrena-state
    URI Sylphrena.State
    INCLUDE_PREFIX state
    SOURCES
        common.cpp
        rootnodes.cpp
    DEPENDENCIES
        Sylphrena.Settings
)
target_link_libraries(sylphrena-state PUBLIC sylphrena-settings)
