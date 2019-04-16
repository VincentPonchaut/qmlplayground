import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Pane {
    id: root

    property var messages: []
    property int unreadMessages: 0

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

            Image {
                id: warningIcon

                height: parent.height * 0.5
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5

                fillMode: Image.PreserveAspectFit

                visible: modelData.type === "warning"

                source: "qrc:///img/exclamation-triangle.svg"
                sourceSize.width: width
                sourceSize.height: height
            }

            Text {
                id: clickableText
                anchors.top: parent.top
                anchors.left: warningIcon.right
                anchors.leftMargin: warningIcon.anchors.leftMargin
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
                    left: warningIcon.right
                    leftMargin: warningIcon.anchors.leftMargin
                    top: clickableText.bottom
                }

                text: "" + modelData.msg
                wrapMode: Text.Wrap
                font.family: "Consolas"
                font.pointSize: 10
                color: messageDelegate.hovered ? "yellow" :
                                                 "white"
            }

        }
    }

    IconButton {
        id: trashButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        imageSource: "qrc:///img/trash.svg"
        ToolTip.text: "Clear console"

        property color baseColor: "#3d3d3d"
        background: Rectangle {
            implicitWidth: 40
            implicitHeight: implicitWidth
            radius: width / 2
            color: trashButton.hovered ? Qt.lighter(trashButton.baseColor):
                                         trashButton.baseColor
        }

        onClicked: root.messages = []
    }

    Connections {
        target: appControl

        onLogMessage: {
            if (String(file).startsWith("qrc:"))
                return;
            pushMessage({
                                   "msg" : message,
                                   "file": String(file).replace(appControl.currentFolder, ""),
                                   "line": line,
                            "path": String(file),
                            "type": "user"
                        });
        }
        onWarningMessage: {
            pushMessage({
                            "msg" : String(message).replace(file, ""),
                            "file": String(file).replace(appControl.currentFolder, ""),
                            "line": line,
                            "path": String(file),
                            "type": "warning"
                               });
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

    function pushMessage(pMsgObject) {
        root.messages.push(pMsgObject);
        root.messagesChanged();
        listView.positionViewAtEnd();

        // Update unread count if not visible
        if (root.state == "closed") {
            unreadMessages++;
        }
    }

    states: [
        State {
            name: "open"
            PropertyChanges {
                target: root
                height: contentRow.height * 0.33
            }
            PropertyChanges {
                target: root
                unreadMessages: 0
                restoreEntryValues: false // really reset to 0 every time console is open
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
