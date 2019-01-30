import QtQuick 2.12
import QtQuick.Controls 2.4
import Qt.labs.platform 1.1

Row {
    property alias text: textField.text
    property alias placeholderText: textField.placeholderText

    TextField {
        id: textField

        width: parent.width - folderButton.width - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        font.pointSize: 9
        selectByMouse: true

        validator: RegExpValidator {
            regExp: /^((?!file:\/\/\/)[\s\S])*$/
        }
    }

    ToolButton {
        id: folderButton
        icon.source: "qrc:///img/folder.svg"
        onClicked: folderDialog.open()
    }

    property var folderDialog: FolderDialog {
        id: folderDialog

        folder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        onAccepted: textField.text = String(folderDialog.folder).replace("file:///","")
    }
}
