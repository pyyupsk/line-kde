# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2026 pyyupsk <>


# Target: static library
set_source_files_properties(contents/ui/Lds.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(linekde_static
    STATIC
    URI com.pyyupsk.linekde
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/com/pyyupsk/linekde"
    QML_FILES
        contents/ui/Lds.qml
        contents/ui/Main.qml
        contents/ui/About.qml
        contents/ui/Settings.qml
    RESOURCES
        contents/ui/assets/line-logo.svg
)


target_sources(linekde_static PUBLIC
    app.cpp
    coreclient.cpp
)

target_compile_definitions(linekde_static PUBLIC
    LINE_KDE_CORE="${CMAKE_CURRENT_SOURCE_DIR}/../../core/src/index.ts"
)

target_link_libraries(linekde_static PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Svg
    KF6::I18n
    KF6::I18nQml
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::ConfigGui
)
target_include_directories(linekde_static PUBLIC ${CMAKE_BINARY_DIR})

if (ANDROID)
    kirigami_package_breeze_icons(ICONS
        list-add
        help-about
        application-exit
        applications-graphics
    )
else()
    target_link_libraries(linekde_static PUBLIC Qt::Widgets)
endif()

kconfig_add_kcfg_files(linekde_static GENERATE_MOC linekdeconfig.kcfgc)

# Target: main executable
add_executable(linekde main.cpp)
target_link_libraries(linekde PUBLIC linekde_static linekde_staticplugin)
install(TARGETS linekde ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
