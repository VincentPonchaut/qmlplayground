import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Pane {
  id: root

  property int unreadMessages: 0

  ListModel {
    id: messages
  }

  Connections {
    target: appControl
    onCurrentFileChanged: {
      clearMessages()
    }
  }

  background: Rectangle {
    color: "black"
  }

  ListView {
    id: listView
    anchors.fill: parent
    clip: true

    model: messages
    spacing: 5
    boundsBehavior: Flickable.StopAtBounds

    property bool haltScrolling: false

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
      width: parent ? parent.width : 0
      height: clickableText.height + messageText.height //childrenRect.height

      highlighted: ListView.isCurrentItem

      Image {
        id: warningIcon

        height: parent.height * 0.5
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 5

        fillMode: Image.PreserveAspectFit

        visible: model.type === "warning"

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

        text: "%1 line %2".arg(model.file).arg(model.line)
        color: messageDelegate.highlighted ? "lightgrey" : "darkgrey"
        font.family: messageText.font.family
        font.underline: messageDelegate.highlighted
        font.pointSize: messageText.font.pointSize - 2
      }
      Text {
        id: messageText
        width: parent.width
        anchors {
          left: warningIcon.right
          leftMargin: warningIcon.anchors.leftMargin
          top: clickableText.bottom
        }

        text: "" + model.msg
        wrapMode: Text.Wrap
        font.family: "Consolas"
        font.pointSize: 10
        color: messageDelegate.highlighted ? "yellow" :
                                             "white"
      }

    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true

    onPositionChanged: {
      var vIndex = listView.indexAt(mouseX + listView.contentX, mouseY + listView.contentY);
      if (vIndex != -1) {
        listView.currentIndex = vIndex
        listView.haltScrolling = true
      }
      else {
        listView.haltScrolling = false
      }
    }
    onClicked: {
      if (listView.currentIndex > -1)
      {
        Qt.openUrlExternally(messages.get(listView.currentIndex).path)
      }
    }

    onExited: {
      listView.haltScrolling = false
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

    onClicked: clearMessages()
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

    onCurrentFileChanged: reload()
    onCurrentFolderChanged: reload()
    onFileChanged: reload()
    onDirectoryChanged: reload()
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

  function reload() {
    if (settings.clearConsoleOnReload)
    {
      clearMessages()
    }
  }

  function pushMessage(pMsgObject) {
    var vCurrentContentY = listView.contentY
    messages.append(pMsgObject)

    if (!listView.haltScrolling)
      listView.positionViewAtEnd();
    else
      listView.contentY = vCurrentContentY

    // Update unread count if not visible
    if (root.state == "closed") {
      unreadMessages++;
    }
  }

  function clearMessages() {
    messages.clear()
    unreadMessages = 0
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
