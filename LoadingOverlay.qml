import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import Qt.labs.lottieqt 1.0

Pane {
    id: loadingOverlay
    
    property bool loading;
    property alias minTimeMs: minTimer.interval

    Timer {
        id: minTimer
        interval: 1000

        repeat: true
        running: true

        onTriggered: {
            if (loadingOverlay.loading)
            {
                minTimer.restart()
            }
            else
            {
                minTimer.stop()
            }
        }
    }

    visible: minTimer.running
    onVisibleChanged: {
        if (visible)
            lottie.play()
        else
            lottie.stop()
    }

    Material.theme: Material.Dark
    background: Rectangle { color: Qt.rgba(0,0,0, 1.0) }

    Item {
        id: busyIndicator
        anchors.centerIn: parent
        width: 200
        height: 200
        
        LottieAnimation {
            id: lottie
            anchors.centerIn: parent

            source: ":/lottie/coffeecup.json"
//            autoPlay: true
            loops: Animation.Infinite
            frameRate: 120

            layer.enabled: true
            layer.mipmap: true
        }
        
    }
    
    Label {
        id: loadingMessage
        anchors.top: busyIndicator.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width

        text: "QmlPlayground is loading..."
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: 18
    }

    Timer {
        id: tooDamnLong
        interval: 5000
        triggeredOnStart: false
        running: loadingOverlay.visible

        onTriggered: {
            loadingMessage.text += "\nYes, it's damn long."
        }
    }
}
