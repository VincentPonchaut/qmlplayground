import QtQuick 2.5
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12

ItemDelegate {
    id: itemDelegate

    // --------------------------------------------------------------------------
    // Data
    // --------------------------------------------------------------------------

    property bool isExpandable: childCount > 0
    property bool isExpanded: state == "expanded"

    property var childModel;
//    property alias childModel: substepsDelegate.model
//    property int childCount: typeof(model[childrenRole]) !== "undefined" ? model[childrenRole].rowCount() : 0//childModel.count
    property int childCount;
    Binding on childCount {
        when: typeof(modelData[childrenRole]) !== "undefined"
//        when: (model.hasModelChildren)
        value: modelData[childrenRole].rowCount()
    }

    property int rowHeight: 40

    property string textRole: "modelData"
    property string childrenRole: "children"

    property bool isCurrentFolder: (model.isDir && fp(model.path) === appControl.currentFolder)
    property bool isCurrentFile: (!model.isDir && fp(model.path) === appControl.currentFile)

    property var modelIndex: visualModel.modelIndex(index)
    property var parentIndex: visualModel.parentModelIndex()
    property var modelData: visualModel.model.data(modelIndex)

    // --------------------------------------------------------------------------
    // Logic
    // --------------------------------------------------------------------------

    // Hack because somehow the listview is not notified
    onChildCountChanged:
    {
        substepsDelegate.model = []
        itemDelegate.childModelChanged()
        substepsDelegate.model = itemDelegate.childModel
    }

    function toggleState() {
        state = state == "expanded" ? "folded" : "expanded"
    }
    function expand() {
        state = "expanded"
    }
    function collapse() {
        state = "folded"
    }

    function expandAll() {
        expand()
        callOnChildren("expandAll")
    }
    function collapseAll() {
        collapse()
        callOnChildren("collapseAll")
    }

    function collapseChildren() {
        callOnChildren("collapseAll")
    }
    function isAnyChildCollapsed() {
        for (var i = 0; i < substepsDelegate.children.length; ++i)
        {
            var child = substepsDelegate.children[i]

            if (getType(child) == "Loader")
                child = child.item

            if (typeof(child["isExpanded"]) !== "undefined" &&
                !child["isExpanded"])
            {
                return true;
            }
        }
        return false;
    }

    onClicked: {
        // Handle click for folders
        if (modelData.isDir)
        {
            if (!isExpanded)
                expand()
            else
                collapse()
            return;
        }
        else if (modelData.path.endsWith("qml"))
        {
            var path = "file:///" + String(modelData.path)
            var folder = path.substring(0, path.lastIndexOf("/"));

            appControl.setCurrentFileAndFolder(folder, path)
        }
    }

    // --------------------------------------------------------------------------
    // View
    // --------------------------------------------------------------------------

//    background: Rectangle {
//        anchors.fill: parent
//        color: Qt.rgba(Math.random(),Math.random(),Math.random())
//    }
    highlighted: isCurrentFolder || isCurrentFile
    padding: 0

    Row {
        id: stepDelegateContentRow
        width: parent.width
        height: rowHeight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: spacing

        spacing: 10

        Icon {
            height: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            source: isExpanded && modelData.isDir ? "img/folderOpen.svg" :
                                  modelData.isDir ? "img/folder.svg" :
                                                "img/newFile.svg";
            color: isCurrentFolder ? Material.accent :
                   isCurrentFile ? "#f9a825" :
                   modelData.isDir ? "white" :
                   modelData.path.endsWith("qml") ? "#81d4fa" :
                                                "#69f0ae"
        }

        Label {
            height: parent.height
//            text: model[textRole]
            text: modelData[textRole]

            opacity: itemDelegate.isExpandable && itemDelegate.state === "expanded" ? 0.6 : 1
            font.bold: modelData.isDir
            font.italic: itemDelegate.isExpandable && itemDelegate.state === "expanded"
            font.family: "Montserrat, Segoe UI, Arial"
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: debugInfo
            text: ""+ typeof(modelData.entries) != "undefined" ? modelData.entries.rowCount() : ""
        }
    }

//    // Contextual folder actions
//    Row {
//        id: folderActionsRow

//        anchors.top: parent.top
//        anchors.right: parent.right
//        height: rowHeight
//        visible: itemDelegate.hovered && modelData.isDir

//        IconButton {
//            id: newFileButton

//            height: parent.height
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            onClicked: fileCreationPopup.openForFolder(fp(modelData.path))
//            imageSource: "qrc:///img/newFile.svg"
//            ToolTip.text: "New file"
//        }

//        RoundButton {
//            id: infoButton
//            height: parent.height
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            onClicked: Qt.openUrlExternally(fp(modelData.path))//appControl.runCommand("cmd /c explorer \"%1\"".arg(modelData))

//            Image {
//                anchors.fill: parent
//                anchors.margins: 5

//                fillMode: Image.PreserveAspectFit
//                smooth: true
//                source: "qrc:///img/folder.svg"
//            }

//            ToolTip.visible: hovered
//            ToolTip.text: "Open in explorer"
//        }
//        RoundButton {
//            id: trashButton
//            height: parent.height
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            visible: appControl.isInFolderList(fp(modelData.path))

//            Image {
//                anchors.fill: parent
//                anchors.margins: 5

//                fillMode: Image.PreserveAspectFit
//                smooth: true
//                source: "qrc:///img/eye_off.svg"
//            }

//            ToolTip.visible: hovered
//            ToolTip.text: "Stop watching folder"

//            onClicked: {
//                if (isCurrentFolder || isCurrentFile) {
//                    appControl.setCurrentFileAndFolder("", "");
//                }

//                appControl.removeFromFolderList(modelData.path)
//            }
//        }
//    }

//    // Contextual file actions
//    Row {
//        id: fileActionsRow

//        anchors.top: parent.top
//        anchors.right: parent.right
//        height: rowHeight
//        visible: itemDelegate.hovered && !modelData.isDir //&& String(modelData.path).length > 0

//        IconButton {
//            id: exploreToButton

//            height: parent.height * 0.9
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            onClicked: Qt.openUrlExternally(fp(parentFolder(modelData.path)))
//            imageSource: "qrc:///img/folder.svg"
//            ToolTip.text: "Open in explorer"
//        }

//        IconButton {
//            id: editFileButton

//            height: parent.height * 0.9
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            onClicked: Qt.openUrlExternally(fp(modelData.path))
//            imageSource: "qrc:///img/edit.svg"
//            ToolTip.text: "Open file in external editor"
//        }

//        IconButton {
//            id: editFileContentButton

//            height: parent.height * 0.9
//            width: height
//            anchors.verticalCenter: parent.verticalCenter

//            onClicked: editFileLocally(fp(modelData.path));
//            imageSource: "qrc:///img/code.svg"
//            ToolTip.text: "Quick edit"
//        }
//        // TODO: clone file
//        // TODO: remove file
//    }

    ListView {
//    Column {
        id: substepsDelegate
        anchors.top: stepDelegateContentRow.bottom
        height: childrenRect.height
        anchors.left: parent.left
        anchors.leftMargin: rowHeight / 3
        anchors.right: parent.right
        spacing: 1

        visible: parent.state == "expanded"

//        model: typeof(itemDelegate.childModel) !== "undefined" ? itemDelegate.childModel : 0
//Repeater {
//        Binding on model {
//            when: typeof(itemDelegate.childModel) !== "undefined"
//            value: itemDelegate.childModel
//        }
        Binding on model {
            when: typeof(itemDelegate.childModel) !== "undefined"
            value: itemDelegate.childModel.rowCount(modelIndex)
        }

        delegate: Item {
            width: parent.width
            height: substepDelegateLoader.item.height // childrenRect.height

            Loader {
                id: substepDelegateLoader
                width: parent.width
                height: childrenRect.height
//                asynchronous: true // dont put async loader in listview
//                asynchronous: appControl.folderModel.filterText.length > 0
            }
            Label {
//                anchors.fill: parent
                text: "cc(" + childCount + "), ssdheight: " + substepsDelegate.height + " idheight: " + itemDelegate.height
                Component.onCompleted: {
                    print("" + Object.keys(model.entries))
                }
            }

            Component.onCompleted: {
                substepDelegateLoader.setSource("VisualItemDelegate.qml",
                                                {
                                                    "textRole" : itemDelegate.textRole,
                                                    //"childModel" : typeof(modelData.entries) != "undefined" ? Qt.binding(function(){ return model.entries }) : [],
                                                    "childModel" : modelData.entries,
                                                    "childrenRole": "entries",
//                                                    "childCount" : typeof(model.entries) != "undefined" ? Qt.binding(function(){ return model.entries.rowCount()}) : 0
//                                                    "childModel" : typeof(model.entries) != "undefined" ? model.entries : [],
//                                                    "childCount" : typeof(model.entries) != "undefined" ? model.entries.rowCount() : 0
                                                })
            }
        }

//        Text {
//            anchors.centerIn: parent
//            text: "ssc: " + substepsDelegate.count + "-" + childCount
//        }
//} // Repeater
    }

    states: [
        State {
            name: "expanded"
            PropertyChanges {
                target: itemDelegate
                height: itemDelegate.rowHeight + substepsDelegate.height
                restoreEntryValues: false
            }
        },
        State {
            name: "folded"
            PropertyChanges {
                target: itemDelegate
                height: itemDelegate.rowHeight
                restoreEntryValues: false
            }
        }
    ]
    state: "folded"

    // ---------------------------------------------------------------
    // Utilities
    // ---------------------------------------------------------------

    function parentFolder(filepath) {
        return filepath.substring(0, filepath.lastIndexOf("/"));
    }

    function fp(filepath) {
        if (filepath.startsWith("file:///"))
            return filepath
        else
            return "file:///" + filepath
    }
}
