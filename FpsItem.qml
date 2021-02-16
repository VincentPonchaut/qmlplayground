import QtQuick 2.0
import QtQuick.Window 2.2

Rectangle {
    id: root
    property int frameCounter: 0
    property int frameCounterAvg: 0
    property int counter: 0
    property int fps: 0
    property int fpsAvg: 0

    readonly property real dp: Screen.pixelDensity * 25.4/160

    color: Qt.rgba(0,0,0,0.7)
    width:  childrenRect.width + 4*dp;
    height: childrenRect.height + 4*dp;

    Image {
        id: spinnerImage
        anchors.verticalCenter: parent.verticalCenter
        x: 4 * dp
        width: 36 * dp
        height: width
        source: "images/spinner.png"
        NumberAnimation on rotation {
            from:0
            to: 360
            duration: 800
            loops: Animation.Infinite
        }
        onRotationChanged: frameCounter++;
    }

    Text {
        anchors.left: spinnerImage.right
        anchors.leftMargin: 8 * dp
        anchors.verticalCenter: spinnerImage.verticalCenter
//        color: "#c0c0c0"
        color: "yellow"
        font.pixelSize: 12 * dp
        text: "Ø " + root.fpsAvg + " | " + root.fps + " fps"
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            frameCounterAvg += frameCounter;
            root.fps = frameCounter/2;
            counter++;
            frameCounter = 0;
            if (counter >= 3) {
                root.fpsAvg = frameCounterAvg/(2*counter)
                frameCounterAvg = 0;
                counter = 0;
            }
        }
    }
}
