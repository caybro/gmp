TEMPLATE = lib
TARGET = SqlExtPlugin
QT += qml sql
CONFIG += qt plugin c++17

CONFIG += qmltypes
QML_IMPORT_NAME = org.gmp.sqlext
QML_IMPORT_MAJOR_VERSION = 1

TARGET = $$qtLibraryTarget($$TARGET)

# Input
SOURCES += \
        sqlquerymodel.cpp \
        sqltablemodel.cpp \
        plugin.cpp

HEADERS += \
        sqlquerymodel.h \
        sqltablemodel.h

DISTFILES = qmldir

!equals(_PRO_FILE_PWD_, $$OUT_PWD) {
    copy_qmldir.target = $$OUT_PWD/qmldir
    copy_qmldir.depends = $$_PRO_FILE_PWD_/qmldir
    copy_qmldir.commands = $(COPY_FILE) "$$replace(copy_qmldir.depends, /, $$QMAKE_DIR_SEP)" "$$replace(copy_qmldir.target, /, $$QMAKE_DIR_SEP)"
    QMAKE_EXTRA_TARGETS += copy_qmldir
    PRE_TARGETDEPS += $$copy_qmldir.target
}

qmldir.files = qmldir $$OUT_PWD/plugins.qmltypes
unix {
    installPath = $$[QT_INSTALL_QML]/$$replace(QML_IMPORT_NAME, \., /)
    qmldir.path = $$installPath
    target.path = $$installPath
    INSTALLS += target qmldir
}
