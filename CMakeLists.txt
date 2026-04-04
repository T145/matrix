cmake_minimum_required(VERSION 3.16)

project(matrixrain VERSION 1.0.0)

set(KF_MIN_VERSION "6.0.0")
set(QT_MIN_VERSION "6.6.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMFindQmlModule)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Qml Quick)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    Package
    Kirigami
)

# Silence Qt QML policy warnings — this is a KPackage plugin, not a compiled module
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# Verify expected QML modules are available at configure time
ecm_find_qmlmodule(org.kde.plasma.plasmoid)
ecm_find_qmlmodule(org.kde.kirigami)
ecm_find_qmlmodule(QtQuick.Controls)
ecm_find_qmlmodule(QtQuick.Layouts)

# ---------------------------------------------------------------------------
# QML module declaration (for qmlls / qmllint tooling only)
#
# This is a pure-QML KPackage plugin — there is no compiled C++ backing
# library.  We declare a STATIC qt_add_qml_module so that the CMake build
# tree contains the metadata qmlls needs for type-checking and completion.
# The OUTPUT_DIRECTORY must end in the URI-derived path for qmllint to
# resolve types correctly.
# ---------------------------------------------------------------------------
qt_add_qml_module(matrixrain_qml
    STATIC
    URI com.t145.matrixrain
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/com/t145/matrixrain"
    QML_FILES
        contents/ui/main.qml
        contents/ui/config.qml
    NO_PLUGIN
)

# ---------------------------------------------------------------------------
# Install the KPackage bundle to the standard Plasma wallpaper location.
# ---------------------------------------------------------------------------
kpackage_install_package(${CMAKE_CURRENT_SOURCE_DIR} com.t145.matrixrain plasma/wallpapers)
