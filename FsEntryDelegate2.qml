import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import QtQml.Models 2.2

//Page {
ItemDelegate {
    id: itemDelegate

    property var itemData;
    property bool isCurrentFolder: itemData && itemData.expandable && fp(itemData.path) === appControl.currentFolder
    property bool isCurrentFile:   itemData && !itemData.expandable && fp(itemData.path) === appControl.currentFile

    // ---------------------------------------------------------------
    // Logic
    // ---------------------------------------------------------------

    onClicked: {
        if (!itemData)
            return;

        if (itemData.expandable)
            itemData.expanded = !itemData.expanded
        else if (itemData.path.endsWith("qml")) {
            var path = "file:///" + String(itemData.path)
            var folder = path.substring(0, path.lastIndexOf("/"))

            appControl.setCurrentFileAndFolder(folder, path)
        }
    }

    // ---------------------------------------------------------------
    // View
    // ---------------------------------------------------------------

    width: parent.width
//    height: _.rowHeight
    clip: true

    highlighted: isCurrentFolder || isCurrentFile
    padding: 0

    // Top row
    Row {
        id: contentRow

        anchors.top: parent.top
        width: parent.width
        height: _.rowHeight

        spacing: 0

        Icon {
            height: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            source: _.icon()
            color: _.iconColor()
        }

        Label {
            height: parent.height
            verticalAlignment: Text.AlignVCenter

            text: itemData ? itemData.name : ""
            color: _.textColor()
            font.bold: itemDelegate.isCurrentFile || itemDelegate.isCurrentFolder
            font.family: ui.defaultFont
        }
    }

    // Contextual folder actions
    Row {
        id: folderActionsRow

        anchors.top: parent.top
        anchors.right: parent.right
        height: _.rowHeight
        visible: itemDelegate.hovered && itemData && itemData.expandable
        spacing: -8 * dp

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

            onClicked: Qt.openUrlExternally(fp(itemData.path)) //appControl.runCommand("cmd /c explorer \"%1\"".arg(itemData))

            imageSource: "qrc:///img/folder.svg"
            margins: 5

            ToolTip.text: "Open in explorer"
        }
        IconButton {
            id: trashButton
            height: parent.height
            width: height
            anchors.verticalCenter: parent.verticalCenter

            visible: itemData && appControl.isInFolderList(fp(itemData.path))

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
        spacing: -8 * dp

        visible: itemDelegate.hovered && itemData && !itemData.expandable

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

    // Children
    Column {
        id: childrenColumn
        anchors.top: contentRow.bottom
        anchors.leftMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
//            width: parent.width
//            height: childrenRect.height

            model: itemDelegate.itemData ? itemDelegate.itemData.entries : 0

            delegate: Loader {
                width: parent.width
//                height: item ? item.height : 0
                source: "FsEntryDelegate2.qml"
                onLoaded: {
                    item.itemData = modelData
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // States
    // ---------------------------------------------------------------

//    Component.onDestruction: {
//        print(this + "is being destroyed")
//    }

//    onStateChanged: {
//        print(this + " state is now " + state + "(height: %1)".arg(itemDelegate.height))
//    }

//    onHeightChanged: {
//        print(this + " height is now " + height)
//    }

    states: [
        State {
            name: "hidden"
            when: itemData && (!itemData.visible)
            PropertyChanges {
                target: itemDelegate
                height: Number.MIN_VALUE
                restoreEntryValues: true
            }
        },
        State {
            name: "expanded"
            when: itemData && itemData.expandable && itemData.expanded
            PropertyChanges {
                target: itemDelegate
                height: contentRow.height + childrenColumn.height
//                restoreEntryValues: false
                restoreEntryValues: true
            }
        },
        State {
            name: "normal"
            when: itemData && ((itemData.expandable && (!itemData.expanded)) ||
                               (!itemData.expandable))
            PropertyChanges {
                target: itemDelegate
                height: _.rowHeight
                restoreEntryValues: false
//                restoreEntryValues: true
            }
        }
    ]


    // ---------------------------------------------------------------
    // Utilities
    // ---------------------------------------------------------------
    QtObject {
        id: _

        property int rowHeight: 50 * dp

        function icon()
        {
            if (!itemData)
                return "";

            if (itemData.expandable)
            {
                if (itemData.expanded)
                    return "img/folderOpen.svg"
                else
                    return "img/folder.svg"
            }
            return "img/newFile.svg"
        }

        function iconColor()
        {
            if (!itemData)
            {
                return "red"
            }

            if (itemDelegate.isCurrentFolder)
            {
                return Material.accent
            }
            else if (itemDelegate.isCurrentFile)
            {
                return "#f9a825"
            }
            else if (itemData.expandable)
            {
                return "white"
            }
            else if (itemData.path.endsWith("qml"))
            {
                return "#81d4fa"
            }
            else
            {
                return "#69f0ae"
            }
        }

        function textColor()
        {
            if (itemDelegate.isCurrentFolder || itemDelegate.isCurrentFile)
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
