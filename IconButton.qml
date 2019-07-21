import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

RoundButton
{
    id: roundButton

    property alias imageSource: img.source
    property int margins: 5
    property var __img__: img
    property alias color: colorOverlay.color
    property bool enableTooltip: true
    property color backgroundColor: "#2e2e2e"
        
    Material.theme: Material.Dark

    background: Rectangle {
        id: bg
        implicitWidth: 40
        implicitHeight: 40
        radius: width / 2
//        color: roundButton.flat ? "transparent" : backgroundColor
//        opacity: roundButton.hovered ? 0.6 : 1.0

        states: [
            State {
                name: "flatHovered";
                when: roundButton.flat && roundButton.hovered
                PropertyChanges {
                    target: bg
                    color: "white"
                    opacity: 0.15
                }
            },
            State {
                name: "flatIdle"
                when: roundButton.flat && !roundButton.hovered
                PropertyChanges {
                    target: bg
                    color: "transparent"
                }
            },
            State {
                name: "normalHovered"
                when: !roundButton.flat && roundButton.hovered
                PropertyChanges {
                    target: bg
                    color: roundButton.backgroundColor
//                    opacity: 0.8
//                    scale: 1.1
                }
                PropertyChanges {
                    target: roundButton
                    scale: 1.1
                }
            },
            State {
                name: "normalIdle"
                when: !roundButton.flat && !roundButton.hovered
                PropertyChanges {
                    target: bg
                    color: roundButton.backgroundColor
                    opacity: 1.0
                }
            }

        ]
        state: "normalIdle"
    }

    Image {
        id: img
        anchors.fill: parent
        anchors.margins: roundButton.margins
        
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: width
        sourceSize.height: height
    }
    ColorOverlay {
        id: colorOverlay
        anchors.fill: img
        source: img
        color: Material.foreground
    }
    
    ToolTip.visible: enableTooltip && hovered
}
