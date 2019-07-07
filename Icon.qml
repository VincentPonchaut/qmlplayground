import QtQuick 2.5
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.0

Item {
    id: root

    property alias source: image.source
    property alias color: colorOverlay.color
    property int margins;

    // Square
    width: height
    height: width

    Image {
        id: image

        anchors.fill: parent
        anchors.margins: root.margins
        fillMode: Image.PreserveAspectFit

        visible: false

        sourceSize.width: width
        sourceSize.height: height
    }

    ColorOverlay {
        id: colorOverlay

        anchors.fill: image
        source: image
    }
}
