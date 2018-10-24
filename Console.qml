import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Pane {
    id: root
    property var messages: []

    background: Rectangle {
        color: "black"
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true

        model: root.messages
        spacing: 5
        boundsBehavior: Flickable.StopAtBounds

        ScrollIndicator.vertical: ScrollIndicator {
            visible: listView.contentHeight > listView.height
            contentItem: Rectangle {
                implicitWidth: 2
                implicitHeight: 20

                color: "#6b6b6b"
                radius: 2
            }
        }

        delegate: ItemDelegate {
            id: messageDelegate
            width: parent.width
            height: clickableText.height + messageText.height //childrenRect.height

            Text {
                id: clickableText
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                text: "%1 line %2".arg(modelData.file).arg(modelData.line)
                color: parent.hovered ? "lightgrey" : "darkgrey"
                font.family: messageText.font.family
                font.underline: clickableText.hovered
                font.pointSize: messageText.font.pointSize - 2

                property bool hovered: mouseArea.containsMouse

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Qt.openUrlExternally(modelData.path)
                }
            }
            Text {
                id: messageText
                width: parent.width
                anchors {
                    left: parent.left
                    top: clickableText.bottom
                }

                text: "" + modelData.msg
                wrapMode: Text.Wrap
                font.family: "Consolas"
                font.pointSize: 10
                color: messageDelegate.hovered ? "yellow" : "white"
            }

        }
    }

    IconButton {
        id: trashButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        imageSource: "qrc:///img/trash.svg"
        ToolTip.text: "Clear console"

        background: Rectangle {
            implicitWidth: 40
            implicitHeight: implicitWidth
            radius: width / 2
            color: trashButton.hovered ? Qt.lighter(color):
                                         "#3d3d3d"
        }

        onClicked: root.messages = []
    }

    Connections {
        target: appControl
        onLogMessage: {
            if (String(file).startsWith("qrc:"))
                return;
            root.messages.push({
                                   "msg" : message,
                                   "file": String(file).replace(appControl.currentFolder, ""),
                                   "line": line,
                                   "path": String(file)
                               });
            root.messagesChanged();
            listView.positionViewAtEnd();
        }
    }

    // ------------------------------------------------------
    // States & Logic
    // ------------------------------------------------------

    function show() {
        state = "open"
    }

    function toggle() {
        state = (state == "open" ? "closed" : "open");
    }

    states: [
        State {
            name: "open"
            PropertyChanges {
                target: root
                height: contentRow.height * 0.33
            }
            PropertyChanges {
                target: trashButton
                visible: true
            }
        },
        State {
            name: "closed"
            PropertyChanges {
                target: root
                height: 0
            }
            PropertyChanges {
                target: trashButton
                visible: false
            }
        }
    ]
    state: "closed"
}
