QT += \
    core gui qml quick \
    quickcontrols2 \
    widgets \
    multimedia sql \
    network websockets \
    xml xmlpatterns svg \
    sensors bluetooth nfc \
    positioning location \
    3dcore 3drender 3dinput 3dlogic 3dextras 3dquick 3danimation \
#    webview \ webengine \
    charts \
    concurrent \
    printsupport

#QMAKE_CXXFLAGS += -O2

# For ZipReader & ZipWriter
QT += gui-private

requires(qtConfig(udpsocket))

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

HEADERS += \
    macros.h \
    folderlistmodel.h \
    multirootfolderlistmodel.h \
    tools/maskedmousearea.h \
    applicationcontrol.h \
    QMLHighlighter.h \
    SyntaxHighlighter.h \
    servercontrol.h

SOURCES += main.cpp \
    folderlistmodel.cpp \
    multirootfolderlistmodel.cpp \
    tools/maskedmousearea.cpp \
    applicationcontrol.cpp \
    QMLHighlighter.cpp \
    SyntaxHighlighter.cpp \
    servercontrol.cpp

include(systemtray/systemtray.pri)
include(svg/svg.pri)

RESOURCES += \
    resources.qrc \
    publishing.qrc

QTQUICK_COMPILER_SKIPPED_RESOURCES += publishing.qrc

RC_FILE = img/appicon.rc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

