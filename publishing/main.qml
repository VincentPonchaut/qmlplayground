import QtQuick 2.12
import QtQuick.Window 2.2

Window {
    visible: true
    width: %2
    height: %3
    title: qsTr("%1")

    Loader {
        anchors.fill: parent
        asynchronous: true; // apparently essential for animations
        source: "qrc:///%4"
    }
}