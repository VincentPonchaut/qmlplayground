import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.12
import QtQml.Models 2.13
import QtQml 2.13

import "Utils.js" as Utils

ItemDelegate {
    id: root

    property int row: index
    property var parentIndex: null
    property var modelIndex: parentIndex != null ? fsProxy.index(row, 0,parentIndex) :
                                                   fsProxy.index(row, 0)
    property var itemData: fsProxy.data(modelIndex,
                                        fsProxy.roleFromString("entry"))

    property bool isValid: Utils.isNotNull(itemData)

    property bool isCurrentFolder: isValid ? itemData.expandable && root.fp(itemData.path) === appControl.currentFolder : false
    property bool isCurrentFile:   isValid ? !itemData.expandable && root.fp(itemData.path) === appControl.currentFile : false
    property bool isExpandable:    isValid ? itemData.expandable : false
    property bool isExpanded:      isValid ? itemData.expanded : false

    // ---------------------------------------------------------------
    // Logic
    // ---------------------------------------------------------------
    onClicked: {
        if (Utils.isNull(itemData))
            return

        if (itemData.expandable) {
            itemData.expanded = !itemData.expanded
        } else if (itemData.path.endsWith("qml")) {
            var path = "file:///" + String(itemData.path)
            var folder = path.substring(0, path.lastIndexOf("/"))

            appControl.setCurrentFileAndFolder(folder, path)
        }
    }

    // ---------------------------------------------------------------
    // View
    // ---------------------------------------------------------------
    width: parent.width
    height: childrenRect.height

    highlighted: isCurrentFolder || isCurrentFile
    padding: 0

    Row {
        id: labelRouge

        width: parent.width
        height: _.rowHeight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: spacing

        spacing: 0

        Icon {
            height: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            source: _.icon()
            color: _.iconColor()
        }
        Label {

            anchors.top: parent.top
            height: parent.height
            verticalAlignment: Text.AlignVCenter

            text: root.isValid ? root.itemData.name : "error"

            color: _.textColor()
            font.bold: root.isCurrentFile || root.isCurrentFolder
            font.family: ui.defaultFont
        }
    }

    // Contextual folder actions
    Row {
        id: folderActionsRow

        anchors.top: parent.top
        anchors.right: parent.right
        height: _.rowHeight
        visible: root.isValid && root.hovered && itemData.expandable
        spacing: -7

        IconButton {
            id: newFileButton

            height: parent.height
            width: height
            anchors.verticalCenter: parent.verticalCenter

            onClicked: fileCreationPopup.openForFolder(fp(itemData.path))
            imageSource: "qrc:///img/newFile.svg"
            ToolTip.text: "New file"
        }

        IconButton {
            id: infoButton
            height: parent.height
            width: height
            anchors.verticalCenter: parent.verticalCenter

            onClicked: Qt.openUrlExternally(
                           fp(itemData.path)) //appControl.runCommand("cmd /c explorer \"%1\"".arg(itemData))

            imageSource: "qrc:///img/folder.svg"
            margins: 5

            ToolTip.text: "Open in explorer"
        }
        IconButton {
            id: trashButton
            height: parent.height
            width: height
            anchors.verticalCenter: parent.verticalCenter

            visible: Utils.isNotNull(itemData) &&
                     appControl.isInFolderList(fp(itemData.path))

            onClicked: {
                if (isCurrentFolder || isCurrentFile) {
                    appControl.setCurrentFileAndFolder("", "")
                }

                appControl.removeFromFolderList(itemData.path)
            }
            imageSource: "qrc:///img/eye_off.svg"
            margins: 5

            ToolTip.text: "Stop watching folder"
        }
    }

    // Contextual file actions
    Row {
        id: fileActionsRow

        anchors.top: parent.top
        anchors.right: parent.right
        height: _.rowHeight
        spacing: -7

        visible: root.isValid && root.hovered && !itemData.expandable

        IconButton {
            id: exploreToButton

            height: parent.height * 0.9
            width: height
            anchors.verticalCenter: parent.verticalCenter

            onClicked: Qt.openUrlExternally(fp(parentFolder(itemData.path)))
            imageSource: "qrc:///img/folder.svg"
            ToolTip.text: "Open in explorer"
        }

        IconButton {
            id: editFileButton

            height: parent.height * 0.9
            width: height
            anchors.verticalCenter: parent.verticalCenter

            onClicked: Qt.openUrlExternally(fp(itemData.path))
            imageSource: "qrc:///img/edit.svg"
            ToolTip.text: "Open file in external editor"
        }

        IconButton {
            id: editFileContentButton

            height: parent.height * 0.9
            width: height
            anchors.verticalCenter: parent.verticalCenter

            onClicked: editFileLocally(fp(itemData.path))
            imageSource: "qrc:///img/code.svg"
            ToolTip.text: "Quick edit"
        }
        // TODO: clone file
        // TODO: remove file
    }

    ListView {
        id: childrenListView

        anchors.top: labelRouge.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        anchors.leftMargin: (settings.windowWidth / 50) * dp
        interactive: false

        model: fsProxy.rowCount(modelIndex)
        delegate: Item {
            width: parent.width
            height: childrenLoader.item.height

            Loader {
                id: childrenLoader
                width: parent.width
                height: childrenRect.height
//                asynchronous: true
            }

            Component.onCompleted: {
                childrenLoader.setSource("FsEntryDelegate.qml", {
                                             "parentIndex": root.modelIndex
                                         })
            }
        }
    }

    // ---------------------------------------------------------------
    // States
    // ---------------------------------------------------------------
    states: [
        State {
            name: "expanded"
            when: typeof (itemData) !== "undefined" && itemData.expandable
                  && itemData.expanded
            PropertyChanges {
                target: childrenListView
                visible: true
                restoreEntryValues: false
            }
            PropertyChanges {
                target: root
                height: _.rowHeight + childrenListView.height
                restoreEntryValues: false
            }
        },
        State {
            name: "folded"
            when: typeof (itemData) !== "undefined" && itemData.expandable
                  && !itemData.expanded
            PropertyChanges {
                target: childrenListView
                visible: false
                restoreEntryValues: false
            }
            PropertyChanges {
                target: root
                height: _.rowHeight
                restoreEntryValues: false
            }
        }
    ]
    state: "folded"

    // ---------------------------------------------------------------
    // Utilities
    // ---------------------------------------------------------------
    QtObject {
        id: _

        property int rowHeight: 50 * dp

        function icon() {
            if (root.isExpandable) {
                if (root.isExpanded)
                    return "img/folderOpen.svg"
                else
                    return "img/folder.svg"
            }
            return "img/newFile.svg"
        }

        function iconColor() {
            if (!root.isValid)
                return "red";

            if (root.isCurrentFolder) {
                return Material.accent
            } else if (root.isCurrentFile) {
                return "#f9a825"
            } else if (root.isExpandable) {
                return "white"
            } else if (itemData.path.endsWith("qml")) {
                return "#81d4fa"
            } else
                return "#69f0ae"
        }

        function textColor() {
            if (root.isCurrentFolder || root.isCurrentFile)
                return iconColor()
            return "white"
        }
    }

    function parentFolder(filepath) {
        return filepath.substring(0, filepath.lastIndexOf("/"))
    }

    function fp(filepath) {
        if (filepath.startsWith("file:///"))
            return filepath
        else
            return "file:///" + filepath
    }
}
