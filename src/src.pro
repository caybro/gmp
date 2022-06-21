TEMPLATE = app
TARGET = gmp

QT += qml gui quick widgets

android: QT -= widgets

CONFIG += c++17

CONFIG += link_pkgconfig
PKGCONFIG += taglib

QML_IMPORT_PATH += $$PWD/qml
QML_IMPORT_PATH += $$OUT_PWD

SOURCES += main.cpp \
    albumproxymodel.cpp \
    artistsmodel.cpp \
    genericproxymodel.cpp \
    genresmodel.cpp \
    musicindexer.cpp \
    tracksmodel.cpp \
    albumsmodel.cpp

HEADERS += \
    albumproxymodel.h \
    artistsmodel.h \
    genericproxymodel.h \
    genresmodel.h \
    musicindexer.h \
    tracksmodel.h \
    albumsmodel.h

OTHER_FILES = \
    qml/*.qml \
    translations/*.ts \
    icons/*.svg

RESOURCES += gmp.qrc

TRANSLATIONS = translations/gmp_base.ts \
               translations/gmp_cs.ts

target.path = $$[QT_HOST_BINS]
sources.files = $$SOURCES $$HEADERS $$RESOURCES $$FORMS $$OTHER_FILES gmp.pro
sources.path = $$[QT_INSTALL_EXAMPLES]/gmp

INSTALLS += target
