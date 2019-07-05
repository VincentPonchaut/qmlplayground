import QtQuick 2.5
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.0

Item {
    id: root

    property alias source: image.source
    property alias color: colorOverlay.color

    // Square
    width: height
    height: width

    Image {
        id: image

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit

        visible: false

        sourceSize.width: width
        sourceSize.height: height
    }

    ColorOverlay {
        id: colorOverlay

        anchors.fill: parent
        source: image
    }
}
