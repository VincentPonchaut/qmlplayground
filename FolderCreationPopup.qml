import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import Qt.labs.lottieqt 1.0

Popup {
  id: folderCreationPopup

  width: parent.width * 0.33
  height: parent.height * 0.33
  x: root.width / 2 - width / 2
  y: root.height / 2 - height / 2

  clip: true

  modal: true
  focus: true
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

  function validate() {
//    var folderToCreate = folderCreationDialog.folder + '/' + newFolderNameTextField.text

//    if (appControl.isAlreadyWatched(folderToCreate)) {
//      print("warning: Cannot create a folder inside a watched folder yet.")
//      errorMessage.text = "Cannot create a folder inside a watched folder yet."
//      return
//    }

    var success = appControl.createFolder(folderCreationDialog.folder,
                                          newFolderNameTextField.text)
    if (success) {
      var vFolder = folderCreationDialog.folder + "/" + newFolderNameTextField.text
      if (createMainQmlFileWithFolderCheckbox.checked) {
        appControl.createFile(vFolder, 'main.qml')

        var vFile = vFolder + "/main.qml"
        appControl.setCurrentFileAndFolder(vFolder, vFile)
        // TODO: Scroll to current File
      }
      appControl.addToFolderList(vFolder)
    }
    folderCreationPopup.close()
  }

  Labs.FolderDialog {
    id: folderCreationDialog
    folder: appControl.currentFolder.substring(0, appControl.currentFolder.lastIndexOf('/'))
    onAccepted: errorMessage.text = ""
  }

  padding: 0

  Page {
    anchors.fill: parent
    padding: 0

    Component.onCompleted: newFolderNameTextField.forceActiveFocus()

    header: Pane {
      Material.theme: Material.Dark

      Label {
        anchors.centerIn: parent
        text: "Create a new folder"
        font.pointSize: 16
      }
    }
    Pane {
      width: parent.width
      height: folderCreationPopup.height

      Row {
        id: newFolderRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        Label {
          id: baseFolderLabel
          anchors.verticalCenter: parent.verticalCenter
          text: String(folderCreationDialog.folder).substring(String(folderCreationDialog.folder).lastIndexOf("/") + 1) + "/"
          font.pointSize: 11

          property bool hovered: baseFolderLabelMouseArea.containsMouse

          color: hovered ? Material.accent : Material.foreground

          ToolTip.visible: hovered
          ToolTip.text: "%1\nClick to change".arg(
                          String(
                            folderCreationDialog.folder).replace(
                            "file:///", ""))

          MouseArea {
            id: baseFolderLabelMouseArea
            anchors.fill: parent
            hoverEnabled: true

            onClicked: folderCreationDialog.open()
          }
        }
        TextField {
          id: newFolderNameTextField
          anchors.baseline: baseFolderLabel.baseline
          placeholderText: "Enter folder name"
          font.pointSize: baseFolderLabel.font.pointSize
          selectByMouse: true
          focus: true

          onAccepted: folderCreationPopup.validate()
        }
      }

      CheckBox {
        id: createMainQmlFileWithFolderCheckbox

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: newFolderRow.bottom
        anchors.topMargin: 0

        text: "Create a 'main.qml' file"
        checked: true
      }

      Label {
        id: errorMessage
        anchors.top: createMainQmlFileWithFolderCheckbox.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        visible: text.length > 0
        color: "red"
      }
    }

    footer: Pane {
      Row {
        id: folderCreationPopupValidationButtonsRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 10

        // TODO: checkbox "Create main.qml file" ou mieux : une liste editable de fichiers à génerer
        Button {
          text: "Create"
          onClicked: folderCreationPopup.validate()
        }
        Button {
          text: "Cancel"
          onClicked: folderCreationPopup.close()
        }
      }
    }
  } //  end page
}
