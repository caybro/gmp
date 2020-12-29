TEMPLATE = app
TARGET = gmp

QT += gui qml sql widgets

CONFIG += c++14

CONFIG += link_pkgconfig
PKGCONFIG += taglib

CONFIG += qmltypes
QML_IMPORT_NAME = org.gmp.model
QML_IMPORT_MAJOR_VERSION = 1
QML_IMPORT_PATH = $$OUT_PWD

SOURCES += main.cpp \
    dbindexer.cpp

HEADERS += \
    dbindexer.h

OTHER_FILES = \
    qml/*.qml \
    translations/*.ts \
    icons/*.svg

RESOURCES += gmp.qrc

lupdate_only {
    SOURCES += ../imports/*/*.cpp
}

TRANSLATIONS = translations/gmp_base.ts \
               translations/gmp_cs.ts

target.path = $$[QT_HOST_BINS]
sources.files = $$SOURCES $$HEADERS $$RESOURCES $$FORMS $$OTHER_FILES gmp.pro
sources.path = $$[QT_INSTALL_EXAMPLES]/gmp

INSTALLS += target
