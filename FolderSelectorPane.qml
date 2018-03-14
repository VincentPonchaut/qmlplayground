import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
Pane {
    id: folderSelectorPane
    
    // Settings
    property alias filterText: filterTextField.text

    // Data
    property var folders;
    property ListModel qmlFiles: ListModel {}

    function refresh() {
        qmlFiles.clear();

        folders.forEach(function(folder) {
            var files = appControl.listFiles(folder);

            files.forEach(function(file)
            {
                if (!String(file).toLowerCase().includes(folderSelectorPane.filterText.toLowerCase()))
                    return;

                qmlFiles.append({
                                    "file" : file,
                                    "folder" : folder
                                });
            })
        });
    }
    onFoldersChanged: refresh()
    onFilterTextChanged: refresh()

    function focusFileFilter() {
        filterTextField.forceActiveFocus()
    }

    width: parent.width * 1/4
    Material.theme: Material.Dark
    Material.elevation: 15
    z: contentPage.z + 10
    padding: 0

    focus: state == "open"
    Keys.onPressed: {
        print("zii")
    }

    Keys.onUpPressed: {
        print("Up pressed")
        listView.decrementCurrentIndex()
    }
    Keys.onDownPressed:  {
        print("Down pressed")
        listView.incrementCurrentIndex()
    }

    Connections {
        target: listView
        onCurrentIndexChanged: {
            var vFilePath = listView.currentItem["filePath"]
            var vFolderPath = listView.currentItem["folderPath"]

            appControl.currentFile = vFilePath
            appControl.currentFolder = vFolderPath
        }
    }

    Pane {
        id: folderSectionTitlePane
        
        width: parent.width
        height: optionsPane.height
        
        Material.elevation: 10
        
        background: Rectangle { color: Qt.darker(Material.background, 1.25) }
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        
        Row {
            anchors.centerIn: parent
            height: parent.height
            
            Image {
                height: parent.height
                anchors.margins: 5
                fillMode: Image.PreserveAspectFit
                source: "qrc:///img/folder.svg"
            }
            
            Label {
                text: "Active Folders"
                anchors.verticalCenter: parent.verticalCenter
                color: Material.accent
            }
        }
        
        ToolButton {
            id: newFolderButton
            
            visible: folderSectionTitlePane.hovered
            anchors.right: parent.right
            
            onClicked: folderCreationPopup.open()
            
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                anchors.margins: 5
                source: "qrc:///img/newFolder.svg"
                mipmap: true
            }
        }
    }
    
    Pane {
        id: filterPane
        width: parent.width
        height: optionsPane.height

        anchors {
            top: folderSectionTitlePane.bottom
            left: parent.left
            right: parent.right
        }

//        ComboBox {
//            editable: true
//            width: parent.width * 0.77
//            model: qmlFiles
//            textRole: "file"
//        }

        TextField {
            id: filterTextField
            width: parent.width * 0.77
            anchors.centerIn: parent
            placeholderText: "Filter files..."
            selectByMouse: true
        }
    }

    ListView {
        id: listView
        
        width: parent.width
        height: parent.height - folderSectionTitlePane.height - filterPane.height

        clip: true
        
        anchors {
            top: filterPane.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        model: folderSelectorPane.qmlFiles

        property var foldedSections: []

        section.property: "folder"
        section.delegate: ItemDelegate
        {
            id: folderDelegate

            width: parent.width
            height: 55
            background: Rectangle { color: Qt.darker(Material.background) }

            topPadding: 0
            bottomPadding: 0
            rightPadding: 2

            function unfold() {
                var arrCopy = listView.foldedSections.slice();
                var sectionIndex = listView.foldedSections.indexOf(section)
                arrCopy.splice(sectionIndex, 1);
                listView.foldedSections = arrCopy
            }

            function fold() {
                var arrCopy = listView.foldedSections.slice();
                arrCopy.push("" + section);
                listView.foldedSections = arrCopy
            }

            function toggle() {
                if (isFolded)
                    unfold()
                else
                    fold()
            }

            property bool isFolded: (listView.foldedSections.indexOf(section) !== -1)
            Connections {
                target: listView
                onFoldedSectionsChanged: {
                    folderDelegate.isFolded = (listView.foldedSections.indexOf(section) !== -1)
                }
            }

            onClicked: toggle()

            Row {
                height: parent.height

                // Folder icon
                Image {
                    id: sectionHeaderIcon
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 5

                    fillMode: Image.PreserveAspectFit
                    source: folderDelegate.isFolded ? "qrc:///img/folder.svg":
                                                      "qrc:///img/folderOpen.svg";

                }

                // only display the folderName
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        var dirs = section.split("/");
                        return String(dirs[dirs.length - 1]);
                    }
                }
            }

            ToolTip.visible: hovered //infoButton.hovered
            ToolTip.delay: 1000
            ToolTip.text: ("" + section).replace("file:///", "")

            // Contextual folder actions
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                visible: folderDelegate.hovered

                IconButton {
                    id: newFileButton

                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: fileCreationPopup.openForFolder(section)
                    imageSource: "qrc:///img/newFile.svg"
                    ToolTip.text: "New file"
                }

                RoundButton {
                    id: infoButton
                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Qt.openUrlExternally(section)//appControl.runCommand("cmd /c explorer \"%1\"".arg(modelData))

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: "qrc:///img/folder.svg"
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: "Open in explorer"
                }
                RoundButton {
                    id: trashButton
                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: "qrc:///img/trash.svg"
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: "Remove folder"

                    onClicked: appControl.removeFromFolderList(section)
                }
            }
        }

        delegate: ItemDelegate
        {
            id: fileDelegate

            property string filePath: ListView.section + file
            property string folderPath: ListView.section

            property bool isSectionFolded: listView.foldedSections.indexOf(ListView.section) !== -1
            property bool matchesFilter: {
                return String(file).toLowerCase().includes(filterTextField.text.toLowerCase());
            }

            width: parent.width
            height: (isSectionFolded || !matchesFilter ) ? 0 : 50
            Behavior on height { NumberAnimation { easing.type: Easing.InOutCubic; duration: 500 } }

            text: "" + file
            font.pointSize: 10
            //highlighted: filePath === appControl.currentFile
            highlighted: ListView.isCurrentItem

            onClicked: {
                listView.currentIndex = index
//                appControl.currentFile = fileDelegate.filePath;
//                appControl.currentFolder = folderPath;
            }

            // Contextual file actions
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                visible: fileDelegate.hovered

                IconButton {
                    id: editFileButton

                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Qt.openUrlExternally(appControl.currentFile)
                    imageSource: "qrc:///img/edit.svg"
                    ToolTip.text: "Open file in external editor"
                }

                IconButton {
                    id: editFileContentButton

                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: editFileContent(fileDelegate.filePath);
                    imageSource: "qrc:///img/code.svg"
                    ToolTip.text: "Quick edit"
                }
                // TODO: clone file
                // TODO: remove file
            }

        }
        
    }
    RoundButton {
        id: addFolderButton
        width: 60
        height: width
        text: "+"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        onClicked: folderDialog.open()
        
        ToolTip.visible: hovered
        ToolTip.text: "Add another folder"
    }
    
    states: [
        State {
            name: "open"
        },
        State {
            name: "closed"
            PropertyChanges {
                target: folderSelectorPane
                x: -folderSelectorPane.width
            }
            AnchorChanges {
                target: folderSelectorPane
                anchors.left: undefined //remove myItem's left anchor
            }
        }
    ]
    state: "open"
    
    transitions: Transition {
        from: "open"
        to: "closed"
        reversible: true
        
        NumberAnimation { properties: "x"; easing.type: Easing.InOutQuad }
    }
    
    function toggle() {
        state = (state == "open" ? "closed" : "open");
    }
}
